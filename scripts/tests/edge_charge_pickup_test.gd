extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")

const AGUJA_CONFIG_PATH := "res://data/config/robots/aguja_archetype.tres"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _drain_frames()
	await _validate_robot_core_skill_charge_refill_behavior()
	await _validate_pickup_cooldown_telegraph()
	_finish()


func _validate_robot_core_skill_charge_refill_behavior() -> void:
	var config := load(AGUJA_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "La prueba de municion/carga necesita el recurso Aguja.")
	if not (config is RobotArchetypeConfig):
		return

	var scenario_root := Node.new()
	root.add_child(scenario_root)
	var tuned_config := (config as RobotArchetypeConfig).duplicate(true) as RobotArchetypeConfig
	tuned_config.set("core_skill_recharge_seconds", 30.0)
	var robot := await _spawn_robot(tuned_config, scenario_root)

	_assert(robot.has_method("restore_core_skill_charges"), "RobotBase deberia exponer una recarga simple de cargas para pickups de municion.")
	if not robot.has_method("restore_core_skill_charges"):
		await _cleanup_scene_root(scenario_root)
		return

	var initial_charges := int(robot.call("get_core_skill_charge_count"))
	var used := bool(robot.call("use_core_skill"))
	_assert(used, "La skill propia deberia poder gastar una carga antes de probar la recarga de municion.")
	if not used:
		await _cleanup_group("temporary_projectiles")
		await _cleanup_scene_root(scenario_root)
		return

	await process_frame

	_assert(
		int(robot.call("get_core_skill_charge_count")) == max(initial_charges - 1, 0),
		"Gastar la skill propia deberia reducir una carga antes de tocar el pickup."
	)

	var refilled := bool(robot.call("restore_core_skill_charges", 1))
	_assert(refilled, "La recarga de municion deberia restaurar al menos una carga faltante.")
	_assert(
		int(robot.call("get_core_skill_charge_count")) == initial_charges,
		"La recarga de municion deberia devolver la skill al maximo sin esperar el timer normal."
	)
	_assert(
		not bool(robot.call("restore_core_skill_charges", 1)),
		"La recarga de municion no deberia sobrellenar una skill que ya esta al maximo."
	)

	await _cleanup_group("temporary_projectiles")
	await _cleanup_scene_root(scenario_root)


func _validate_pickup_cooldown_telegraph() -> void:
	var pickup_scene := _load_edge_charge_pickup_scene()
	if pickup_scene == null:
		return

	var config := load(AGUJA_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "El pickup de municion/carga necesita probarse con una skill real.")
	if not (config is RobotArchetypeConfig):
		return

	var scenario_root := Node.new()
	root.add_child(scenario_root)
	var tuned_config := (config as RobotArchetypeConfig).duplicate(true) as RobotArchetypeConfig
	tuned_config.set("core_skill_recharge_seconds", 30.0)
	var pickup := pickup_scene.instantiate()
	scenario_root.add_child(pickup)
	var robot := await _spawn_robot(tuned_config, scenario_root)

	await process_frame
	await physics_frame

	var used := bool(robot.call("use_core_skill"))
	_assert(used, "La prueba del pickup de municion necesita una carga gastada antes de recogerlo.")
	if not used:
		await _cleanup_group("temporary_projectiles")
		await _cleanup_scene_root(scenario_root)
		return

	await process_frame

	pickup.call("_on_body_entered", robot)
	await process_frame

	_assert(
		int(robot.call("get_core_skill_charge_count")) == int(robot.call("get_core_skill_max_charges")),
		"Tocar el pickup de municion deberia restaurar la carga faltante de la skill propia."
	)

	var base_mesh := pickup.get_node_or_null("Visuals/Base")
	var core_mesh := pickup.get_node_or_null("Visuals/Core")
	_assert(base_mesh is MeshInstance3D, "El pickup de municion deberia conservar un pedestal visible.")
	_assert(core_mesh is MeshInstance3D, "El pickup de municion deberia conservar un nucleo visible para marcar la carga disponible.")
	if base_mesh is MeshInstance3D:
		_assert(
			(base_mesh as MeshInstance3D).is_visible_in_tree(),
			"El pedestal del pickup de municion deberia seguir visible durante cooldown."
		)
	if core_mesh is MeshInstance3D:
		_assert(
			not (core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup de municion deberia apagarse durante cooldown."
		)

	pickup.call("_on_respawn_timer_timeout")
	await process_frame

	if core_mesh is MeshInstance3D:
		_assert(
			(core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup de municion deberia volver a verse al reaparecer."
		)

	await _cleanup_group("temporary_projectiles")
	await _cleanup_scene_root(scenario_root)

func _load_edge_charge_pickup_scene() -> PackedScene:
	var loaded_scene := load("res://scenes/pickups/edge_charge_pickup.tscn")
	_assert(loaded_scene is PackedScene, "Deberia existir una escena dedicada para el pickup de municion/carga.")
	if loaded_scene is PackedScene:
		return loaded_scene as PackedScene

	return null


func _spawn_robot(config: RobotArchetypeConfig, parent: Node = root) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	if config != null:
		robot.archetype_config = config

	parent.add_child(robot)
	await process_frame
	await process_frame
	return robot

func _cleanup_group(group_name: String) -> void:
	for node in get_nodes_in_group(group_name):
		if node is Node:
			await _cleanup_scene_root(node as Node)


func _drain_frames(frame_count: int = 2) -> void:
	for _index in range(maxi(frame_count, 1)):
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


func _cleanup_scene_root(node: Node) -> void:
	if not is_instance_valid(node):
		return

	node.queue_free()
	await _drain_frames(3)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	call_deferred("_finish_after_cleanup")


func _finish_after_cleanup() -> void:
	await _drain_frames(4)
	quit(1 if _failed else 0)
