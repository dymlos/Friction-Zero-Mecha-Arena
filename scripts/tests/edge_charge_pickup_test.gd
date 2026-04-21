extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")

const AGUJA_CONFIG_PATH := "res://data/config/robots/aguja_archetype.tres"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _drain_frames()
	await _validate_robot_core_skill_charge_refill_behavior()
	await _validate_pickup_cooldown_telegraph()
	await _validate_default_teams_scene_keeps_charge_pickups_inactive()
	await _validate_ffa_scene_enables_charge_pickups_for_skill_robots()
	_finish()


func _validate_robot_core_skill_charge_refill_behavior() -> void:
	var config := load(AGUJA_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "La prueba de municion/carga necesita el recurso Aguja.")
	if not (config is RobotArchetypeConfig):
		return

	var tuned_config := (config as RobotArchetypeConfig).duplicate(true) as RobotArchetypeConfig
	tuned_config.set("core_skill_recharge_seconds", 30.0)
	var robot := await _spawn_robot(tuned_config)

	_assert(robot.has_method("restore_core_skill_charges"), "RobotBase deberia exponer una recarga simple de cargas para pickups de municion.")
	if not robot.has_method("restore_core_skill_charges"):
		await _cleanup_node(robot)
		return

	var initial_charges := int(robot.call("get_core_skill_charge_count"))
	var used := bool(robot.call("use_core_skill"))
	_assert(used, "La skill propia deberia poder gastar una carga antes de probar la recarga de municion.")
	if not used:
		await _cleanup_group("temporary_projectiles")
		await _cleanup_node(robot)
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
	await _cleanup_node(robot)


func _validate_pickup_cooldown_telegraph() -> void:
	var pickup_scene := _load_edge_charge_pickup_scene()
	if pickup_scene == null:
		return

	var config := load(AGUJA_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "El pickup de municion/carga necesita probarse con una skill real.")
	if not (config is RobotArchetypeConfig):
		return

	var tuned_config := (config as RobotArchetypeConfig).duplicate(true) as RobotArchetypeConfig
	tuned_config.set("core_skill_recharge_seconds", 30.0)
	var pickup := pickup_scene.instantiate()
	var robot := await _spawn_robot(tuned_config)
	root.add_child(pickup)

	await process_frame
	await physics_frame

	var used := bool(robot.call("use_core_skill"))
	_assert(used, "La prueba del pickup de municion necesita una carga gastada antes de recogerlo.")
	if not used:
		await _cleanup_node(pickup)
		await _cleanup_group("temporary_projectiles")
		await _cleanup_node(robot)
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

	await _cleanup_node(pickup)
	await _cleanup_group("temporary_projectiles")
	await _cleanup_node(robot)


func _validate_default_teams_scene_keeps_charge_pickups_inactive() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var arena := main.get_node_or_null("ArenaRoot/ArenaBlockout")
	_assert(arena is ArenaBase, "La escena principal deberia seguir montando un ArenaBase real.")
	if not (arena is ArenaBase):
		await _cleanup_node(main)
		return

	var charge_pickups := _get_charge_pickups(main)
	_assert(charge_pickups.size() >= 2, "La arena principal deberia reservar al menos dos pedestales para municion/carga.")
	if charge_pickups.size() < 2:
		await _cleanup_node(main)
		return

	var arena_base := arena as ArenaBase
	for round_number in range(1, 7):
		arena_base.activate_edge_pickup_layout_for_round(round_number)
		await process_frame
		_assert(
			_find_enabled_pickup(main) == null,
			"El laboratorio 2v2 base no deberia activar municion/carga si solo un equipo trae skills propias."
		)

	await _disable_edge_pickups(main)
	await _cleanup_node(main)


