extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var robot = ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(robot)

	await process_frame

	robot.receive_attack_hit(Vector3.BACK, 12.0)
	_assert(
		robot.get_part_health("right_leg") < robot.max_part_health,
		"En Easy, un impacto desde atras deberia seguir castigando una pierna."
	)
	_assert(
		is_equal_approx(robot.get_part_health("left_arm"), robot.max_part_health),
		"En Easy, ese impacto trasero no deberia pegar primero en un brazo."
	)

	robot.reset_modular_state()
	robot.control_mode = RobotBase.ControlMode.HARD
	robot.set_torso_world_direction(Vector3.RIGHT)

	var combat_forward: Vector3 = robot.get_combat_forward_vector()
	_assert(
		combat_forward.dot(Vector3.RIGHT) > 0.95,
		"En Hard, la direccion de combate deberia poder separarse del frente del chasis."
	)
	_assert(
		(-robot.global_transform.basis.z).dot(Vector3.FORWARD) > 0.95,
		"Separar el torso no deberia rotar automaticamente todo el robot."
	)

	robot.receive_attack_hit(Vector3.BACK, 12.0)
	_assert(
		robot.get_part_health("left_arm") < robot.max_part_health
			or robot.get_part_health("right_arm") < robot.max_part_health,
		"En Hard, el mismo impacto deberia reinterpretarse segun el torso y poder golpear un brazo."
	)
	_assert(
		is_equal_approx(robot.get_part_health("left_leg"), robot.max_part_health)
			and is_equal_approx(robot.get_part_health("right_leg"), robot.max_part_health),
		"Con torso girado, ese impacto ya no deberia seguir contando como pierna trasera."
	)

	_cleanup_robot(robot)
	await process_frame
	_finish()


func _cleanup_robot(robot: RobotBase) -> void:
	if not is_instance_valid(robot):
		return

	var parent := robot.get_parent()
	if parent != null:
		parent.remove_child(robot)
	robot.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
