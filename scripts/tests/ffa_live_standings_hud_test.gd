extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const FFA_SCENES := [
	"res://scenes/main/main_ffa.tscn",
	"res://scenes/main/main_ffa_validation.tscn",
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in FFA_SCENES:
		await _assert_scene_uses_neutral_ffa_opening_hud(scene_path)
	_finish()


func _assert_scene_uses_neutral_ffa_opening_hud(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena %s deberia exponer MatchController." % scene_path)
	_assert(robots.size() >= 4, "La escena %s deberia ofrecer cuatro robots para validar posiciones en vivo." % scene_path)
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.round_reset_delay = 0.2
	match_controller.round_intro_duration = 0.0
	var void_round_points := 1
	if match_controller.match_config != null:
		void_round_points = match_controller.match_config.get_round_victory_points_for_cause(
			int(MatchController.EliminationCause.VOID)
		)
	for robot in robots:
		robot.void_fall_y = -100.0

	var opening_round_lines := match_controller.get_round_state_lines()
	_assert(
		not _has_prefix_line(opening_round_lines, "Marcador | "),
		"La escena %s no deberia gastar una linea en un marcador totalmente empatado durante la apertura neutral FFA." % scene_path
	)
	_assert(
		not _has_prefix_line(opening_round_lines, "Posiciones | "),
		"La escena %s no deberia mostrar posiciones mientras toda la ronda sigue empatada y nadie fue eliminado." % scene_path
	)
	_assert(
		not _has_prefix_line(opening_round_lines, "Desempate | "),
		"La escena %s no deberia gastar una linea en el desempate mientras el ranking todavia no aporta informacion real." % scene_path
	)

	robots[0].fall_into_void()
	await create_timer(0.05).timeout
	robots[1].fall_into_void()
	await create_timer(0.05).timeout
	robots[2].fall_into_void()
	await create_timer(0.05).timeout

	var round_lines := match_controller.get_round_state_lines()
	_assert(
		_has_prefix_line(round_lines, "Marcador | "),
		"La escena %s deberia volver a mostrar el marcador en cuanto la ronda FFA ya tiene score util." % scene_path
	)
	var expected_standings := "Posiciones | 1. %s (%s) | 2. %s (0) | 3. %s (0) | 4. %s (0)" % [
		robots[3].display_name,
		void_round_points,
		robots[2].display_name,
		robots[1].display_name,
		robots[0].display_name,
	]
	_assert(
		_has_line(round_lines, expected_standings),
		"La escena %s deberia mostrar las posiciones actuales junto al marcador." % scene_path
	)
	_assert(
		_has_line(
			round_lines,
			"Desempate | 0 pts: %s > %s > %s" % [
				robots[2].display_name,
				robots[1].display_name,
				robots[0].display_name,
			]
		),
		"La escena %s deberia dejar visible que rivales ganan el desempate cuando varios competidores comparten score." % scene_path
	)

	await _cleanup_main(main)


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


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


func _has_line(lines: Array[String], expected: String) -> bool:
	for line in lines:
		if line == expected:
			return true

	return false


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
