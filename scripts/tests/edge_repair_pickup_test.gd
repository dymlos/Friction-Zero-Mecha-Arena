extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const PICKUP_SCENE := preload("res://scenes/pickups/edge_repair_pickup.tscn")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_robot_repair_behavior()
	await _validate_pickup_cooldown_telegraph()
	await _validate_main_scene_edge_pickups()
	_finish()


func _validate_robot_repair_behavior() -> void:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(robot)

	await process_frame
	await physics_frame

	robot.apply_damage_to_part("left_leg", 50.0)
	robot.apply_damage_to_part("right_arm", 10.0)
	var has_repair_method := robot.has_method("repair_most_damaged_part")
	_assert(has_repair_method, "El robot deberia exponer una reparacion simple para pickups universales de borde.")
	var repaired_part: Variant = ""
	if has_repair_method:
		repaired_part = robot.call("repair_most_damaged_part", 25.0)

	if has_repair_method:
		_assert(
			repaired_part == "left_leg",
			"El pickup de borde deberia reparar primero la parte activa mas castigada."
		)
		_assert(
			is_equal_approx(robot.get_part_health("left_leg"), 75.0),
			"La reparacion deberia sumar vida a la parte mas dañada sin revivir partes destruidas."
		)
		_assert(
			is_equal_approx(robot.get_part_health("right_arm"), 90.0),
			"La reparacion no deberia repartirse entre todas las partes si la mas dañada sigue activa."
		)

	await _cleanup_node(robot)


func _validate_pickup_cooldown_telegraph() -> void:
	var pickup := PICKUP_SCENE.instantiate()
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(pickup)
	root.add_child(robot)

	await process_frame
	await physics_frame

	robot.apply_damage_to_part("left_arm", 25.0)
	pickup.call("_on_body_entered", robot)

	var base_mesh := pickup.get_node_or_null("Visuals/Base")
	var core_mesh := pickup.get_node_or_null("Visuals/Core")
	_assert(base_mesh is MeshInstance3D, "El pickup de borde deberia conservar una base visual dedicada.")
	_assert(core_mesh is MeshInstance3D, "El pickup de borde deberia conservar un nucleo visible para la carga activa.")
	if base_mesh is MeshInstance3D:
		_assert(
			(base_mesh as MeshInstance3D).is_visible_in_tree(),
			"El pedestal del pickup deberia seguir visible durante cooldown para telegraph del borde."
		)
	if core_mesh is MeshInstance3D:
		_assert(
			not (core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo activo deberia apagarse durante cooldown para marcar que la carga no esta disponible."
		)

	pickup.call("_on_respawn_timer_timeout")
	await process_frame

	if core_mesh is MeshInstance3D:
		_assert(
			(core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup deberia volver a verse cuando la carga reaparece."
		)

	await _cleanup_node(robot)
	await _cleanup_node(pickup)


func _validate_main_scene_edge_pickups() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var arena := main.get_node_or_null("ArenaRoot/ArenaBlockout")
	_assert(arena is ArenaBase, "La escena principal deberia seguir montando un ArenaBase real.")
	if not (arena is ArenaBase):
		await _cleanup_node(main)
		return

	var edge_pickups := get_nodes_in_group("edge_repair_pickups")
	_assert(edge_pickups.size() >= 2, "La arena principal deberia ofrecer pickups universales en los bordes.")

	var arena_base := arena as ArenaBase
	var half_size := arena_base.get_safe_play_area_size() * 0.5
	var pickup_near_edge := false
	for pickup in edge_pickups:
		if not (pickup is Node3D):
			continue

		var local_position := arena_base.to_local((pickup as Node3D).global_position)
		if absf(local_position.x) >= half_size.x * 0.55 or absf(local_position.z) >= half_size.y * 0.55:
			pickup_near_edge = true
			break

	_assert(pickup_near_edge, "Los pickups nuevos deberian vivir cerca del riesgo de borde, no en el centro limpio.")

	await _cleanup_node(main)


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
