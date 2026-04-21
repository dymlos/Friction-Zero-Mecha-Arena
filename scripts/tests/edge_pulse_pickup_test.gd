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
	await _validate_robot_carried_item_behavior()
	await _validate_pickup_cooldown_telegraph()
	await _validate_main_scene_pulse_pickups()
	await _validate_pickups_follow_arena_contraction()
	_finish()


func _validate_robot_carried_item_behavior() -> void:
	var source := ROBOT_SCENE.instantiate() as RobotBase
	var target := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(source)
	root.add_child(target)

	await process_frame
	await physics_frame

	source.global_position = Vector3.ZERO
	target.global_position = Vector3(0.0, 0.8, -2.2)

	var has_store_method := source.has_method("store_carried_item")
	var has_has_method := source.has_method("has_carried_item")
	var has_name_method := source.has_method("get_carried_item_name")
	var has_use_method := source.has_method("use_carried_item")
	_assert(has_store_method, "El robot deberia poder guardar un item universal de una sola carga.")
	_assert(has_has_method, "El robot deberia poder informar si tiene un item cargado.")
	_assert(has_name_method, "El robot deberia poder exponer el id del item cargado para HUD/roster.")
	_assert(has_use_method, "El robot deberia poder consumir el item cargado desde una accion jugable.")
	if not (has_store_method and has_has_method and has_name_method and has_use_method):
		await _cleanup_node(source)
		await _cleanup_node(target)
		return

	var stored := bool(source.call("store_carried_item", "pulse_charge"))
	_assert(stored, "El primer item cargado deberia entrar en el robot si el slot esta vacio.")
	_assert(bool(source.call("has_carried_item")), "Tras cargarlo, el robot deberia quedar marcado como portador de item.")
	_assert(
		String(source.call("get_carried_item_name")) == "pulse_charge",
		"El item cargado deberia conservar su id para lectura del HUD y del disparo."
	)
	var indicator := source.get_node_or_null("CarryIndicator")
	_assert(indicator is MeshInstance3D, "El robot deberia reutilizar un indicador diegético en runtime para marcar item o parte.")
	if indicator is MeshInstance3D:
		_assert(
			(indicator as MeshInstance3D).visible,
			"El indicador diegético deberia verse tambien cuando el robot guarda un item de una carga."
		)

	var duplicate_store := bool(source.call("store_carried_item", "pulse_charge"))
	_assert(not duplicate_store, "El robot no deberia aceptar dos items simultaneos en la misma carga.")

	var baseline_target_health := target.get_part_health("right_arm")
	var baseline_target_impulse := target.external_impulse.length()
	var used := bool(source.call("use_carried_item"))
	_assert(used, "El item cargado deberia poder consumirse para disparar un pulso repulsor.")

	await create_timer(0.35).timeout
	await process_frame
	await physics_frame

	_assert(
		not bool(source.call("has_carried_item")),
		"Tras disparar el pulso, el robot no deberia seguir marcado como portador del item."
	)
	if indicator is MeshInstance3D:
		_assert(
			not (indicator as MeshInstance3D).visible,
			"El indicador diegético deberia ocultarse al gastar la carga."
		)
	_assert(
		target.get_part_health("right_arm") < baseline_target_health,
		"El pulso repulsor deberia castigar al menos una parte frontal del rival alcanzado."
	)
	_assert(
		target.external_impulse.length() > baseline_target_impulse,
		"El pulso repulsor deberia empujar al rival y no quedarse en daño cosmetico."
	)

	await _cleanup_node(target)
	await _cleanup_node(source)


