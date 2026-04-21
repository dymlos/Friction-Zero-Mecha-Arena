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
	await _validate_robot_energy_surge_behavior()
	await _validate_pickup_cooldown_telegraph()
	await _validate_main_scene_energy_pickups()
	await _validate_pickups_follow_arena_contraction()
	_finish()


func _validate_robot_energy_surge_behavior() -> void:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(robot)

	await process_frame
	await physics_frame

	robot.energy_shift_cooldown = 0.0
	robot.overdrive_duration = 0.1
	robot.overdrive_recovery_duration = 0.35
	robot.overdrive_cooldown = 0.8
	var focused := robot.set_energy_focus("left_leg")
	_assert(focused, "El robot deberia poder preparar un foco de energia antes del pickup.")
	var focused_leg_drive: float = robot.get_effective_leg_drive_multiplier()
	var activated := robot.activate_overdrive()
	_assert(activated, "El robot deberia poder entrar en overdrive para probar la recuperacion.")
	robot._update_energy_state(0.2)
	_assert(robot._overdrive_recovery_remaining > 0.0, "La prueba deberia entrar en recuperacion tras el overdrive.")

	var has_apply_method := robot.has_method("apply_energy_surge")
	var has_active_method := robot.has_method("is_energy_surge_active")
	_assert(has_apply_method, "El robot deberia exponer una recarga de energia simple para pickups universales.")
	_assert(has_active_method, "El robot deberia poder informar si una recarga temporal de energia sigue activa.")
	if has_apply_method and has_active_method:
		var applied := bool(robot.call("apply_energy_surge", 0.25))
		_assert(applied, "La recarga de energia deberia activarse cuando el robot sigue operativo.")
		await process_frame
		_assert(
			bool(robot.call("is_energy_surge_active")),
			"El robot deberia entrar en estado de energia reforzada tras tocar el pickup."
		)
		_assert(
			robot._overdrive_recovery_remaining == 0.0,
			"El pickup de energia deberia cortar la recuperacion posterior al overdrive."
		)
		_assert(
			robot.get_effective_leg_drive_multiplier() > focused_leg_drive,
			"La recarga de energia deberia reforzar el par de energia actualmente seleccionado."
		)

		await create_timer(0.4).timeout
		await process_frame
		_assert(
			not bool(robot.call("is_energy_surge_active")),
			"La recarga de energia no deberia quedar permanente tras expirar su ventana."
		)
		_assert(
			is_equal_approx(robot.get_effective_leg_drive_multiplier(), focused_leg_drive),
			"Al terminar la recarga, el robot deberia volver al foco energetico base y no a una sobrecarga permanente."
		)

	await _cleanup_node(robot)


func _validate_pickup_cooldown_telegraph() -> void:
	var pickup_scene := _load_edge_energy_pickup_scene()
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
		bool(robot.call("is_energy_surge_active")),
		"Tocar el pickup de energia deberia activar la recarga temporal en el robot que lo recoge."
	)

	var base_mesh := pickup.get_node_or_null("Visuals/Base")
	var core_mesh := pickup.get_node_or_null("Visuals/Core")
	_assert(base_mesh is MeshInstance3D, "El pickup de energia deberia conservar un pedestal visible.")
	_assert(core_mesh is MeshInstance3D, "El pickup de energia deberia conservar un nucleo visible para su estado activo.")
	if base_mesh is MeshInstance3D:
		_assert(
			(base_mesh as MeshInstance3D).is_visible_in_tree(),
			"El pedestal del pickup de energia deberia seguir visible durante cooldown para telegraph del borde."
		)
	if core_mesh is MeshInstance3D:
		_assert(
			not (core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup de energia deberia apagarse durante cooldown para indicar que ya fue consumido."
		)

	pickup.call("_on_respawn_timer_timeout")
	await process_frame

	if core_mesh is MeshInstance3D:
		_assert(
			(core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup de energia deberia volver a verse cuando reaparece la carga."
		)

	await _cleanup_node(robot)
	await _cleanup_node(pickup)


func _validate_main_scene_energy_pickups() -> void:
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

	var edge_pickups := get_nodes_in_group("edge_energy_pickups")
	_assert(edge_pickups.size() >= 2, "La arena principal deberia ofrecer al menos dos pickups de energia.")

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

	_assert(pickup_near_edge, "Los pickups de energia deberian vivir cerca del riesgo de borde, no en el centro limpio.")

	var scene_robots := _get_scene_robots(main)
	if edge_pickups.size() > 0 and scene_robots.size() > 0:
		var robot := scene_robots[0]
		var pickup := edge_pickups[0] as Node3D
		robot.global_position = pickup.global_position
		(pickup as Node).call("_on_body_entered", robot)
		await process_frame
		var roster_lines := (match_controller as MatchController).get_robot_status_lines()
		_assert(
			roster_lines.any(func(line: String) -> bool: return line.contains(robot.display_name) and line.contains("energia")),
			"El roster compacto deberia dejar visible cuando un robot tiene la recarga de energia activa."
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
	var pickups := _get_edge_energy_pickups(arena)
	_assert(pickups.size() >= 2, "La escena de arena deberia mantener pickups de energia durante la contraccion.")
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
			"Antes de la contraccion, los pickups de energia deberian seguir cargados hacia el borde."
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
			"Los pickups de energia deberian seguir dentro del area viva cuando el arena se contrae."
		)
		_assert(
			shrunk_ratio >= 0.45,
			"Los pickups de energia deberian seguir cerca del nuevo borde util, no migrar al centro."
		)
		_assert(
			shrunk_ratio <= initial_edge_ratios[index] + 0.05,
			"Los pickups de energia no deberian desplazarse hacia fuera del borde vivo tras la contraccion."
		)

	await _cleanup_node(arena)


func _load_edge_energy_pickup_scene() -> PackedScene:
	var loaded_scene := load("res://scenes/pickups/edge_energy_pickup.tscn")
	_assert(loaded_scene is PackedScene, "Deberia existir una escena dedicada para el pickup de energia de borde.")
	if loaded_scene is PackedScene:
		return loaded_scene as PackedScene

	return null


func _get_edge_energy_pickups(root_node: Node) -> Array[Node3D]:
	var pickups: Array[Node3D] = []
	for child in root_node.find_children("*", "Node3D", true, false):
		if child.is_in_group("edge_energy_pickups"):
			pickups.append(child as Node3D)

	return pickups


func _get_scene_robots(root_node: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	for child in root_node.find_children("*", "RobotBase", true, false):
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
