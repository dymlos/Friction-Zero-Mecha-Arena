extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stable_robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(stable_robot)

	await process_frame
	await physics_frame

	var stable_indicator := stable_robot.get_node_or_null("DisabledWarningIndicator") as MeshInstance3D
	_assert(stable_indicator != null, "El robot deberia crear un marcador diegetico para la explosion diferida.")
	if stable_indicator == null:
		await _cleanup_robot(stable_robot)
		_finish()
		return

	_assert(not stable_indicator.visible, "El marcador no deberia verse mientras el robot siga activo.")

	stable_robot.disabled_explosion_delay = 0.5
	stable_robot.disabled_explosion_timer.wait_time = 0.5
	for part_name in stable_robot.BODY_PARTS:
		stable_robot.apply_damage_to_part(part_name, stable_robot.max_part_health + 10.0, Vector3.RIGHT)

	await process_frame

	_assert(stable_indicator.visible, "El cuerpo inutilizado deberia telegraphar la explosion sobre la arena.")
	_assert(
		is_equal_approx(stable_indicator.scale.x, stable_robot.disabled_explosion_radius),
		"El radio visual deberia reflejar la explosion base real."
	)
	_assert(
		is_equal_approx(stable_indicator.scale.z, stable_robot.disabled_explosion_radius),
		"El telegraph deberia mantenerse circular sobre el piso."
	)

	await create_timer(0.6).timeout

	_assert(not stable_indicator.visible, "Tras explotar y salir de inutilizado, el marcador deberia ocultarse.")

	var unstable_robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(unstable_robot)

	await process_frame
	await physics_frame

	var unstable_indicator := unstable_robot.get_node_or_null("DisabledWarningIndicator") as MeshInstance3D
	_assert(unstable_indicator != null, "El segundo robot tambien deberia exponer el marcador de explosion.")
	if unstable_indicator == null:
		await _cleanup_robot(stable_robot)
		await _cleanup_robot(unstable_robot)
		_finish()
		return

	unstable_robot.set_energy_focus("right_arm")
	unstable_robot.activate_overdrive()
	unstable_robot.disabled_explosion_delay = 0.5
	unstable_robot.disabled_explosion_timer.wait_time = 0.5
	for part_name in unstable_robot.BODY_PARTS:
		unstable_robot.apply_damage_to_part(part_name, unstable_robot.max_part_health + 10.0, Vector3.LEFT)

	await process_frame

	var expected_unstable_radius := unstable_robot.disabled_explosion_radius * unstable_robot.unstable_disabled_explosion_radius_multiplier
	_assert(unstable_indicator.visible, "La variante inestable deberia seguir usando el telegraph diegetico.")
	_assert(
		unstable_indicator.scale.x > stable_indicator.scale.x,
		"La explosion inestable deberia leerse mas grande que la estable."
	)
	_assert(
		is_equal_approx(unstable_indicator.scale.x, expected_unstable_radius),
		"El radio visual inestable deberia coincidir con el multiplicador real del gameplay."
	)

	await _cleanup_robot(stable_robot)
	await _cleanup_robot(unstable_robot)
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
