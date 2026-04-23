extends Resource
class_name LocalSession

const RobotBase = preload("res://scripts/robots/robot_base.gd")

enum SlotState { EMPTY, KEYBOARD, JOYPAD, DISCONNECTED }

const SLOT_STATE_LABELS := {
	SlotState.EMPTY: "empty",
	SlotState.KEYBOARD: "keyboard",
	SlotState.JOYPAD: "joypad",
	SlotState.DISCONNECTED: "disconnected",
}

@export_range(1, 8) var max_local_slots := 8
@export_range(1, 8) var active_match_slots := 4

var _slots: Dictionary = {}


func configure(max_slots: int, active_slots: int) -> void:
	max_local_slots = max(1, max_slots)
	active_match_slots = clampi(active_slots, 1, max_local_slots)
	reset_slots()


func reset_slots() -> void:
	_slots.clear()
	for slot in range(1, max_local_slots + 1):
		_slots[slot] = _build_empty_slot(slot)


func get_max_local_slots() -> int:
	return max_local_slots


func get_active_match_slots() -> int:
	return min(active_match_slots, max_local_slots)


func get_slot_state(slot: int) -> String:
	return str(SLOT_STATE_LABELS.get(_get_slot_info(slot).state, "empty"))


func get_slot_device_id(slot: int) -> int:
	return int(_get_slot_info(slot).device_id)


func get_slot_keyboard_profile(slot: int) -> int:
	return int(_get_slot_info(slot).keyboard_profile)


func get_slot_player_index(slot: int) -> int:
	return int(_get_slot_info(slot).player_index)


func get_slot_control_mode(slot: int) -> int:
	return int(_get_slot_info(slot).control_mode)


func is_slot_occupied(slot: int) -> bool:
	var slot_state := int(_get_slot_info(slot).state)
	return slot_state != SlotState.EMPTY


func has_unique_slot_ownership() -> bool:
	var seen_player_indices := {}
	for slot in range(1, get_active_match_slots() + 1):
		var slot_info: Dictionary = _get_slot_info(slot)
		if int(slot_info.get("state", SlotState.EMPTY)) == SlotState.EMPTY:
			return false

		var player_index := int(slot_info.get("player_index", 0))
		if player_index <= 0 or seen_player_indices.has(player_index):
			return false

		seen_player_indices[player_index] = true

	return seen_player_indices.size() == get_active_match_slots()


func assign_keyboard_slot(
	slot: int,
	keyboard_profile: int,
	control_mode: int = RobotBase.ControlMode.EASY
) -> void:
	if not _slots.has(slot):
		return

	_slots[slot] = {
		"slot": slot,
		"state": SlotState.KEYBOARD,
		"player_index": slot,
		"keyboard_profile": keyboard_profile,
		"device_id": -1,
		"control_mode": control_mode,
	}


func assign_joypad_slot(
	slot: int,
	device_id: int,
	control_mode: int = RobotBase.ControlMode.EASY
) -> void:
	if not _slots.has(slot):
		return

	_slots[slot] = {
		"slot": slot,
		"state": SlotState.JOYPAD,
		"player_index": slot,
		"keyboard_profile": RobotBase.KeyboardProfile.NONE,
		"device_id": device_id,
		"control_mode": control_mode,
	}


func mark_slot_disconnected(slot: int) -> void:
	if not _slots.has(slot):
		return

	var slot_info: Dictionary = _get_slot_info(slot)
	if int(slot_info.get("device_id", -1)) < 0:
		return

	slot_info["state"] = SlotState.DISCONNECTED
	slot_info["keyboard_profile"] = RobotBase.KeyboardProfile.NONE
	_slots[slot] = slot_info


func restore_joypad_slot(device_id: int) -> int:
	for slot in range(1, max_local_slots + 1):
		var slot_info: Dictionary = _get_slot_info(slot)
		if int(slot_info.get("state", SlotState.EMPTY)) != SlotState.DISCONNECTED:
			continue
		if int(slot_info.get("device_id", -1)) != device_id:
			continue

		slot_info["state"] = SlotState.JOYPAD
		_slots[slot] = slot_info
		return slot

	return -1


func apply_to_robot(robot: RobotBase, slot: int) -> void:
	if robot == null or not _slots.has(slot):
		return

	var slot_info: Dictionary = _get_slot_info(slot)
	robot.player_index = int(slot_info.get("player_index", slot))
	robot.is_player_controlled = int(slot_info.get("state", SlotState.EMPTY)) != SlotState.EMPTY
	robot.control_mode = int(slot_info.get("control_mode", RobotBase.ControlMode.EASY))
	robot.keyboard_profile = int(slot_info.get("keyboard_profile", RobotBase.KeyboardProfile.NONE))
	robot.joypad_device = int(slot_info.get("device_id", -1))


func _build_empty_slot(slot: int) -> Dictionary:
	return {
		"slot": slot,
		"state": SlotState.EMPTY,
		"player_index": slot,
		"keyboard_profile": RobotBase.KeyboardProfile.NONE,
		"device_id": -1,
		"control_mode": RobotBase.ControlMode.EASY,
	}


func _get_slot_info(slot: int) -> Dictionary:
	if _slots.is_empty():
		reset_slots()

	return _slots.get(slot, _build_empty_slot(slot))
