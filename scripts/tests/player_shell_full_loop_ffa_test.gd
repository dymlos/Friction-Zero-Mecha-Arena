extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")
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

	game_shell.call("open_local_setup")
	await process_frame
	await process_frame

	var setup: Variant = game_shell.call("get_active_screen")
	_assert(setup != null, "La shell deberia exponer el setup local antes de lanzar FFA.")
	if setup == null:
		await _cleanup_current_scene()
		_finish()
		return

	setup.call("set_match_mode", MatchController.MatchMode.FFA)
	var launch_config: Variant = setup.call("build_launch_config")
	_assert(launch_config is MatchLaunchConfig, "El setup local deberia construir un launch config real para FFA.")
	if not (launch_config is MatchLaunchConfig):
		await _cleanup_current_scene()
		_finish()
		return
	_assert(
		launch_config.mode_variant_id == MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE,
		"El loop FFA principal debe seguir default en Puntos por eliminacion."
	)

	game_shell.call("launch_local_match", launch_config)
	await process_frame
	await process_frame
	await process_frame

	var main := current_scene
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapScroll/RecapLabel") as Label
	var match_result_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultScroll/MatchResultLabel") as Label
	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var robots := _get_scene_robots(main)

	_assert(main != null, "Lanzar desde shell deberia abrir la escena principal de FFA.")
	_assert(match_controller != null, "El loop integrado FFA deberia exponer MatchController.")
	_assert(recap_label != null and match_result_label != null, "FFA deberia exponer recap y resultado final legibles en el loop integrado.")
	_assert(round_label != null, "FFA deberia seguir exponiendo RoundLabel en el HUD integrado.")
	_assert(robots.size() >= 4, "FFA deberia seguir exponiendo cuatro robots para validar standings integrados.")
	if main == null or match_controller == null or recap_label == null or match_result_label == null or round_label == null or robots.size() < 4:
		await _cleanup_current_scene()
		_finish()
		return

	_assert(
		String(main.get("entry_context")) == MatchLaunchConfig.ENTRY_CONTEXT_PLAYER_SHELL,
		"FFA lanzado desde shell deberia conservar contexto `player_shell`."
	)

	match_controller.match_config.rounds_to_win = 1
	for robot in robots:
		robot.void_fall_y = -100.0

	robots[0].fall_into_void()
	await create_timer(0.05).timeout
	robots[1].fall_into_void()
	await create_timer(0.05).timeout
	robots[2].fall_into_void()
	await create_timer(0.1).timeout

	var winner_name := robots[3].display_name
	var standings_line := "Posiciones | 1. %s (2) | 2. %s (0) | 3. %s (0) | 4. %s (0)" % [
		robots[3].display_name,
		robots[2].display_name,
		robots[1].display_name,
		robots[0].display_name,
	]
	var tiebreak_line := "Desempate | 0 pts: %s > %s > %s" % [
		robots[2].display_name,
		robots[1].display_name,
		robots[0].display_name,
	]

	_assert(match_controller.is_match_over(), "El loop integrado FFA deberia cerrar la partida al quedar un solo robot.")
	_assert(
		recap_label.text.contains("%s gana la partida" % winner_name),
		"El recap integrado FFA deberia reiterar al ganador final."
	)
	_assert(
		match_result_label.text.contains("%s gana la partida" % winner_name),
		"El panel final integrado FFA deberia reiterar al ganador final."
	)
	_assert(
		recap_label.text.contains(standings_line),
		"El recap integrado FFA deberia dejar visibles las posiciones finales."
	)
	_assert(
		match_result_label.text.contains(standings_line),
		"El panel final integrado FFA deberia dejar visibles las posiciones finales."
	)
	_assert(
		recap_label.text.contains(tiebreak_line),
		"El recap integrado FFA deberia dejar visible el desempate final."
	)
	_assert(
		match_result_label.text.contains(tiebreak_line),
		"El panel final integrado FFA deberia dejar visible el desempate final."
	)
	_assert(
		not round_label.text.contains("Lab |") and not round_label.text.contains("HUD |"),
		"El HUD integrado FFA no deberia exponer prompts del laboratorio."
	)
	_assert(
		not recap_label.text.contains("Reinicio | F5"),
		"El recap integrado FFA no deberia anunciar reinicio de laboratorio en `player_shell`."
	)
	_assert(
		not match_result_label.text.contains("Reinicio | F5"),
		"El panel final integrado FFA no deberia anunciar reinicio de laboratorio en `player_shell`."
	)

	await create_timer(match_controller.match_restart_delay + 0.4).timeout

	_assert(
		match_controller.is_match_over(),
		"El cierre FFA lanzado desde shell deberia mantenerse estable y no autoreiniciarse."
	)
	_assert(
		recap_label.visible,
		"El recap integrado FFA deberia seguir visible mientras el jugador decide salir."
	)
	_assert(
		match_result_label.visible,
		"El panel final integrado FFA deberia seguir visible mientras el jugador decide salir."
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
