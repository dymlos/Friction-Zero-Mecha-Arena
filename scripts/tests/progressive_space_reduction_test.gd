extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var arena := main.get_node("ArenaRoot/ArenaBlockout") as ArenaBase
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia exponer MatchController.")
	_assert(arena != null, "La escena principal deberia exponer el arena blockout.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar la presion de arena.")
	if match_controller == null or arena == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.round_reset_delay = 0.15
	match_controller.match_config.round_time_seconds = 1
	match_controller.match_config.progressive_space_reduction = true
	match_controller.space_reduction_start_ratio = 0.25
	match_controller.space_reduction_min_scale = 0.5
	match_controller.start_match()

	for robot in robots:
		robot.void_fall_y = -100.0

	var initial_size := arena.get_safe_play_area_size()
	await create_timer(0.45).timeout
	await process_frame

	var shrunken_size := arena.get_safe_play_area_size()
	_assert(
		shrunken_size.x < initial_size.x and shrunken_size.y < initial_size.y,
		"El area segura deberia reducirse cuando la ronda avanza y la reduccion progresiva esta activa."
	)
	_assert(
		match_controller.get_round_state_lines().any(func(line: String) -> bool: return line.contains("Arena")),
		"El HUD de ronda deberia informar cuando la arena empieza a cerrarse."
	)

	robots[2].fall_into_void()
	await create_timer(0.05).timeout
	robots[3].fall_into_void()
	await create_timer(match_controller.round_reset_delay + 0.15).timeout
	await process_frame

	var reset_size := arena.get_safe_play_area_size()
	_assert(
		reset_size.is_equal_approx(initial_size),
		"Tras el reset comun de ronda, el arena deberia volver al tamano completo."
	)

	await create_timer(0.8).timeout
	await _cleanup_main(main)
	_finish()


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
