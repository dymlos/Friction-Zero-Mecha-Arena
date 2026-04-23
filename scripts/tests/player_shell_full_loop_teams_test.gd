extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(game_shell)
	current_scene = game_shell

	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "main_menu",
		"El loop integrado Teams deberia arrancar en el menu principal de la shell."
	)

	game_shell.call("open_local_setup")
	await process_frame
	await process_frame

	var setup: Variant = game_shell.call("get_active_screen")
	_assert(setup != null, "La shell deberia exponer el setup local antes de lanzar Teams.")
	if setup == null:
		await _cleanup_current_scene()
		_finish()
		return

	var launch_config: Variant = setup.call("build_launch_config")
	_assert(launch_config is MatchLaunchConfig, "El setup local deberia construir un launch config real para Teams.")
	if not (launch_config is MatchLaunchConfig):
		await _cleanup_current_scene()
		_finish()
		return

	game_shell.call("launch_local_match", launch_config)
	await process_frame
	await process_frame
	await process_frame

	var main := current_scene
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var recap_title_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapTitleLabel") as Label
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapLabel") as Label
	var match_result_title_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultTitleLabel") as Label
	var match_result_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultLabel") as Label
	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var robots := _get_scene_robots(main)

	_assert(main != null, "Lanzar desde shell deberia abrir la escena principal de Teams.")
	_assert(match_controller != null, "El loop integrado Teams deberia exponer MatchController.")
	_assert(recap_title_label != null and recap_label != null, "Teams deberia exponer recap final legible en el loop integrado.")
	_assert(match_result_title_label != null and match_result_label != null, "Teams deberia exponer resultado final legible en el loop integrado.")
	_assert(round_label != null, "Teams deberia seguir exponiendo RoundLabel en el HUD integrado.")
	_assert(robots.size() >= 4, "Teams deberia seguir exponiendo cuatro robots para el loop integrado.")
	if main == null or match_controller == null or recap_title_label == null or recap_label == null or match_result_title_label == null or match_result_label == null or round_label == null or robots.size() < 4:
		await _cleanup_current_scene()
		_finish()
		return

	_assert(
		String(main.get("entry_context")) == MatchLaunchConfig.ENTRY_CONTEXT_PLAYER_SHELL,
		"Teams lanzado desde shell deberia conservar contexto `player_shell`."
	)

	var pause_requested := bool(main.call("request_pause_for_slot", 2))
	_assert(pause_requested, "El owner local deberia poder abrir pausa dentro del loop integrado Teams.")
	var pause_lines := PackedStringArray(main.call("get_pause_overlay_lines"))
	var pause_text := "\n".join(pause_lines)
	_assert(
		pause_text.contains("Volver al menu"),
		"La pausa integrada Teams deberia conservar la salida a menu propia de `player_shell`."
	)
	_assert(
		not pause_text.contains("Lab |"),
		"La pausa integrada Teams no deberia filtrar metadata del laboratorio."
	)
	_assert(
		bool(main.call("request_resume_for_slot", 2)),
		"El owner local deberia poder reanudar la partida integrada tras abrir pausa."
	)

	match_controller.match_config.rounds_to_win = 1
	for robot in robots:
		robot.void_fall_y = -100.0

	robots[2].fall_into_void()
	robots[3].fall_into_void()
	await create_timer(0.1).timeout

	_assert(match_controller.is_match_over(), "El loop integrado Teams deberia cerrar la partida al ganar la primera ronda configurada.")
	_assert(
		recap_title_label.text == "Resultado de partida",
		"Teams integrado deberia distinguir cierre de partida en el recap."
	)
	_assert(
		match_result_title_label.text == "Partida cerrada",
		"Teams integrado deberia distinguir cierre de partida en el panel final."
	)
	_assert(
		recap_label.text.contains("Equipo 1 gana la partida"),
		"El recap integrado Teams deberia reiterar la decision final del match."
	)
	_assert(
		match_result_label.text.contains("Equipo 1 gana la partida"),
		"El panel final integrado Teams deberia reiterar la decision final del match."
	)
	_assert(
		not round_label.text.contains("Lab |") and not round_label.text.contains("HUD |"),
		"El HUD integrado Teams no deberia exponer prompts del laboratorio."
	)
	_assert(
		not recap_label.text.contains("Reinicio | F5"),
		"El recap integrado Teams no deberia anunciar reinicio de laboratorio en `player_shell`."
	)
	_assert(
		not match_result_label.text.contains("Reinicio | F5"),
		"El panel final integrado Teams no deberia anunciar reinicio de laboratorio en `player_shell`."
	)

	await create_timer(match_controller.match_restart_delay + 0.4).timeout

	_assert(
		match_controller.is_match_over(),
		"El cierre Teams lanzado desde shell deberia mantenerse estable y no autoreiniciarse."
	)
	_assert(
		recap_label.visible,
		"El recap integrado Teams deberia seguir visible mientras el jugador decide salir."
	)
	_assert(
		match_result_label.visible,
		"El panel final integrado Teams deberia seguir visible mientras el jugador decide salir."
	)

	await _cleanup_current_scene()
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _cleanup_current_scene() -> void:
	if current_scene == null or not is_instance_valid(current_scene):
		return

	var scene := current_scene
	var parent := scene.get_parent()
	if parent != null:
		parent.remove_child(scene)
	scene.free()
	current_scene = null
	paused = false
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
