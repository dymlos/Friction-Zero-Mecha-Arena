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

	_assert(game_shell.has_method("open_how_to_play"), "GameShell deberia exponer la navegacion hacia How to Play.")
	if not game_shell.has_method("open_how_to_play"):
		await _cleanup_current_scene()
		_finish()
		return

	game_shell.call("open_how_to_play")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "how_to_play",
		"La shell deberia poder abrir la pantalla How to Play."
	)

	var how_to_play_screen: Variant = game_shell.call("get_active_screen")
	_assert(how_to_play_screen != null, "GameShell deberia devolver la pantalla How to Play activa.")
	if how_to_play_screen == null:
		await _cleanup_current_scene()
		_finish()
		return

	_assert(
		how_to_play_screen.has_method("get_selected_topic_id"),
		"How to Play deberia exponer el tema seleccionado para tests de flujo."
	)
	_assert(
		String(how_to_play_screen.call("get_selected_topic_id")) == "victory",
		"How to Play deberia arrancar mostrando victoria primero."
	)

	var focus_owner := root.get_viewport().gui_get_focus_owner()
	_assert(
		focus_owner != null and String(focus_owner.name) == "TopicList",
		"How to Play deberia dejar el foco inicial en la lista de temas."
	)

	how_to_play_screen.call("focus_back_button")
	await process_frame
	await process_frame
	how_to_play_screen.call("go_back")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "main_menu",
		"Volver desde How to Play deberia regresar al menu principal."
	)

	var main_menu: Variant = game_shell.call("get_active_screen")
	_assert(main_menu != null, "La shell deberia restaurar el menu principal.")
	if main_menu != null:
		_assert(
			main_menu.has_method("focus_how_to_play_button"),
			"El menu principal deberia permitir restaurar foco en How to Play."
		)
		var main_menu_focus := root.get_viewport().gui_get_focus_owner()
		_assert(
			main_menu_focus != null and String(main_menu_focus.name) == "HowToPlayButton",
			"Al volver desde How to Play, el menu principal deberia restaurar foco en su acceso."
		)

	game_shell.call("open_local_setup")
	await process_frame
	await process_frame

	var setup: Variant = game_shell.call("get_active_screen")
	_assert(setup != null, "La shell deberia poder volver a exponer el setup local.")
	if setup == null:
		await _cleanup_current_scene()
		_finish()
		return

	_assert(setup.has_signal("how_to_play_requested"), "El setup local deberia poder abrir How to Play.")
	_assert(setup.has_method("focus_how_to_play_button"), "El setup local deberia permitir restaurar foco en How to Play.")
	setup.call("focus_how_to_play_button")
	await process_frame
	await process_frame

	var setup_focus := root.get_viewport().gui_get_focus_owner()
	_assert(
		setup_focus != null and String(setup_focus.name) == "HowToPlayButton",
		"El setup local deberia poder dejar foco en el acceso a How to Play."
	)

	game_shell.call("open_how_to_play", "local_match_setup")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "how_to_play",
		"How to Play deberia abrirse tambien desde setup."
	)

	how_to_play_screen = game_shell.call("get_active_screen")
	_assert(
		how_to_play_screen.has_method("focus_back_button"),
		"How to Play deberia permitir mover el foco a Volver."
	)
	_assert(
		how_to_play_screen.has_method("go_back"),
		"How to Play deberia exponer una salida explicita."
	)
	if how_to_play_screen != null:
		how_to_play_screen.call("focus_back_button")
		await process_frame
		await process_frame
		how_to_play_screen.call("go_back")
		await process_frame
		await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "local_match_setup",
		"Volver desde How to Play abierto en setup deberia regresar al setup local."
	)

	setup = game_shell.call("get_active_screen")
	setup_focus = root.get_viewport().gui_get_focus_owner()
	_assert(
		setup_focus != null and String(setup_focus.name) == "HowToPlayButton",
		"Al regresar desde How to Play, el setup deberia restaurar el foco en su acceso."
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
