extends Resource
class_name MatchLaunchConfig

const MatchConfig = preload("res://scripts/systems/match_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const ENTRY_CONTEXT_PLAYER_SHELL := "player_shell"
const DEFAULT_MAX_LOCAL_SLOTS := 8

@export var match_mode := 0
@export var target_scene_path := ""
@export var entry_context := ENTRY_CONTEXT_PLAYER_SHELL
@export var hud_detail_mode: MatchConfig.HudDetailMode = MatchConfig.HudDetailMode.EXPLICIT
@export var local_slots: Array[Dictionary] = []


func configure_for_local_match(
	next_match_mode: int,
	next_target_scene_path: String,
	slot_specs: Array
) -> void:
	match_mode = next_match_mode
	target_scene_path = next_target_scene_path
	entry_context = ENTRY_CONTEXT_PLAYER_SHELL
	local_slots = _sanitize_local_slots(slot_specs)


func duplicate_for_runtime() -> MatchLaunchConfig:
	return duplicate(true) as MatchLaunchConfig


func _sanitize_local_slots(slot_specs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_slots := {}
	for slot_spec_variant in slot_specs:
		if not (slot_spec_variant is Dictionary):
			continue

		var slot_spec := slot_spec_variant as Dictionary
		var slot := int(slot_spec.get("slot", -1))
		if slot <= 0 or slot > DEFAULT_MAX_LOCAL_SLOTS:
			continue
		if seen_slots.has(slot):
			continue

		var control_mode := int(slot_spec.get("control_mode", RobotBase.ControlMode.EASY))
		if control_mode != RobotBase.ControlMode.HARD:
			control_mode = RobotBase.ControlMode.EASY

		seen_slots[slot] = true
		result.append({
			"slot": slot,
			"control_mode": control_mode,
		})

	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("slot", 0)) < int(b.get("slot", 0))
	)
	return result
