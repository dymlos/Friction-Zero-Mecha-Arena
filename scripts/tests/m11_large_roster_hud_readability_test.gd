extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const MAIN_FFA_LARGE_SCENE := preload("res://scenes/main/main_ffa_large.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_FFA_LARGE_SCENE.instantiate()
	root.add_child(main)
	current_scene = main

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "FFA grande deberia exponer MatchController.")
	_assert(robots.size() == 8, "FFA grande deberia exponer ocho robots.")
	if match_controller == null or robots.size() != 8:
		await _cleanup_current_scene()
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.FFA
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.round_intro_duration = 0.0
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[7].fall_into_void()
	await create_timer(0.05).timeout

	var roster_lines := match_controller.get_robot_status_lines()
	_assert(roster_lines.size() == 8, "HUD explicito grande deberia mantener una linea por slot.")
	_assert(
		roster_lines.any(func(line: String) -> bool: return line.begins_with("P5 Aguja |")),
		"Roster 8P deberia priorizar formato corto por slot para P5 Aguja."
	)
	_assert(
		roster_lines.any(func(line: String) -> bool: return line.begins_with("P6 Ancla |")),
		"Roster 8P deberia priorizar formato corto por slot para P6 Ancla."
	)
	for line in roster_lines:
		_assert(
			line.length() <= 72,
			"Cada linea del roster 8P deberia mantenerse compacta: %s" % line
		)

	var round_lines := match_controller.get_round_state_lines()
	var standings_line := _find_line_containing(round_lines, "Posiciones |")
	_assert(standings_line.contains("Player 1"), "Standings FFA grandes deberian conservar el lider visible.")
	_assert(standings_line.contains("+"), "Standings FFA grandes deberian compactar el resto como +N.")
	_assert(
		standings_line.split("|", false).size() <= 5,
		"Standings FFA grandes deberian tener maximo cuatro segmentos visibles mas prefijo."
	)

	await _cleanup_current_scene()
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _find_line_containing(lines: Array[String], expected_fragment: String) -> String:
	for line in lines:
		if line.contains(expected_fragment):
			return line
	return ""


func _cleanup_current_scene() -> void:
	if current_scene == null or not is_instance_valid(current_scene):
		return

	var scene := current_scene
	var parent := scene.get_parent()
	if parent != null:
		parent.remove_child(scene)
	scene.free()
	current_scene = null
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
