extends RefCounted
class_name InputPromptCatalog

const PROFILE_GENERIC := "generic"
const PROFILE_XBOX := "xbox"
const PROFILE_PLAYSTATION := "playstation"
const PROFILE_NINTENDO := "nintendo"

const CONTROL_MODE_HARD := 1
const MENU_START_ACTION := "fz_menu_start"
const MENU_PAUSE_ACTION := "fz_menu_pause"

const KEYBOARD_PROFILE_LABELS := {
	0: "sin teclado",
	1: "WASD",
	2: "flechas",
	3: "numpad",
	4: "IJKL",
}

const KEYBOARD_PROFILE_HARD_AIM_LABELS := {
	1: "TFGX",
	2: "Ins/Del/PgUp/PgDn",
	3: "KP7/KP9/KP//KP*",
}

const KEYBOARD_PROFILE_ATTACK_LABELS := {
	1: "Space",
	2: "Enter",
	3: "KP0",
	4: "U",
}

const KEYBOARD_PROFILE_ENERGY_LABELS := {
	1: "Q/E",
	2: ",/.",
	3: "KP1/KP3",
	4: "Y/H",
}

const KEYBOARD_PROFILE_THROW_LABELS := {
	1: "C",
	2: "/",
	3: "KP+",
	4: "N",
}

const KEYBOARD_PROFILE_OVERDRIVE_LABELS := {
	1: "R",
	2: "M",
	3: "KP5",
	4: "B",
}


static func get_keyboard_reference_hint(keyboard_profile: int, control_mode: int) -> String:
	var segments: Array[String] = ["mueve %s" % get_keyboard_move_label(keyboard_profile)]
	if control_mode == CONTROL_MODE_HARD:
		segments.append("aim %s" % get_keyboard_aim_label(keyboard_profile))
	segments.append("ataca %s" % get_keyboard_attack_label(keyboard_profile))
	segments.append("energia %s" % get_keyboard_energy_label(keyboard_profile))
	segments.append("overdrive %s" % get_keyboard_overdrive_label(keyboard_profile))
	segments.append("suelta %s" % get_keyboard_throw_label(keyboard_profile))
	return " | ".join(segments)


static func get_keyboard_short_hint(keyboard_profile: int, control_mode: int) -> String:
	var move_label := get_keyboard_move_label(keyboard_profile)
	if control_mode == CONTROL_MODE_HARD:
		return "%s + aim %s" % [move_label, get_keyboard_aim_label(keyboard_profile)]
	return move_label


static func get_keyboard_support_hint(keyboard_profile: int) -> String:
	return "usa %s | objetivo %s" % [
		get_keyboard_throw_label(keyboard_profile),
		get_keyboard_energy_label(keyboard_profile),
	]


static func get_keyboard_move_label(keyboard_profile: int) -> String:
	return String(KEYBOARD_PROFILE_LABELS.get(keyboard_profile, "teclado"))


static func get_keyboard_aim_label(keyboard_profile: int) -> String:
	return String(KEYBOARD_PROFILE_HARD_AIM_LABELS.get(keyboard_profile, "stick derecho"))


static func get_keyboard_attack_label(keyboard_profile: int) -> String:
	return String(KEYBOARD_PROFILE_ATTACK_LABELS.get(keyboard_profile, "?"))


static func get_keyboard_energy_label(keyboard_profile: int) -> String:
	return String(KEYBOARD_PROFILE_ENERGY_LABELS.get(keyboard_profile, "?/?"))


static func get_keyboard_overdrive_label(keyboard_profile: int) -> String:
	return String(KEYBOARD_PROFILE_OVERDRIVE_LABELS.get(keyboard_profile, "?"))


static func get_keyboard_throw_label(keyboard_profile: int) -> String:
	return String(KEYBOARD_PROFILE_THROW_LABELS.get(keyboard_profile, "?"))


static func get_joypad_reference_hint(device_id: int, control_mode: int) -> String:
	return get_joypad_reference_hint_for_name(Input.get_joy_name(device_id), control_mode)


static func get_joypad_reference_hint_for_name(device_name: String, control_mode: int) -> String:
	var profile := get_joypad_profile_for_name(device_name)
	var labels := get_joypad_button_labels(profile)
	var segments: Array[String] = ["mueve stick izq"]
	if control_mode == CONTROL_MODE_HARD:
		segments.append("aim stick der")
	segments.append("ataca %s" % String(labels.get("attack", "Sur")))
	segments.append("energia %s" % String(labels.get("energy", "LB/RB")))
	segments.append("overdrive %s" % String(labels.get("overdrive", "Norte")))
	segments.append("suelta %s" % String(labels.get("throw", "Oeste")))
	return " | ".join(segments)


static func get_joypad_short_hint(device_id: int) -> String:
	var labels := get_joypad_button_labels(get_joypad_profile_for_name(Input.get_joy_name(device_id)))
	return "joy %s | ataca %s" % [device_id, String(labels.get("attack", "Sur"))]


