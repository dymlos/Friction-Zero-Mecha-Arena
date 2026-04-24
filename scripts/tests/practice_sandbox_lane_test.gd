extends SceneTree

const LANE_SCENE := preload("res://scenes/practice/stations/sandbox_lane.tscn")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lane := LANE_SCENE.instantiate()
	var player_robot := _spawn_player_robot(1)
	root.add_child(lane)
	root.add_child(player_robot)
	current_scene = lane

	await process_frame
	await process_frame

	lane.call("configure_lane", PracticeCatalog.get_module("sandbox"), [player_robot])
	await process_frame
	await process_frame

	_assert(not Array(lane.call("get_objective_lines")).is_empty(), "SandboxLane deberia exponer instrucciones objetivas.")
	_assert(not Array(lane.call("get_callout_lines")).is_empty(), "SandboxLane deberia exponer callout de lectura.")
	_assert(not bool(lane.call("is_lane_completed")), "SandboxLane no deberia cerrar por defecto.")

	await _cleanup_node(player_robot)
	await _cleanup_node(lane)
	_finish()


func _spawn_player_robot(player_index: int) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate()
	robot.is_player_controlled = true
	robot.player_index = player_index
	robot.control_mode = RobotBase.ControlMode.EASY
	robot.display_name = "Player %s" % player_index
	robot.position = Vector3.ZERO
	return robot


func _cleanup_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
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
