extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")


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

	robot.queue_free()

	quit()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	quit(1)

