extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const ARENA_SCENE := preload("res://scenes/arenas/arena_blockout.tscn")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_main_scene_mobility_pickups()
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	await _validate_pickups_follow_arena_contraction()
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	await _validate_robot_mobility_boost_behavior()
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	await _validate_pickup_cooldown_telegraph()
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	_finish()


func _validate_robot_mobility_boost_behavior() -> void:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(robot)

	await process_frame
	await physics_frame

	var baseline_leg_drive: float = robot.get_effective_leg_drive_multiplier()
	var baseline_leg_control: float = robot._get_effective_leg_control_multiplier()
	var has_apply_method := robot.has_method("apply_mobility_boost")
	var has_active_method := robot.has_method("is_mobility_boost_active")
	_assert(has_apply_method, "El robot deberia exponer una forma simple de recibir un boost temporal de movilidad.")
	_assert(has_active_method, "El robot deberia poder informar si un boost temporal de movilidad sigue activo.")
	if has_apply_method and has_active_method:
		var applied := bool(robot.call("apply_mobility_boost", 0.25))
		_assert(applied, "El boost de movilidad deberia activarse cuando el robot sigue operativo.")
		await process_frame
		_assert(
			bool(robot.call("is_mobility_boost_active")),
			"El robot deberia entrar en estado de movilidad reforzada tras tocar el pickup."
		)
		_assert(
			robot.get_effective_leg_drive_multiplier() > baseline_leg_drive,
			"El boost de movilidad deberia mejorar la traccion real del robot."
		)
		_assert(
			robot._get_effective_leg_control_multiplier() > baseline_leg_control,
			"El boost de movilidad tambien deberia mejorar el control del derrape."
		)

		await create_timer(0.4).timeout
		await process_frame
		_assert(
			not bool(robot.call("is_mobility_boost_active")),
			"El boost de movilidad no deberia quedar permanente tras expirar su ventana."
		)
		_assert(
			is_equal_approx(robot.get_effective_leg_drive_multiplier(), baseline_leg_drive),
			"Al terminar el boost, la traccion deberia volver a su base previa."
		)

	await _cleanup_node(robot)


