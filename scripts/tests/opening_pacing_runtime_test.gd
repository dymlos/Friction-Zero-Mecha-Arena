extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const EdgeRepairPickup = preload("res://scripts/pickups/edge_repair_pickup.gd")

const SCENE_SPECS := [
	{
		"path": "res://scenes/main/main.tscn",
		"label": "Teams base",
	},
	{
		"path": "res://scenes/main/main_teams_validation.tscn",
		"label": "Teams rapido",
	},
	{
		"path": "res://scenes/main/main_ffa.tscn",
		"label": "FFA base",
	},
	{
		"path": "res://scenes/main/main_ffa_validation.tscn",
		"label": "FFA rapido",
	},
]

const INTRO_DURATION := 0.55
const MAX_INTRO_DRIFT := 0.05
const MAX_PICKUP_RELEASE_DELAY := 0.45

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_spec in SCENE_SPECS:
		await _assert_opening_runtime_buffer(scene_spec)

	_finish()


func _assert_opening_runtime_buffer(scene_spec: Dictionary) -> void:
	var scene_path := String(scene_spec.get("path", ""))
	var label := String(scene_spec.get("label", scene_path))
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia seguir existiendo." % label)
	if not (packed_scene is PackedScene):
		return

	var main := (packed_scene as PackedScene).instantiate()
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_configure_short_opening(match_controller)
	root.add_child(main)

	await process_frame
	await process_frame

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel") as Label
	var arena := _get_active_arena(main)
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena %s deberia exponer MatchController." % label)
	_assert(round_label != null, "La escena %s deberia exponer RoundLabel para leer el opening." % label)
	_assert(arena != null, "La escena %s deberia exponer ArenaBase." % label)
	_assert(robots.size() >= 4, "La escena %s deberia conservar cuatro robots para medir opening." % label)
	if match_controller == null or round_label == null or arena == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	var repair_pickup := await _activate_round_with_repair_pickup(main, arena)
	_assert(repair_pickup != null, "La escena %s deberia ofrecer un pickup de reparacion activo para validar el lock del borde." % label)
	if repair_pickup == null:
		await _cleanup_main(main)
		return

	var edge_robot := robots[0]
	var clash_robots: Array[RobotBase] = []
	for index in range(1, robots.size()):
		clash_robots.append(robots[index])

	edge_robot.apply_damage_to_part("left_leg", 20.0, Vector3.BACK)
	var damaged_health := edge_robot.get_part_health("left_leg")
	edge_robot.global_position = repair_pickup.global_position
	await physics_frame
	await process_frame

	var start_positions := {}
	var baseline_health := {}
	var ring_out_state := {
		"meaningful_collision": false,
		"ring_out_before_damage": false,
	}
	var signal_connections: Array[Dictionary] = []
	for robot in clash_robots:
		start_positions[robot.get_instance_id()] = robot.global_position
		baseline_health[robot.get_instance_id()] = _get_total_part_health(robot)
		var callable := Callable(self, "_on_probe_robot_fell_into_void").bind(ring_out_state)
		robot.fell_into_void.connect(callable)
		signal_connections.append({
			"robot": robot,
			"callable": callable,
		})

	var intro_elapsed := -1.0
	var pickup_release_delay := -1.0
	var first_collision_delay := -1.0
	var max_intro_drift := 0.0
	var runtime_start_msec := Time.get_ticks_msec()
	var timeout_msec := runtime_start_msec + 4000

	while Time.get_ticks_msec() < timeout_msec:
		_apply_runtime_center_drive_inputs(clash_robots)
		await physics_frame
		await process_frame

		var elapsed_sec := float(Time.get_ticks_msec() - runtime_start_msec) / 1000.0
		if match_controller.is_round_intro_active():
			_assert(
				is_equal_approx(edge_robot.get_part_health("left_leg"), damaged_health),
				"%s | el pickup de borde no deberia curar mientras el intro sigue activo." % label
			)
			_assert(
				round_label.text.contains("abre en"),
				"%s | el opening runtime deberia seguir explicando que el borde aun no abrio." % label
			)
			max_intro_drift = maxf(max_intro_drift, _get_max_intro_drift(clash_robots, start_positions))
			continue

		if intro_elapsed < 0.0:
			intro_elapsed = elapsed_sec

		if pickup_release_delay < 0.0 and edge_robot.get_part_health("left_leg") > damaged_health:
			pickup_release_delay = elapsed_sec - intro_elapsed

		if first_collision_delay < 0.0:
			for robot in clash_robots:
				if not is_instance_valid(robot):
					continue

				var damage_delta := float(baseline_health.get(robot.get_instance_id(), 0.0)) - _get_total_part_health(robot)
				if damage_delta <= 0.0:
					continue

				ring_out_state["meaningful_collision"] = true
				first_collision_delay = elapsed_sec - intro_elapsed
				break

		if pickup_release_delay >= 0.0 and first_collision_delay >= 0.0:
			break

		if bool(ring_out_state.get("ring_out_before_damage", false)):
			break

	_release_runtime_center_drive_inputs(clash_robots)
	for connection in signal_connections:
		var robot := connection.get("robot") as RobotBase
		var callable := connection.get("callable") as Callable
		if is_instance_valid(robot) and robot.fell_into_void.is_connected(callable):
			robot.fell_into_void.disconnect(callable)

	_assert(
		max_intro_drift <= MAX_INTRO_DRIFT,
		"%s | el intro deberia bloquear deriva temprana antes del primer choque." % label
	)
	_assert(
		pickup_release_delay >= 0.0 and pickup_release_delay <= MAX_PICKUP_RELEASE_DELAY,
		"%s | el pickup del borde deberia liberarse poco despues del opening sin exigir reingreso." % label
	)
	_assert(
		not round_label.text.contains("abre en"),
		"%s | al liberar la ronda el HUD ya no deberia anunciar el lock del borde." % label
	)

	print(
		"OPENING | %s | intro=%.2fs | deriva_intro=%.3f | pickup_post_unlock=%.3fs | choque_post_unlock=%s | ring_out_antes_dano=%s"
		% [
			label,
			intro_elapsed,
			max_intro_drift,
			pickup_release_delay,
			_format_metric_delay(first_collision_delay),
			_bool_to_si_no(bool(ring_out_state.get("ring_out_before_damage", false))),
		]
	)

	await _cleanup_main(main)


