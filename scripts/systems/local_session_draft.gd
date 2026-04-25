extends Resource
class_name LocalSessionDraft

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const LocalSessionBuilder = preload("res://scripts/systems/local_session_builder.gd")
const InputPromptCatalog = preload("res://scripts/systems/input_prompt_catalog.gd")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const MapCatalog = preload("res://scripts/systems/map_catalog.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")

const INPUT_SOURCE_KEYBOARD := "keyboard"
const INPUT_SOURCE_JOYPAD := "joypad"
const TEAM_BLUE := 1
const TEAM_RED := 2

@export_range(1, 8) var max_slots := 4
@export var match_mode: MatchController.MatchMode = MatchController.MatchMode.TEAMS
@export var selected_map_id := ""

var _slots: Dictionary = {}
var _selected_mode_variant_by_mode: Dictionary = {}


func _init() -> void:
	configure(max_slots)


func configure(next_max_slots: int) -> void:
	max_slots = clampi(next_max_slots, 1, 8)
	for slot in range(1, max_slots + 1):
		if not _slots.has(slot):
			_slots[slot] = _build_default_slot(slot)
	for slot_key in _slots.keys():
		if int(slot_key) > max_slots:
			_slots.erase(slot_key)


func set_match_mode(next_match_mode: int) -> void:
	match_mode = next_match_mode as MatchController.MatchMode
	selected_map_id = MapCatalog.sanitize_map_id(selected_map_id, match_mode, build_active_slot_specs(max_slots).size())
	_ensure_mode_variant_for_current_mode()


func set_selected_map_id(map_id: String, active_slots: int = 4) -> void:
	selected_map_id = MapCatalog.sanitize_map_id(map_id, match_mode, active_slots)


func get_selected_map_id(active_slots: int = 4) -> String:
	selected_map_id = MapCatalog.sanitize_map_id(selected_map_id, match_mode, active_slots)
	return selected_map_id


func cycle_selected_map(active_slots: int = 4, direction: int = 1) -> void:
	var candidates := MapCatalog.get_maps_for(match_mode, active_slots)
	if candidates.is_empty():
		selected_map_id = ""
		return
	var current_id := get_selected_map_id(active_slots)
	var current_index := 0
	for index in range(candidates.size()):
		if String(candidates[index].get("id", "")) == current_id:
			current_index = index
			break
	selected_map_id = String(candidates[wrapi(current_index + direction, 0, candidates.size())].get("id", ""))


func get_selected_mode_variant_id() -> String:
	return _ensure_mode_variant_for_current_mode()


func set_selected_mode_variant_id(variant_id: String) -> void:
	_selected_mode_variant_by_mode[int(match_mode)] = MatchModeVariantCatalog.sanitize_variant_id(match_mode, variant_id)


func cycle_mode_variant(direction: int = 1) -> void:
	var variants := MatchModeVariantCatalog.get_enabled_variants(match_mode)
	if variants.is_empty():
		set_selected_mode_variant_id("")
		return
	var current_id := get_selected_mode_variant_id()
	var current_index := 0
	for index in range(variants.size()):
		if String(variants[index].get("id", "")) == current_id:
			current_index = index
			break
	set_selected_mode_variant_id(String(variants[wrapi(current_index + direction, 0, variants.size())].get("id", "")))


func get_mode_variant_summary_line() -> String:
	return MatchModeVariantCatalog.get_setup_summary_line(match_mode, get_selected_mode_variant_id())


func set_slot_active(player_slot: int, active: bool) -> void:
	if not _slots.has(player_slot):
		return
	var slot_info: Dictionary = _slots[player_slot]
	slot_info["active"] = active
	_slots[player_slot] = slot_info


func set_slot_control_mode(player_slot: int, control_mode: int) -> void:
	if not _slots.has(player_slot):
		return
	var slot_info: Dictionary = _slots[player_slot]
	slot_info["control_mode"] = _sanitize_control_mode(control_mode)
	_slots[player_slot] = slot_info


