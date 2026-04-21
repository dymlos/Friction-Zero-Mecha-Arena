extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var robot = ROBOT_SCENE.instantiate()
	root.add_child(robot)

	await process_frame

	var baseline_leg_drive: float = robot.get_effective_leg_drive_multiplier()
	var baseline_arm_power: float = robot.get_effective_arm_power_multiplier()
	var baseline_arm_energy: float = robot.get_part_energy_amount("left_arm")
	var baseline_leg_energy: float = robot.get_part_energy_amount("left_leg")
	robot.energy_shift_cooldown = 0.0

	var focused: bool = robot.set_energy_focus("left_leg")
	_assert(focused, "La energia deberia poder enfocarse en una parte valida.")
	_assert(robot.get_energy_focus_part_name() == "left_leg", "El foco de energia deberia reflejar la parte seleccionada.")
	_assert(robot.get_part_energy_amount("left_leg") > baseline_leg_energy, "La pierna enfocada deberia recibir mas energia.")
	_assert(robot.get_part_energy_amount("left_arm") < baseline_arm_energy, "Los brazos deberian ceder energia al enfocar piernas.")
	_assert(robot.get_effective_leg_drive_multiplier() > baseline_leg_drive, "El foco en piernas deberia mejorar la traccion real.")
	_assert(robot.get_effective_arm_power_multiplier() < baseline_arm_power, "El foco en piernas deberia debilitar el empuje real.")

	robot.overdrive_duration = 0.1
	robot.overdrive_recovery_duration = 0.2
	robot.overdrive_cooldown = 0.35
	var refocused: bool = robot.set_energy_focus("right_arm")
	_assert(refocused, "La energia deberia poder cambiar de foco antes de activar overdrive.")
	var activated: bool = robot.activate_overdrive()
	_assert(activated, "El overdrive deberia activarse cuando no hay cooldown.")
	_assert(robot.is_overdrive_active(), "El robot deberia entrar en estado de overdrive.")
	_assert(robot.get_part_energy_amount("right_arm") > robot.get_part_energy_amount("left_arm"), "El brazo en overdrive deberia concentrar la mayor energia.")
	_assert(not robot.activate_overdrive(), "No deberia poder spamearse overdrive mientras ya esta activo.")

	robot._update_energy_state(0.24)

	_assert(not robot.is_overdrive_active(), "El overdrive deberia apagarse al terminar su ventana activa.")
	_assert(robot.is_overdrive_cooling_down(), "Tras el overdrive deberia existir enfriamiento.")
	_assert(robot.get_part_energy_amount("right_arm") < robot.starting_energy_per_part, "La parte sobrecargada deberia quedar penalizada durante la recuperacion.")
	_assert(not robot.activate_overdrive(), "No deberia poder reactivarse durante el cooldown.")

	robot._update_energy_state(0.5)

	_assert(not robot.is_overdrive_cooling_down(), "El cooldown de overdrive deberia terminar tras el tiempo configurado.")
	_assert(robot.activate_overdrive(), "El overdrive deberia volver a estar disponible al terminar el cooldown.")

	var energy_readability_root := robot.get_node_or_null("EnergyReadability") as Node3D
	_assert(
		energy_readability_root != null,
		"El robot deberia montar un root runtime para leer redistribucion de energia sobre el propio cuerpo."
	)

	var left_arm_indicator := robot.get_node_or_null("UpperBodyPivot/LeftArm/EnergyFocusIndicator") as MeshInstance3D
	var right_arm_indicator := robot.get_node_or_null("UpperBodyPivot/RightArm/EnergyFocusIndicator") as MeshInstance3D
	var left_leg_indicator := robot.get_node_or_null("ModularParts/LeftLeg/EnergyFocusIndicator") as MeshInstance3D
	var right_leg_indicator := robot.get_node_or_null("ModularParts/RightLeg/EnergyFocusIndicator") as MeshInstance3D
	_assert(left_arm_indicator != null, "El brazo izquierdo deberia exponer un indicador de energia diegetico.")
	_assert(right_arm_indicator != null, "El brazo derecho deberia exponer un indicador de energia diegetico.")
	_assert(left_leg_indicator != null, "La pierna izquierda deberia exponer un indicador de energia diegetico.")
	_assert(right_leg_indicator != null, "La pierna derecha deberia exponer un indicador de energia diegetico.")
	if (
		energy_readability_root == null
		or left_arm_indicator == null
		or right_arm_indicator == null
		or left_leg_indicator == null
		or right_leg_indicator == null
	):
		robot.queue_free()
		_finish()
		return

	robot.reset_modular_state()
	await process_frame

	_assert(
		not left_arm_indicator.visible and not right_arm_indicator.visible and not left_leg_indicator.visible and not right_leg_indicator.visible,
		"Con energia balanceada no deberian quedar marcadores persistentes en las extremidades."
	)

	robot.energy_shift_cooldown = 0.0
	_assert(robot.set_energy_focus("left_leg"), "La prueba de lectura necesita poder enfocar energia en una pierna.")
	await process_frame

	_assert(left_leg_indicator.visible, "La pierna enfocada deberia marcarse en el propio cuerpo.")
	_assert(right_leg_indicator.visible, "La pareja de la pierna enfocada tambien deberia quedar marcada.")
	_assert(
		not left_arm_indicator.visible and not right_arm_indicator.visible,
		"Al enfocar piernas, los brazos no deberian competir con la lectura principal."
	)
	var left_leg_material := left_leg_indicator.material_override as StandardMaterial3D
	var right_leg_material := right_leg_indicator.material_override as StandardMaterial3D
	_assert(left_leg_material != null, "El indicador de la pierna enfocada deberia poder reforzar emision y color.")
	_assert(right_leg_material != null, "La pareja energetica tambien deberia poder reforzar su lectura.")
	if left_leg_material != null and right_leg_material != null:
		_assert(
			left_leg_material.emission_energy_multiplier > right_leg_material.emission_energy_multiplier,
			"La extremidad exacta del foco deberia leerse con mas intensidad que su pareja."
		)

	robot.overdrive_duration = 0.25
	robot.overdrive_cooldown = 0.4
	robot.overdrive_recovery_duration = 0.2
	robot.energy_shift_cooldown = 0.0
	_assert(robot.set_energy_focus("right_arm"), "La prueba de overdrive necesita cambiar el foco a un brazo.")
	_assert(robot.activate_overdrive(), "La prueba de lectura necesita activar overdrive en el brazo derecho.")
	await process_frame

	_assert(right_arm_indicator.visible, "El brazo en overdrive deberia seguir marcado sobre el cuerpo.")
	_assert(left_arm_indicator.visible, "La pareja del brazo en overdrive deberia conservar contexto de energia.")
	_assert(
		not left_leg_indicator.visible and not right_leg_indicator.visible,
		"Durante overdrive de brazos, las piernas no deberian competir con esa lectura."
	)
	var right_arm_material := right_arm_indicator.material_override as StandardMaterial3D
	var left_arm_material := left_arm_indicator.material_override as StandardMaterial3D
	_assert(right_arm_material != null, "El brazo en overdrive deberia exponer material para lectura caliente.")
	_assert(left_arm_material != null, "La pareja del brazo tambien deberia exponer material propio.")
	if right_arm_material != null and left_arm_material != null:
		_assert(
			right_arm_material.emission.r > right_arm_material.emission.b,
			"El overdrive de brazos deberia empujar la lectura hacia un color mas caliente."
		)
		_assert(
			right_arm_material.emission_energy_multiplier > left_arm_material.emission_energy_multiplier,
			"El brazo exacto en overdrive deberia destacar sobre su pareja."
		)

	robot.queue_free()

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
