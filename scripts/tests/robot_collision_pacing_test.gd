extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")

const MATCH_SCENES := [
	{
		"path": "res://scenes/main/main.tscn",
		"label": "2v2 main.tscn",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"path": "res://scenes/main/main_teams_validation.tscn",
		"label": "2v2 validación",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"path": "res://scenes/main/main_teams_large_validation.tscn",
		"label": "2v2 grande",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"path": "res://scenes/main/main_ffa.tscn",
		"label": "FFA main_ffa",
		"mode": MatchController.MatchMode.FFA,
	},
	{
		"path": "res://scenes/main/main_ffa_validation.tscn",
		"label": "FFA main_ffa_validation",
		"mode": MatchController.MatchMode.FFA,
	},
	{
		"path": "res://scenes/main/main_ffa_large_validation.tscn",
		"label": "FFA main_ffa_large_validation",
		"mode": MatchController.MatchMode.FFA,
		"use_opponent_probe_after_first_round": true,
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_glide_decay_preserves_slide_before_settling()
	await _validate_collision_damage_requires_committed_closing_speed()
	await _validate_short_sessions_by_mode()
	await process_frame
	await process_frame
	_finish()


func _validate_glide_decay_preserves_slide_before_settling() -> void:
	var robot := await _spawn_robot()
	var initial_speed := robot.max_move_speed
	robot._planar_velocity = Vector3.RIGHT * initial_speed

	robot._update_prototype_movement(0.1)
	var short_decay_speed := robot._planar_velocity.length()
	_assert(
		short_decay_speed < initial_speed,
		"Sin input el robot deberia empezar a perder velocidad."
	)
	_assert(
		short_decay_speed > initial_speed * 0.8,
		"El glide no deberia frenar de golpe; el robot deberia seguir deslizando tras soltar control."
	)

	for _step in range(26):
		robot._update_prototype_movement(0.1)

	_assert(
		robot._planar_velocity.length() < 0.25,
		"Tras suficiente tiempo sin input el deslizamiento deberia apagarse para recuperar lectura."
	)

	await _cleanup_node(robot)


func _validate_collision_damage_requires_committed_closing_speed() -> void:
	var attacker := await _spawn_robot()
	var victim := await _spawn_robot()
	victim.global_position = Vector3(1.5, victim.global_position.y, 0.0)
	await process_frame

	var baseline_total_health := _get_total_part_health(victim)
	attacker._collision_damage_ready_at.clear()
	attacker._planar_velocity = Vector3.RIGHT * maxf(attacker.collision_damage_threshold - 0.05, 0.0)
	attacker._try_apply_collision_damage(victim, Vector3.RIGHT)
	_assert(
		is_equal_approx(_get_total_part_health(victim), baseline_total_health),
		"Los contactos por debajo del umbral no deberian convertirse en partes danadas."
	)

	attacker._collision_damage_ready_at.clear()
	attacker._planar_velocity = Vector3.RIGHT * (attacker.collision_damage_threshold + 1.25)
	attacker._try_apply_collision_damage(victim, Vector3.RIGHT)
	_assert(
		_get_total_part_health(victim) < baseline_total_health,
		"Cuando el cierre supera el umbral, el choque deberia castigar una parte del rival."
	)
	_assert(
		victim.get_recent_elimination_source() == attacker,
		"El dano de choque deberia conservar la atribucion del agresor reciente."
	)

	await _cleanup_node(victim)
	await _cleanup_node(attacker)


func _validate_short_sessions_by_mode() -> void:
	for scene_spec in MATCH_SCENES:
		await _run_short_sessions_for_scene(scene_spec)


func _run_short_sessions_for_scene(scene_spec: Dictionary) -> void:
	var scene_path := String(scene_spec.get("path", ""))
	var label := String(scene_spec.get("label", scene_path))
	var expected_mode := int(scene_spec.get("mode", MatchController.MatchMode.TEAMS))

	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia poder cargarse en prueba de ritmo corto." % label)
	if not (packed_scene is PackedScene):
		return

	var main := (packed_scene as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as Node
	_assert(
		match_controller is MatchController,
		"La escena %s deberia exponer MatchController para corrida real." % label
	)
	if not (match_controller is MatchController):
		await _cleanup_main(main)
		return

	var controller := match_controller as MatchController
	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "La escena %s deberia tener 4 robots para validar ritmo." % label)
	_assert(controller.match_mode == expected_mode, "La escena %s deberia arrancar en el modo esperado." % label)
	_assert(
		controller.get_round_status_line().contains("Ronda 1"),
		"La escena %s deberia iniciar con estado de ronda activa." % label
	)

	_configure_scene_for_short_session(controller)
	_assert(
		not controller.is_match_over(),
		"El match de %s no deberia venir con cierre previo." % label
	)
	await _await_round_intro_clear(controller, label)

	for round_index in range(3):
		var round_start_time := Time.get_ticks_msec()
		var round_id := "Ronda %s" % (round_index + 1)

		await _await_round_intro_clear(controller, label)
		var use_opponent_probe := bool(scene_spec.get("use_opponent_probe_after_first_round", false)) and round_index > 0
		var collision_probe := await _capture_runtime_collision_probe(
			controller,
			robots,
			"%s | %s" % [label, round_id],
			use_opponent_probe
		)
		_assert(
			bool(collision_probe.get("meaningful_collision", false)),
			"%s | el primer choque post-respawn deberia provocar daño modular visible." % ["%s | %s" % [label, round_id]]
		)
		_assert(
			not bool(collision_probe.get("ring_out_before_damage", true)),
			"%s | la ronda no deberia caer en ring-out antes del primer daño de choque." % ["%s | %s" % [label, round_id]]
		)
		_force_round_closure_for_scene_mode(controller, robots)

		await _await_round_end(controller, 2.5)
		var round_duration := float(Time.get_ticks_msec() - round_start_time) / 1000.0
		print("PACING | %s | %s | %.2fs | %s" % [label, round_id, round_duration, controller.get_last_elimination_summary()])

		await _await_round_reset_or_match_result(controller, label)
		var robots_back := _get_scene_robots(main)
		_assert(robots_back.size() == robots.size(), "La escena %s deberia retornar con mismos jugadores tras reset." % label)
		robots = robots_back

		if controller.is_match_over():
			break

	await _cleanup_main(main)


func _capture_runtime_collision_probe(
	controller: MatchController,
	robots: Array[RobotBase],
	context: String,
	use_opponent_probe := false
) -> Dictionary:
	var result := {
		"meaningful_collision": false,
		"damage_delta": 0.0,
		"ring_out_before_damage": false,
		"victim_label": "",
		"source_label": "",
	}
	if controller == null or robots.size() < 2:
		return result

	var baseline_health := {}
	var ring_out_state := {
		"meaningful_collision": false,
		"ring_out_before_damage": false,
	}
	var signal_connections: Array[Dictionary] = []
	for robot in robots:
		if not is_instance_valid(robot):
			continue

		baseline_health[robot.get_instance_id()] = _get_total_part_health(robot)
		var callable := Callable(self, "_on_probe_robot_fell_into_void").bind(ring_out_state)
		robot.fell_into_void.connect(callable)
		signal_connections.append({
			"robot": robot,
			"callable": callable,
		})

	var timeout_msec := Time.get_ticks_msec() + 1800
	while Time.get_ticks_msec() < timeout_msec and not controller.is_round_reset_pending() and controller.is_round_active():
		if use_opponent_probe:
			_apply_runtime_collision_probe_inputs(controller, robots)
		else:
			_apply_runtime_center_drive_inputs(robots)
		await physics_frame

		for robot in robots:
			if not is_instance_valid(robot):
				continue

			var baseline_total := float(baseline_health.get(robot.get_instance_id(), 0.0))
			var current_total := _get_total_part_health(robot)
			var damage_delta := baseline_total - current_total
			if damage_delta <= 0.0:
				continue

			ring_out_state["meaningful_collision"] = true
			result["meaningful_collision"] = true
			result["damage_delta"] = damage_delta
			result["ring_out_before_damage"] = bool(ring_out_state.get("ring_out_before_damage", false))
			result["victim_label"] = robot.display_name
			var source_robot := robot.get_recent_elimination_source()
			if is_instance_valid(source_robot):
				result["source_label"] = source_robot.display_name
			break

		if bool(result.get("meaningful_collision", false)):
			break

		if bool(ring_out_state.get("ring_out_before_damage", false)):
			result["ring_out_before_damage"] = true
			break

	_release_runtime_center_drive_inputs(robots)
	for connection in signal_connections:
		var robot := connection.get("robot") as RobotBase
		var callable := connection.get("callable") as Callable
		if is_instance_valid(robot) and robot.fell_into_void.is_connected(callable):
			robot.fell_into_void.disconnect(callable)

	print(
		"PACING | %s | choque_significativo=%s | dano=%.3f | ring_out_antes_dano=%s | fuente=%s | victima=%s"
		% [
			context,
			str(_meaningful_bool_str(bool(result.get("meaningful_collision", false)))),
			float(result.get("damage_delta", 0.0)),
			str(_meaningful_bool_str(bool(result.get("ring_out_before_damage", false)))),
			String(result.get("source_label", "")),
			String(result.get("victim_label", "")),
		]
	)

	return result


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


func _apply_runtime_collision_probe_inputs(controller: MatchController, robots: Array[RobotBase]) -> void:
	for robot in robots:
		if not is_instance_valid(robot):
			continue
		if not robot.visible or robot.is_disabled_state():
			_release_robot_move_inputs(robot)
			continue

		var target := _find_nearest_runtime_opponent(controller, robot, robots)
		if target == null:
			_release_robot_move_inputs(robot)
			continue

		var to_target := target.global_position - robot.global_position
		to_target.y = 0.0
		_set_robot_move_inputs(robot, to_target)


func _find_nearest_runtime_opponent(
	controller: MatchController,
	source_robot: RobotBase,
	robots: Array[RobotBase]
) -> RobotBase:
	var nearest: RobotBase = null
	var nearest_distance_sq := INF
	for candidate in robots:
		if not is_instance_valid(candidate) or candidate == source_robot:
			continue
		if not candidate.visible or candidate.is_disabled_state():
			continue
		if controller.match_mode == MatchController.MatchMode.TEAMS and candidate.team_id == source_robot.team_id:
			continue

		var distance_sq := source_robot.global_position.distance_squared_to(candidate.global_position)
		if distance_sq >= nearest_distance_sq:
			continue

		nearest = candidate
		nearest_distance_sq = distance_sq

	return nearest


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


func _meaningful_bool_str(value: bool) -> String:
	return "si" if value else "no"


func _on_probe_robot_fell_into_void(_robot: RobotBase, ring_out_state: Dictionary) -> void:
	if bool(ring_out_state.get("meaningful_collision", false)):
		return

	ring_out_state["ring_out_before_damage"] = true


func _configure_scene_for_short_session(controller: MatchController) -> void:
	if controller.match_config != null:
		var config := controller.match_config.duplicate()
		config.rounds_to_win = 99
		config.round_intro_duration_teams = 0.2
		config.round_intro_duration_ffa = 0.2
		controller.match_config = config

	controller.round_reset_delay = 0.18
	controller.match_restart_delay = 0.35
	controller.space_reduction_start_ratio = 0.5


func _force_round_closure_for_scene_mode(controller: MatchController, robots: Array[RobotBase]) -> void:
	if robots.is_empty():
		return

	var is_ffa := controller.match_mode == MatchController.MatchMode.FFA
	var forced := 0

	for robot in robots:
		if not is_instance_valid(robot) or robot.is_disabled_state():
			continue

		if is_ffa:
			if robot.player_index > 1:
				robot.fall_into_void()
				forced += 1
				await create_timer(0.06).timeout
				if forced >= 3:
					break
			continue

		if robot.team_id == 1:
			continue

		robot.fall_into_void()
		forced += 1
		await create_timer(0.06).timeout
		if forced >= 2:
			break


func _await_round_intro_clear(controller: MatchController, label: String) -> void:
	var timeout_sec := 2.5
	var end_time := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while controller.is_round_intro_active():
		_assert(
			Time.get_ticks_msec() < end_time,
			"La escena %s no termino el intro a tiempo para validar ritmo." % label
		)
		await physics_frame


func _await_round_end(controller: MatchController, timeout_sec: float) -> void:
	var end_time := Time.get_ticks_msec() + int(maxf(timeout_sec, 0.1) * 1000.0)
	while not controller.is_round_reset_pending() and controller.is_round_active():
		_assert(
			Time.get_ticks_msec() <= end_time,
			"No se cerro la ronda en tiempo para ritmo corto."
		)
		await physics_frame


func _await_round_reset_or_match_result(controller: MatchController, label: String) -> void:
	var deadline := Time.get_ticks_msec() + 2500
	while not controller.is_match_over() and not controller.is_round_active():
		_assert(
			Time.get_ticks_msec() < deadline,
			"La ronda de %s no termino de reiniciarse con tiempo." % label
		)
		await physics_frame


func _spawn_robot() -> RobotBase:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	robot.gravity = 0.0
	robot.void_fall_y = -100.0
	root.add_child(robot)
	await process_frame
	await process_frame
	return robot


func _get_total_part_health(robot: RobotBase) -> float:
	var total := 0.0
	for part_name in robot.BODY_PARTS:
		total += robot.get_part_health(part_name)

	return total


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _cleanup_main(main: Node) -> void:
	if not is_instance_valid(main):
		return

	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
