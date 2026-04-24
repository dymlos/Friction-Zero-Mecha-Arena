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

	var help_label := game_shell.get_node_or_null("GamepadHelpLabel") as Label
	_assert(help_label != null, "La shell deberia mostrar ayuda de joystick persistente.")
	if help_label != null:
		var help_text := help_label.text
		_assert(help_text.contains("A aceptar"), "La ayuda visible debe indicar A para aceptar.")
		_assert(help_text.contains("B volver"), "La ayuda visible debe indicar B para volver.")
		_assert(help_text.contains("Start iniciar"), "La ayuda visible debe indicar Start para iniciar.")
		_assert(help_text.contains("Select pausa"), "La ayuda visible debe indicar Select para pausa.")

	var start_event := InputEventJoypadButton.new()
	start_event.button_index = JOY_BUTTON_START
	start_event.pressed = true
	game_shell._unhandled_input(start_event)
	await process_frame
	await process_frame
	_assert(
		String(game_shell.call("get_active_screen_id")) == "local_match_setup",
		"Start desde menu principal deberia entrar al setup local."
	)

	var back_event := InputEventJoypadButton.new()
	back_event.button_index = JOY_BUTTON_B
	back_event.pressed = true
	game_shell._unhandled_input(back_event)
	await process_frame
	await process_frame
	_assert(
		String(game_shell.call("get_active_screen_id")) == "main_menu",
		"B desde setup local deberia volver al menu principal."
	)

	game_shell.call("open_characters")
	await process_frame
	await process_frame
	game_shell._unhandled_input(back_event)
	await process_frame
	await process_frame
	_assert(
		String(game_shell.call("get_active_screen_id")) == "main_menu",
		"B desde Characters deberia volver atras."
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
