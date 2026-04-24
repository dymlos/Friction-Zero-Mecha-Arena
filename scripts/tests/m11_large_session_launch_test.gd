extends SceneTree

const LOCAL_MATCH_SETUP_SCENE := preload("res://scenes/shell/local_match_setup.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _assert_large_launch(MatchController.MatchMode.FFA, "res://scenes/main/main_ffa_large.tscn")
	await _assert_large_launch(MatchController.MatchMode.TEAMS, "res://scenes/main/main_teams_large.tscn")
	_finish()


func _assert_large_launch(match_mode: int, expected_scene_path: String) -> void:
	var setup := LOCAL_MATCH_SETUP_SCENE.instantiate()
	root.add_child(setup)
	await process_frame
	await process_frame

	setup.call("set_match_mode", match_mode)
	for slot in range(5, 9):
		setup.call("set_slot_active", slot, true)
		setup.call("set_slot_input_source", slot, "joypad")
		setup.call("reserve_joypad_for_slot", slot, 40 + slot, true)

	var launch_config = setup.call("build_launch_config")
	_assert(String(launch_config.target_scene_path) == expected_scene_path, "Mas de cuatro slots deberian lanzar %s." % expected_scene_path)
	if match_mode == MatchController.MatchMode.FFA:
		_assert(String(launch_config.map_id) == "borde_fundicion_ffa_5_8", "FFA 8P debe transportar map_id de mapa fuerte 5-8.")
	else:
		_assert(String(launch_config.map_id) == "borde_fundicion_teams_5_8", "Teams 8P debe transportar map_id de mapa fuerte 5-8.")
	_assert(launch_config.local_slots.size() == 8, "La ruta grande deberia transportar ocho slots activos.")
	setup.queue_free()
	await process_frame

	var packed_scene := load(expected_scene_path)
	_assert(packed_scene is PackedScene, "La escena grande %s deberia existir." % expected_scene_path)
	if not (packed_scene is PackedScene):
		return
	var main := (packed_scene as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var robots := _get_scene_robots(main)
	_assert(robots.size() == 8, "%s deberia montar ocho robots." % expected_scene_path)
	if robots.size() == 8:
		if match_mode == MatchController.MatchMode.FFA:
			for robot in robots:
				_assert(robot.team_id == 0, "FFA grande deberia mantener competidores individuales.")
		else:
			_assert(_uses_balanced_teams(robots), "Teams grande deberia asignar 4v4 por paridad de slot.")

	await _cleanup_node(main)


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _uses_balanced_teams(robots: Array[RobotBase]) -> bool:
	for index in range(robots.size()):
		var expected_team := 1 if (index + 1) % 2 == 1 else 2
		if robots[index].team_id != expected_team:
			return false
	return true


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
