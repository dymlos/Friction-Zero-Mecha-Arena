extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(game_shell)
	current_scene = game_shell
	await process_frame
	await process_frame

	game_shell.call("open_local_setup")
	await process_frame
	await process_frame
	var setup: Variant = game_shell.call("get_active_screen")
	_assert(setup != null, "GameShell deberia montar setup local.")
	if setup == null:
		await _cleanup_current_scene()
		_finish()
		return

	setup.call("cycle_slot_roster_entry", 1)
	setup.call("set_slot_active", 5, true)
	setup.call("set_slot_input_source", 5, "joypad")
	setup.call("reserve_joypad_for_slot", 5, 25, true)
	while _get_roster_entry_id_for_slot(setup.call("build_launch_config").local_slots, 5) != "aguja":
		setup.call("cycle_slot_roster_entry", 5)
	await process_frame

	game_shell.call("open_characters", "local_match_setup")
	await process_frame
	await process_frame
	var characters: Variant = game_shell.call("get_active_screen")
	characters.call("emit_signal", "back_requested")
	await process_frame
	await process_frame
	setup = game_shell.call("get_active_screen")
	_assert(String(game_shell.call("get_active_screen_id")) == "local_match_setup", "Volver desde Characters deberia regresar al setup.")

	game_shell.call("open_how_to_play", "local_match_setup")
	await process_frame
	await process_frame
	var how_to_play: Variant = game_shell.call("get_active_screen")
	how_to_play.call("emit_signal", "back_requested")
	await process_frame
	await process_frame
	setup = game_shell.call("get_active_screen")
	_assert(String(game_shell.call("get_active_screen_id")) == "local_match_setup", "Volver desde How to Play deberia regresar al setup.")

	game_shell.call("open_practice_setup", "local_match_setup", "impacto")
	await process_frame
	await process_frame
	var practice: Variant = game_shell.call("get_active_screen")
	practice.call("emit_signal", "back_requested")
	await process_frame
	await process_frame
	setup = game_shell.call("get_active_screen")
	_assert(String(game_shell.call("get_active_screen_id")) == "local_match_setup", "Volver desde Practica deberia regresar al setup.")

	setup.call("set_match_mode", MatchController.MatchMode.FFA)
	var launch_config = setup.call("build_launch_config")
	_assert(launch_config.match_mode == MatchController.MatchMode.FFA, "El flujo deberia poder lanzar FFA.")
	_assert(launch_config.local_slots.size() >= 5, "El launch config deberia conservar P5 activo.")
	_assert(String(launch_config.local_slots[0].get("roster_entry_id", "")) == "grua", "P1 deberia conservar el cambio de Ariete a Grua.")
	_assert(String(launch_config.local_slots[4].get("roster_entry_id", "")) == "aguja", "P5 deberia conservar Aguja.")

	await _cleanup_current_scene()
	_finish()


func _get_roster_entry_id_for_slot(slot_specs: Array, player_slot: int) -> String:
	for slot_spec in slot_specs:
		if slot_spec is Dictionary and int(slot_spec.get("slot", -1)) == player_slot:
			return String(slot_spec.get("roster_entry_id", ""))
	return ""


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
