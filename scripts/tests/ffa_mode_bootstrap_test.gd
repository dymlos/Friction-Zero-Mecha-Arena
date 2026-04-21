extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	_assert(match_controller != null, "La escena principal deberia exponer MatchController para alternar FFA.")
	if match_controller == null:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.FFA
	root.add_child(main)

	await process_frame
	await process_frame

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar FFA.")
	if robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	_assert(match_controller.match_mode == MatchController.MatchMode.FFA, "La prueba deberia arrancar en modo FFA.")
	_assert(
		not robots[0].is_ally_of(robots[1]),
		"En FFA Player 1 y Player 2 no deberian quedar aliados por los team_id del laboratorio 2v2."
	)
	_assert(
		not robots[2].is_ally_of(robots[3]),
		"En FFA Player 3 y Player 4 tambien deberian competir por separado."
	)

	for robot in robots:
		robot.set_physics_process(false)
		robot.gravity = 0.0
		robot.void_fall_y = -100.0

	var owner := robots[0]
	var rival := robots[1]
	owner.apply_damage_to_part("left_arm", owner.max_part_health + 5.0, Vector3.LEFT)

	await process_frame

	var detached_part := _get_only_detached_part()
	_assert(detached_part != null, "La destruccion modular deberia seguir generando una parte desprendida en FFA.")
	if detached_part == null:
		await _cleanup_main(main)
		_finish()
		return

	await create_timer(detached_part.pickup_delay + 0.05).timeout

	rival.global_position = detached_part.global_position
	var picked_up := detached_part.try_pick_up(rival)
	_assert(picked_up, "En FFA un rival deberia poder recoger la parte para negarla.")

	var delivered_as_fake_ally := detached_part.try_deliver_to_robot(owner, rival)
	_assert(
		not delivered_as_fake_ally,
		"En FFA un rival no deberia devolver la parte como si fuera aliado."
	)

	var round_lines := match_controller.get_round_state_lines()
	var score_line := round_lines[2] if round_lines.size() > 2 else ""
	_assert(score_line.contains("Player 1"), "El marcador FFA deberia listar a cada robot por nombre.")
	_assert(not score_line.contains("Equipo"), "El marcador FFA no deberia agrupar competidores por equipo.")

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _get_only_detached_part() -> DetachedPart:
	var detached_parts := get_nodes_in_group("detached_parts")
	_assert(detached_parts.size() == 1, "Se esperaba exactamente una parte desprendida para la validacion FFA.")
	if detached_parts.size() != 1:
		return null

	return detached_parts[0] as DetachedPart


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
