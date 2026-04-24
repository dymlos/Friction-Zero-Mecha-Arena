extends SceneTree

const LANE_SCENE := preload("res://scenes/practice/stations/movement_lane.tscn")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lane := LANE_SCENE.instantiate()
	var player_robot := _spawn_player_robot(1, RobotBase.ControlMode.EASY)
	root.add_child(lane)
	root.add_child(player_robot)
	current_scene = lane

	await process_frame
	await process_frame

	lane.call("configure_lane", PracticeCatalog.get_module("movimiento"), [player_robot])
	await process_frame
	await process_frame

	_assert_lane_contract(lane)
	var progress_lines := Array(lane.call("get_progress_lines"))
	_assert(
		not progress_lines.is_empty() and String(progress_lines[0]).contains("Simple"),
		"MovementLane deberia mostrar Easy o Hard en progreso."
	)

	player_robot.global_position = Vector3(0.0, 1.2, -7.5)
	lane.call("_physics_process", 0.016)

	_assert(bool(lane.call("is_lane_completed")), "MovementLane deberia completar cuando el robot cruza la meta.")
	_assert(
		"\n".join(Array(lane.call("get_context_card_lines"))).contains("Impacto"),
		"MovementLane deberia sugerir Impacto al completar."
	)

	await _cleanup_node(player_robot)
	await _cleanup_node(lane)
	_finish()


func _spawn_player_robot(player_index: int, control_mode: int) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate()
	robot.is_player_controlled = true
	robot.player_index = player_index
	robot.control_mode = control_mode
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


func _assert_lane_contract(lane: Node) -> void:
	_assert(lane.has_method("get_objective_lines"), "La estacion debe exponer objetivos.")
	_assert(lane.has_method("get_progress_lines"), "La estacion debe exponer progreso.")
	_assert(lane.has_method("get_callout_lines"), "La estacion debe exponer callouts.")
	_assert(lane.has_method("get_context_card_lines"), "La estacion debe exponer tarjeta contextual.")
	_assert(Array(lane.call("get_objective_lines")).size() <= 2, "Objetivos deben ser cortos.")
	_assert(Array(lane.call("get_context_card_lines")).size() <= 3, "Tarjeta contextual debe ser breve.")
	_assert(not Array(lane.call("get_objective_lines")).is_empty(), "MovementLane deberia exponer instrucciones objetivas.")
	_assert(not Array(lane.call("get_callout_lines")).is_empty(), "MovementLane deberia exponer callout de lectura.")


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
