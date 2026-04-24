extends SceneTree

const PRACTICE_SCENE := preload("res://scenes/practice/practice_mode.tscn")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio_director := root.get_node_or_null("/root/AudioDirector")
	_assert(audio_director != null, "AudioDirector deberia estar disponible en practica.")
	if audio_director == null:
		_finish()
		return
	audio_director.call("set_sfx_volume", 0.5)

	var shell_session := ShellSession.new()
	shell_session.store_match_launch_config(null)
	var launch_config := MatchLaunchConfig.new()
	launch_config.configure_for_practice(
		"movimiento",
		"res://scenes/practice/practice_mode.tscn",
		[{"slot": 1, "control_mode": 0, "input_source": "keyboard", "keyboard_profile": 1}]
	)
	shell_session.store_match_launch_config(launch_config)

	var practice = PRACTICE_SCENE.instantiate()
	root.add_child(practice)
	current_scene = practice
	await process_frame
	await process_frame

	_assert(bool(practice.call("request_pause_for_slot", 1)), "P1 deberia poder pausar practica.")
	var pause_text := "\n".join(PackedStringArray(practice.call("get_pause_lines")))
	_assert(pause_text.contains("Acciones"), "Practica deberia usar la misma estructura operacional.")
	_assert(pause_text.contains("Quick settings"), "Practica deberia exponer quick settings.")

	_assert(bool(practice.call("select_pause_action_for_slot", 1, "audio_sfx")), "El owner deberia seleccionar SFX.")
	var action := String(practice.call("activate_pause_menu_selection_for_slot", 1))
	_assert(action == "audio_sfx", "Activar SFX deberia devolver accion operacional.")
	_assert(float(audio_director.call("get_sfx_volume")) > 0.5, "SFX deberia cambiar en AudioDirector.")

	_assert(bool(practice.call("select_pause_action_for_slot", 1, "restart")), "El owner deberia conservar reinicio de modulo.")
	action = String(practice.call("activate_pause_menu_selection_for_slot", 1))
	_assert(action == "restart", "Practica deberia conservar reinicio desde pausa.")
	_assert(not paused, "Reiniciar modulo desde pausa deberia limpiar pausa.")

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
	paused = false
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