static func get_joypad_support_hint(device_id: int = -1) -> String:
	var device_name := Input.get_joy_name(device_id) if device_id >= 0 else ""
	var labels := get_joypad_button_labels(get_joypad_profile_for_name(device_name))
	return "usa %s | objetivo %s" % [
		String(labels.get("throw", "Oeste")),
		String(labels.get("energy", "LB/RB")),
	]


static func get_connected_joypad_lines() -> Array[String]:
	var lines: Array[String] = []
	var connected := Input.get_connected_joypads()
	if connected.is_empty():
		return ["Joypads | ninguno conectado"]
	for device_id in connected:
		var joy_name := Input.get_joy_name(int(device_id)).strip_edges()
		if joy_name.is_empty():
			joy_name = "Joypad"
		var labels := get_joypad_button_labels(get_joypad_profile_for_name(joy_name))
		lines.append("Joypad %s | %s | ataca %s | energia %s" % [
			int(device_id),
			joy_name,
			String(labels.get("attack", "Sur")),
			String(labels.get("energy", "LB/RB")),
		])
	return lines


static func ensure_menu_input_actions() -> void:
	_ensure_input_action("ui_accept")
	_ensure_input_action("ui_cancel")
	_ensure_input_action("ui_up")
	_ensure_input_action("ui_down")
	_ensure_input_action("ui_left")
	_ensure_input_action("ui_right")
	_ensure_input_action(MENU_START_ACTION)
	_ensure_input_action(MENU_PAUSE_ACTION)

	_add_joy_button_event("ui_accept", JOY_BUTTON_A)
	_add_joy_button_event("ui_cancel", JOY_BUTTON_B)
	_add_joy_button_event("ui_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button_event("ui_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy_button_event("ui_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button_event("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_button_event(MENU_START_ACTION, JOY_BUTTON_START)
	_add_joy_button_event(MENU_PAUSE_ACTION, JOY_BUTTON_BACK)

	_remove_joy_motion_events("ui_up")
	_remove_joy_motion_events("ui_down")
	_remove_joy_motion_events("ui_left")
	_remove_joy_motion_events("ui_right")


static func get_menu_navigation_help_line(include_start: bool = false, include_pause: bool = false) -> String:
	var segments: Array[String] = ["Stick/D-pad mover", "A aceptar", "B volver"]
	if include_start:
		segments.append("Start iniciar")
	if include_pause:
		segments.append("Select pausa")
	return " | ".join(segments)


static func get_pause_navigation_help_line() -> String:
	return "Stick/D-pad mover | A aceptar | B volver | Select reanudar"


static func get_joypad_profile_for_name(device_name: String) -> String:
	var normalized := device_name.to_lower()
	if normalized.contains("xbox") or normalized.contains("xinput"):
		return PROFILE_XBOX
	if normalized.contains("playstation") or normalized.contains("dualsense") or normalized.contains("dualshock"):
		return PROFILE_PLAYSTATION
	if normalized.contains("nintendo") or normalized.contains("switch") or normalized.contains("pro controller"):
		return PROFILE_NINTENDO
	return PROFILE_GENERIC


static func get_joypad_button_labels(profile: String) -> Dictionary:
	match profile:
		PROFILE_XBOX:
			return {"attack": "A", "throw": "X", "overdrive": "Y", "energy": "LB/RB"}
		PROFILE_PLAYSTATION:
			return {"attack": "Cruz", "throw": "Cuadrado", "overdrive": "Triangulo", "energy": "L1/R1"}
		PROFILE_NINTENDO:
			return {"attack": "B", "throw": "Y", "overdrive": "X", "energy": "L/R"}
		_:
			return {"attack": "Sur", "throw": "Oeste", "overdrive": "Norte", "energy": "LB/RB"}


static func _ensure_input_action(action_name: String, deadzone: float = 0.35) -> void:
	var action := StringName(action_name)
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
		return

	InputMap.action_set_deadzone(action, deadzone)


static func _add_joy_button_event(action_name: String, button_index: int) -> void:
	var action := StringName(action_name)
	if _has_joy_button_event(action, button_index):
		return

	var input_event := InputEventJoypadButton.new()
	input_event.device = -1
	input_event.button_index = button_index
	InputMap.action_add_event(action, input_event)


static func _add_joy_motion_event(action_name: String, axis: int, axis_value: float) -> void:
	var action := StringName(action_name)
	if _has_joy_motion_event(action, axis, axis_value):
		return

	var input_event := InputEventJoypadMotion.new()
	input_event.device = -1
	input_event.axis = axis
	input_event.axis_value = axis_value
	InputMap.action_add_event(action, input_event)


static func _remove_joy_motion_events(action_name: String) -> void:
	var action := StringName(action_name)
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			InputMap.action_erase_event(action, event)


static func _has_joy_button_event(action: StringName, button_index: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and int(event.button_index) == button_index and int(event.device) == -1:
			return true
	return false


static func _has_joy_motion_event(action: StringName, axis: int, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if not (event is InputEventJoypadMotion):
			continue
		if int(event.axis) != axis or int(event.device) != -1:
			continue
		if signf(float(event.axis_value)) == signf(axis_value):
			return true
	return false
