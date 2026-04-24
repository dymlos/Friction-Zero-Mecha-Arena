extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const CASES := [
	{
		"label": "Teams ring-out base",
		"path": "res://scenes/main/main.tscn",
		"mode": MatchController.MatchMode.TEAMS,
		"cause": "void",
		"reading": "ring-out",
		"snippet": "ring-out",
	},
	{
		"label": "Teams destruccion validation",
		"path": "res://scenes/main/main_teams_validation.tscn",
		"mode": MatchController.MatchMode.TEAMS,
		"cause": "explosion",
		"reading": "desgaste modular",
		"snippet": "destruccion total",
	},
	{
		"label": "Teams inestable base",
		"path": "res://scenes/main/main.tscn",
		"mode": MatchController.MatchMode.TEAMS,
		"cause": "unstable",
		"reading": "sobrecarga",
		"snippet": "explosion inestable",
	},
	{
		"label": "FFA ring-out validation",
		"path": "res://scenes/main/main_ffa_validation.tscn",
		"mode": MatchController.MatchMode.FFA,
		"cause": "void",
		"reading": "supervivencia",
		"snippet": "ring-out",
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for test_case in CASES:
		await _assert_cause_reading(test_case)
	_finish()


func _assert_cause_reading(test_case: Dictionary) -> void:
	var label := String(test_case.get("label", "Caso"))
	var scene_path := String(test_case.get("path", ""))
	var test_mode := int(test_case.get("mode", MatchController.MatchMode.TEAMS))
	var cause := String(test_case.get("cause", "void"))
	var expected_reading := String(test_case.get("reading", ""))
	var expected_snippet := String(test_case.get("snippet", ""))
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % label)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para cerrar match." % label)
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = test_mode
	match_controller.match_config.rounds_to_win = 1
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.round_intro_duration = 0.0
	match_controller.round_reset_delay = 0.1
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0
		robot.disabled_explosion_delay = 0.05
		robot.disabled_explosion_timer.wait_time = 0.05

	if test_mode == MatchController.MatchMode.FFA:
		await _close_ffa(robots, cause)
	else:
		await _close_teams(robots, cause)

	await create_timer(0.16).timeout

	var story_lines := match_controller.get_post_match_review_lines()
	var snippet_lines := match_controller.get_post_match_snippet_lines()
	_assert(match_controller.is_match_over(), "%s deberia cerrar match." % label)
	_assert(_has_line_containing(story_lines, "Lectura |"), "%s deberia producir lectura." % label)
	_assert(_has_line_containing(story_lines, expected_reading), "%s lectura deberia mencionar `%s`." % [label, expected_reading])
	_assert(_has_line_containing(snippet_lines, "Replay |"), "%s deberia producir replay snippet." % label)
	_assert(_has_line_containing(snippet_lines, expected_snippet), "%s snippet deberia mencionar `%s`." % [label, expected_snippet])

	await _cleanup_main(main)


func _close_teams(robots: Array[RobotBase], cause: String) -> void:
	if cause == "void":
		robots[2].fall_into_void()
		robots[3].fall_into_void()
		return

	for robot in [robots[2], robots[3]]:
		if cause == "unstable":
			robot.set_energy_focus("left_arm")
			robot.activate_overdrive()
		for part_name in robot.BODY_PARTS:
			robot.apply_damage_to_part(part_name, robot.max_part_health + 10.0, Vector3.LEFT)
		await create_timer(0.08).timeout


func _close_ffa(robots: Array[RobotBase], cause: String) -> void:
	if cause == "void":
		robots[0].fall_into_void()
		robots[1].fall_into_void()
		robots[2].fall_into_void()
		return

	for robot in [robots[0], robots[1], robots[2]]:
		if cause == "unstable":
			robot.set_energy_focus("left_arm")
			robot.activate_overdrive()
		for part_name in robot.BODY_PARTS:
			robot.apply_damage_to_part(part_name, robot.max_part_health + 10.0, Vector3.LEFT)
		await create_timer(0.08).timeout


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia seguir existiendo." % scene_path)
	if not (packed_scene is PackedScene):
		return null

	var main := (packed_scene as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	return main


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
