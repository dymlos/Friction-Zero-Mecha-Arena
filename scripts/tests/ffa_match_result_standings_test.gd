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
	var recap_panel := main.get_node_or_null("UI/MatchHud/Root/RecapPanel") as Control
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapLabel") as Label
	var match_result_panel := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel") as Control
	var match_result_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena FFA deberia exponer MatchController.")
	_assert(recap_panel != null and recap_label != null, "El HUD FFA deberia exponer recap legible.")
	_assert(match_result_panel != null and match_result_label != null, "El HUD FFA deberia exponer resultado final legible.")
	_assert(robots.size() >= 4, "La escena FFA deberia ofrecer cuatro robots para validar posiciones finales.")
	if match_controller == null or recap_panel == null or recap_label == null or match_result_panel == null or match_result_label == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.FFA
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
	robots[2].fall_into_void()
	await create_timer(0.05).timeout

	var expected_standings := "Posiciones | 1. %s (1) | 2. %s (0) | 3. %s (0) | 4. %s (0)" % [
		robots[3].display_name,
		robots[2].display_name,
		robots[1].display_name,
		robots[0].display_name,
	]
	_assert(match_controller.is_match_over(), "Con objetivo 1 la ronda FFA deberia cerrar la partida.")
	_assert(recap_panel.visible, "El cierre FFA deberia mostrar recap lateral.")
	_assert(match_result_panel.visible, "El cierre FFA deberia mostrar panel final.")
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), expected_standings),
		"El recap FFA deberia explicitar el orden final de posiciones."
	)
	_assert(
		_has_line(match_controller.get_match_result_lines(), expected_standings),
		"El resultado final FFA deberia explicitar el orden final de posiciones junto al marcador."
	)
	_assert(
		recap_label.text.contains(expected_standings),
		"El recap visible FFA deberia incluir la linea compacta de posiciones."
	)
	_assert(
		match_result_label.text.contains(expected_standings),
		"El panel final FFA deberia incluir la linea compacta de posiciones."
	)
	_assert(
		match_result_label.text.contains("%s | baja 3 | vacio" % robots[2].display_name),
		"El panel final FFA deberia repetir tambien el detalle compacto por robot para explicar el cierre individual."
	)
	_assert(
		_has_line(
			match_controller.get_round_recap_panel_lines(),
			"Desempate | 0 pts: %s > %s > %s" % [
				robots[2].display_name,
				robots[1].display_name,
				robots[0].display_name,
			]
		),
		"El recap FFA deberia explicar que jugadores ganan el desempate cuando varios cierran con el mismo score."
	)
	_assert(
		_has_line(
			match_controller.get_match_result_lines(),
			"Desempate | 0 pts: %s > %s > %s" % [
				robots[2].display_name,
				robots[1].display_name,
				robots[0].display_name,
			]
		),
		"El resultado final FFA deberia repetir que jugadores ganan el desempate para que las posiciones empatadas no parezcan arbitrarias."
	)
	_assert(
		recap_label.text.contains(
			"Desempate | 0 pts: %s > %s > %s" % [
				robots[2].display_name,
				robots[1].display_name,
				robots[0].display_name,
			]
		),
		"El recap visible FFA deberia dejar legible que jugadores ganan el desempate."
	)
	_assert(
		match_result_label.text.contains(
			"Desempate | 0 pts: %s > %s > %s" % [
				robots[2].display_name,
				robots[1].display_name,
				robots[0].display_name,
			]
		),
		"El panel final FFA deberia dejar legible que jugadores ganan el desempate."
	)
	var winner_detail := "%s | sigue en pie | 4/4 partes" % robots[3].display_name
	var third_place_detail := "%s | baja 3 | vacio | 4/4 partes" % robots[2].display_name
	var fourth_place_detail := "%s | baja 2 | vacio | 4/4 partes" % robots[1].display_name
	var fifth_place_detail := "%s | baja 1 | vacio | 4/4 partes" % robots[0].display_name
	var recap_lines := match_controller.get_round_recap_panel_lines()
	var match_result_lines := match_controller.get_match_result_lines()
	_assert(
		_line_index(recap_lines, winner_detail) < _line_index(recap_lines, third_place_detail),
		"El recap FFA deberia ordenar el detalle por robot siguiendo la posicion final real."
	)
	_assert(
		_line_index(recap_lines, third_place_detail) < _line_index(recap_lines, fourth_place_detail),
		"El recap FFA deberia mantener el detalle de empates en el mismo orden real del cierre."
	)
	_assert(
		_line_index(recap_lines, fourth_place_detail) < _line_index(recap_lines, fifth_place_detail),
		"El recap FFA deberia dejar ultimo al primer eliminado cuando todos empatan en score."
	)
	_assert(
		_line_index(match_result_lines, winner_detail) < _line_index(match_result_lines, third_place_detail),
		"El resultado final FFA deberia ordenar el detalle por robot siguiendo la posicion final real."
	)
	_assert(
		_line_index(match_result_lines, third_place_detail) < _line_index(match_result_lines, fourth_place_detail),
		"El resultado final FFA deberia mantener el orden real del desempate tambien en el detalle por robot."
	)
	_assert(
		_line_index(match_result_lines, fourth_place_detail) < _line_index(match_result_lines, fifth_place_detail),
		"El resultado final FFA deberia dejar ultimo al primer eliminado cuando todos empatan en score."
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


func _has_line(lines: Array[String], expected: String) -> bool:
	for line in lines:
		if line == expected:
			return true

	return false


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
