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
	await _validate_robot_stability_boost_behavior()
	await _validate_pickup_cooldown_telegraph()
	await _validate_main_scene_utility_pickups()
	await _validate_pickups_follow_arena_contraction()
	_finish()


func _validate_robot_stability_boost_behavior() -> void:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(robot)

	await process_frame
	await physics_frame

	var baseline_impulse_multiplier := robot.get_received_impulse_multiplier()
	var has_apply_method := robot.has_method("apply_stability_boost")
	var has_active_method := robot.has_method("is_stability_boost_active")
	_assert(has_apply_method, "El robot deberia exponer una forma simple de recibir una ventana de estabilidad utility.")
	_assert(has_active_method, "El robot deberia poder informar si la estabilidad utility sigue activa.")
	if not has_apply_method or not has_active_method:
		await _cleanup_node(robot)
		return

	robot.apply_control_zone_suppression(0.3, 0.7, 0.65)
	_assert(robot.is_control_zone_suppressed(), "La prueba utility necesita arrancar desde una supresion activa.")

	var applied := bool(robot.call("apply_stability_boost", 0.35))
	_assert(applied, "La estabilidad utility deberia activarse cuando el robot sigue operativo.")
	await process_frame

	var status_indicator := robot.get_node_or_null("UpperBodyPivot/StatusEffectIndicator") as MeshInstance3D
	_assert(
		status_indicator != null,
		"El robot deberia crear un indicador diegetico para estados de estabilidad/supresion."
	)

	_assert(
		bool(robot.call("is_stability_boost_active")),
		"El robot deberia entrar en estado de estabilidad tras recoger utility."
	)
	if status_indicator != null:
		_assert(
			status_indicator.visible,
			"La estabilidad utility deberia leerse tambien sobre el cuerpo del robot, no solo en el roster."
		)

	_assert(
		not robot.is_control_zone_suppressed(),
		"La estabilidad utility deberia limpiar una supresion de zona/interferencia que ya estaba activa."
	)
	_assert(
		robot.get_received_impulse_multiplier() < baseline_impulse_multiplier,
		"La estabilidad utility deberia volver al robot algo mas firme frente a empujes externos."
	)

	robot.apply_control_zone_suppression(0.25, 0.68, 0.62)
	_assert(
		not robot.is_control_zone_suppressed(),
		"Mientras la estabilidad siga activa, nuevas zonas/interferencias no deberian reprimir al robot."
	)

	await create_timer(0.45).timeout
	await process_frame
	_assert(
		not bool(robot.call("is_stability_boost_active")),
		"La estabilidad utility no deberia quedar permanente tras expirar su ventana."
	)
	if status_indicator != null:
		_assert(
			not status_indicator.visible,
			"Al terminar la estabilidad utility, el indicador diegetico deberia apagarse."
		)
	_assert(
		is_equal_approx(robot.get_received_impulse_multiplier(), baseline_impulse_multiplier),
		"Al terminar la estabilidad, la resistencia a empuje deberia volver a su base previa."
	)

	robot.apply_control_zone_suppression(0.2, 0.7, 0.65)
	_assert(
		robot.is_control_zone_suppressed(),
		"Cuando la estabilidad expira, el robot deberia volver a poder ser afectado por zonas/interferencias."
	)

	await _cleanup_node(robot)


