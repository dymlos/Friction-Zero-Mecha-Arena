extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")

const SCENE_SPECS := [
	{
		"path": "res://scenes/main/main.tscn",
		"set_ffa_mode_before_ready": true,
		"min_spawn_radius": 3.5,
	},
	{
		"path": "res://scenes/main/main_ffa_large_validation.tscn",
		"set_ffa_mode_before_ready": false,
		"min_spawn_radius": 4.8,
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_spec in SCENE_SPECS:
		await _assert_ffa_scene(scene_spec)

	_finish()


func _assert_ffa_scene(scene_spec: Dictionary) -> void:
	var packed_scene := load(String(scene_spec.path))
	_assert(packed_scene is PackedScene, "La escena %s deberia existir para validar el bootstrap FFA." % String(scene_spec.path))
	if not (packed_scene is PackedScene):
		return

	var main := (packed_scene as PackedScene).instantiate()
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	_assert(match_controller != null, "La escena %s deberia exponer MatchController para validar FFA." % String(scene_spec.path))
	if match_controller == null:
		await _cleanup_main(main)
		return

	if bool(scene_spec.set_ffa_mode_before_ready):
		match_controller.match_mode = MatchController.MatchMode.FFA
	root.add_child(main)

	await process_frame
	await process_frame

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "La escena %s deberia ofrecer cuatro robots para validar FFA." % String(scene_spec.path))
	if robots.size() < 4:
		await _cleanup_main(main)
		return

	_assert(match_controller.match_mode == MatchController.MatchMode.FFA, "La escena %s deberia arrancar en modo FFA." % String(scene_spec.path))
	_assert(
		not robots[0].is_ally_of(robots[1]),
		"En FFA Player 1 y Player 2 no deberian quedar aliados por team_id heredado en %s." % String(scene_spec.path)
	)
	_assert(
		not robots[2].is_ally_of(robots[3]),
		"En FFA Player 3 y Player 4 tambien deberian competir por separado en %s." % String(scene_spec.path)
	)
	_assert(
		_uses_distinct_ffa_spawn_layout(robots, float(scene_spec.min_spawn_radius)),
		"La escena %s deberia sostener spawns diagonales propios en la nueva escala." % String(scene_spec.path)
	)

	for robot in robots:
		robot.set_physics_process(false)
		robot.gravity = 0.0
		robot.void_fall_y = -100.0

	var owner := robots[0]
	var rival := robots[1]
	owner.apply_damage_to_part("left_arm", owner.max_part_health + 5.0, Vector3.LEFT)

	await process_frame

	var detached_part := _get_only_detached_part()
	_assert(detached_part != null, "La destruccion modular deberia seguir generando una parte desprendida en FFA.")
	if detached_part == null:
		await _cleanup_main(main)
		return

	await create_timer(detached_part.pickup_delay + 0.05).timeout

	rival.global_position = detached_part.global_position
	var picked_up := detached_part.try_pick_up(rival)
	_assert(picked_up, "En FFA un rival deberia poder recoger la parte para negarla.")

	var delivered_as_fake_ally := detached_part.try_deliver_to_robot(owner, rival)
	_assert(
		not delivered_as_fake_ally,
		"En FFA un rival no deberia devolver la parte como si fuera aliado."
	)

	var round_lines := match_controller.get_round_state_lines()
	var score_line := _find_line_with_prefix(round_lines, "Marcador |")
	_assert(
		score_line == "",
		"La escena %s deberia conservar el opening neutral limpio mientras el score siga empatado." % String(scene_spec.path)
	)

	await _cleanup_main(main)


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _get_only_detached_part() -> DetachedPart:
	var detached_parts := get_nodes_in_group("detached_parts")
	_assert(detached_parts.size() == 1, "Se esperaba exactamente una parte desprendida para la validacion FFA.")
	if detached_parts.size() != 1:
		return null

	return detached_parts[0] as DetachedPart


func _find_line_with_prefix(lines: Array[String], prefix: String) -> String:
	for line in lines:
		if line.begins_with(prefix):
			return line

	return ""


func _uses_distinct_ffa_spawn_layout(robots: Array[RobotBase], min_spawn_radius: float) -> bool:
	if robots.size() < 4:
		return false

	var seen_quadrants := {}
	for robot in robots:
		var planar_position := Vector2(robot.global_position.x, robot.global_position.z)
		if planar_position.length() < min_spawn_radius:
			return false
		if absf(planar_position.x) < 1.0 or absf(planar_position.y) < 1.0:
			return false

		var quadrant_key := "%s:%s" % [signi(planar_position.x), signi(planar_position.y)]
		seen_quadrants[quadrant_key] = true

	return seen_quadrants.size() == 4


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
