extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_glide_decay_preserves_slide_before_settling()
	await _validate_collision_damage_requires_committed_closing_speed()
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

	for _step in range(24):
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
		"Los contactos por debajo del umbral no deberian convertirse en dano modular."
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


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
