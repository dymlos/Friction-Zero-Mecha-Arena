extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const Main = preload("res://scripts/main/main.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio_director := root.get_node_or_null("AudioDirector")
	_assert(audio_director != null, "El proyecto deberia registrar AudioDirector como autoload.")
	if audio_director == null:
		_finish()
		return

	_assert(audio_director.has_method("reset_debug_history"), "AudioDirector deberia permitir resetear historia antes de cada escenario.")
	_assert(audio_director.has_method("get_music_state"), "AudioDirector deberia exponer el estado musical actual.")
	if not (audio_director.has_method("reset_debug_history") and audio_director.has_method("get_music_state")):
		_finish()
		return

	audio_director.call("reset_debug_history")

	var main := MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	_assert(
		String(audio_director.call("get_music_state")) == "match_intro",
		"Al arrancar la partida, Main deberia empujar `match_intro`."
	)

	for _index in range(90):
		await process_frame

	_assert(
		String(audio_director.call("get_music_state")) == "match_live",
		"Cuando termina el intro real, Main deberia cambiar a `match_live`."
	)

	main.request_pause_for_slot(1)
	await process_frame
	await process_frame
	_assert(
		String(audio_director.call("get_music_state")) == "pause",
		"Al pausar, Main deberia cambiar la musica a `pause`."
	)

	main.request_resume_for_slot(1)
	await process_frame
	await process_frame
	_assert(
		String(audio_director.call("get_music_state")) == "match_live",
		"Al reanudar, Main deberia volver a `match_live`."
	)

	main.match_controller.set("_round_elapsed_seconds", float(main.match_controller.match_config.round_time_seconds) * 0.92)
	await process_frame
	await process_frame
	_assert(
		String(audio_director.call("get_music_state")) == "final_pressure",
		"Cuando entra la presion final real, Main deberia cambiar a `final_pressure`."
	)

	main.match_controller.set("_match_over", true)
	main.match_controller.set("_round_active", false)
	await process_frame
	await process_frame
	_assert(
		String(audio_director.call("get_music_state")) == "results",
		"Cuando el match queda cerrado, Main deberia cambiar a `results`."
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
