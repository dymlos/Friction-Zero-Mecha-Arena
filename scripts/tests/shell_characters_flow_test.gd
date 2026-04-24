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

	_assert(game_shell.has_method("open_characters"), "GameShell deberia exponer la navegacion hacia Characters.")
	if not game_shell.has_method("open_characters"):
		await _cleanup_current_scene()
		_finish()
		return

	game_shell.call("open_characters")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "characters",
		"La shell deberia poder abrir la pantalla Characters."
	)

	var characters_screen: Variant = game_shell.call("get_active_screen")
	_assert(characters_screen != null, "GameShell deberia devolver la pantalla Characters activa.")
	if characters_screen == null:
		await _cleanup_current_scene()
		_finish()
		return

	_assert(
		characters_screen.has_method("get_selected_character_label"),
		"Characters deberia exponer la ficha seleccionada para tests de flujo."
	)
	_assert(
		characters_screen.has_method("get_visible_character_labels"),
		"Characters deberia exponer el roster visible para tests de flujo."
	)
	_assert(
		characters_screen.has_method("set_surface_scope"),
		"Characters deberia exponer scope global/pausa."
	)
	_assert(
		characters_screen.has_method("set_filter"),
		"Characters debe poder mostrar el foco inicial M4."
	)
	_assert(
		String(characters_screen.call("get_selected_character_label")) == "Ariete",
		"Characters deberia arrancar mostrando a Ariete primero."
	)
	if characters_screen.has_method("get_visible_character_labels"):
		var visible_labels: Array = characters_screen.call("get_visible_character_labels")
		_assert(
			visible_labels.size() == 6 and visible_labels.has("Aguja") and visible_labels.has("Ancla"),
			"Characters deberia arrancar con las seis fichas competitivas visibles."
		)

	if characters_screen.has_method("set_filter") and characters_screen.has_method("get_visible_character_labels"):
		characters_screen.call("set_filter", "teaching_focus")
		await process_frame
		_assert(
			characters_screen.call("get_visible_character_labels") == ["Ariete", "Patin", "Cizalla"],
			"El filtro Foco inicial debe mostrar los tres arquetipos mas ensenables."
		)
		characters_screen.call("set_filter", "all")
		await process_frame

	var focus_owner := root.get_viewport().gui_get_focus_owner()
	_assert(
		focus_owner != null and String(focus_owner.name) == "CharacterList",
		"Characters deberia dejar el foco inicial en la lista de personajes."
	)

	game_shell.call("return_to_main_menu")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "main_menu",
		"Volver desde Characters deberia regresar al menu principal."
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

	_assert(setup.has_signal("characters_requested"), "El setup local deberia poder abrir Characters.")
	_assert(setup.has_method("focus_characters_button"), "El setup local deberia permitir restaurar foco al boton Characters.")

	setup.call("focus_characters_button")
	await process_frame
	await process_frame

	var setup_focus := root.get_viewport().gui_get_focus_owner()
	_assert(
		setup_focus != null and String(setup_focus.name) == "CharactersButton",
		"El setup local deberia poder dejar foco en el acceso a Characters."
	)

	game_shell.call("open_characters", "local_match_setup")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "characters",
		"Characters deberia abrirse tambien desde setup."
	)

	characters_screen = game_shell.call("get_active_screen")
	characters_screen.call("focus_back_button")
	await process_frame
	await process_frame
	characters_screen.call("go_back")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "local_match_setup",
		"Volver desde Characters abierto en setup deberia regresar al setup local."
	)

	setup = game_shell.call("get_active_screen")
	setup_focus = root.get_viewport().gui_get_focus_owner()
	_assert(
		setup_focus != null and String(setup_focus.name) == "CharactersButton",
		"Al regresar desde Characters, el setup deberia restaurar el foco en su boton Characters."
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
