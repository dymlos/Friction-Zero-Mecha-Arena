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
	_assert(recap_label != null, "El recap deberia exponer texto legible para validar momentos clave.")
	_assert(match_result_label != null, "El cierre final deberia exponer texto legible para validar momentos clave.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar momentos clave.")
	if match_controller == null or recap_label == null or match_result_label == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.rounds_to_win = 1
	match_controller.round_reset_delay = 0.45
	match_controller.match_restart_delay = 1.1

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[2].fall_into_void()
	await create_timer(0.05).timeout
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	_assert(
		_has_line(
			match_controller.get_round_recap_panel_lines(),
			"Resumen | Player 3 cayo al vacio -> Player 4 cayo al vacio"
		),
		"El recap lateral deberia incluir tambien el resumen compacto de bajas para que el cierre se entienda de un vistazo."
	)
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), "Momento inicial | Player 3 cayo al vacio"),
		"El recap deberia destacar la primera baja como snippet compacto del cierre."
	)
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), "Momento final | Player 4 cayo al vacio"),
		"El recap deberia destacar tambien la baja que cerro la ronda/partida."
	)
	_assert(
		recap_label.text.contains("Resumen | Player 3 cayo al vacio -> Player 4 cayo al vacio"),
		"El recap visible deberia incluir tambien el resumen compacto de bajas."
	)
	_assert(
		recap_label.text.contains("Momento inicial | Player 3 cayo al vacio"),
		"El recap visible deberia incluir el snippet del primer momento clave."
	)
	_assert(
		recap_label.text.contains("Momento final | Player 4 cayo al vacio"),
		"El recap visible deberia incluir el snippet del momento final."
	)
	_assert(
		match_result_label.text.contains("Resumen | Player 3 cayo al vacio -> Player 4 cayo al vacio"),
		"El panel final deberia reutilizar tambien el resumen compacto del cierre."
	)
	_assert(
		match_result_label.text.contains("Momento inicial | Player 3 cayo al vacio"),
		"El panel final deberia reutilizar el primer momento clave del cierre."
	)
	_assert(
		match_result_label.text.contains("Momento final | Player 4 cayo al vacio"),
		"El panel final deberia reutilizar el momento final del cierre."
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
