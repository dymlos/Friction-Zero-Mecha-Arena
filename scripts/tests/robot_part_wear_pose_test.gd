extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(robot)

	await process_frame
	await physics_frame

	var left_arm := robot.get_node_or_null("UpperBodyPivot/LeftArm") as MeshInstance3D
	var right_arm := robot.get_node_or_null("UpperBodyPivot/RightArm") as MeshInstance3D
	var left_leg := robot.get_node_or_null("ModularParts/LeftLeg") as MeshInstance3D
	var right_leg := robot.get_node_or_null("ModularParts/RightLeg") as MeshInstance3D
	var left_leg_thruster := robot.get_node_or_null("ModularParts/LeftLegThruster") as MeshInstance3D
	var right_leg_thruster := robot.get_node_or_null("ModularParts/RightLegThruster") as MeshInstance3D
	_assert(left_arm != null, "El robot deberia exponer el brazo izquierdo para lectura modular.")
	_assert(right_arm != null, "El robot deberia exponer el brazo derecho para comparacion.")
	_assert(left_leg != null, "El robot deberia exponer la pierna izquierda para lectura modular.")
	_assert(right_leg != null, "El robot deberia exponer la pierna derecha para comparacion.")
	_assert(left_leg_thruster != null, "La pierna izquierda deberia incluir su thruster visual.")
	_assert(right_leg_thruster != null, "La pierna derecha deberia incluir su thruster visual.")
	if left_arm == null or right_arm == null or left_leg == null or right_leg == null or left_leg_thruster == null or right_leg_thruster == null:
		await _cleanup_robot(robot)
		_finish()
		return

	var left_arm_base := left_arm.transform
	var right_arm_base := right_arm.transform
	var left_leg_base := left_leg.transform
	var right_leg_base := right_leg.transform
	var left_leg_thruster_base := left_leg_thruster.transform
	var right_leg_thruster_base := right_leg_thruster.transform

	robot.apply_damage_to_part("left_arm", 55.0)
	await process_frame

	_assert(
		left_arm.transform.origin.y < left_arm_base.origin.y - 0.01,
		"Un brazo dañado deberia leerse caido sobre el propio robot."
	)
	_assert(
		not _transforms_close(left_arm.transform, left_arm_base),
		"El brazo dañado deberia cambiar de pose, no solo de color."
	)
	_assert(
		_transforms_close(right_arm.transform, right_arm_base),
		"El brazo sano no deberia heredar la pose de desgaste del otro lado."
	)

	robot.repair_part("left_arm", 200.0)
	await process_frame

	_assert(
		_transforms_close(left_arm.transform, left_arm_base),
		"Reparar un brazo deberia devolver su pose de fabrica."
	)

	robot.apply_damage_to_part("left_leg", 55.0)
	await process_frame

	_assert(
		left_leg.transform.origin.y < left_leg_base.origin.y - 0.01,
		"Una pierna dañada deberia sentirse mas torpe y baja visualmente."
	)
	_assert(
		left_leg.transform.origin.z > left_leg_base.origin.z + 0.01,
		"Una pierna dañada deberia arrastrarse hacia atras para reforzar la lectura."
	)
	_assert(
		left_leg_thruster.transform.origin.z > left_leg_thruster_base.origin.z + 0.01,
		"El thruster de la pierna dañada deberia acompañar la misma pose floja."
	)
	_assert(
		_transforms_close(right_leg.transform, right_leg_base),
		"La pierna sana no deberia deformarse cuando solo la otra esta dañada."
	)
	_assert(
		_transforms_close(right_leg_thruster.transform, right_leg_thruster_base),
		"El thruster sano tampoco deberia moverse."
	)

	robot.repair_part("left_leg", 200.0)
	await process_frame

	_assert(
		_transforms_close(left_leg.transform, left_leg_base),
		"Reparar la pierna deberia restaurar su pose original."
	)
	_assert(
		_transforms_close(left_leg_thruster.transform, left_leg_thruster_base),
		"El thruster reparado deberia volver a su pose original."
	)

	await _cleanup_robot(robot)
	_finish()


func _transforms_close(left: Transform3D, right: Transform3D) -> bool:
	return (
		left.origin.is_equal_approx(right.origin)
		and left.basis.x.is_equal_approx(right.basis.x)
		and left.basis.y.is_equal_approx(right.basis.y)
		and left.basis.z.is_equal_approx(right.basis.z)
	)


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
