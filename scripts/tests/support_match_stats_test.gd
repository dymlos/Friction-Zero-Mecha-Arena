extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia exponer MatchController para medir stats de soporte.")
	_assert(support_root != null, "La escena principal deberia seguir reservando un SupportRoot para el soporte post-muerte.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para cerrar una partida Teams.")
	if match_controller == null or support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.rounds_to_win = 1
	match_controller.round_reset_delay = 0.15
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado en Teams deberia aparecer una unica nave de apoyo."
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		_finish()
		return

	var support_ship := support_root.get_child(0) as Node3D
	_assert(support_ship != null, "La nave de apoyo deberia existir para poder alimentar stats de soporte.")
	if support_ship == null:
		await _cleanup_main(main)
		_finish()
		return

	var support_pickups := get_nodes_in_group("pilot_support_pickups")
	var stabilizer_pickup: Node3D = null
	for pickup in support_pickups:
		if not (pickup is Node3D):
			continue
		if str((pickup as Node3D).get("payload_name")) == "stabilizer":
			stabilizer_pickup = pickup as Node3D
			break

	_assert(
		stabilizer_pickup != null,
		"El carril de soporte deberia ofrecer al menos una carga estabilizadora para validar stats de uso."
	)
	if stabilizer_pickup == null:
		await _cleanup_main(main)
		_finish()
		return

	robots[0].apply_damage_to_part("left_arm", robots[0].max_part_health * 0.35, Vector3.LEFT)
	support_ship.global_position = stabilizer_pickup.global_position
	await _wait_frames(3)

	Input.action_press("p2_throw_part")
	await _wait_frames(2)
	Input.action_release("p2_throw_part")
	await _wait_frames(2)

	var surge_pickup: Node3D = null
	for pickup in support_pickups:
		if not (pickup is Node3D):
			continue
		if str((pickup as Node3D).get("payload_name")) == "surge":
			surge_pickup = pickup as Node3D
			break

	_assert(
		surge_pickup != null,
		"El carril de soporte deberia ofrecer una segunda carga para desglosar stats por payload."
	)
	if surge_pickup == null:
		await _cleanup_main(main)
		_finish()
		return

	support_ship.global_position = surge_pickup.global_position
	await _wait_frames(3)

	Input.action_press("p2_throw_part")
	await _wait_frames(2)
	Input.action_release("p2_throw_part")
	await _wait_frames(2)

	robots[2].fall_into_void()
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	_assert(match_controller.is_match_over(), "La ronda objetivo deberia cerrar la partida tras eliminar al equipo rival.")
	_assert(
		_has_line_containing(
			match_controller.get_match_result_lines(),
			"Stats | Equipo 1 | apoyo 2 (2 usos: estabilizador 1, energia 1) | bajas 1 (1 vacio)"
		),
		"El cierre de partida deberia distinguir pickups y payloads usados por el soporte del equipo ganador."
	)
	_assert(
		_has_line_containing(
			match_controller.get_round_recap_panel_lines(),
			"Stats | Equipo 1 | apoyo 2 (2 usos: estabilizador 1, energia 1) | bajas 1 (1 vacio)"
		),
		"El recap lateral deberia reutilizar el mismo desglose compacto de payloads de soporte."
	)

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _has_line_containing(lines: Array[String], expected_fragment: String) -> bool:
	for line in lines:
		if line.contains(expected_fragment):
			return true

	return false


func _wait_frames(count: int) -> void:
	for _step in range(count):
		await process_frame


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
