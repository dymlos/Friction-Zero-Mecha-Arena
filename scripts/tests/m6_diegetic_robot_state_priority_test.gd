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

	_assert(robot.has_method("get_diegetic_readability_snapshot"), "RobotBase debe exponer snapshot diegetico para QA M6.")
	if not robot.has_method("get_diegetic_readability_snapshot"):
		await _cleanup_robot(robot)
		_finish()
		return

	robot.apply_damage_to_part("left_arm", 35.0)
	await process_frame

	var damage_snapshot: Dictionary = robot.call("get_diegetic_readability_snapshot")
	var parts: Dictionary = damage_snapshot.get("parts", {})
	var left_arm: Dictionary = parts.get("left_arm", {})
	_assert(bool(left_arm.get("visual_visible", false)), "El brazo danado debe seguir visible mientras no esta destruido.")
	_assert(bool(left_arm.get("damage_feedback_visible", false)), "El dano moderado debe leerse en el brazo, no solo en HUD.")
	_assert(String(left_arm.get("damage_feedback_anchor", "")) == "UpperBodyPivot/LeftArm", "El feedback de dano debe estar anclado a la parte visual.")
	_assert(float(left_arm.get("pose_damage_severity", 0.0)) > 0.0, "El deterioro debe cambiar pose ademas de color.")

	robot.set_energy_focus("right_leg")
	robot.activate_overdrive()
	await process_frame

	var overdrive_snapshot: Dictionary = robot.call("get_diegetic_readability_snapshot")
	var state_channels: Dictionary = overdrive_snapshot.get("state_channels", {})
	_assert(String(state_channels.get("energy_anchor", "")) == "right_leg", "El foco/overdrive debe leerse desde la extremidad afectada.")
	_assert(bool(state_channels.get("energy_diegetic_visible", false)), "El overdrive debe tener indicador diegetico visible en el robot.")
	_assert(bool(state_channels.get("core_state_visible", false)), "El core debe reforzar estados sin reemplazar la lectura de partes.")

	for part_name in RobotBase.BODY_PARTS:
		robot.apply_damage_to_part(part_name, robot.max_part_health + 5.0)
	await process_frame

	var disabled_snapshot: Dictionary = robot.call("get_diegetic_readability_snapshot")
	var disabled: Dictionary = disabled_snapshot.get("disabled", {})
	_assert(bool(disabled.get("body_warning_visible", false)), "El cuerpo inutilizado debe mostrar warning diegetico antes de explotar.")
	_assert(float(disabled.get("explosion_radius", 0.0)) > 0.0, "El radio de explosion debe estar disponible para lectura/QA.")
	_assert(bool(disabled_snapshot.get("hud_is_secondary", false)), "M6 exige que el HUD sea refuerzo, no fuente primaria.")

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
