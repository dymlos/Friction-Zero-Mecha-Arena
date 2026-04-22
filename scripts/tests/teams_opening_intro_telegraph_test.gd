extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const TEAMS_SCENES := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
]
const FFA_SCENES := [
	"res://scenes/main/main_ffa.tscn",
	"res://scenes/main/main_ffa_validation.tscn",
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in TEAMS_SCENES:
		await _assert_teams_scene_shows_opening_lane_telegraph(scene_path)

	for scene_path in FFA_SCENES:
		await _assert_ffa_scene_keeps_opening_telegraph_hidden(scene_path)
	_finish()


func _assert_teams_scene_shows_opening_lane_telegraph(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var arena := _get_active_arena(main)
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena %s deberia montar MatchController." % scene_path)
	_assert(arena != null, "La escena %s deberia montar un ArenaBase." % scene_path)
	_assert(robots.size() == 4, "La escena %s deberia bootear cuatro robots para validar la apertura Teams." % scene_path)
	if match_controller == null or arena == null or robots.size() != 4:
		await _cleanup_main(main)
		return

	_assert(match_controller.is_round_intro_active(), "La escena %s deberia seguir dentro del intro para validar el telegraph de apertura." % scene_path)
	_assert(
		match_controller.get_round_status_line().contains("carriles"),
		"La escena %s deberia explicar en el estado de ronda que la apertura Teams arranca por carriles." % scene_path
	)

	var opening_root := arena.get_node_or_null("OpeningTelegraph") as Node3D
	_assert(opening_root != null, "La escena %s deberia exponer un root OpeningTelegraph dentro del arena." % scene_path)
	if opening_root != null:
		_assert(opening_root.visible, "La escena %s deberia mostrar el telegraph de apertura mientras dura el intro Teams." % scene_path)
		var lane_a := opening_root.get_node_or_null("LaneA") as MeshInstance3D
		var lane_b := opening_root.get_node_or_null("LaneB") as MeshInstance3D
		_assert(lane_a != null and lane_b != null, "La escena %s deberia exponer dos bandas de apertura, una por carril inicial." % scene_path)
		if lane_a != null and lane_b != null:
			_assert(lane_a.visible and lane_b.visible, "La escena %s deberia mostrar ambas bandas del telegraph de apertura." % scene_path)
			_assert(_lane_bands_match_team_rows(arena, lane_a, lane_b, robots), "La escena %s deberia alinear las bandas con las dos filas iniciales de Teams." % scene_path)

	await create_timer(match_controller.get_round_intro_time_left() + 0.15).timeout
	await process_frame

	_assert(not match_controller.is_round_intro_active(), "La escena %s deberia terminar el intro para ocultar el telegraph." % scene_path)
	_assert(
		not match_controller.get_round_status_line().contains("carriles"),
		"La escena %s deberia volver al wording normal una vez que la ronda entra en juego." % scene_path
	)
	if opening_root != null:
		_assert(not opening_root.visible, "La escena %s deberia ocultar el telegraph de apertura cuando libera la ronda." % scene_path)

	await _cleanup_main(main)


func _assert_ffa_scene_keeps_opening_telegraph_hidden(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var arena := _get_active_arena(main)
	_assert(match_controller != null, "La escena %s deberia montar MatchController." % scene_path)
	_assert(arena != null, "La escena %s deberia montar un ArenaBase." % scene_path)
	if match_controller == null or arena == null:
		await _cleanup_main(main)
		return

	_assert(match_controller.is_round_intro_active(), "La escena %s deberia seguir dentro del intro para validar que FFA no hereda el telegraph de Teams." % scene_path)
	_assert(
		not match_controller.get_round_status_line().contains("carriles"),
		"La escena %s no deberia anunciar carriles en la apertura FFA." % scene_path
	)

	var opening_root := arena.get_node_or_null("OpeningTelegraph") as Node3D
	_assert(opening_root != null, "La escena %s deberia seguir montando el root OpeningTelegraph para reutilizar el mismo arena." % scene_path)
	if opening_root != null:
		_assert(not opening_root.visible, "La escena %s no deberia mostrar el telegraph de carriles en FFA." % scene_path)

	await _cleanup_main(main)


func _lane_bands_match_team_rows(arena: ArenaBase, lane_a: MeshInstance3D, lane_b: MeshInstance3D, robots: Array[RobotBase]) -> bool:
	var team_rows: Array[float] = []
	var teams_seen := {}
	for robot in robots:
		if teams_seen.has(robot.team_id):
			continue
		teams_seen[robot.team_id] = true
		var team_members := _get_team_members(robot.team_id, robots)
		if team_members.size() != 2:
			return false
		var average_row := 0.0
		for member in team_members:
			average_row += arena.to_local(member.global_position).z
		average_row /= float(team_members.size())
		team_rows.append(average_row)

	if team_rows.size() != 2:
		return false

	team_rows.sort()
	var lane_rows := [
		arena.to_local(lane_a.global_position).z,
		arena.to_local(lane_b.global_position).z,
	]
	lane_rows.sort()
	return absf(team_rows[0] - lane_rows[0]) <= 0.25 and absf(team_rows[1] - lane_rows[1]) <= 0.25


func _get_team_members(team_id: int, robots: Array[RobotBase]) -> Array[RobotBase]:
	var members: Array[RobotBase] = []
	for robot in robots:
		if robot.team_id == team_id:
			members.append(robot)
	return members


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


func _get_active_arena(main: Node) -> ArenaBase:
	var arena_root := main.get_node_or_null("ArenaRoot")
	if arena_root == null:
		return null

	for child in arena_root.get_children():
		if child is ArenaBase:
			return child as ArenaBase

	return null


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

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
