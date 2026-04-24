extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const SCENE_SPECS := [
	{
		"label": "Teams base",
		"path": "res://scenes/main/main.tscn",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"label": "FFA base",
		"path": "res://scenes/main/main_ffa.tscn",
		"mode": MatchController.MatchMode.FFA,
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_spec in SCENE_SPECS:
		await _assert_post_match_review_lines(scene_spec)
	_finish()


func _assert_post_match_review_lines(scene_spec: Dictionary) -> void:
	var label := String(scene_spec.get("label", "Escena"))
	var scene_path := String(scene_spec.get("path", ""))
	var test_mode := int(scene_spec.get("mode", MatchController.MatchMode.TEAMS))
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % label)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para cerrar el match." % label)
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = test_mode
	match_controller.set_runtime_match_restart_enabled(false)
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

	if test_mode == MatchController.MatchMode.FFA:
		robots[0].fall_into_void()
		await create_timer(0.03).timeout
		robots[1].fall_into_void()
		await create_timer(0.03).timeout
		robots[2].fall_into_void()
	else:
		robots[2].fall_into_void()
		await create_timer(0.03).timeout
		robots[3].fall_into_void()

	await create_timer(0.08).timeout

	var result_lines := match_controller.get_match_result_lines()
	var recap_lines := match_controller.get_round_recap_panel_lines()
	_assert(match_controller.is_match_over(), "%s deberia cerrar el match." % label)
	_assert(_has_line_containing(result_lines, "Replay |"), "%s resultado deberia incluir replay snippets." % label)
	_assert(_has_line_containing(recap_lines, "Replay |"), "%s recap deberia incluir replay snippets." % label)
	_assert(_line_index_containing(result_lines, "Lectura |") < _line_index_containing(result_lines, "Stats |"), "%s lectura deberia aparecer antes de stats." % label)
	_assert(not _has_line_containing(result_lines, "Reinicio | F5"), "%s resultado sin autorestart no deberia mostrar F5." % label)
	if test_mode == MatchController.MatchMode.FFA:
		_assert(
			_has_line_containing(result_lines, "Lectura | FFA") or _has_line_containing(result_lines, "Posiciones |"),
			"%s resultado FFA deberia conservar lectura de supervivencia/posiciones." % label
		)
		_assert(_has_line_containing(result_lines, "Desempate |"), "%s resultado FFA deberia mantener desempate." % label)
	else:
		_assert(_has_line_containing(result_lines, "Lectura | Equipo"), "%s resultado Teams deberia incluir lectura de equipo." % label)

	await _cleanup_main(main)


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
	return _line_index_containing(lines, expected_fragment) < 999


func _line_index_containing(lines: Array[String], expected_fragment: String) -> int:
	for index in range(lines.size()):
		if lines[index].contains(expected_fragment):
			return index
	return 999


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
