extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")
const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const Main = preload("res://scripts/main/main.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio_director := root.get_node_or_null("AudioDirector")
	_assert(audio_director != null, "El proyecto deberia registrar AudioDirector como autoload.")
	if audio_director == null:
		_finish()
		return

	_assert(audio_director.has_method("reset_debug_history"), "AudioDirector deberia exponer historia debug para tests de ruteo.")
	_assert(audio_director.has_method("get_debug_history"), "AudioDirector deberia exponer historia debug para inspeccion.")
	_assert(audio_director.has_method("get_music_state"), "AudioDirector deberia exponer el estado musical activo.")
	if not (
		audio_director.has_method("reset_debug_history")
		and audio_director.has_method("get_debug_history")
		and audio_director.has_method("get_music_state")
	):
		_finish()
		return

	audio_director.call("reset_debug_history")

	var game_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(game_shell)
	current_scene = game_shell
	await process_frame
	await process_frame

	_assert(
		String(audio_director.call("get_music_state")) == "shell",
		"La shell deberia empujar el estado musical `shell` al director."
	)

	var main_menu: Variant = game_shell.call("get_active_screen")
	_assert(main_menu != null, "GameShell deberia exponer la pantalla activa para tests de audio.")
	if main_menu != null:
		main_menu.call("_on_play_local_pressed")
		await process_frame
		await process_frame

	var setup: Variant = game_shell.call("get_active_screen")
	_assert(setup != null, "Tras `Jugar local`, la shell deberia abrir el setup.")
	if setup != null:
		setup.call("_on_how_to_play_pressed")
		await process_frame
		await process_frame

	var how_to_play: Variant = game_shell.call("get_active_screen")
	_assert(how_to_play != null, "How to Play deberia abrirse para validar el cue de vuelta.")
	if how_to_play != null:
		how_to_play.call("go_back")
		await process_frame
		await process_frame

	var shell_history := audio_director.call("get_debug_history") as Array
	_assert(
		_history_contains(shell_history, "cue", "ui_confirm"),
		"La shell deberia rutear confirmaciones hacia AudioDirector."
	)
	_assert(
		_history_contains(shell_history, "cue", "ui_back"),
		"La shell deberia rutear el gesto de volver hacia AudioDirector."
	)

	await _cleanup_current_scene()
	audio_director.call("reset_debug_history")

	var main := MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var robots := main.get_tree().get_nodes_in_group("robots")
	var robot := robots[0] as RobotBase if not robots.is_empty() else null
	_assert(robot != null, "La escena principal deberia exponer al menos un robot para validar cues de match.")
	if robot != null:
		main.call("_on_robot_part_destroyed", robot, "left_arm", null)
		main.call("_on_edge_repair_pickup_collected", robot, "left_arm")
		await process_frame
		await process_frame

	var match_history := audio_director.call("get_debug_history") as Array
	_assert(
		_history_contains(match_history, "cue", "part_destroyed"),
		"Main deberia rutear la destruccion modular hacia AudioDirector."
	)
	_assert(
		_history_contains(match_history, "cue", "pickup_taken"),
		"Main deberia rutear pickups de borde hacia AudioDirector."
	)

	await _cleanup_current_scene()
	_finish()


func _history_contains(history: Array, entry_type: String, value: String) -> bool:
	for entry in history:
		if not (entry is Dictionary):
			continue
		var typed_entry := entry as Dictionary
		if String(typed_entry.get("type", "")) != entry_type:
			continue
		if String(typed_entry.get("value", "")) == value:
			return true
	return false


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