func _validate_pickup_cooldown_telegraph() -> void:
	var pickup_scene := _load_edge_utility_pickup_scene()
	if pickup_scene == null:
		return

	var pickup := pickup_scene.instantiate()
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(pickup)
	root.add_child(robot)

	await process_frame
	await physics_frame

	robot.apply_control_zone_suppression(0.3, 0.72, 0.64)
	pickup.call("_on_body_entered", robot)
	await process_frame

	_assert(
		bool(robot.call("is_stability_boost_active")),
		"Tocar el pickup utility deberia activar estabilidad en el robot que lo recoge."
	)
	_assert(
		not robot.is_control_zone_suppressed(),
		"Tocar el pickup utility deberia limpiar la supresion activa del robot."
	)

	var base_mesh := pickup.get_node_or_null("Visuals/Base")
	var core_mesh := pickup.get_node_or_null("Visuals/Core")
	var status_indicator := robot.get_node_or_null("UpperBodyPivot/StatusEffectIndicator") as MeshInstance3D
	_assert(base_mesh is MeshInstance3D, "El pickup utility deberia conservar un pedestal visible.")
	_assert(core_mesh is MeshInstance3D, "El pickup utility deberia conservar un nucleo visible para su estado activo.")
	_assert(
		status_indicator != null,
		"El robot deberia exponer el indicador diegetico de estabilidad tambien en el camino del pickup."
	)
	if status_indicator != null:
		_assert(
			status_indicator.visible,
			"Recoger utility en escena deberia prender el indicador diegetico de estabilidad."
		)
	if base_mesh is MeshInstance3D:
		_assert(
			(base_mesh as MeshInstance3D).is_visible_in_tree(),
			"El pedestal del pickup utility deberia seguir visible durante cooldown para telegraph del borde."
		)
	if core_mesh is MeshInstance3D:
		_assert(
			not (core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup utility deberia apagarse durante cooldown para indicar que ya fue consumido."
		)

	pickup.call("_on_respawn_timer_timeout")
	await process_frame

	if core_mesh is MeshInstance3D:
		_assert(
			(core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup utility deberia volver a verse cuando reaparece la carga."
		)

	await _cleanup_node(robot)
	await _cleanup_node(pickup)


func _validate_main_scene_utility_pickups() -> void:
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

	var edge_pickups := get_nodes_in_group("edge_utility_pickups")
	_assert(edge_pickups.size() >= 2, "La arena principal deberia ofrecer al menos dos pickups utility.")

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

	_assert(pickup_near_edge, "Los pickups utility deberian vivir cerca del riesgo de borde, no en el centro limpio.")

	var scene_robots := _get_scene_robots(main)
	var active_pickup := _find_enabled_pickup(main, "edge_utility_pickups")
	if active_pickup == null:
		for round_number in range(1, 9):
			arena_base.activate_edge_pickup_layout_for_round(round_number)
			await process_frame
			active_pickup = _find_enabled_pickup(main, "edge_utility_pickups")
			if active_pickup != null:
				break

	_assert(active_pickup != null, "La escena principal deberia habilitar utility en al menos un layout del borde.")

	if active_pickup != null and scene_robots.size() > 0:
		var robot := scene_robots[0]
		robot.apply_control_zone_suppression(0.3, 0.72, 0.64)
		robot.global_position = active_pickup.global_position
		active_pickup.call("_on_body_entered", robot)
		await process_frame
		var status_indicator := robot.get_node_or_null("UpperBodyPivot/StatusEffectIndicator") as MeshInstance3D
		var roster_lines := (match_controller as MatchController).get_robot_status_lines()
		_assert(
			roster_lines.any(func(line: String) -> bool: return line.contains(robot.display_name) and line.contains("estabilidad")),
			"El roster compacto deberia dejar visible cuando un robot tiene utility de estabilidad activa."
		)
		_assert(
			status_indicator != null and status_indicator.visible,
			"El robot que asegura utility deberia mostrar tambien un cue diegetico de estabilidad."
		)
		var status_message := String(main.ui.status_label.text)
		_assert(
			status_message.contains("estabilidad"),
			"El HUD deberia publicar una linea breve cuando alguien asegura utility en el borde."
		)

	await _cleanup_node(main)


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
	var pickups := _get_edge_utility_pickups(arena)
	_assert(pickups.size() >= 2, "La escena de arena deberia mantener pickups utility durante la contraccion.")
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
			"Antes de la contraccion, los pickups utility deberian seguir cargados hacia el borde."
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
			"Los pickups utility deberian seguir dentro del area viva cuando el arena se contrae."
		)
		_assert(
			shrunk_ratio >= 0.45,
			"Los pickups utility deberian seguir cerca del nuevo borde util, no migrar al centro."
		)
		_assert(
			shrunk_ratio <= initial_edge_ratios[index] + 0.05,
			"Los pickups utility no deberian desplazarse hacia fuera del borde vivo tras la contraccion."
		)

	await _cleanup_node(arena)


func _load_edge_utility_pickup_scene() -> PackedScene:
	var loaded_scene := load("res://scenes/pickups/edge_utility_pickup.tscn")
	_assert(loaded_scene is PackedScene, "Deberia existir una escena dedicada para el pickup utility de borde.")
	if loaded_scene is PackedScene:
		return loaded_scene as PackedScene

	return null


func _get_edge_utility_pickups(root_node: Node) -> Array[Node3D]:
	var pickups: Array[Node3D] = []
	for child in root_node.find_children("*", "Node3D", true, false):
		if child.is_in_group("edge_utility_pickups"):
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