func _configure_short_opening(match_controller: MatchController) -> void:
	if match_controller == null:
		return

	match_controller.round_intro_duration = INTRO_DURATION
	match_controller.round_reset_delay = 0.18
	match_controller.match_restart_delay = 0.35
	if match_controller.match_config != null:
		var config := match_controller.match_config.duplicate()
		config.rounds_to_win = 99
		config.round_intro_duration_teams = INTRO_DURATION
		config.round_intro_duration_ffa = INTRO_DURATION
		match_controller.match_config = config


func _activate_round_with_repair_pickup(root_node: Node, arena: ArenaBase) -> EdgeRepairPickup:
	for round_number in range(1, 9):
		arena.activate_edge_pickup_layout_for_round(round_number)
		await process_frame
		for pickup in root_node.get_tree().get_nodes_in_group("edge_repair_pickups"):
			if not root_node.is_ancestor_of(pickup):
				continue
			if pickup is EdgeRepairPickup and bool(pickup.is_spawn_enabled()):
				return pickup as EdgeRepairPickup

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


func _get_active_arena(main: Node) -> ArenaBase:
	var arena_root := main.get_node_or_null("ArenaRoot")
	if arena_root == null:
		return null

	for child in arena_root.get_children():
		if child is ArenaBase:
			return child as ArenaBase

	return null


func _get_total_part_health(robot: RobotBase) -> float:
	var total := 0.0
	for part_name in robot.BODY_PARTS:
		total += robot.get_part_health(part_name)

	return total


func _get_max_intro_drift(robots: Array[RobotBase], start_positions: Dictionary) -> float:
	var max_drift := 0.0
	for robot in robots:
		if not is_instance_valid(robot):
			continue

		var origin: Vector3 = start_positions.get(robot.get_instance_id(), robot.global_position)
		max_drift = maxf(max_drift, robot.global_position.distance_to(origin))

	return max_drift


func _apply_runtime_center_drive_inputs(robots: Array[RobotBase]) -> void:
	for robot in robots:
		if not is_instance_valid(robot):
			continue
		if not robot.visible or robot.is_disabled_state():
			_release_robot_move_inputs(robot)
			continue

		var to_center := Vector3.ZERO - robot.global_position
		to_center.y = 0.0
		_set_robot_move_inputs(robot, to_center)


func _release_runtime_center_drive_inputs(robots: Array[RobotBase]) -> void:
	for robot in robots:
		if not is_instance_valid(robot):
			continue
		_release_robot_move_inputs(robot)


func _set_robot_move_inputs(robot: RobotBase, world_direction: Vector3) -> void:
	var move_left := _player_action_name(robot, "move_left")
	var move_right := _player_action_name(robot, "move_right")
	var move_forward := _player_action_name(robot, "move_forward")
	var move_back := _player_action_name(robot, "move_back")
	var normalized := Vector2(world_direction.x, world_direction.z)
	if normalized.length_squared() > 1.0:
		normalized = normalized.normalized()

	var horizontal_threshold := 0.2
	var vertical_threshold := 0.2
	_set_action_pressed(move_left, normalized.x < -horizontal_threshold)
	_set_action_pressed(move_right, normalized.x > horizontal_threshold)
	_set_action_pressed(move_forward, normalized.y < -vertical_threshold)
	_set_action_pressed(move_back, normalized.y > vertical_threshold)


func _release_robot_move_inputs(robot: RobotBase) -> void:
	_set_action_pressed(_player_action_name(robot, "move_left"), false)
	_set_action_pressed(_player_action_name(robot, "move_right"), false)
	_set_action_pressed(_player_action_name(robot, "move_forward"), false)
	_set_action_pressed(_player_action_name(robot, "move_back"), false)


func _set_action_pressed(action_name: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(action_name)
		return

	Input.action_release(action_name)


func _player_action_name(robot: RobotBase, action_suffix: String) -> StringName:
	return StringName("p%s_%s" % [robot.player_index, action_suffix])

func _format_metric_delay(delay: float) -> String:
	if delay < 0.0:
		return "sin_dato"

	return "%.3fs" % delay


func _bool_to_si_no(value: bool) -> String:
	return "si" if value else "no"


func _on_probe_robot_fell_into_void(_robot: RobotBase, ring_out_state: Dictionary) -> void:
	if bool(ring_out_state.get("meaningful_collision", false)):
		return

	ring_out_state["ring_out_before_damage"] = true


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
