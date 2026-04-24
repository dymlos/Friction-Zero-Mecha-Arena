extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")
const PRACTICE_MODE_SCENE := preload("res://scenes/practice/practice_mode.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_shell_entry_and_configuration()
	await _verify_practice_is_part_of_product_cut()
	await _verify_competitive_match_pause_and_close()
	_finish()


func _verify_shell_entry_and_configuration() -> void:
	var game_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(game_shell)
	current_scene = game_shell
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "main_menu",
		"M7 debe arrancar desde menu principal, no desde laboratorio."
	)

	game_shell.call("open_settings")
	await process_frame
	await process_frame
	_assert(
		String(game_shell.call("get_active_screen_id")) == "settings",
		"El primer corte completo debe exponer Settings desde menu principal."
	)
	var settings: Variant = game_shell.call("get_active_screen")
	_assert(settings != null, "Settings debe montarse como pantalla real de shell.")
	if settings != null:
		_assert(
			settings.has_method("get_available_sections") or settings.has_method("focus_back_button"),
			"Settings debe conservar una API navegable para foco/retorno."
		)

	if settings != null and settings.has_method("emit_signal"):
		settings.call("emit_signal", "back_requested")
	else:
		game_shell.call("return_to_main_menu")
	await process_frame
	await process_frame

	game_shell.call("open_local_setup")
	await process_frame
	await process_frame
	_assert(
		String(game_shell.call("get_active_screen_id")) == "local_match_setup",
		"El primer corte completo debe permitir configurar una sesion local antes de jugar."
	)

	var setup: Variant = game_shell.call("get_active_screen")
	_assert(setup != null, "Local setup debe estar activo.")
	if setup == null:
		await _cleanup_current_scene()
		return

	_assert(setup.has_method("build_launch_config"), "Local setup debe construir MatchLaunchConfig real.")
	_assert(setup.has_method("set_slot_control_mode"), "Local setup debe editar Simple/Avanzado por slot.")
	_assert(setup.has_method("set_slot_input_source"), "Local setup debe editar teclado/joypad por slot.")
	_assert(setup.has_method("set_match_mode"), "Local setup debe editar modo Teams/FFA.")

	if setup.has_method("set_slot_control_mode"):
		setup.call("set_slot_control_mode", 1, RobotBase.ControlMode.EASY)
		setup.call("set_slot_control_mode", 2, RobotBase.ControlMode.HARD)
	if setup.has_method("set_slot_input_source"):
		setup.call("set_slot_input_source", 1, "keyboard")
		setup.call("set_slot_input_source", 2, "keyboard")

	var launch_config: Variant = setup.call("build_launch_config")
	_assert(launch_config is MatchLaunchConfig, "Configurar debe producir MatchLaunchConfig.")
	if launch_config is MatchLaunchConfig:
		var typed := launch_config as MatchLaunchConfig
		_assert(
			typed.entry_context == MatchLaunchConfig.ENTRY_CONTEXT_PLAYER_SHELL,
			"El match competitivo debe salir con contexto player_shell."
		)
		_assert(
			typed.local_slots.size() >= 2,
			"El primer corte debe transportar al menos P1/P2 desde setup."
		)
		_assert(
			int(typed.local_slots[0].get("control_mode", -1)) == RobotBase.ControlMode.EASY,
			"P1 Easy debe viajar desde setup al launch config."
		)
		_assert(
			int(typed.local_slots[1].get("control_mode", -1)) == RobotBase.ControlMode.HARD,
			"P2 Hard debe viajar desde setup al launch config."
		)

	await _cleanup_current_scene()


func _verify_practice_is_part_of_product_cut() -> void:
	var game_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(game_shell)
	current_scene = game_shell
	await process_frame
	await process_frame

	_assert(game_shell.has_method("open_practice_setup"), "GameShell debe exponer Practica como ruta de jugador.")
	game_shell.call("open_practice_setup", "main_menu", "impacto")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "practice_setup",
		"Practica debe abrirse desde menu principal como parte del corte completo."
	)
	var practice_setup: Variant = game_shell.call("get_active_screen")
	_assert(practice_setup != null, "PracticeSetup debe estar activo.")
	if practice_setup == null:
		await _cleanup_current_scene()
		return

	_assert(practice_setup.has_method("get_selected_module_id"), "PracticeSetup debe exponer modulo seleccionado.")
	_assert(practice_setup.has_method("build_launch_config"), "PracticeSetup debe construir launch config real.")
	_assert(practice_setup.has_method("get_player_scope_line"), "PracticeSetup debe comunicar 1-2P/ayuda visible.")
	_assert(
		String(practice_setup.call("get_selected_module_id")) == "impacto",
		"Practica debe poder abrir modulo contextual desde shell."
	)
	if practice_setup.has_method("get_player_scope_line"):
		var scope_line := String(practice_setup.call("get_player_scope_line"))
		_assert(scope_line.contains("1-2"), "Practica debe comunicar alcance 1-2 jugadores.")
		_assert(scope_line.contains("ayuda visible"), "Practica debe comunicar ayuda visible por defecto.")

	var practice_launch_config: Variant = practice_setup.call("build_launch_config")
	_assert(practice_launch_config is MatchLaunchConfig, "PracticeSetup debe emitir MatchLaunchConfig.")
	if practice_launch_config is MatchLaunchConfig:
		var typed_practice := practice_launch_config as MatchLaunchConfig
		_assert(
			typed_practice.entry_context == MatchLaunchConfig.ENTRY_CONTEXT_PRACTICE,
			"Practica debe viajar con contexto practice, no player_shell ni laboratorio."
		)
		_assert(
			typed_practice.target_scene_path == "res://scenes/practice/practice_mode.tscn",
			"Practica debe lanzar runtime propio, separado de main*.tscn."
		)

	var shell_session := ShellSession.new()
	if practice_launch_config is MatchLaunchConfig:
		shell_session.store_match_launch_config(practice_launch_config)
	var practice_mode := PRACTICE_MODE_SCENE.instantiate()
	root.add_child(practice_mode)
	await process_frame
	await process_frame

	_assert(practice_mode.has_method("get_pause_lines"), "PracticeMode debe exponer pausa propia.")
	_assert(practice_mode.has_method("request_pause_for_slot"), "PracticeMode debe pausar por slot.")
	if practice_mode.has_method("request_pause_for_slot"):
		_assert(bool(practice_mode.call("request_pause_for_slot", 1)), "Practica debe poder pausar desde P1.")
		var pause_lines := PackedStringArray(practice_mode.call("get_pause_lines"))
		var pause_text := "\n".join(pause_lines)
		_assert(pause_text.contains("Volver al menu"), "Pausa de practica debe permitir cerrar hacia menu.")
		_assert(not pause_text.contains("Lab |"), "Pausa de practica no debe filtrar metadata de laboratorio.")
		_assert(bool(practice_mode.call("request_resume_for_slot", 1)), "Practica debe poder reanudar desde P1.")

	if is_instance_valid(practice_mode):
		practice_mode.queue_free()
	await _cleanup_current_scene()