func _validate_ffa_scene_enables_charge_pickups_for_skill_robots() -> void:
	var main = FFA_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var arena := main.get_node_or_null("ArenaRoot/ArenaBlockout")
	_assert(arena is ArenaBase, "La escena FFA deberia seguir montando un ArenaBase real.")
	if not (arena is ArenaBase):
		await _cleanup_node(main)
		return

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "La escena FFA deberia seguir ofreciendo cuatro robots.")
	if robots.size() < 4:
		await _cleanup_node(main)
		return

	var skill_robot := robots[1]
	_assert(
		skill_robot.has_method("has_core_skill") and bool(skill_robot.call("has_core_skill")),
		"La escena FFA deberia conservar al menos un robot con skill propia para justificar la municion/carga."
	)
	if not (skill_robot.has_method("has_core_skill") and bool(skill_robot.call("has_core_skill"))):
		await _cleanup_node(main)
		return

	var initial_charges := int(skill_robot.call("get_core_skill_charge_count"))
	var used := bool(skill_robot.call("use_core_skill"))
	_assert(used, "La escena FFA deberia poder gastar una carga antes de buscar el pickup de municion.")
	if not used:
		await _cleanup_node(main)
		return

	var arena_base := arena as ArenaBase
	var active_pickup: Node3D = null
	for round_number in range(1, 9):
		arena_base.activate_edge_pickup_layout_for_round(round_number)
		await process_frame
		active_pickup = _find_enabled_pickup(main)
		if active_pickup != null:
			break

	_assert(active_pickup != null, "FFA deberia habilitar municion/carga cuando el roster libre si tiene skills propias que aprovechar.")
	if active_pickup == null:
		await _cleanup_node(main)
		return

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel")
	_assert(round_label is Label, "El HUD FFA deberia seguir exponiendo el bloque de estado de ronda.")
	if round_label is Label:
		_assert(
			String((round_label as Label).text).contains("municion"),
			"El resumen `Borde | ...` deberia nombrar la municion/carga cuando forme parte del layout activo."
		)

	skill_robot.global_position = active_pickup.global_position
	active_pickup.call("_on_body_entered", skill_robot)
	await process_frame

	_assert(
		int(skill_robot.call("get_core_skill_charge_count")) == initial_charges,
		"El pickup de municion/carga deberia restaurar la carga gastada del robot con skill propia."
	)
	var status_message := String(main.ui.status_label.text)
	_assert(
		status_message.contains("municion") or status_message.contains("carga"),
		"El HUD deberia publicar una linea breve cuando alguien recarga su skill en el borde."
	)

	await _disable_edge_pickups(main)
	await _cleanup_node(main)
	await _cleanup_group("temporary_projectiles")


func _load_edge_charge_pickup_scene() -> PackedScene:
	var loaded_scene := load("res://scenes/pickups/edge_charge_pickup.tscn")
	_assert(loaded_scene is PackedScene, "Deberia existir una escena dedicada para el pickup de municion/carga.")
	if loaded_scene is PackedScene:
		return loaded_scene as PackedScene

	return null


func _spawn_robot(config: RobotArchetypeConfig) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	if config != null:
		robot.archetype_config = config

	root.add_child(robot)
	await process_frame
	await process_frame
	return robot


func _get_charge_pickups(root_node: Node) -> Array[Node3D]:
	var pickups: Array[Node3D] = []
	for node in root_node.get_tree().get_nodes_in_group("edge_charge_pickups"):
		if not root_node.is_ancestor_of(node):
			continue
		if node is Node3D:
			pickups.append(node as Node3D)

	return pickups


func _find_enabled_pickup(root_node: Node) -> Node3D:
	for pickup in _get_charge_pickups(root_node):
		if pickup.has_method("is_spawn_enabled") and bool(pickup.call("is_spawn_enabled")):
			return pickup

	return null


func _get_scene_robots(root_node: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := root_node.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _cleanup_group(group_name: String) -> void:
	for node in get_nodes_in_group(group_name):
		if node is Node:
			await _cleanup_node(node as Node)


func _disable_edge_pickups(root_node: Node) -> void:
	for pickup in root_node.get_tree().get_nodes_in_group("edge_pickups"):
		if not root_node.is_ancestor_of(pickup):
			continue
		if pickup.has_method("set_spawn_enabled"):
			pickup.call("set_spawn_enabled", false)

	await _drain_frames()


func _drain_frames(frame_count: int = 2) -> void:
	for _index in range(maxi(frame_count, 1)):
		await process_frame
		await physics_frame


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.queue_free()
	await process_frame
	await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
