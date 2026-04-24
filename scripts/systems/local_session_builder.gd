extends RefCounted
class_name LocalSessionBuilder

const LocalSession = preload("res://scripts/systems/local_session.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const INPUT_SOURCE_KEYBOARD := "keyboard"
const INPUT_SOURCE_JOYPAD := "joypad"


static func build_from_slot_specs(slot_specs: Array, default_config: LocalSession = null) -> LocalSession:
	var session := default_config.duplicate(true) as LocalSession if default_config != null else LocalSession.new()
	if session == null:
		session = LocalSession.new()

	var sanitized_specs := sanitize_slot_specs(slot_specs)
	var max_slot := 1
	for slot_spec in sanitized_specs:
		max_slot = maxi(max_slot, int(slot_spec.get("slot", 1)))
	session.configure(maxi(session.get_max_local_slots(), max_slot), maxi(sanitized_specs.size(), 1))

	for slot_spec in sanitized_specs:
		var slot := int(slot_spec.get("slot", 0))
		if slot <= 0:
			continue
		var control_mode := int(slot_spec.get("control_mode", RobotBase.ControlMode.EASY))
		var input_source := String(slot_spec.get("input_source", INPUT_SOURCE_KEYBOARD))
		if input_source == INPUT_SOURCE_JOYPAD:
			var device_id := int(slot_spec.get("device_id", -1))
			if device_id >= 0:
				session.assign_joypad_slot(slot, device_id, control_mode)
				if not bool(slot_spec.get("device_connected", true)):
					session.mark_slot_disconnected(slot)
			continue

		session.assign_keyboard_slot(
			slot,
			_sanitize_keyboard_profile(
				int(slot_spec.get("keyboard_profile", get_default_keyboard_profile_for_slot(slot))),
				slot
			),
			control_mode
		)

	return session


static func sanitize_slot_specs(slot_specs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_slots := {}
	for slot_spec_variant in slot_specs:
		if not (slot_spec_variant is Dictionary):
			continue
		var slot_spec := slot_spec_variant as Dictionary
		var slot := int(slot_spec.get("slot", -1))
		if slot <= 0 or slot > 8 or seen_slots.has(slot):
			continue
		var input_source := String(slot_spec.get("input_source", INPUT_SOURCE_KEYBOARD))
		if input_source != INPUT_SOURCE_JOYPAD:
			input_source = INPUT_SOURCE_KEYBOARD
		var control_mode := RobotBase.ControlMode.HARD if int(slot_spec.get("control_mode", RobotBase.ControlMode.EASY)) == RobotBase.ControlMode.HARD else RobotBase.ControlMode.EASY
		var keyboard_profile := _sanitize_keyboard_profile(
			int(slot_spec.get("keyboard_profile", get_default_keyboard_profile_for_slot(slot))),
			slot
		)
		if input_source == INPUT_SOURCE_JOYPAD:
			keyboard_profile = RobotBase.KeyboardProfile.NONE
		seen_slots[slot] = true
		result.append({
			"slot": slot,
			"control_mode": control_mode,
			"input_source": input_source,
			"keyboard_profile": keyboard_profile,
			"device_id": int(slot_spec.get("device_id", -1)),
			"device_connected": bool(slot_spec.get("device_connected", true)),
		})

	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("slot", 0)) < int(b.get("slot", 0))
	)
	return result


static func get_default_keyboard_profile_for_slot(player_slot: int) -> int:
	match player_slot:
		1:
			return RobotBase.KeyboardProfile.WASD_SPACE
		2:
			return RobotBase.KeyboardProfile.ARROWS_ENTER
		3:
			return RobotBase.KeyboardProfile.NUMPAD
		4:
			return RobotBase.KeyboardProfile.IJKL
		_:
			return RobotBase.KeyboardProfile.NONE


static func get_keyboard_profile_label(keyboard_profile: int) -> String:
	return String(RobotBase.KEYBOARD_PROFILE_LABELS.get(keyboard_profile, "sin teclado"))


static func _sanitize_keyboard_profile(keyboard_profile: int, player_slot: int) -> int:
	if keyboard_profile in [
		RobotBase.KeyboardProfile.WASD_SPACE,
		RobotBase.KeyboardProfile.ARROWS_ENTER,
		RobotBase.KeyboardProfile.NUMPAD,
		RobotBase.KeyboardProfile.IJKL,
	]:
		return keyboard_profile
	return get_default_keyboard_profile_for_slot(player_slot)
