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
	var match_result_panel := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel") as Control
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia instanciar MatchController.")
	_assert(match_result_panel != null, "El HUD deberia exponer un panel dedicado al resultado final.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para el laboratorio 2v2.")
	if match_controller == null or match_result_panel == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	_assert(match_controller.match_config != null, "El controller deberia cargar una MatchConfig base.")
	if match_controller.match_config == null:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_config.rounds_to_win = 1
	match_controller.match_restart_delay = 0.25
	for robot in robots:
		robot.void_fall_y = -100.0

	_eliminate_team_two(robots)
	await _wait_frames(4)

	_assert(match_controller.is_match_over(), "La partida deberia cerrarse al alcanzar el objetivo de una ronda.")
	_assert(match_result_panel.visible, "El panel final deberia quedar visible mientras el match esta cerrado.")

	var restart_event := InputEventKey.new()
	restart_event.pressed = true
	restart_event.keycode = KEY_F5
	main._unhandled_input(restart_event)

	await process_frame
	await process_frame

	_assert(not match_controller.is_match_over(), "F5 deberia reiniciar el match sin esperar al timer automatico.")
	_assert(match_controller.is_round_active(), "Tras reiniciar manualmente deberia arrancar una ronda nueva.")
	_assert(
		match_controller.get_round_status_line().contains("Ronda 1"),
		"El reinicio manual deberia volver a un match limpio desde la ronda 1."
	)
	_assert(match_controller.get_team_score(1) == 0, "El reinicio manual deberia limpiar el score del ganador previo.")
	_assert(match_controller.get_team_score(2) == 0, "El reinicio manual deberia limpiar el score del rival.")
	_assert(not match_result_panel.visible, "Tras reiniciar manualmente el panel final deberia ocultarse.")

	await _wait_frames(4)
	await _cleanup_main(main)
	_finish()


func _eliminate_team_two(robots: Array[RobotBase]) -> void:
	robots[2].fall_into_void()
	robots[3].fall_into_void()


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


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


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
