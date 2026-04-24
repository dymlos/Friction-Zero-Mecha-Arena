extends RefCounted
class_name InputPromptCatalog

const PROFILE_GENERIC := "generic"
const PROFILE_XBOX := "xbox"
const PROFILE_PLAYSTATION := "playstation"
const PROFILE_NINTENDO := "nintendo"

const CONTROL_MODE_HARD := 1

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
