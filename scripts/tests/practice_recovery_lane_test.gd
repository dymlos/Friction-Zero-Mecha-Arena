extends SceneTree

const LANE_SCENE := preload("res://scenes/practice/stations/recovery_lane.tscn")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")
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
	await process_frame

	lane.call("configure_lane", PracticeCatalog.get_module("recuperacion"), [player_robot])
	await process_frame
	await process_frame

	_assert(not Array(lane.call("get_objective_lines")).is_empty(), "RecoveryLane deberia exponer instrucciones objetivas.")
	_assert(not Array(lane.call("get_callout_lines")).is_empty(), "RecoveryLane deberia exponer callout de lectura.")

	var ally_robot := _find_fixture_robot_by_name(lane, "Aliado")
	var rival_robot := _find_fixture_robot_by_name(lane, "Rival")
	_assert(ally_robot != null and rival_robot != null, "RecoveryLane deberia crear robots de apoyo y negacion.")
	if ally_robot == null or rival_robot == null:
		await _cleanup_node(player_robot)
		await _cleanup_node(lane)
		_finish()
		return

	var detached_parts := _get_detached_parts_for_lane(lane)
	_assert(detached_parts.size() >= 2, "RecoveryLane deberia crear partes reales desprendidas.")
	if detached_parts.size() < 2:
		await _cleanup_node(player_robot)
		await _cleanup_node(lane)
		_finish()
		return

	var ally_part := _find_detached_part(detached_parts, ally_robot)
	var rival_part := _find_detached_part(detached_parts, rival_robot)
	_assert(ally_part != null and rival_part != null, "RecoveryLane deberia crear una parte aliada y una rival.")
	if ally_part == null or rival_part == null:
		await _cleanup_node(player_robot)
		await _cleanup_node(lane)
		_finish()
		return

	ally_part.set("_pickup_ready_at", 0.0)
	_assert(ally_part.try_deliver_to_robot(ally_robot, player_robot), "La parte aliada deberia poder volver a su robot original.")

	rival_part.set("_pickup_ready_at", 0.0)
	rival_part.deny_to_void()
	await process_frame
	lane.call("_physics_process", 0.016)

	_assert(bool(lane.call("is_lane_completed")), "RecoveryLane deberia completar al cerrar recuperacion y negacion.")

	await _cleanup_node(player_robot)
	await _cleanup_node(lane)
	_finish()


func _spawn_player_robot(player_index: int) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate()
	robot.is_player_controlled = true
	robot.player_index = player_index
	robot.control_mode = RobotBase.ControlMode.EASY
	robot.display_name = "Player %s" % player_index
	robot.team_id = 1
	robot.position = Vector3.ZERO
	return robot


func _find_fixture_robot_by_name(lane: Node, display_name: String) -> RobotBase:
	for child in lane.get_children():
		if child is RobotBase and String(child.get("display_name")) == display_name:
			return child as RobotBase

	return null


func _get_detached_parts_for_lane(lane: Node) -> Array[DetachedPart]:
	var parts: Array[DetachedPart] = []
	for node in lane.get_tree().get_nodes_in_group("detached_parts"):
		if node is DetachedPart:
			parts.append(node as DetachedPart)

	return parts


func _find_detached_part(parts: Array[DetachedPart], original_robot: RobotBase) -> DetachedPart:
	for part in parts:
		if part != null and is_instance_valid(part) and part.get_original_robot() == original_robot:
			return part

	return null


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
