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
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapLabel") as Label
	var match_result_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia exponer MatchController.")
	_assert(recap_label != null, "El recap lateral deberia exponer el detalle de cierre.")
	_assert(match_result_label != null, "El panel final deberia exponer el detalle de cierre.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar el orden del detalle Teams.")
	if match_controller == null or recap_label == null or match_result_label == null or robots.size() < 4:
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

	robots[0].fall_into_void()
	await create_timer(0.05).timeout
	robots[1].fall_into_void()
	await create_timer(0.05).timeout

	_assert(match_controller.is_match_over(), "Con objetivo 1 el cierre de la ronda Teams deberia cerrar tambien la partida.")

	var recap_lines := match_controller.get_round_recap_panel_lines()
	var match_result_lines := match_controller.get_match_result_lines()
	var winner_detail_a := "%s | sigue en pie | 4/4 partes" % robots[2].display_name
	var winner_detail_b := "%s | sigue en pie | 4/4 partes" % robots[3].display_name
	var loser_detail_a := "%s | baja 1 | vacio | 4/4 partes" % robots[0].display_name
	var loser_detail_b := "%s | baja 2 | vacio | 4/4 partes" % robots[1].display_name

	_assert(
		_line_index(recap_lines, winner_detail_a) < _line_index(recap_lines, loser_detail_a),
		"El recap Teams deberia listar primero al equipo ganador antes que al derrotado."
	)
	_assert(
		_line_index(recap_lines, winner_detail_b) < _line_index(recap_lines, loser_detail_a),
		"El recap Teams deberia mantener todos los robots del equipo ganador antes del detalle del derrotado."
	)
	_assert(
		_line_index(recap_lines, loser_detail_a) < _line_index(recap_lines, loser_detail_b),
		"El recap Teams deberia mantener el orden real de bajas dentro del equipo derrotado."
	)
	_assert(
		_line_index(match_result_lines, winner_detail_a) < _line_index(match_result_lines, loser_detail_a),
		"El resultado final Teams deberia listar primero al equipo ganador antes que al derrotado."
	)
	_assert(
		_line_index(match_result_lines, winner_detail_b) < _line_index(match_result_lines, loser_detail_a),
		"El resultado final Teams deberia mantener todos los robots del equipo ganador antes del detalle del derrotado."
	)
	_assert(
		_line_index(match_result_lines, loser_detail_a) < _line_index(match_result_lines, loser_detail_b),
		"El resultado final Teams deberia conservar el orden real de bajas dentro del equipo derrotado."
	)
	_assert(
		recap_label.text.find(winner_detail_a) < recap_label.text.find(loser_detail_a),
		"El recap visible Teams deberia dejar primero al equipo ganador."
	)
	_assert(
		match_result_label.text.find(winner_detail_a) < match_result_label.text.find(loser_detail_a),
		"El panel final visible Teams deberia dejar primero al equipo ganador."
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
