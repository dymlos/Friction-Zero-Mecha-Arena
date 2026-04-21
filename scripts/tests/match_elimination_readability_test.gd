extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia exponer MatchController.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar lectura de eliminacion.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.round_reset_delay = 0.45

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[2].disabled_explosion_delay = 0.35
	robots[2].disabled_explosion_timer.wait_time = 0.35
	for part_name in robots[2].BODY_PARTS:
		robots[2].apply_damage_to_part(part_name, robots[2].max_part_health + 10.0, Vector3.LEFT)

	await create_timer(0.05).timeout

	var disabled_line := _find_robot_status_line(match_controller, robots[2])
	_assert(
		disabled_line.contains("Inutilizado"),
		"El roster deberia seguir marcando al robot sin partes como inutilizado antes de la explosion."
	)
	_assert(
		disabled_line.contains("explota"),
		"El roster deberia avisar que el cuerpo inutilizado va a explotar pronto."
	)

	await create_timer(0.4).timeout

	var exploded_line := _find_robot_status_line(match_controller, robots[2])
	_assert(
		exploded_line.contains("Fuera"),
		"Tras explotar, el roster deberia marcar al robot como fuera de la ronda."
	)
	_assert(
		exploded_line.contains("explosion"),
		"El roster deberia conservar la causa breve de eliminacion por explosion."
	)
	_assert(
		_has_line_with_fragment(match_controller.get_round_state_lines(), "Ultima baja | Player 3 explosiono"),
		"El estado de ronda deberia dejar visible la ultima baja por explosion."
	)

	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	var void_line := _find_robot_status_line(match_controller, robots[3])
	_assert(
		void_line.contains("Fuera"),
		"El robot que cae al vacio deberia figurar como fuera en el roster."
	)
	_assert(
		void_line.contains("vacio"),
		"El roster deberia conservar la causa breve de eliminacion por vacio."
	)
	_assert(
		_has_line_with_fragment(match_controller.get_round_state_lines(), "Ultima baja | Player 4 cayo al vacio"),
		"El estado de ronda deberia exponer tambien la ultima baja por vacio."
	)

	await create_timer(maxf(match_controller.round_reset_delay + 0.2, 0.95)).timeout
	await _cleanup_main(main)
	_finish()


func _find_robot_status_line(match_controller: MatchController, robot: RobotBase) -> String:
	var lookup := "P%s %s" % [robot.player_index, robot.display_name]
	for line in match_controller.get_robot_status_lines():
		if line.begins_with(lookup):
			return line

	return ""


func _has_line_with_fragment(lines: Array[String], fragment: String) -> bool:
	for line in lines:
		if line.contains(fragment):
			return true

	return false


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
