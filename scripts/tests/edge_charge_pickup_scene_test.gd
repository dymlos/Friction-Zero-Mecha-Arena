extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_default_teams_scene_enables_charge_pickups_when_both_teams_have_skills()
	await _validate_ffa_scene_enables_charge_pickups_for_skill_robots()
	_finish()


func _validate_default_teams_scene_enables_charge_pickups_when_both_teams_have_skills() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var arena := main.get_node_or_null("ArenaRoot/ArenaBlockout")
	var match_controller := main.get_node_or_null("Systems/MatchController")
	_assert(arena is ArenaBase, "La escena principal deberia seguir montando un ArenaBase real.")
	if not (arena is ArenaBase):
		await _cleanup_scene_root(main)
		return

	var charge_pickups := _get_charge_pickups(main)
	_assert(charge_pickups.size() >= 2, "La arena principal deberia reservar al menos dos pedestales para municion/carga.")
	if charge_pickups.size() < 2:
		await _cleanup_scene_root(main)
		return

	var robots := _get_scene_robots(main)
	var skill_robot: RobotBase = null
	for robot in robots:
		if robot.has_method("has_core_skill") and bool(robot.call("has_core_skill")):
			skill_robot = robot
			break

	_assert(
		skill_robot != null,
		"El laboratorio 2v2 base deberia conservar al menos un robot con skill propia para probar la municion/carga."
	)
	if skill_robot == null:
		await _cleanup_scene_root(main)
		return

	var initial_charges := int(skill_robot.call("get_core_skill_charge_count"))
	var used := bool(skill_robot.call("use_core_skill"))
	_assert(used, "La escena Teams deberia poder gastar una carga antes de buscar el pickup de municion.")
	if not used:
		await _cleanup_scene_root(main)
		return

	var arena_base := arena as ArenaBase
	var active_pickup: Node3D = null
	for round_number in range(1, 7):
		arena_base.activate_edge_pickup_layout_for_round(round_number)
		await process_frame
		active_pickup = _find_enabled_pickup(main)
		if active_pickup != null:
			break

	_assert(
		active_pickup != null,
		"El laboratorio 2v2 base deberia activar municion/carga cuando ambos equipos ya traen al menos una skill propia."
	)
	if active_pickup == null:
		await _cleanup_scene_root(main)
		return

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel")
	_assert(round_label is Label, "El HUD Teams deberia seguir exponiendo el bloque de estado de ronda.")
	if round_label is Label:
		_assert(
			String((round_label as Label).text).contains("municion"),
			"El resumen `Borde | ...` deberia nombrar la municion/carga cuando forme parte del layout activo en Teams."
		)

	if match_controller != null and bool(match_controller.call("is_round_intro_active")):
		await create_timer(float(match_controller.call("get_round_intro_time_left")) + 0.15).timeout
		await process_frame
	skill_robot.global_position = active_pickup.global_position
	active_pickup.call("_on_body_entered", skill_robot)
	await process_frame

	_assert(
		int(skill_robot.call("get_core_skill_charge_count")) == initial_charges,
		"El pickup de municion/carga de Teams deberia restaurar la carga gastada del robot con skill propia."
	)

	await _disable_edge_pickups(main)
	await _cleanup_scene_root(main)


func _validate_ffa_scene_enables_charge_pickups_for_skill_robots() -> void:
	var main = FFA_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var arena := main.get_node_or_null("ArenaRoot/ArenaBlockout")
	var match_controller := main.get_node_or_null("Systems/MatchController")
	_assert(arena is ArenaBase, "La escena FFA deberia seguir montando un ArenaBase real.")
	if not (arena is ArenaBase):
		await _cleanup_scene_root(main)
		return

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "La escena FFA deberia seguir ofreciendo cuatro robots.")
	if robots.size() < 4:
		await _cleanup_scene_root(main)
		return

	var skill_robot := robots[1]
	_assert(
		skill_robot.has_method("has_core_skill") and bool(skill_robot.call("has_core_skill")),
		"La escena FFA deberia conservar al menos un robot con skill propia para justificar la municion/carga."
	)
	if not (skill_robot.has_method("has_core_skill") and bool(skill_robot.call("has_core_skill"))):
		await _cleanup_scene_root(main)
		return

	var initial_charges := int(skill_robot.call("get_core_skill_charge_count"))
	var used := bool(skill_robot.call("use_core_skill"))
	_assert(used, "La escena FFA deberia poder gastar una carga antes de buscar el pickup de municion.")
	if not used:
		await _cleanup_scene_root(main)
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
		await _cleanup_scene_root(main)
		return

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel")
	_assert(round_label is Label, "El HUD FFA deberia seguir exponiendo el bloque de estado de ronda.")
	if round_label is Label:
		_assert(
			String((round_label as Label).text).contains("municion"),
			"El resumen `Borde | ...` deberia nombrar la municion/carga cuando forme parte del layout activo."
		)

	if match_controller != null and bool(match_controller.call("is_round_intro_active")):
		await create_timer(float(match_controller.call("get_round_intro_time_left")) + 0.15).timeout
		await process_frame
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
	await _cleanup_group("temporary_projectiles")
	await _cleanup_scene_root(main)


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
			await _cleanup_scene_root(node as Node)


func _disable_edge_pickups(root_node: Node) -> void:
	for pickup in root_node.get_tree().get_nodes_in_group("edge_pickups"):
		if not root_node.is_ancestor_of(pickup):
			continue
		if pickup.has_method("set_spawn_enabled"):
			pickup.call("set_spawn_enabled", false)

	await _drain_frames(4)


func _cleanup_scene_root(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await _drain_frames(3)


func _drain_frames(frame_count: int = 2) -> void:
	for _index in range(maxi(frame_count, 1)):
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
	await _drain_frames(4)
	quit(1 if _failed else 0)
