extends Resource
class_name MatchLaunchConfig

const MatchConfig = preload("res://scripts/systems/match_config.gd")
const LocalSessionBuilder = preload("res://scripts/systems/local_session_builder.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const UserSettingsStore = preload("res://scripts/autoload/user_settings_store.gd")

const ENTRY_CONTEXT_PLAYER_SHELL := "player_shell"
const ENTRY_CONTEXT_PRACTICE := "practice"
const DEFAULT_MAX_LOCAL_SLOTS := 8

@export var match_mode := 0
@export var target_scene_path := ""
@export var map_id := ""
@export var entry_context := ENTRY_CONTEXT_PLAYER_SHELL
@export var practice_module_id := ""
@export var hud_detail_mode: MatchConfig.HudDetailMode = MatchConfig.HudDetailMode.EXPLICIT
@export var auto_restart_on_match_end := false
@export var local_slots: Array[Dictionary] = []


func configure_for_local_match(
	next_match_mode: int,
	next_target_scene_path: String,
	slot_specs: Array,
	next_map_id: String = ""
) -> void:
	match_mode = next_match_mode
	target_scene_path = next_target_scene_path
	map_id = next_map_id
	entry_context = ENTRY_CONTEXT_PLAYER_SHELL
	auto_restart_on_match_end = false
	hud_detail_mode = _resolve_effective_hud_detail_mode()
	local_slots = _sanitize_local_slots(slot_specs)


func configure_for_practice(
	module_id: String,
	next_target_scene_path: String,
	slot_specs: Array
) -> void:
	match_mode = 0
	target_scene_path = next_target_scene_path
	map_id = ""
	entry_context = ENTRY_CONTEXT_PRACTICE
	practice_module_id = module_id
	auto_restart_on_match_end = false
	hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT
	local_slots = _sanitize_local_slots(slot_specs)


func duplicate_for_runtime() -> MatchLaunchConfig:
	return duplicate(true) as MatchLaunchConfig


func _sanitize_local_slots(slot_specs: Array) -> Array[Dictionary]:
	return LocalSessionBuilder.sanitize_slot_specs(slot_specs)


func _resolve_effective_hud_detail_mode() -> MatchConfig.HudDetailMode:
	var settings_store := UserSettingsStore.get_singleton()
	if settings_store == null:
		return MatchConfig.HudDetailMode.EXPLICIT
	return settings_store.get_default_hud_detail_mode()
