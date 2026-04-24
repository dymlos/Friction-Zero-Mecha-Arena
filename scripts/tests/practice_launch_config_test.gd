extends SceneTree

const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var launch_config := MatchLaunchConfig.new()
	var shell_session := ShellSession.new()

	_assert(
		launch_config.has_method("configure_for_practice"),
		"MatchLaunchConfig deberia exponer una configuracion dedicada para Practica."
	)
	if not launch_config.has_method("configure_for_practice"):
		_finish()
		return

	launch_config.configure_for_practice(
		"impacto",
		"res://scenes/practice/practice_mode.tscn",
		[
			{"slot": 2, "control_mode": RobotBase.ControlMode.HARD, "input_source": "joypad", "device_id": 9, "device_connected": true},
			{"slot": 1, "control_mode": RobotBase.ControlMode.EASY, "input_source": "keyboard", "keyboard_profile": RobotBase.KeyboardProfile.WASD_SPACE},
			{"slot": 2, "control_mode": RobotBase.ControlMode.EASY},
			{"slot": 12, "control_mode": RobotBase.ControlMode.HARD},
		]
	)

	_assert(
		String(launch_config.entry_context) == MatchLaunchConfig.ENTRY_CONTEXT_PRACTICE,
		"El launch config de practica deberia marcar el contexto `practice`."
	)
	_assert(
		String(launch_config.practice_module_id) == "impacto",
		"El launch config de practica deberia conservar el modulo pedido."
	)
	_assert(
		String(launch_config.target_scene_path) == "res://scenes/practice/practice_mode.tscn",
		"El launch config de practica deberia apuntar a practice_mode."
	)
	_assert(
		int(launch_config.hud_detail_mode) == MatchConfig.HudDetailMode.EXPLICIT,
		"Practica deberia arrancar con ayuda visible aunque el default competitivo sea contextual."
	)
	_assert(
		launch_config.local_slots.size() == 2,
		"El launch config de practica deberia sanear slots a P1/P2."
	)
	_assert(
		int(launch_config.local_slots[0].get("slot", -1)) == 1
		and int(launch_config.local_slots[1].get("slot", -1)) == 2,
		"Practica deberia ordenar slots locales por indice ascendente."
	)
	_assert(
		String(launch_config.local_slots[1].get("input_source", "")) == "joypad"
		and int(launch_config.local_slots[1].get("device_id", -1)) == 9,
		"Practica deberia transportar el contrato completo de dispositivo por slot."
	)

	shell_session.store_match_launch_config(launch_config)
	var stored_launch_config := shell_session.consume_match_launch_config()
	_assert(stored_launch_config != null, "ShellSession deberia transportar launch configs de practica.")
	if stored_launch_config != null:
		_assert(
			String(stored_launch_config.entry_context) == MatchLaunchConfig.ENTRY_CONTEXT_PRACTICE,
			"El contexto `practice` deberia sobrevivir al salto de escena."
		)
		_assert(
			String(stored_launch_config.practice_module_id) == "impacto",
			"ShellSession deberia clonar tambien el modulo de practica."
		)

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