func set_slot_team_id(player_slot: int, team_id: int) -> void:
	if not _slots.has(player_slot):
		return
	var slot_info: Dictionary = _slots[player_slot]
	slot_info["team_id"] = _sanitize_team_id(team_id, player_slot)
	_slots[player_slot] = slot_info


func toggle_slot_team_id(player_slot: int) -> void:
	if not _slots.has(player_slot):
		return
	var current_team := int(_slots[player_slot].get("team_id", _get_default_team_id(player_slot)))
	set_slot_team_id(player_slot, TEAM_RED if current_team == TEAM_BLUE else TEAM_BLUE)


func toggle_slot_control_mode(player_slot: int) -> void:
	if not _slots.has(player_slot):
		return
	var current_mode := int(_slots[player_slot].get("control_mode", RobotBase.ControlMode.EASY))
	set_slot_control_mode(
		player_slot,
		RobotBase.ControlMode.EASY if current_mode == RobotBase.ControlMode.HARD else RobotBase.ControlMode.HARD
	)


func set_slot_input_source(player_slot: int, input_source: String) -> void:
	if not _slots.has(player_slot):
		return
	var slot_info: Dictionary = _slots[player_slot]
	var sanitized_source := _sanitize_input_source(input_source)
	slot_info["input_source"] = sanitized_source
	if sanitized_source == INPUT_SOURCE_KEYBOARD:
		slot_info["keyboard_profile"] = LocalSessionBuilder.get_default_keyboard_profile_for_slot(player_slot)
		slot_info["device_id"] = -1
		slot_info["device_connected"] = true
	else:
		slot_info["keyboard_profile"] = RobotBase.KeyboardProfile.NONE
	_slots[player_slot] = slot_info


func set_slot_roster_entry(player_slot: int, roster_entry_id: String) -> void:
	if not _slots.has(player_slot):
		return
	var entry := RosterCatalog.get_competitive_entry(roster_entry_id)
	if entry.is_empty():
		entry = RosterCatalog.get_competitive_entry(RosterCatalog.get_default_entry_id_for_slot(player_slot))
	var slot_info: Dictionary = _slots[player_slot]
	slot_info["roster_entry_id"] = String(entry.get("id", ""))
	slot_info["archetype_path"] = String(entry.get("config_path", ""))
	_slots[player_slot] = slot_info


func cycle_slot_roster_entry(player_slot: int, direction: int = 1) -> void:
	if not _slots.has(player_slot):
		return
	var entry_ids := RosterCatalog.get_competitive_entry_ids()
	if entry_ids.is_empty():
		return
	var current_id := String(_slots[player_slot].get("roster_entry_id", RosterCatalog.get_default_entry_id_for_slot(player_slot)))
	var current_index := entry_ids.find(current_id)
	if current_index < 0:
		current_index = entry_ids.find(RosterCatalog.get_default_entry_id_for_slot(player_slot))
	set_slot_roster_entry(player_slot, String(entry_ids[wrapi(current_index + direction, 0, entry_ids.size())]))


func reserve_joypad_for_slot(player_slot: int, device_id: int, connected: bool = true) -> void:
	if not _slots.has(player_slot):
		return
	var slot_info: Dictionary = _slots[player_slot]
	slot_info["active"] = true
	slot_info["input_source"] = INPUT_SOURCE_JOYPAD
	slot_info["keyboard_profile"] = RobotBase.KeyboardProfile.NONE
	slot_info["device_id"] = device_id
	slot_info["device_connected"] = connected
	_slots[player_slot] = slot_info


func cycle_slot_state(player_slot: int) -> void:
	if not _slots.has(player_slot):
		return
	var slot_info: Dictionary = _slots[player_slot]
	if not bool(slot_info.get("active", true)):
		set_slot_active(player_slot, true)
		set_slot_input_source(player_slot, INPUT_SOURCE_KEYBOARD)
		set_slot_control_mode(player_slot, RobotBase.ControlMode.EASY)
		return
	if String(slot_info.get("input_source", INPUT_SOURCE_KEYBOARD)) == INPUT_SOURCE_KEYBOARD:
		if int(slot_info.get("control_mode", RobotBase.ControlMode.EASY)) == RobotBase.ControlMode.EASY:
			set_slot_control_mode(player_slot, RobotBase.ControlMode.HARD)
		else:
			reserve_joypad_for_slot(player_slot, int(slot_info.get("device_id", player_slot - 1)), false)
			set_slot_control_mode(player_slot, RobotBase.ControlMode.EASY)
		return
	set_slot_active(player_slot, false)