func _validate_pickup_cooldown_telegraph() -> void:
	var pickup_scene := _load_edge_pulse_pickup_scene()
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
		robot.has_method("has_carried_item") and bool(robot.call("has_carried_item")),
		"Tocar el pickup de pulso deberia cargar el item en el robot que lo recoge."
	)

	var base_mesh := pickup.get_node_or_null("Visuals/Base")
	var core_mesh := pickup.get_node_or_null("Visuals/Core")
	_assert(base_mesh is MeshInstance3D, "El pickup de pulso deberia conservar un pedestal visible.")
	_assert(core_mesh is MeshInstance3D, "El pickup de pulso deberia conservar un nucleo visible para su carga activa.")
	if base_mesh is MeshInstance3D:
		_assert(
			(base_mesh as MeshInstance3D).is_visible_in_tree(),
			"El pedestal del pickup de pulso deberia seguir visible durante cooldown para telegraph del borde."
		)
	if core_mesh is MeshInstance3D:
		_assert(
			not (core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup de pulso deberia apagarse durante cooldown para indicar que la carga ya fue tomada."
		)

	pickup.call("_on_respawn_timer_timeout")
	await process_frame

	if core_mesh is MeshInstance3D:
		_assert(
			(core_mesh as MeshInstance3D).is_visible_in_tree(),
			"El nucleo del pickup de pulso deberia volver a verse cuando la carga reaparece."
		)

	await _cleanup_node(robot)
	await _cleanup_node(pickup)


func _validate_main_scene_pulse_pickups() -> void:
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

	var edge_pickups := get_nodes_in_group("edge_pulse_pickups")
	_assert(edge_pickups.size() >= 2, "La arena principal deberia ofrecer al menos dos pickups de item utilitario en bordes.")

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

	_assert(pickup_near_edge, "Los pickups de pulso deberian vivir cerca del riesgo de borde, no en el centro limpio.")

	var scene_robots := _get_scene_robots(main)
	var active_pickup := _find_enabled_pickup(main, "edge_pulse_pickups")
	if active_pickup == null:
		for round_number in range(1, 5):
			arena_base.activate_edge_pickup_layout_for_round(round_number)
			await process_frame
			active_pickup = _find_enabled_pickup(main, "edge_pulse_pickups")
			if active_pickup != null:
				break

	_assert(active_pickup != null, "La escena principal deberia habilitar pulso en al menos un layout del borde.")

	if active_pickup != null and scene_robots.size() > 0:
		var robot := scene_robots[0]
		robot.global_position = active_pickup.global_position
		active_pickup.call("_on_body_entered", robot)
		await process_frame
		var roster_lines := (match_controller as MatchController).get_robot_status_lines()
		_assert(
			roster_lines.any(func(line: String) -> bool: return line.contains(robot.display_name) and line.contains("item pulso")),
			"El roster compacto deberia dejar visible cuando un robot guarda la carga de pulso."
		)
		var status_message := String(main.ui.status_label.text)
		_assert(
			status_message.contains("pulso"),
			"El HUD deberia publicar una linea breve cuando alguien asegura un item de una sola carga en el borde."
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
	var pickups := _get_edge_pulse_pickups(arena)
	_assert(pickups.size() >= 2, "La escena de arena deberia mantener pickups de pulso durante la contraccion.")
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
			"Antes de la contraccion, los pickups de pulso deberian seguir cargados hacia el borde."
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
			"Los pickups de pulso deberian seguir dentro del area viva cuando el arena se contrae."
		)
		_assert(
			shrunk_ratio >= 0.45,
			"Los pickups de pulso deberian seguir cerca del nuevo borde util, no migrar al centro."
		)
		_assert(
			shrunk_ratio <= initial_edge_ratios[index] + 0.05,
			"Los pickups de pulso no deberian desplazarse hacia fuera del borde vivo tras la contraccion."
		)

	await _cleanup_node(arena)


func _load_edge_pulse_pickup_scene() -> PackedScene:
	var loaded_scene := load("res://scenes/pickups/edge_pulse_pickup.tscn")
	_assert(loaded_scene is PackedScene, "Deberia existir una escena dedicada para el pickup de pulso de borde.")
	if loaded_scene is PackedScene:
		return loaded_scene as PackedScene

	return null


func _get_edge_pulse_pickups(root_node: Node) -> Array[Node3D]:
	var pickups: Array[Node3D] = []
	for child in root_node.get_children():
		if child.is_in_group("edge_pulse_pickups"):
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
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
