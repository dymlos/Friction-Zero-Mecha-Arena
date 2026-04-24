extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")

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
		game_shell.has_method("open_practice_setup"),
		"GameShell deberia exponer la navegacion hacia Practica."
	)
	if not game_shell.has_method("open_practice_setup"):
		await _cleanup_current_scene()
		_finish()
		return

	game_shell.call("open_practice_setup")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "practice_setup",
		"La shell deberia poder abrir PracticeSetup."
	)

	var practice_setup: Variant = game_shell.call("get_active_screen")
	_assert(practice_setup != null, "GameShell deberia exponer PracticeSetup activo.")
	if practice_setup == null:
		await _cleanup_current_scene()
		_finish()
		return

	_assert(
		practice_setup.has_method("set_selected_module"),
		"PracticeSetup deberia permitir preseleccionar el modulo activo."
	)
	_assert(
		practice_setup.has_method("get_selected_module_id"),
		"PracticeSetup deberia exponer el modulo seleccionado."
	)
	_assert(
		practice_setup.has_method("focus_back_button"),
		"PracticeSetup deberia permitir restaurar foco en volver."
	)
	_assert(
		practice_setup.has_method("get_related_topic_labels"),
		"PracticeSetup deberia exponer los temas relacionados que enlaza."
	)
	_assert(
		practice_setup.has_method("get_recommended_robot_label"),
		"PracticeSetup deberia resolver el robot recomendado desde RosterCatalog."
	)
	_assert(
		practice_setup.has_method("cycle_slot_roster_entry"),
		"PracticeSetup deberia permitir cambiar el robot de P1/P2."
	)
	_assert(
		practice_setup.has_method("get_context_card_lines"),
		"PracticeSetup deberia exponer la tarjeta contextual del modulo."
	)
	_assert(
		practice_setup.has_method("get_player_scope_line"),
		"PracticeSetup deberia exponer el alcance 1-2P/ayuda visible."
	)
	_assert(
		practice_setup.has_method("get_first_pass_module_labels"),
		"PracticeSetup debe exponer la ruta recomendada del primer pase M8."
	)
	if practice_setup.has_method("get_first_pass_module_labels"):
		_assert(
			practice_setup.call("get_first_pass_module_labels") == ["Movimiento", "Impacto", "Partes", "Libre"],
			"PracticeSetup debe comunicar la ruta recomendada sin ocultar los otros modulos."
		)
	_assert(
		String(practice_setup.call("get_player_scope_line")).contains("1-2 jugadores locales"),
		"PracticeSetup debe comunicar explicitamente el alcance 1-2P."
	)
	_assert(
		String(practice_setup.call("get_player_scope_line")).contains("ayuda visible"),
		"PracticeSetup debe comunicar que Practica arranca con ayuda visible."
	)
	if not (
		practice_setup.has_method("set_selected_module")
		and practice_setup.has_method("get_selected_module_id")
		and practice_setup.has_method("focus_back_button")
		and practice_setup.has_method("get_related_topic_labels")
		and practice_setup.has_method("get_recommended_robot_label")
		and practice_setup.has_method("cycle_slot_roster_entry")
	):
		await _cleanup_current_scene()
		_finish()
		return

	_assert(
		String(practice_setup.call("get_selected_module_id")) == "movimiento",
		"PracticeSetup deberia arrancar con `movimiento` como primer modulo."
	)
	var related_topics: Array = practice_setup.call("get_related_topic_labels")
	_assert(
		not related_topics.is_empty(),
		"PracticeSetup deberia mostrar temas relacionados del catalogo de onboarding."
	)
	_assert(
		not String(practice_setup.call("get_recommended_robot_label")).is_empty(),
		"PracticeSetup deberia mostrar un robot recomendado legible."
	)
	if practice_setup.has_method("get_context_card_lines"):
		var context_card_lines: Array = practice_setup.call("get_context_card_lines")
		_assert(not context_card_lines.is_empty(), "PracticeSetup deberia mostrar tarjeta contextual.")
	if practice_setup.has_method("get_player_scope_line"):
		_assert(
			String(practice_setup.call("get_player_scope_line")).contains("1-2"),
			"PracticeSetup deberia comunicar el alcance 1-2 jugadores."
		)
		_assert(
			String(practice_setup.call("get_player_scope_line")).contains("ayuda visible"),
			"PracticeSetup deberia comunicar ayuda visible por defecto."
		)
	var initial_practice_launch_config = practice_setup.call("build_launch_config")
	_assert(
		String(initial_practice_launch_config.local_slots[0].get("roster_entry_id", "")) == "patin",
		"PracticeSetup abierto desde menu deberia iniciar P1 con el robot recomendado del modulo."
	)

	practice_setup.call("focus_back_button")
	await process_frame
	await process_frame
	practice_setup.call("emit_signal", "back_requested")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "main_menu",
		"Volver desde PracticeSetup abierto en menu principal deberia regresar al menu."
	)

	var main_menu_focus := root.get_viewport().gui_get_focus_owner()
	_assert(
		main_menu_focus != null and String(main_menu_focus.name) == "PracticeButton",
		"Al volver desde PracticeSetup, el menu principal deberia restaurar foco en Practica."
	)

	game_shell.call("open_local_setup")
	await process_frame
	await process_frame
	game_shell.call("open_practice_setup", "local_match_setup", "impacto")
	await process_frame
	await process_frame

	practice_setup = game_shell.call("get_active_screen")
	_assert(
		String(practice_setup.call("get_selected_module_id")) == "impacto",
		"Setup y How to Play deberian poder abrir PracticeSetup con modulo preseleccionado."
	)
	practice_setup.call("set_slot_control_mode", 2, 1)
	practice_setup.call("set_slot_input_source", 2, "joypad")
	practice_setup.call("reserve_joypad_for_slot", 2, 31, true)
	practice_setup.call("cycle_slot_roster_entry", 1)
	var practice_launch_config = practice_setup.call("build_launch_config")
	_assert(
		practice_launch_config.local_slots.size() == 2,
		"PracticeSetup deberia heredar solo P1/P2 del contrato operativo."
	)
	_assert(
		String(practice_launch_config.local_slots[1].get("input_source", "")) == "joypad"
		and int(practice_launch_config.local_slots[1].get("device_id", -1)) == 31,
		"PracticeSetup deberia conservar el dispositivo reclamado para P2."
	)
	_assert(
		String(practice_launch_config.local_slots[0].get("roster_entry_id", "")) != "",
		"PracticeSetup deberia escribir el robot elegido en local_slots."
	)

	practice_setup.call("emit_signal", "back_requested")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "local_match_setup",
		"Volver desde PracticeSetup abierto en setup deberia regresar al setup local."
	)

	var setup_focus := root.get_viewport().gui_get_focus_owner()
	_assert(
		setup_focus != null and String(setup_focus.name) == "PracticeButton",
		"Al volver desde PracticeSetup, el setup local deberia restaurar foco en Practica."
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


func _finish() -> void:
	quit(1 if _failed else 0)