func is_slot_launchable(player_slot: int) -> bool:
	if not _slots.has(player_slot):
		return false
	var slot_info: Dictionary = _slots[player_slot]
	if not bool(slot_info.get("active", false)):
		return false
	if String(slot_info.get("input_source", INPUT_SOURCE_KEYBOARD)) == INPUT_SOURCE_JOYPAD:
		return bool(slot_info.get("device_connected", false)) and int(slot_info.get("device_id", -1)) >= 0
	return int(slot_info.get("keyboard_profile", RobotBase.KeyboardProfile.NONE)) != RobotBase.KeyboardProfile.NONE


func can_launch(max_active_slots: int = -1) -> bool:
	var active_specs := build_active_slot_specs(max_active_slots)
	if active_specs.is_empty():
		return false
	for slot_spec in active_specs:
		var slot := int(slot_spec.get("slot", -1))
		if not is_slot_launchable(slot):
			return false
	return true


func get_slot_summary_lines(max_visible_slots: int = -1) -> Array[String]:
	var lines: Array[String] = []
	var visible_slots := max_slots if max_visible_slots <= 0 else mini(max_visible_slots, max_slots)
	for slot in range(1, visible_slots + 1):
		lines.append(_build_slot_summary_line(slot))
	return lines


func build_active_slot_specs(max_active_slots: int = -1) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	var limit := max_slots if max_active_slots <= 0 else mini(max_active_slots, max_slots)
	for slot in range(1, limit + 1):
		var slot_info: Dictionary = _slots.get(slot, _build_default_slot(slot))
		if not bool(slot_info.get("active", false)):
			continue
		specs.append(_sanitize_slot_spec(slot_info, slot))
	return specs


func get_slot_info(player_slot: int) -> Dictionary:
	return (_slots.get(player_slot, _build_default_slot(player_slot)) as Dictionary).duplicate(true)


func copy_from(other: LocalSessionDraft) -> void:
	if other == null:
		return
	max_slots = other.max_slots
	match_mode = other.match_mode
	selected_map_id = other.selected_map_id
	_selected_mode_variant_by_mode = other._selected_mode_variant_by_mode.duplicate(true)
	_slots.clear()
	for slot in range(1, max_slots + 1):
		_slots[slot] = other.get_slot_info(slot)


func _build_default_slot(player_slot: int) -> Dictionary:
	var roster_entry_id := RosterCatalog.get_default_entry_id_for_slot(player_slot)
	var entry := RosterCatalog.get_competitive_entry(roster_entry_id)
	return {
		"slot": player_slot,
		"active": player_slot <= 4,
		"control_mode": RobotBase.ControlMode.EASY,
		"input_source": INPUT_SOURCE_KEYBOARD,
		"keyboard_profile": LocalSessionBuilder.get_default_keyboard_profile_for_slot(player_slot),
		"device_id": -1,
		"device_connected": true,
		"team_id": _get_default_team_id(player_slot),
		"roster_entry_id": roster_entry_id,
		"archetype_path": String(entry.get("config_path", "")),
	}


