extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const TEAMS_SCENES := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
	"res://scenes/main/main_teams_large_validation.tscn",
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in TEAMS_SCENES:
		await _assert_scene_opens_with_coordinated_team_spawns(scene_path)

	_finish()


func _assert_scene_opens_with_coordinated_team_spawns(scene_path: String) -> void:
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia seguir existiendo." % scene_path)
	if not (packed_scene is PackedScene):
		return

	var main := (packed_scene as PackedScene).instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var arena := main.get_node_or_null("ArenaRoot").get_child(0)
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena %s deberia montar MatchController." % scene_path)
	_assert(arena != null, "La escena %s deberia montar un arena para validar la apertura Teams." % scene_path)
	_assert(robots.size() == 4, "La escena %s deberia bootear con cuatro robots de Teams." % scene_path)
	if match_controller == null or arena == null or robots.size() != 4:
		await _cleanup_main(main)
		return

	_assert(
		match_controller.match_mode == MatchController.MatchMode.TEAMS,
		"La escena %s deberia abrir en modo Equipos para validar coordinacion inicial." % scene_path
	)

	for robot in robots:
		var ally_distance := _get_nearest_ally_distance(robot, robots)
		var enemy_distance := _get_nearest_enemy_distance(robot, robots)
		_assert(
			ally_distance + 0.01 < enemy_distance,
			"La escena %s deberia dejar a %s mas cerca de su aliado que del rival mas cercano." % [
				scene_path,
				robot.display_name,
			]
		)
		_assert(
			_is_robot_facing_opening_lane(robot, arena),
			"La escena %s deberia hacer que %s mire hacia el carril central al iniciar Teams." % [
				scene_path,
				robot.display_name,
			]
		)

	await _cleanup_main(main)


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _get_nearest_ally_distance(robot: RobotBase, robots: Array[RobotBase]) -> float:
	var best_distance := INF
	for other in robots:
		if other == robot or not robot.is_ally_of(other):
			continue
		best_distance = minf(best_distance, robot.global_position.distance_to(other.global_position))

	return best_distance


func _get_nearest_enemy_distance(robot: RobotBase, robots: Array[RobotBase]) -> float:
	var best_distance := INF
	for other in robots:
		if other == robot or robot.is_ally_of(other):
			continue
		best_distance = minf(best_distance, robot.global_position.distance_to(other.global_position))

	return best_distance


func _is_robot_facing_opening_lane(robot: RobotBase, arena: Node3D) -> bool:
	var local_position := arena.to_local(robot.global_position)
	if absf(local_position.x) <= 0.05:
		return true

	var forward := -robot.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return false

	forward = forward.normalized()
	var expected_forward := Vector3.RIGHT if local_position.x < 0.0 else Vector3.LEFT
	return forward.dot(expected_forward) >= 0.8


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
