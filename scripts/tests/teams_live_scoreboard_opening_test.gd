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
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController.")
	_assert(robots.size() >= 4, "La escena principal Teams deberia seguir ofreciendo cuatro robots jugables.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.round_intro_duration = 0.0
	match_controller.round_reset_delay = 0.2
	for robot in robots:
		robot.void_fall_y = -100.0

	var opening_lines := match_controller.get_round_state_lines()
	_assert(
		not _has_prefix_line(opening_lines, "Marcador | "),
		"El HUD vivo Teams no deberia gastar una linea en un marcador 0-0 totalmente neutro al abrir la ronda."
	)

	robots[2].fall_into_void()
	await create_timer(0.05).timeout
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	_assert(
		_has_prefix_line(match_controller.get_round_state_lines(), "Marcador | "),
		"Despues de decidir una ronda Teams, el marcador deberia volver a mostrarse porque ya aporta contexto real."
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


func _has_prefix_line(lines: Array[String], expected_prefix: String) -> bool:
	for line in lines:
		if line.begins_with(expected_prefix):
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
