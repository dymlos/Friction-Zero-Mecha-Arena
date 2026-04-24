extends SceneTree

const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const SCENE_SPECS := [
	{
		"path": "res://scenes/main/main_teams_large_validation.tscn",
		"arena_name": "ArenaTeamsLargeValidation",
		"mode": "teams",
		"expected_robots": 4,
		"expected_spawns": 4,
		"max_spawn_to_crossing_distance": 5.4,
		"min_edge_pickup_distance": 7.2,
	},
	{
		"path": "res://scenes/main/main_teams_large.tscn",
		"arena_name": "ArenaTeamsLarge",
		"mode": "teams",
		"expected_robots": 8,
		"expected_spawns": 8,
		"max_spawn_to_crossing_distance": 6.9,
		"min_edge_pickup_distance": 7.2,
	},
	{
		"path": "res://scenes/main/main_ffa_large_validation.tscn",
		"arena_name": "ArenaFFALargeValidation",
		"mode": "ffa",
		"expected_robots": 4,
		"expected_spawns": 4,
		"max_spawn_to_crossing_distance": 6.2,
		"min_edge_pickup_distance": 6.8,
	},
	{
		"path": "res://scenes/main/main_ffa_large.tscn",
		"arena_name": "ArenaFFALarge",
		"mode": "ffa",
		"expected_robots": 8,
		"expected_spawns": 8,
		"max_spawn_to_crossing_distance": 5.9,
		"min_edge_pickup_distance": 6.8,
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_spec in SCENE_SPECS:
		await _assert_large_scale_slice(scene_spec)

	_finish()


func _assert_large_scale_slice(scene_spec: Dictionary) -> void:
	var packed_scene := load(String(scene_spec.path))
	_assert(packed_scene is PackedScene, "La escena %s deberia existir para validar la escala grande." % String(scene_spec.path))
	if not (packed_scene is PackedScene):
		return

	var main := (packed_scene as PackedScene).instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var arena := main.get_node_or_null("ArenaRoot/%s" % String(scene_spec.arena_name)) as ArenaBase
	var robots := _get_scene_robots(main)
	var expected_robots := int(scene_spec.get("expected_robots", 4))
	var expected_spawns := int(scene_spec.get("expected_spawns", 4))
	_assert(arena != null, "La escena %s deberia montar su arena dedicada." % String(scene_spec.path))
	_assert(robots.size() == expected_robots, "La escena %s deberia bootear con %s robots." % [String(scene_spec.path), expected_robots])
	if arena == null or robots.size() != expected_robots:
		await _cleanup_main(main)
		return

	var spawn_positions: Array[Vector2] = arena.get_spawn_local_planar_positions()
	var edge_pickup_positions: Array[Vector2] = arena.get_edge_pickup_local_planar_positions()
	_assert(
		spawn_positions.size() == expected_spawns,
		"La escena %s deberia exponer %s spawns medibles desde ArenaBase." % [String(scene_spec.path), expected_spawns]
	)
	_assert(
		not edge_pickup_positions.is_empty(),
		"La escena %s deberia exponer pickups de borde medibles desde ArenaBase." % String(scene_spec.path)
	)
	if spawn_positions.size() != expected_spawns or edge_pickup_positions.is_empty():
		await _cleanup_main(main)
		return

	_assert(
		arena.get_play_area_half_extents().x >= 11.0,
		"La escena %s deberia sostener una escala realmente mayor que los laboratorios compactos." % String(scene_spec.path)
	)
	_assert(
		_get_longest_center_distance(spawn_positions) <= float(scene_spec.max_spawn_to_crossing_distance),
		"La escena %s no deberia dejar que el viaje inicial gane al primer cruce." % String(scene_spec.path)
	)
	_assert(
		_get_shortest_center_distance(edge_pickup_positions) >= float(scene_spec.min_edge_pickup_distance),
		"La escena %s deberia seguir tentando hacia el borde con pickups realmente periféricos." % String(scene_spec.path)
	)

	if String(scene_spec.mode) == "teams":
		_assert(_teams_keep_center_relatively_clean(arena), "Teams large deberia conservar un centro relativamente limpio.")
		if expected_robots == 4:
			_assert(_robots_keep_ally_pairing(robots), "Teams large deberia dejar aliados mas cerca entre si que de los rivales.")
	else:
		_assert(_spawns_cover_four_quadrants(spawn_positions), "FFA large deberia repartir el arranque sobre cuatro cuadrantes.")
		_assert(_center_remains_faster_than_edge(spawn_positions, edge_pickup_positions), "FFA large no deberia convertir el centro en tiempo muerto respecto del borde.")

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


func _get_longest_center_distance(points: Array[Vector2]) -> float:
	var longest := 0.0
	for point in points:
		longest = maxf(longest, point.length())
	return longest


func _get_shortest_center_distance(points: Array[Vector2]) -> float:
	var shortest := INF
	for point in points:
		shortest = minf(shortest, point.length())
	return shortest


func _teams_keep_center_relatively_clean(arena: ArenaBase) -> bool:
	for cover_position in arena.get_cover_local_planar_positions():
		if absf(cover_position.x) <= 3.2 and absf(cover_position.y) <= 2.4:
			return false
	return true


func _robots_keep_ally_pairing(robots: Array[RobotBase]) -> bool:
	for robot in robots:
		var nearest_ally := INF
		var nearest_enemy := INF
		for other in robots:
			if other == robot:
				continue
			var distance := robot.global_position.distance_to(other.global_position)
			if robot.is_ally_of(other):
				nearest_ally = minf(nearest_ally, distance)
			else:
				nearest_enemy = minf(nearest_enemy, distance)
		if nearest_ally + 0.01 >= nearest_enemy:
			return false
	return true


func _spawns_cover_four_quadrants(spawn_positions: Array[Vector2]) -> bool:
	var quadrants := {}
	for point in spawn_positions:
		if absf(point.x) < 0.5 or absf(point.y) < 0.5:
			continue
		quadrants["%s:%s" % [signi(point.x), signi(point.y)]] = true
	return quadrants.size() == 4


func _center_remains_faster_than_edge(spawn_positions: Array[Vector2], edge_pickup_positions: Array[Vector2]) -> bool:
	return _get_longest_center_distance(spawn_positions) + 1.2 < _get_shortest_center_distance(edge_pickup_positions)


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
