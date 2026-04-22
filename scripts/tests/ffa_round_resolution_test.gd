extends SceneTree

const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = FFA_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena FFA deberia exponer MatchController.")
	_assert(robots.size() >= 4, "La escena FFA deberia ofrecer cuatro robots para resolver una ronda real.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.round_reset_delay = 0.2
	var void_round_points := 1
	if match_controller.match_config != null:
		void_round_points = match_controller.match_config.get_round_victory_points_for_cause(
			int(MatchController.EliminationCause.VOID)
		)
	for robot in robots:
		robot.void_fall_y = -100.0

	var initial_round_lines := match_controller.get_round_state_lines()
	_assert(
		_has_line_with_fragment(initial_round_lines, "Modo | FFA"),
		"El HUD de estado deberia dejar explicito que la ronda actual corre en FFA."
	)

	robots[0].fall_into_void()
	await create_timer(0.05).timeout
	robots[1].fall_into_void()
	await create_timer(0.05).timeout
	robots[2].fall_into_void()
	await create_timer(0.05).timeout

	_assert(not match_controller.is_round_active(), "La ronda FFA deberia cerrarse al quedar un solo robot en pie.")
	_assert(
		match_controller.get_round_status_line().contains("Player 4"),
		"El ganador de la ronda FFA deberia anunciarse por nombre de robot, no por equipo."
	)
	_assert(
		not match_controller.get_round_status_line().contains("Equipo"),
		"El cierre de ronda FFA no deberia usar etiquetas de equipo."
	)

	var resolved_round_lines := match_controller.get_round_state_lines()
	_assert(
		_has_line_with_fragment(resolved_round_lines, "Modo | FFA"),
		"La lectura de modo deberia persistir tambien cuando la ronda ya se resolvio."
	)
	_assert(
		_has_line_with_fragment(resolved_round_lines, "%s %s" % [robots[3].display_name, void_round_points]),
		"El marcador FFA deberia reflejar los puntos configurados para el robot ganador."
	)

	await create_timer(match_controller.round_reset_delay + 0.25).timeout
	_assert(match_controller.is_round_active(), "Tras el reset deberia comenzar otra ronda FFA.")
	await create_timer(0.35).timeout

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _has_line_with_fragment(lines: Array[String], fragment: String) -> bool:
	for line in lines:
		if line.contains(fragment):
			return true

	return false


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
