extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const RESULT_LINE_BUDGET := 22
const FORBIDDEN_RESULT_FRAGMENTS := [
	"How to Play",
	"Controles",
	"Easy",
	"Hard",
	"Tutorial",
	"Practica",
	"energia Q/E",
	"ataque",
	"tabla",
	"wiki",
]

const CASES := [
	{
		"label": "Teams 4P base",
		"path": "res://scenes/main/main.tscn",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"label": "FFA 4P base",
		"path": "res://scenes/main/main_ffa.tscn",
		"mode": MatchController.MatchMode.FFA,
	},
]
const LARGE_CASES := [
	{
		"label": "Teams 8P large",
		"path": "res://scenes/main/main_teams_large.tscn",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"label": "FFA 8P large",
		"path": "res://scenes/main/main_ffa_large.tscn",
		"mode": MatchController.MatchMode.FFA,
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for test_case in CASES:
		await _assert_post_match_product_boundary(test_case)
	for test_case in LARGE_CASES:
		await _assert_large_result_does_not_expand_into_table(test_case)
	_finish()


func _assert_post_match_product_boundary(test_case: Dictionary) -> void:
	var label := String(test_case.get("label", "Escena"))
	var scene_path := String(test_case.get("path", ""))
	var test_mode := int(test_case.get("mode", MatchController.MatchMode.TEAMS))
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % label)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots." % label)
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = test_mode
	_assert(match_controller.match_config != null, "%s deberia cargar MatchConfig." % label)
	if match_controller.match_config == null:
		await _cleanup_main(main)
		return

	match_controller.match_config.rounds_to_win = 1
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.round_intro_duration = 0.0
	match_controller.round_reset_delay = 0.1
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame

	await _close_match(test_mode, robots)
	await create_timer(0.08).timeout

	var result_lines := match_controller.get_match_result_lines()
	_assert(match_controller.is_match_over(), "%s deberia cerrar la partida." % label)
	_assert(
		result_lines.size() <= RESULT_LINE_BUDGET,
		"%s no deberia superar %s lineas; obtuvo %s:\n%s" % [
			label,
			RESULT_LINE_BUDGET,
			result_lines.size(),
			"\n".join(PackedStringArray(result_lines)),
		]
	)
	_assert(_has_line_containing(result_lines, "gana la partida"), "%s debe conservar decision principal." % label)
	_assert(_has_line_containing(result_lines, "Lectura |"), "%s debe conservar lectura compacta." % label)
	_assert(_has_line_containing(result_lines, "Replay |"), "%s debe conservar replay event-driven." % label)
	_assert(_has_line_containing(result_lines, "Stats |"), "%s debe conservar stats simples." % label)
	for required_prefix in ["Lectura |", "Replay |", "Stats |"]:
		_assert(
			_has_line_containing(result_lines, required_prefix),
			"%s no debe recortar `%s` al aplicar presupuesto." % [label, required_prefix]
		)
	if test_mode == MatchController.MatchMode.FFA:
		_assert(_has_line_containing(result_lines, "Posiciones |"), "%s debe conservar posiciones FFA." % label)
	else:
		_assert(_has_line_containing(result_lines, "Marcador |"), "%s debe conservar marcador Teams." % label)

	var joined_result := "\n".join(PackedStringArray(result_lines))
	for forbidden in FORBIDDEN_RESULT_FRAGMENTS:
		_assert(
			not joined_result.contains(forbidden),
			"%s no debe convertir post-partida en onboarding: encontro `%s`." % [label, forbidden]
		)

	var stats_count := _count_lines_containing(result_lines, "Stats |")
	_assert(stats_count >= 1, "%s debe conservar al menos una linea de stats." % label)
	_assert(stats_count <= robots.size(), "%s no debe generar mas stats que competidores visibles." % label)

	await _cleanup_main(main)


func _close_match(test_mode: int, robots: Array[RobotBase]) -> void:
	for index in range(robots.size()):
		robots[index].void_fall_y = -100.0
		robots[index].global_position = Vector3(5.0 + float(index), 0.0, 0.0)

	if test_mode == MatchController.MatchMode.FFA:
		robots[0].fall_into_void()
		await create_timer(0.03).timeout
		robots[1].fall_into_void()
		await create_timer(0.03).timeout
		robots[2].fall_into_void()
		return

	robots[2].fall_into_void()
	await create_timer(0.03).timeout
	robots[3].fall_into_void()


func _assert_large_result_does_not_expand_into_table(test_case: Dictionary) -> void:
	var label := String(test_case.get("label", "Escena grande"))
	var scene_path := String(test_case.get("path", ""))
	var test_mode := int(test_case.get("mode", MatchController.MatchMode.TEAMS))
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % label)
	if match_controller == null:
		await _cleanup_main(main)
		return
	if robots.size() < 8:
		await _cleanup_main(main)
		return

	match_controller.match_mode = test_mode
	_assert(match_controller.match_config != null, "%s deberia cargar MatchConfig." % label)
	if match_controller.match_config == null:
		await _cleanup_main(main)
		return

	match_controller.match_config.rounds_to_win = 1
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.round_intro_duration = 0.0
	match_controller.round_reset_delay = 0.1
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame
	await _close_large_match(test_mode, robots)
	await create_timer(0.12).timeout

	var lines := match_controller.get_match_result_lines()
	_assert(match_controller.is_match_over(), "%s deberia cerrar la partida." % label)
	_assert(_count_lines_containing(lines, "Replay |") <= 3, "%s debe mantener maximo tres snippets." % label)
	_assert(_count_lines_containing(lines, "Stats |") <= robots.size(), "%s no debe generar tablas extra fuera de stats por competidor." % label)
	_assert(not "\n".join(PackedStringArray(lines)).contains("Tabla |"), "%s no debe introducir tabla extensa." % label)

	await _cleanup_main(main)


func _close_large_match(test_mode: int, robots: Array[RobotBase]) -> void:
	for index in range(robots.size()):
		robots[index].void_fall_y = -100.0
		robots[index].global_position = Vector3(8.0 + float(index), 0.0, 0.0)

	if test_mode == MatchController.MatchMode.FFA:
		for index in range(robots.size() - 1):
			robots[index].fall_into_void()
			await create_timer(0.02).timeout
		return

	for robot in robots:
		if robot.team_id == 2:
			robot.fall_into_void()
			await create_timer(0.02).timeout


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
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _has_line_containing(lines: Array, expected_fragment: String) -> bool:
	for line in lines:
		if str(line).contains(expected_fragment):
			return true
	return false


func _count_lines_containing(lines: Array, expected_fragment: String) -> int:
	var count := 0
	for line in lines:
		if str(line).contains(expected_fragment):
			count += 1
	return count


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
