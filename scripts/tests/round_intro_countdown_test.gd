extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const SCENE_SPECS := [
	{
		"path": "res://scenes/main/main.tscn",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"path": "res://scenes/main/main_teams_validation.tscn",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"path": "res://scenes/main/main_ffa.tscn",
		"mode": MatchController.MatchMode.FFA,
	},
	{
		"path": "res://scenes/main/main_ffa_validation.tscn",
		"mode": MatchController.MatchMode.FFA,
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_spec in SCENE_SPECS:
		await _assert_round_intro_contract(scene_spec)
	_finish()


func _assert_round_intro_contract(scene_spec: Dictionary) -> void:
	var scene_path := String(scene_spec.get("path", ""))
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia seguir existiendo." % scene_path)
	if not (packed_scene is PackedScene):
		return

	var main := (packed_scene as PackedScene).instantiate()
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	_apply_round_intro_duration(match_controller, 0.35)
	root.add_child(main)

	await process_frame
	await process_frame

	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena %s deberia seguir montando MatchController." % scene_path)
	_assert(robots.size() >= 1, "La escena %s deberia exponer al menos un robot jugable para validar el arranque." % scene_path)
	if match_controller == null or robots.is_empty():
		await _cleanup_main(main)
		return

	var robot := robots[0]
	var intro_indicator := robot.get_node_or_null("RoundIntroIndicator") as MeshInstance3D
	_assert(match_controller.is_round_active(), "La escena %s deberia mantener la ronda activa mientras corre el intro." % scene_path)
	_assert(match_controller.is_round_intro_active(), "La escena %s deberia quedar dentro del intro cuando se configura una duracion positiva." % scene_path)
	_assert(
		_intro_status_matches_mode(match_controller.get_round_status_line(), int(scene_spec.get("mode", MatchController.MatchMode.TEAMS))),
		"La escena %s deberia anunciar el opening correcto mientras el control sigue bloqueado." % scene_path
	)
	_assert(
		intro_indicator != null,
		"La escena %s deberia exponer un telegraph diegetico de intro sobre el robot." % scene_path
	)
	if intro_indicator != null:
		_assert(
			intro_indicator.visible,
			"El telegraph diegetico del intro deberia verse en %s mientras el control sigue bloqueado." % scene_path
		)

	var locked_origin := _get_planar_position(robot)
	Input.action_press("p1_move_forward", 1.0)
	await _advance_physics_frames(8)
	Input.action_release("p1_move_forward")
	var locked_distance := _get_planar_position(robot).distance_to(locked_origin)
	_assert(
		locked_distance < 0.05,
		"Durante el intro de ronda el robot no deberia acelerar ni deslizarse por input en %s." % scene_path
	)

	await create_timer(match_controller.get_round_intro_time_left() + 0.15).timeout
	await process_frame

	_assert(not match_controller.is_round_intro_active(), "Al agotarse el countdown, el intro de ronda deberia terminar en %s." % scene_path)
	_assert(
		match_controller.get_round_status_line().contains("en juego"),
		"Cuando termina el intro, el HUD deberia volver al estado normal de ronda en juego en %s." % scene_path
	)
	if intro_indicator != null:
		_assert(
			not intro_indicator.visible,
			"Al liberar la ronda, el telegraph diegetico del intro deberia apagarse en %s." % scene_path
		)

	var unlocked_origin := _get_planar_position(robot)
	Input.action_press("p1_move_forward", 1.0)
	await _advance_physics_frames(12)
	Input.action_release("p1_move_forward")
	var unlocked_distance := _get_planar_position(robot).distance_to(unlocked_origin)
	_assert(
		unlocked_distance > 0.08,
		"Una vez liberado el intro, el robot deberia volver a responder al input de movimiento en %s." % scene_path
	)

	await _cleanup_main(main)


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


func _intro_status_matches_mode(status_line: String, match_mode: int) -> bool:
	if match_mode == MatchController.MatchMode.TEAMS:
		return status_line.contains("carriles")

	return status_line.contains("arranca") and not status_line.contains("carriles")


func _apply_round_intro_duration(match_controller: MatchController, duration: float) -> void:
	if match_controller == null:
		return

	match_controller.round_intro_duration = duration
	if match_controller.match_config != null:
		match_controller.match_config.round_intro_duration_teams = duration
		match_controller.match_config.round_intro_duration_ffa = duration


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