func _validate_pickup_cooldown_telegraph() -> void:
	var pickup_scene := _load_edge_mobility_pickup_scene()
	if pickup_scene == null:
		return

	var pickup := pickup_scene.instantiate()
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(pickup)
	root.add_child(robot)

	await process_frame
	await physics_frame

	pickup.call("_on_body_entered", robot)
	await process_frame

	_assert(
		bool(robot.call("is_mobility_boost_active")),
		"Tocar el pickup de movilidad deberia activar el boost en el robot que lo recoge."
	)

	var base_mesh := pickup.get_node_or_null("Visuals/Base")
	var core_mesh := pickup.get_node_or_null("Visuals/Core")
	_assert(base_mesh is MeshInstance3D, "El pickup de movilidad deberia conservar un pedestal visible.")
	_assert(core_mesh is MeshInstance3D, "El pickup de movilidad deberia conservar un nucleo visible para su estado activo.")
	if base_mesh is MeshInstance3D:
		_assert(
			(base_mesh as MeshInstance3D).is_visible_in_tree(),
			"El pedestal del pickup de movilidad deberia seguir visible durante cooldown para telegraph del borde."
		)
	if core_mesh is MeshInstance3D:
		_assert(
			not (core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup de movilidad deberia apagarse durante cooldown para indicar que ya fue consumido."
		)

	pickup.call("_on_respawn_timer_timeout")
	await process_frame

	if core_mesh is MeshInstance3D:
		_assert(
			(core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup de movilidad deberia volver a verse cuando reaparece la carga."
		)

	await _cleanup_node(pickup)
	await _cleanup_node(robot)


func _validate_main_scene_mobility_pickups() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var arena := main.get_node_or_null("ArenaRoot/ArenaBlockout")
	var match_controller := main.get_node_or_null("Systems/MatchController")
	_assert(arena is ArenaBase, "La escena principal deberia seguir montando un ArenaBase real.")
	_assert(match_controller is MatchController, "La escena principal deberia seguir exponiendo MatchController para el roster compacto.")
	if not (arena is ArenaBase) or not (match_controller is MatchController):
		await _cleanup_node(main)
		return

	var edge_pickups := get_nodes_in_group("edge_mobility_pickups")
	_assert(edge_pickups.size() >= 2, "La arena principal deberia ofrecer al menos dos pickups de movilidad en bordes.")

	var arena_base := arena as ArenaBase
	var half_size := arena_base.get_safe_play_area_size() * 0.5
	var pickup_near_edge := false
	for pickup in edge_pickups:
		if not (pickup is Node3D):
			continue

		var local_position := arena_base.to_local((pickup as Node3D).global_position)
		var edge_ratio := maxf(
			absf(local_position.x) / maxf(half_size.x, 0.01),
			absf(local_position.z) / maxf(half_size.y, 0.01)
		)
		if edge_ratio >= 0.55:
			pickup_near_edge = true
			break

	_assert(pickup_near_edge, "Los pickups de movilidad deberian vivir cerca del riesgo de borde, no en el centro limpio.")

	var scene_robots := _get_scene_robots(main)
	var active_pickup := _find_enabled_pickup(main, "edge_mobility_pickups")
	if active_pickup == null:
		for round_number in range(1, 5):
			arena_base.activate_edge_pickup_layout_for_round(round_number)
			await process_frame
			active_pickup = _find_enabled_pickup(main, "edge_mobility_pickups")
			if active_pickup != null:
				break

	_assert(active_pickup != null, "La escena principal deberia habilitar movilidad en al menos un layout del borde.")

	if active_pickup != null and scene_robots.size() > 0:
		if (match_controller as MatchController).is_round_intro_active():
			await create_timer((match_controller as MatchController).get_round_intro_time_left() + 0.15).timeout
			await process_frame
		var robot := scene_robots[0]
		robot.global_position = active_pickup.global_position
		active_pickup.call("_on_body_entered", robot)
		await process_frame
		var roster_lines := (match_controller as MatchController).get_robot_status_lines()
		_assert(
			roster_lines.any(func(line: String) -> bool: return line.contains(robot.display_name) and line.contains("impulso")),
			"El roster compacto deberia dejar visible cuando un robot tiene el pickup de movilidad activo."
		)

	await _disable_edge_pickups(main)
	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame


func _validate_pickups_follow_arena_contraction() -> void:
	var arena := ARENA_SCENE.instantiate()
	root.add_child(arena)

	await process_frame
	await process_frame

	_assert(arena is ArenaBase, "La escena de arena deberia exponer el contrato base de contraccion.")
	if not (arena is ArenaBase):
		await _cleanup_node(arena)
		return

	var arena_base := arena as ArenaBase
	var initial_half_size := arena_base.get_safe_play_area_size() * 0.5
	var pickups := _get_edge_mobility_pickups(arena)
	_assert(pickups.size() >= 2, "La escena de arena deberia mantener pickups de movilidad durante la contraccion.")
	if pickups.size() < 2:
		await _cleanup_node(arena)
		return

	var initial_edge_ratios: Array[float] = []
	for pickup in pickups:
		var local_position := arena_base.to_local(pickup.global_position)
		var initial_ratio := maxf(
			absf(local_position.x) / maxf(initial_half_size.x, 0.01),
			absf(local_position.z) / maxf(initial_half_size.y, 0.01)
		)
		initial_edge_ratios.append(initial_ratio)
		_assert(
			initial_ratio >= 0.55,
			"Antes de la contraccion, los pickups de movilidad deberian seguir cargados hacia el borde."
		)

	arena_base.set_play_area_scale(0.5)
	await process_frame

	var shrunk_half_size := arena_base.get_safe_play_area_size() * 0.5
	for index in range(pickups.size()):
		var pickup := pickups[index]
		var local_position := arena_base.to_local(pickup.global_position)
		var shrunk_ratio := maxf(
			absf(local_position.x) / maxf(shrunk_half_size.x, 0.01),
			absf(local_position.z) / maxf(shrunk_half_size.y, 0.01)
		)
		_assert(
			arena_base.is_position_inside_play_area(pickup.global_position),
			"Los pickups de movilidad deberian seguir dentro del area viva cuando el arena se contrae."
		)
		_assert(
			shrunk_ratio >= 0.45,
			"Los pickups de movilidad deberian seguir cerca del nuevo borde util, no migrar al centro."
		)
		_assert(
			shrunk_ratio <= initial_edge_ratios[index] + 0.05,
			"Los pickups de movilidad no deberian desplazarse hacia fuera del borde vivo tras la contraccion."
		)

	await _cleanup_node(arena)


func _load_edge_mobility_pickup_scene() -> PackedScene:
	var loaded_scene := load("res://scenes/pickups/edge_mobility_pickup.tscn")
	_assert(loaded_scene is PackedScene, "Deberia existir una escena dedicada para el pickup de movilidad de borde.")
	if loaded_scene is PackedScene:
		return loaded_scene as PackedScene

	return null


func _get_edge_mobility_pickups(root_node: Node) -> Array[Node3D]:
	var pickups: Array[Node3D] = []
	for child in root_node.find_children("*", "Node3D", true, false):
		if child.is_in_group("edge_mobility_pickups"):
			pickups.append(child as Node3D)

	return pickups


func _find_enabled_pickup(root_node: Node, group_name: String) -> Node3D:
	for pickup in root_node.get_tree().get_nodes_in_group(group_name):
		if not root_node.is_ancestor_of(pickup):
			continue
		if not (pickup is Node3D):
			continue
		if pickup.has_method("is_spawn_enabled") and bool(pickup.call("is_spawn_enabled")):
			return pickup as Node3D

	return null


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _disable_edge_pickups(root_node: Node) -> void:
	for pickup in root_node.get_tree().get_nodes_in_group("edge_pickups"):
		if not root_node.is_ancestor_of(pickup):
			continue
		if pickup.has_method("set_spawn_enabled"):
			pickup.call("set_spawn_enabled", false)

	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var areas: Array[Area3D] = []
	if node is Area3D:
		areas.append(node as Area3D)
	for child in node.find_children("*", "Area3D", true, false):
		if child is Area3D:
			areas.append(child as Area3D)
	for area in areas:
		area.monitoring = false
		area.monitorable = false
		var collision_shape := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision_shape != null:
			collision_shape.disabled = true
	if not areas.is_empty():
		await physics_frame
		await process_frame

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	call_deferred("_finish_after_cleanup")


func _finish_after_cleanup() -> void:
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	quit(1 if _failed else 0)
