extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	if match_controller != null and match_controller.match_config != null:
		match_controller.match_config.round_intro_duration_teams = 0.45
	root.add_child(main)

	await process_frame
	await process_frame

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel") as Label
	var arena := main.get_node_or_null("ArenaRoot/ArenaBlockout") as ArenaBase
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController.")
	_assert(round_label != null, "La escena principal deberia seguir mostrando el bloque de estado de ronda.")
	_assert(arena != null, "La escena principal deberia seguir exponiendo un arena activo.")
	_assert(robots.size() >= 1, "La escena principal deberia seguir ofreciendo robots jugables para validar el opening.")
	if match_controller == null or round_label == null or arena == null or robots.is_empty():
		await _cleanup_main(main)
		_finish()
		return

	var pickup := await _activate_round_with_repair_pickup(main, arena)
	var robot := robots[0]
	_assert(pickup != null, "La apertura Teams deberia poder validar un pickup de reparacion activo en el borde.")
	_assert(match_controller.is_round_intro_active(), "La escena principal deberia seguir dentro del intro para bloquear el borde.")
	if pickup == null or not match_controller.is_round_intro_active():
		await _cleanup_main(main)
		_finish()
		return

	robot.apply_damage_to_part("left_leg", 20.0, Vector3.BACK)
	var damaged_health := robot.get_part_health("left_leg")
	_assert(damaged_health < robot.max_part_health, "La prueba necesita una parte dañada antes de tocar el pickup.")
	robot.global_position = (pickup as Node3D).global_position
	pickup.call("_on_body_entered", robot)
	await process_frame

	_assert(
		is_equal_approx(robot.get_part_health("left_leg"), damaged_health),
		"Durante el intro, los pickups de borde no deberian poder recogerse aunque el robot ya este encima."
	)
	_assert(
		round_label.text.contains("Borde |"),
		"El HUD del laboratorio deberia seguir explicando que tipos de pickup esperan en el borde."
	)
	_assert(
		round_label.text.contains("abre en"),
		"Durante el intro, el HUD deberia aclarar que el borde todavia no esta liberado."
	)

	await create_timer(match_controller.get_round_intro_time_left() + 0.15).timeout
	await process_frame

	pickup.call("_on_body_entered", robot)
	await process_frame

	_assert(
		robot.get_part_health("left_leg") > damaged_health,
		"Al terminar el intro, el pickup de borde deberia volver a poder recogerse."
	)

	await _cleanup_main(main)
	_finish()


func _activate_round_with_repair_pickup(root_node: Node, arena: ArenaBase) -> Node:
	for round_number in range(1, 9):
		arena.activate_edge_pickup_layout_for_round(round_number)
		await process_frame
		for pickup in root_node.get_tree().get_nodes_in_group("edge_repair_pickups"):
			if not root_node.is_ancestor_of(pickup):
				continue
			if not pickup.has_method("is_spawn_enabled") or not bool(pickup.call("is_spawn_enabled")):
				continue
			return pickup

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


func _cleanup_main(main: Node) -> void:
	if not is_instance_valid(main):
		return

	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
