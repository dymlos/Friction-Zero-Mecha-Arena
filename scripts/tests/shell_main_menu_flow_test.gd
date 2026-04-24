extends SceneTree

const GAME_SHELL_SCENE_PATH := "res://scenes/shell/game_shell.tscn"
const LOCAL_MATCH_SETUP_SCRIPT_PATH := "res://scripts/shell/local_match_setup.gd"
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(
		String(ProjectSettings.get_setting("application/run/main_scene", "")) == GAME_SHELL_SCENE_PATH,
		"El entrypoint del proyecto deberia arrancar en la shell raiz y no en un laboratorio."
	)
	var game_shell_scene := load(GAME_SHELL_SCENE_PATH)
	_assert(
		game_shell_scene is PackedScene,
		"La shell raiz deberia vivir en scenes/shell/game_shell.tscn."
	)
	var local_match_setup_script := load(LOCAL_MATCH_SETUP_SCRIPT_PATH)
	_assert(
		local_match_setup_script != null,
		"El setup local deberia vivir en scripts/shell/local_match_setup.gd."
	)
	if not (game_shell_scene is PackedScene) or local_match_setup_script == null:
		_finish()
		return

	var game_shell := (game_shell_scene as PackedScene).instantiate()
	root.add_child(game_shell)
	current_scene = game_shell

	await process_frame
	await process_frame

	_assert(game_shell.has_method("get_active_screen_id"), "GameShell deberia exponer la pantalla activa.")
	_assert(game_shell.has_method("open_local_setup"), "GameShell deberia poder abrir el setup local.")
	_assert(game_shell.has_method("open_characters"), "GameShell deberia poder abrir Characters desde la shell.")
	_assert(game_shell.has_method("open_how_to_play"), "GameShell deberia poder abrir How to Play desde la shell.")
	_assert(game_shell.has_method("open_settings"), "GameShell deberia poder abrir Settings desde la shell.")
	_assert(game_shell.has_method("open_practice_setup"), "GameShell deberia poder abrir Practica desde la shell.")
	_assert(game_shell.has_method("return_to_main_menu"), "GameShell deberia poder volver al menu principal.")
	_assert(game_shell.has_method("launch_local_match"), "GameShell deberia poder lanzar un match local.")
	if not (
		game_shell.has_method("get_active_screen_id")
		and game_shell.has_method("open_local_setup")
		and game_shell.has_method("open_characters")
		and game_shell.has_method("open_how_to_play")
		and game_shell.has_method("open_settings")
		and game_shell.has_method("open_practice_setup")
		and game_shell.has_method("return_to_main_menu")
		and game_shell.has_method("launch_local_match")
	):
		await _cleanup_current_scene()
		_finish()
		return

	_assert(
		String(game_shell.call("get_active_screen_id")) == "main_menu",
		"La shell deberia arrancar mostrando el menu principal."
	)
	var main_menu_initial: Variant = game_shell.call("get_active_screen")
	_assert(main_menu_initial != null, "GameShell deberia exponer MainMenu al arrancar.")
	if main_menu_initial != null:
		_assert(main_menu_initial.has_method("focus_play_local_button"), "MainMenu deberia exponer foco explicito en Jugar local.")
		main_menu_initial.call("focus_play_local_button")
		await process_frame
		var initial_focus := root.get_viewport().gui_get_focus_owner()
		_assert(
			initial_focus != null and String(initial_focus.name) == "PlayLocalButton",
			"El arranque nuevo del menu deberia enfocar Jugar local."
		)
		var vbox := main_menu_initial.get_node_or_null("CenterPanel/Margin/VBox") as VBoxContainer
		_assert(vbox != null, "MainMenu deberia conservar VBox navegable.")
		if vbox != null:
			var first_button: Button = null
			for child in vbox.get_children():
				if child is Button:
					first_button = child as Button
					break
			_assert(
				first_button != null and String(first_button.name) == "PlayLocalButton",
				"Jugar local deberia ser el primer boton navegable del menu."
			)

	game_shell.call("open_characters")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "characters",
		"El menu principal deberia poder derivar a Characters."
	)

	game_shell.call("return_to_main_menu")
	await process_frame
	await process_frame

	game_shell.call("open_local_setup")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "local_match_setup",
		"`Jugar local` deberia llevar al setup local."
	)

	var setup: Variant = game_shell.call("get_active_screen")
	_assert(setup != null, "GameShell deberia poder devolver la superficie activa.")
	if setup == null:
		await _cleanup_current_scene()
		_finish()
		return

	_assert(
		setup.has_method("set_match_mode"),
		"LocalMatchSetup deberia permitir elegir entre Teams y FFA."
	)
	_assert(
		setup.has_signal("how_to_play_requested"),
		"LocalMatchSetup deberia poder derivar a How to Play desde setup."
	)
	_assert(
		setup.has_signal("practice_requested"),
		"LocalMatchSetup deberia poder derivar a Practica desde setup."
	)
	_assert(
		setup.has_method("toggle_slot_control_mode"),
		"LocalMatchSetup deberia permitir alternar Easy/Hard por slot."
	)
	_assert(
		setup.has_method("build_launch_config"),
		"LocalMatchSetup deberia poder construir un MatchLaunchConfig consumible por GameShell."
	)
	_assert(
		setup.has_method("get_variant_summary_line"),
		"LocalMatchSetup deberia exponer la variante de modo visible."
	)
	if not (
		setup.has_method("set_match_mode")
		and setup.has_method("toggle_slot_control_mode")
		and setup.has_method("build_launch_config")
	):
		await _cleanup_current_scene()
		_finish()
		return

	game_shell.call("return_to_main_menu")
	await process_frame
	await process_frame
	_assert(
		String(game_shell.call("get_active_screen_id")) == "main_menu",
		"`Volver` desde setup deberia regresar al menu principal sin cambiar de escena."
	)

	game_shell.call("return_to_main_menu")
	await process_frame
	await process_frame

	var main_menu: Variant = game_shell.call("get_active_screen")
	_assert(main_menu != null, "GameShell deberia volver a exponer el menu principal.")
	if main_menu != null:
		_assert(main_menu.has_signal("settings_requested"), "El menu principal deberia exponer acceso a Settings.")
		_assert(main_menu.has_method("focus_settings_button"), "El menu principal deberia poder restaurar foco en Settings.")

	game_shell.call("open_local_setup")
	await process_frame
	await process_frame
	setup = game_shell.call("get_active_screen")
	setup.call("set_match_mode", MatchController.MatchMode.FFA)
	setup.call("toggle_slot_control_mode", 2)
	var launch_config: Variant = setup.call("build_launch_config")

	_assert(
		launch_config is MatchLaunchConfig,
		"LocalMatchSetup deberia producir un MatchLaunchConfig real."
	)
	if launch_config is MatchLaunchConfig:
		var typed_launch_config := launch_config as MatchLaunchConfig
		_assert(
			typed_launch_config.match_mode == MatchController.MatchMode.FFA,
			"El setup local deberia reflejar el modo FFA elegido."
		)
		_assert(
			String(typed_launch_config.target_scene_path) == "res://scenes/main/main_ffa.tscn",
			"El setup local deberia apuntar a la escena estable FFA."
		)
		_assert(
			typed_launch_config.local_slots.size() >= 2,
			"El setup local deberia conservar al menos los slots locales activos."
		)
		_assert(
			int(typed_launch_config.local_slots[1].get("control_mode", -1)) == RobotBase.ControlMode.HARD,
			"El toggle del slot 2 deberia reflejarse en el launch config."
		)
		_assert(
			_get_string_property(typed_launch_config, "mode_variant_id") == "score_by_cause",
			"El setup local deberia transportar la variante Score por causa."
		)

	game_shell.call("launch_local_match", launch_config)
	await process_frame
	await process_frame
	await process_frame

	_assert(current_scene != null, "Lanzar el match deberia dejar una escena activa.")
	if current_scene != null:
		_assert(
			String(current_scene.scene_file_path) == "res://scenes/main/main_ffa.tscn",
			"La shell deberia abrir la escena estable correspondiente al modo elegido."
		)
		_assert(
			String(current_scene.get("entry_context")) == MatchLaunchConfig.ENTRY_CONTEXT_PLAYER_SHELL,
			"El match lanzado desde shell deberia entrar en contexto `player_shell`."
		)

	await _cleanup_current_scene()
	_finish()


func _cleanup_current_scene() -> void:
	if current_scene == null or not is_instance_valid(current_scene):
		return

	var scene := current_scene
	var parent := scene.get_parent()
	if parent != null:
		parent.remove_child(scene)
	scene.free()
	current_scene = null
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _get_string_property(target: Object, property_name: String) -> String:
	if target == null:
		return ""
	for property_info in target.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return String(target.get(property_name))
	return ""


func _finish() -> void:
	quit(1 if _failed else 0)
