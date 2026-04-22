extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const TEAMS_SCENES := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in TEAMS_SCENES:
		await _assert_detail_order_contract(scene_path)
	_finish()


func _assert_detail_order_contract(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var scene_label := "La escena %s" % scene_path
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapLabel") as Label
	var match_result_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % scene_label)
	_assert(recap_label != null, "%s deberia exponer el detalle de cierre en el recap lateral." % scene_label)
	_assert(match_result_label != null, "%s deberia exponer el detalle de cierre en el panel final." % scene_label)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para validar el orden Teams." % scene_label)
	if match_controller == null or recap_label == null or match_result_label == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	_assert(match_controller.match_config != null, "%s deberia cargar una MatchConfig base." % scene_label)
	if match_controller.match_config == null:
		await _cleanup_main(main)
		return

	match_controller.match_config.rounds_to_win = 1
	match_controller.round_reset_delay = 0.15
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[0].fall_into_void()
	await create_timer(0.05).timeout
	robots[1].fall_into_void()
	await create_timer(0.05).timeout

	_assert(match_controller.is_match_over(), "%s deberia cerrar tambien la partida cuando el objetivo es 1." % scene_label)

	var recap_lines := match_controller.get_round_recap_panel_lines()
	var match_result_lines := match_controller.get_match_result_lines()
	var winner_detail_a := "%s / Cizalla | sigue en pie | 4/4 partes" % robots[2].display_name
	var winner_detail_b := "%s / Patin | sigue en pie | 4/4 partes" % robots[3].display_name
	var loser_detail_a := "%s / Ariete | baja 1 | vacio | 4/4 partes" % robots[0].display_name
	var loser_detail_b := "%s / Grua | baja 2 | vacio | 4/4 partes" % robots[1].display_name
	var winner_stats := "Stats | Equipo 2 | bajas sufridas 0"
	var loser_stats := "Stats | Equipo 1 | bajas sufridas 2 (2 vacio)"

	_assert(
		_line_index(recap_lines, winner_stats) < _line_index(recap_lines, loser_stats),
		"%s deberia ordenar tambien las stats del recap siguiendo el resultado real del match." % scene_label
	)
	_assert(
		_line_index(match_result_lines, winner_stats) < _line_index(match_result_lines, loser_stats),
		"%s deberia ordenar tambien las stats del resultado final siguiendo el resultado real del match." % scene_label
	)

	_assert(
		_line_index(recap_lines, winner_detail_a) < _line_index(recap_lines, loser_detail_a),
		"%s deberia listar primero al equipo ganador en el recap." % scene_label
	)
	_assert(
		_line_index(recap_lines, winner_detail_b) < _line_index(recap_lines, loser_detail_a),
		"%s deberia mantener todos los robots ganadores antes del detalle del derrotado en el recap." % scene_label
	)
	_assert(
		_line_index(recap_lines, loser_detail_a) < _line_index(recap_lines, loser_detail_b),
		"%s deberia conservar el orden real de bajas dentro del equipo derrotado en el recap." % scene_label
	)
	_assert(
		_line_index(match_result_lines, winner_detail_a) < _line_index(match_result_lines, loser_detail_a),
		"%s deberia listar primero al equipo ganador en el resultado final." % scene_label
	)
	_assert(
		_line_index(match_result_lines, winner_detail_b) < _line_index(match_result_lines, loser_detail_a),
		"%s deberia mantener todos los robots ganadores antes del detalle del derrotado en el resultado final." % scene_label
	)
	_assert(
		_line_index(match_result_lines, loser_detail_a) < _line_index(match_result_lines, loser_detail_b),
		"%s deberia conservar el orden real de bajas dentro del equipo derrotado en el resultado final." % scene_label
	)
	_assert(
		recap_label.text.find(winner_detail_a) < recap_label.text.find(loser_detail_a),
		"%s deberia dejar primero al equipo ganador en el recap visible." % scene_label
	)
	_assert(
		match_result_label.text.find(winner_detail_a) < match_result_label.text.find(loser_detail_a),
		"%s deberia dejar primero al equipo ganador en el panel final visible." % scene_label
	)

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


func _line_index(lines: Array[String], expected: String) -> int:
	for index in range(lines.size()):
		if lines[index] == expected:
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
