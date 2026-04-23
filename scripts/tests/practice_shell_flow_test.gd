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
	if not (
		practice_setup.has_method("set_selected_module")
		and practice_setup.has_method("get_selected_module_id")
		and practice_setup.has_method("focus_back_button")
		and practice_setup.has_method("get_related_topic_labels")
		and practice_setup.has_method("get_recommended_robot_label")
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