func _verify_competitive_match_pause_and_close() -> void:
	var game_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(game_shell)
	current_scene = game_shell
	await process_frame
	await process_frame

	game_shell.call("open_local_setup")
	await process_frame
	await process_frame

	var setup: Variant = game_shell.call("get_active_screen")
	_assert(setup != null and setup.has_method("build_launch_config"), "Setup debe poder lanzar match competitivo.")
	if setup == null or not setup.has_method("build_launch_config"):
		await _cleanup_current_scene()
		return

	var launch_config: Variant = setup.call("build_launch_config")
	_assert(launch_config is MatchLaunchConfig, "Setup debe construir launch config para match competitivo.")
	if not (launch_config is MatchLaunchConfig):
		await _cleanup_current_scene()
		return

	var typed_launch_config := launch_config as MatchLaunchConfig
	typed_launch_config.auto_restart_on_match_end = false
	var match_scene: Variant = game_shell.call("build_local_match_scene", typed_launch_config)
	_assert(match_scene is Node, "GameShell debe construir match real usando wiring comun.")
	if not (match_scene is Node):
		await _cleanup_current_scene()
		return

	await _cleanup_current_scene()
	root.add_child(match_scene)
	current_scene = match_scene
	await process_frame
	await process_frame

	var main := match_scene as Node
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "Match competitivo debe tener MatchController.")
	_assert(robots.size() >= 4, "Teams base debe conservar robots suficientes para cierre determinista.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_current_scene()
		return

	_assert(
		String(main.get("entry_context")) == MatchLaunchConfig.ENTRY_CONTEXT_PLAYER_SHELL,
		"Match lanzado desde shell debe conservar contexto player_shell."
	)
	_assert(bool(main.call("request_pause_for_slot", 1)), "P1 debe poder abrir pausa del match competitivo.")
	var pause_lines := PackedStringArray(main.call("get_pause_overlay_lines"))
	var pause_text := "\n".join(pause_lines)
	_assert(pause_text.contains("Settings"), "Pausa completa debe exponer Settings.")
	_assert(pause_text.contains("How to Play"), "Pausa completa debe exponer How to Play.")
	_assert(pause_text.contains("Characters"), "Pausa completa debe exponer Characters.")
	_assert(pause_text.contains("Volver al menu"), "Pausa completa debe permitir cerrar sesion hacia menu.")
	_assert(not pause_text.contains("Lab |"), "Pausa competitiva no debe filtrar metadata de laboratorio.")

	for surface_id in ["settings", "how_to_play", "characters"]:
		_assert(bool(main.call("select_pause_action_for_slot", 1, surface_id)), "P1 debe seleccionar %s desde pausa." % surface_id)
		_assert(String(main.call("activate_pause_menu_selection_for_slot", 1)) == surface_id, "Activar %s debe devolver su id." % surface_id)
		await process_frame
		await process_frame
		_assert(String(main.call("get_active_pause_surface_id")) == surface_id, "%s debe quedar montada sobre match pausado." % surface_id)
		_assert(bool(main.call("close_active_pause_surface_for_slot", 1)), "Owner debe cerrar %s." % surface_id)
		await process_frame

	_assert(bool(main.call("request_resume_for_slot", 1)), "Owner debe poder reanudar match competitivo.")

	match_controller.match_config.rounds_to_win = 1
	for robot in robots:
		robot.void_fall_y = -100.0
	robots[2].fall_into_void()
	robots[3].fall_into_void()
	await create_timer(0.1).timeout

	_assert(match_controller.is_match_over(), "El primer corte debe poder cerrar una partida sin autorestart.")
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapScroll/RecapLabel") as Label
	var result_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultScroll/MatchResultLabel") as Label
	_assert(recap_label != null and recap_label.visible, "Recap debe quedar visible tras cierre.")
	_assert(result_label != null and result_label.visible, "Resultado final debe quedar visible tras cierre.")
	if recap_label != null:
		_assert(not recap_label.text.contains("Reinicio | F5"), "Recap player_shell no debe anunciar reinicio de laboratorio.")
	if result_label != null:
		_assert(not result_label.text.contains("Reinicio | F5"), "Resultado player_shell no debe anunciar reinicio de laboratorio.")

	await _cleanup_current_scene()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	if main == null:
		return robots
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _cleanup_current_scene() -> void:
	if current_scene == null or not is_instance_valid(current_scene):
		paused = false
		await process_frame
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
