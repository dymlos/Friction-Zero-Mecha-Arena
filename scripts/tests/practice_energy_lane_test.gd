extends SceneTree

const LANE_SCENE := preload("res://scenes/practice/stations/energy_lane.tscn")
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

	lane.call("configure_lane", PracticeCatalog.get_module("energia"), [player_robot])
	await process_frame
	await process_frame

	_assert_lane_contract(lane)

	_assert(player_robot.set_energy_focus("left_leg"), "EnergyLane deberia poder cambiar el foco a piernas.")
	lane.call("_physics_process", 0.016)
	_assert(String(player_robot.get_energy_state_summary()).contains("Foco"), "El estado de energia deberia reflejar el foco activo.")

	player_robot.set("_energy_shift_cooldown_remaining", 0.0)
	_assert(player_robot.set_energy_focus("left_arm"), "EnergyLane deberia poder cambiar el foco a brazos.")
	player_robot.set("_energy_shift_cooldown_remaining", 0.0)
	_assert(player_robot.activate_overdrive(), "EnergyLane deberia poder activar Overdrive.")
	lane.call("_physics_process", 0.016)

	var progress_text := "\n".join(Array(lane.call("get_progress_lines")))
	_assert(progress_text.contains("P1 |"), "EnergyLane deberia mostrar resumen de energia por jugador.")
	_assert(progress_text.contains("OD"), "EnergyLane deberia mostrar estado de Overdrive.")
	_assert(bool(lane.call("is_lane_completed")), "EnergyLane deberia completar al pasar por las tres capas de energia.")

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


func _assert_lane_contract(lane: Node) -> void:
	_assert(lane.has_method("get_objective_lines"), "La estacion debe exponer objetivos.")
	_assert(lane.has_method("get_progress_lines"), "La estacion debe exponer progreso.")
	_assert(lane.has_method("get_callout_lines"), "La estacion debe exponer callouts.")
	_assert(lane.has_method("get_context_card_lines"), "La estacion debe exponer tarjeta contextual.")
	_assert(Array(lane.call("get_objective_lines")).size() <= 2, "Objetivos deben ser cortos.")
	_assert(Array(lane.call("get_context_card_lines")).size() <= 3, "Tarjeta contextual debe ser breve.")
	_assert(not Array(lane.call("get_objective_lines")).is_empty(), "EnergyLane deberia exponer instrucciones objetivas.")
	_assert(not Array(lane.call("get_callout_lines")).is_empty(), "EnergyLane deberia exponer callout de lectura.")


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
