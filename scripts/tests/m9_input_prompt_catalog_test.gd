extends SceneTree

const InputPromptCatalog = preload("res://scripts/systems/input_prompt_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var keyboard_hint := InputPromptCatalog.get_keyboard_reference_hint(
		RobotBase.KeyboardProfile.WASD_SPACE,
		RobotBase.ControlMode.HARD
	)
	_assert(keyboard_hint.contains("mueve WASD"), "Prompt teclado debe incluir movimiento.")
	_assert(keyboard_hint.contains("aim TFGX"), "Prompt Hard debe incluir aim dedicado.")
	_assert(keyboard_hint.contains("ataca Space"), "Prompt teclado debe incluir ataque.")

	var xbox_hint := InputPromptCatalog.get_joypad_reference_hint_for_name("Xbox Wireless Controller", RobotBase.ControlMode.HARD)
	_assert(xbox_hint.contains("ataca A"), "Xbox debe mostrar boton A para ataque.")
	_assert(xbox_hint.contains("suelta X"), "Xbox debe mostrar X para soltar.")
	_assert(xbox_hint.contains("overdrive Y"), "Xbox debe mostrar Y para overdrive.")

	var ps_hint := InputPromptCatalog.get_joypad_reference_hint_for_name("DualSense Wireless Controller", RobotBase.ControlMode.EASY)
	_assert(ps_hint.contains("ataca Cruz"), "PlayStation debe mostrar Cruz para ataque.")
	_assert(ps_hint.contains("suelta Cuadrado"), "PlayStation debe mostrar Cuadrado para soltar.")

	var generic_hint := InputPromptCatalog.get_joypad_reference_hint_for_name("", RobotBase.ControlMode.EASY)
	_assert(generic_hint.contains("ataca Sur"), "Joypad desconocido debe usar labels direccionales genericos.")
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
