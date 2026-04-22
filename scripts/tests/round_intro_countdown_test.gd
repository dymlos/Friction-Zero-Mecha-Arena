extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	match_controller.round_intro_duration = 0.35
	root.add_child(main)

	await process_frame
	await process_frame

	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia seguir montando MatchController.")
	_assert(robots.size() >= 1, "La escena principal deberia exponer al menos un robot jugable para validar el arranque.")
	if match_controller == null or robots.is_empty():
		await _cleanup_main(main)
		_finish()
		return

	var robot := robots[0]
	_assert(match_controller.is_round_active(), "La ronda deberia seguir activa mientras corre el intro.")
	_assert(match_controller.is_round_intro_active(), "El intro de ronda deberia quedar activo cuando se configura una duracion positiva.")
	_assert(
		match_controller.get_round_status_line().contains("arranca"),
		"El estado visible deberia anunciar que la ronda todavia no libero el control."
	)

	var locked_origin := _get_planar_position(robot)
	Input.action_press("p1_move_forward", 1.0)
	await _advance_physics_frames(8)
	Input.action_release("p1_move_forward")
	var locked_distance := _get_planar_position(robot).distance_to(locked_origin)
	_assert(
		locked_distance < 0.05,
		"Durante el intro de ronda el robot no deberia acelerar ni deslizarse por input."
	)

	await create_timer(match_controller.round_intro_duration + 0.15).timeout
	await process_frame

	_assert(not match_controller.is_round_intro_active(), "Al agotarse el countdown, el intro de ronda deberia terminar.")
	_assert(
		match_controller.get_round_status_line().contains("en juego"),
		"Cuando termina el intro, el HUD deberia volver al estado normal de ronda en juego."
	)

	var unlocked_origin := _get_planar_position(robot)
	Input.action_press("p1_move_forward", 1.0)
	await _advance_physics_frames(12)
	Input.action_release("p1_move_forward")
	var unlocked_distance := _get_planar_position(robot).distance_to(unlocked_origin)
	_assert(
		unlocked_distance > 0.08,
		"Una vez liberado el intro, el robot deberia volver a responder al input de movimiento."
	)

	await _cleanup_main(main)
	_finish()


func _advance_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _get_planar_position(robot: RobotBase) -> Vector2:
	return Vector2(robot.global_position.x, robot.global_position.z)


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
