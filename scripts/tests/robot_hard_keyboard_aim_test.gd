extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	robot.is_player_controlled = true
	robot.player_index = 1
	robot.keyboard_profile = RobotBase.KeyboardProfile.WASD_SPACE
	robot.control_mode = RobotBase.ControlMode.HARD
	root.add_child(robot)

	await process_frame
	await physics_frame

	Input.action_press(&"p1_aim_right", 1.0)
	robot._update_control_mode_orientation(0.2)
	Input.action_release(&"p1_aim_right")

	var combat_forward := robot.get_combat_forward_vector()
	_assert(
		combat_forward.dot(Vector3.RIGHT) > 0.85,
		"El aim por teclado deberia poder orientar el torso Hard hacia la derecha."
	)

	await _cleanup_robot(robot)
	_finish()


func _cleanup_robot(robot: RobotBase) -> void:
	if not is_instance_valid(robot):
		return

	var parent := robot.get_parent()
	if parent != null:
		parent.remove_child(robot)
	robot.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
