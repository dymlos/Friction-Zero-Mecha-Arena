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

	InputPromptCatalog.ensure_menu_input_actions()
	var menu_help := InputPromptCatalog.get_menu_navigation_help_line(true, true)
	_assert(menu_help.contains("A aceptar"), "La ayuda de menu debe indicar A para aceptar.")
	_assert(menu_help.contains("B volver"), "La ayuda de menu debe indicar B para volver.")
	_assert(menu_help.contains("Start iniciar"), "La ayuda de menu debe indicar Start para iniciar.")
	_assert(menu_help.contains("Select pausa"), "La ayuda de menu debe indicar Select para pausa.")
	_assert(_action_has_joy_button("ui_accept", JOY_BUTTON_A, -1), "ui_accept debe aceptar A de cualquier joystick en la shell.")
	_assert(_action_has_joy_button("ui_cancel", JOY_BUTTON_B, -1), "ui_cancel debe aceptar B de cualquier joystick en la shell.")
	_assert(_action_has_joy_button(InputPromptCatalog.MENU_START_ACTION, JOY_BUTTON_START, -1), "Start debe quedar mapeado como accion de inicio de menu.")
	_assert(_action_has_joy_button(InputPromptCatalog.MENU_PAUSE_ACTION, JOY_BUTTON_BACK, -1), "Select debe quedar mapeado como accion de pausa de menu.")

	var robot := RobotBase.new()
	robot.is_player_controlled = true
	robot.player_index = 3
	robot.keyboard_profile = RobotBase.KeyboardProfile.NONE
	robot.joypad_device = 5
	robot.refresh_input_setup()
	_assert(_action_has_joy_button("p3_attack", JOY_BUTTON_A, 5), "El slot con joystick debe mapear A para aceptar/atacar por dispositivo.")
	_assert(_action_has_joy_button("p3_menu_back", JOY_BUTTON_B, 5), "El slot con joystick debe mapear B para volver por dispositivo.")
	_assert(_action_has_joy_button("p3_pause", JOY_BUTTON_BACK, 5), "El slot con joystick debe mapear Select para pausa por dispositivo.")
	robot.free()
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _action_has_joy_button(action_name: String, button_index: int, device_id: int) -> bool:
	if not InputMap.has_action(StringName(action_name)):
		return false

	for event in InputMap.action_get_events(StringName(action_name)):
		if not (event is InputEventJoypadButton):
			continue
		if int(event.button_index) == button_index and int(event.device) == device_id:
			return true
	return false


func _finish() -> void:
	quit(1 if _failed else 0)