func _build_slot_summary_line(player_slot: int) -> String:
	var slot_info: Dictionary = _slots.get(player_slot, _build_default_slot(player_slot))
	var roster_entry := RosterCatalog.get_competitive_entry(String(slot_info.get("roster_entry_id", "")))
	var roster_label := String(roster_entry.get("label", slot_info.get("roster_entry_id", "")))
	if not bool(slot_info.get("active", false)):
		return "P%s | inactivo | %s" % [player_slot, roster_label]
	var mode_label := "Avanzado" if int(slot_info.get("control_mode", RobotBase.ControlMode.EASY)) == RobotBase.ControlMode.HARD else "Simple"
	var input_source := String(slot_info.get("input_source", INPUT_SOURCE_KEYBOARD))
	if input_source == INPUT_SOURCE_JOYPAD:
		var device_id := int(slot_info.get("device_id", -1))
		var connection_label := "conectado" if bool(slot_info.get("device_connected", false)) else "desconectado"
		var team_label := _get_team_label(int(slot_info.get("team_id", _get_default_team_id(player_slot))))
		var team_segment := ""
		if match_mode == MatchController.MatchMode.TEAMS:
			team_segment = " | %s" % team_label
		return "P%s%s | %s | joy %s %s | %s | %s" % [
			player_slot,
			team_segment,
			mode_label,
			device_id,
			connection_label,
			roster_label,
			InputPromptCatalog.get_joypad_short_hint(device_id),
		]
	var profile := int(slot_info.get("keyboard_profile", LocalSessionBuilder.get_default_keyboard_profile_for_slot(player_slot)))
	var team_label := _get_team_label(int(slot_info.get("team_id", _get_default_team_id(player_slot))))
	var team_segment := ""
	if match_mode == MatchController.MatchMode.TEAMS:
		team_segment = " | %s" % team_label
	return "P%s%s | %s | teclado %s | %s" % [player_slot, team_segment, mode_label, LocalSessionBuilder.get_keyboard_profile_label(profile), roster_label]


func _sanitize_slot_spec(slot_info: Dictionary, fallback_slot: int) -> Dictionary:
	var slot := int(slot_info.get("slot", fallback_slot))
	var input_source := _sanitize_input_source(String(slot_info.get("input_source", INPUT_SOURCE_KEYBOARD)))
	var keyboard_profile := int(slot_info.get("keyboard_profile", LocalSessionBuilder.get_default_keyboard_profile_for_slot(slot)))
	if input_source == INPUT_SOURCE_KEYBOARD and keyboard_profile == RobotBase.KeyboardProfile.NONE:
		keyboard_profile = LocalSessionBuilder.get_default_keyboard_profile_for_slot(slot)
	if input_source == INPUT_SOURCE_JOYPAD:
		keyboard_profile = RobotBase.KeyboardProfile.NONE
	return {
		"slot": slot,
		"control_mode": _sanitize_control_mode(int(slot_info.get("control_mode", RobotBase.ControlMode.EASY))),
		"input_source": input_source,
		"keyboard_profile": keyboard_profile,
		"device_id": int(slot_info.get("device_id", -1)),
		"device_connected": bool(slot_info.get("device_connected", true)),
		"team_id": _sanitize_team_id(int(slot_info.get("team_id", _get_default_team_id(slot))), slot) if match_mode == MatchController.MatchMode.TEAMS else 0,
		"roster_entry_id": String(slot_info.get("roster_entry_id", RosterCatalog.get_default_entry_id_for_slot(slot))),
		"archetype_path": String(slot_info.get("archetype_path", "")),
	}


func _sanitize_input_source(input_source: String) -> String:
	return INPUT_SOURCE_JOYPAD if input_source == INPUT_SOURCE_JOYPAD else INPUT_SOURCE_KEYBOARD


func _sanitize_control_mode(control_mode: int) -> int:
	return RobotBase.ControlMode.HARD if control_mode == RobotBase.ControlMode.HARD else RobotBase.ControlMode.EASY


func _sanitize_team_id(team_id: int, player_slot: int) -> int:
	return TEAM_RED if team_id == TEAM_RED else TEAM_BLUE


func _get_default_team_id(player_slot: int) -> int:
	return TEAM_BLUE if player_slot % 2 == 1 else TEAM_RED


func _get_team_label(team_id: int) -> String:
	return "Rojo" if team_id == TEAM_RED else "Azul"


func _ensure_mode_variant_for_current_mode() -> String:
	var mode_key := int(match_mode)
	var current_id := String(_selected_mode_variant_by_mode.get(mode_key, ""))
	var sanitized_id := MatchModeVariantCatalog.sanitize_variant_id(match_mode, current_id)
	_selected_mode_variant_by_mode[mode_key] = sanitized_id
	return sanitized_id
