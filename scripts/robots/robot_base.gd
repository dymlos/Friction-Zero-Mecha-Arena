extends CharacterBody3D
class_name RobotBase

const DetachedPart = preload("res://scripts/robots/detached_part.gd")
const PulseBolt = preload("res://scripts/projectiles/pulse_bolt.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")

signal fell_into_void(robot: RobotBase)
signal respawned(robot: RobotBase)
signal prototype_attack_used(robot: RobotBase)
signal part_destroyed(robot: RobotBase, part_name: String, detached_part: DetachedPart)
signal robot_disabled(robot: RobotBase)
signal part_restored(robot: RobotBase, part_name: String, restored_by: RobotBase)
signal robot_exploded(robot: RobotBase)

enum ControlMode { EASY, HARD }
enum KeyboardProfile { NONE, WASD_SPACE, ARROWS_ENTER, NUMPAD, IJKL }

const DETACHED_PART_SCENE := preload("res://scenes/robots/detached_part.tscn")
const PULSE_BOLT_SCENE := preload("res://scenes/projectiles/pulse_bolt.tscn")
const CONTROL_BEACON_SCENE := preload("res://scenes/skills/control_beacon.tscn")

const BODY_PARTS := [
	"left_arm",
	"right_arm",
	"left_leg",
	"right_leg",
]

const BODY_PART_LABELS := {
	"left_arm": "brazo izquierdo",
	"right_arm": "brazo derecho",
	"left_leg": "pierna izquierda",
	"right_leg": "pierna derecha",
}

const CARRY_PART_COLORS := {
	"left_arm": Color(0.98, 0.45, 0.12, 1.0),
	"right_arm": Color(0.98, 0.58, 0.15, 1.0),
	"left_leg": Color(0.22, 0.56, 0.94, 1.0),
	"right_leg": Color(0.29, 0.72, 1.0, 1.0),
}

const CARRIED_ITEM_LABELS := {
	"pulse_charge": "pulso",
}

const CARRIED_ITEM_COLORS := {
	"pulse_charge": Color(1.0, 0.86, 0.24, 1.0),
}

const PART_VISUAL_PATHS := {
	"left_arm": ["UpperBodyPivot/LeftArm"],
	"right_arm": ["UpperBodyPivot/RightArm"],
	"left_leg": ["ModularParts/LeftLeg", "ModularParts/LeftLegThruster", "ModularParts/LeftThrusterNozzle"],
	"right_leg": ["ModularParts/RightLeg", "ModularParts/RightLegThruster", "ModularParts/RightThrusterNozzle"],
}

const CORE_VISUAL_PATHS := [
	"UpperBodyPivot/BodyVisual",
	"UpperBodyPivot/ShouldersVisual",
	"UpperBodyPivot/HeadVisual",
	"UpperBodyPivot/FacingMarker",
	"UpperBodyPivot/LeftCoreLight",
	"UpperBodyPivot/RightCoreLight",
]

const INPUT_ACTION_SUFFIXES := [
	"move_left",
	"move_right",
	"move_forward",
	"move_back",
	"aim_left",
	"aim_right",
	"aim_forward",
	"aim_back",
	"attack",
	"energy_prev",
	"energy_next",
	"overdrive",
	"throw_part",
]

const KEYBOARD_PROFILE_LABELS := {
	KeyboardProfile.NONE: "sin teclado",
	KeyboardProfile.WASD_SPACE: "WASD",
	KeyboardProfile.ARROWS_ENTER: "flechas",
	KeyboardProfile.NUMPAD: "numpad",
	KeyboardProfile.IJKL: "IJKL",
}

const KEYBOARD_PROFILE_HARD_AIM_LABELS := {
	KeyboardProfile.WASD_SPACE: "TFGX",
	KeyboardProfile.ARROWS_ENTER: "Ins/Del/PgUp/PgDn",
	KeyboardProfile.NUMPAD: "KP7/KP9/KP//KP*",
}

const KEYBOARD_PROFILE_ATTACK_LABELS := {
	KeyboardProfile.WASD_SPACE: "Space",
	KeyboardProfile.ARROWS_ENTER: "Enter",
	KeyboardProfile.NUMPAD: "KP0",
	KeyboardProfile.IJKL: "U",
}

const KEYBOARD_PROFILE_ENERGY_LABELS := {
	KeyboardProfile.WASD_SPACE: "Q/E",
	KeyboardProfile.ARROWS_ENTER: ",/.",
	KeyboardProfile.NUMPAD: "KP1/KP3",
	KeyboardProfile.IJKL: "Y/H",
}

const KEYBOARD_PROFILE_THROW_LABELS := {
	KeyboardProfile.WASD_SPACE: "C",
	KeyboardProfile.ARROWS_ENTER: "/",
	KeyboardProfile.NUMPAD: "KP+",
	KeyboardProfile.IJKL: "N",
}

const KEYBOARD_PROFILE_OVERDRIVE_LABELS := {
	KeyboardProfile.WASD_SPACE: "R",
	KeyboardProfile.ARROWS_ENTER: "M",
	KeyboardProfile.NUMPAD: "KP5",
	KeyboardProfile.IJKL: "B",
}

const IDENTITY_COLORS := [
	Color(1.0, 0.62, 0.18, 1.0),
	Color(0.24, 0.78, 1.0, 1.0),
	Color(0.44, 0.92, 0.46, 1.0),
	Color(0.92, 0.42, 0.92, 1.0),
	Color(1.0, 0.84, 0.2, 1.0),
	Color(0.52, 0.62, 1.0, 1.0),
	Color(0.3, 0.9, 0.78, 1.0),
	Color(1.0, 0.42, 0.56, 1.0),
]

const ENERGY_LIMB_PAIRS := {
	"left_arm": ["left_arm", "right_arm"],
	"right_arm": ["left_arm", "right_arm"],
	"left_leg": ["left_leg", "right_leg"],
	"right_leg": ["left_leg", "right_leg"],
}

const ARCHETYPE_BASE_FIELDS := [
	"max_move_speed",
	"move_acceleration",
	"glide_damping",
	"max_part_health",
	"restored_part_health_ratio",
	"passive_push_strength",
	"attack_impulse_strength",
	"attack_damage",
	"collision_damage_scale",
	"detached_part_pickup_range",
	"carried_part_return_range",
]

const KEYBOARD_PROFILE_BINDINGS := {
	KeyboardProfile.NONE: {},
	KeyboardProfile.WASD_SPACE: {
		"move_left": [KEY_A],
		"move_right": [KEY_D],
		"move_forward": [KEY_W],
		"move_back": [KEY_S],
		"aim_left": [KEY_F],
		"aim_right": [KEY_G],
		"aim_forward": [KEY_T],
		"aim_back": [KEY_X],
		"attack": [KEY_SPACE],
		"energy_prev": [KEY_Q],
		"energy_next": [KEY_E],
		"throw_part": [KEY_C],
		"overdrive": [KEY_R],
	},
	KeyboardProfile.ARROWS_ENTER: {
		"move_left": [KEY_LEFT],
		"move_right": [KEY_RIGHT],
		"move_forward": [KEY_UP],
		"move_back": [KEY_DOWN],
		"aim_left": [KEY_INSERT],
		"aim_right": [KEY_DELETE],
		"aim_forward": [KEY_PAGEUP],
		"aim_back": [KEY_PAGEDOWN],
		"attack": [KEY_ENTER],
		"energy_prev": [KEY_COMMA],
		"energy_next": [KEY_PERIOD],
		"throw_part": [KEY_SLASH],
		"overdrive": [KEY_M],
	},
	KeyboardProfile.NUMPAD: {
		"move_left": [KEY_KP_4],
		"move_right": [KEY_KP_6],
		"move_forward": [KEY_KP_8],
		"move_back": [KEY_KP_2],
		"aim_left": [KEY_KP_7],
		"aim_right": [KEY_KP_9],
		"aim_forward": [KEY_KP_DIVIDE],
		"aim_back": [KEY_KP_MULTIPLY],
		"attack": [KEY_KP_0],
		"energy_prev": [KEY_KP_1],
		"energy_next": [KEY_KP_3],
		"throw_part": [KEY_KP_ADD],
		"overdrive": [KEY_KP_5],
	},
	KeyboardProfile.IJKL: {
		"move_left": [KEY_J],
		"move_right": [KEY_L],
		"move_forward": [KEY_I],
		"move_back": [KEY_K],
		"attack": [KEY_U],
		"energy_prev": [KEY_Y],
		"energy_next": [KEY_H],
		"throw_part": [KEY_N],
		"overdrive": [KEY_B],
	},
}

@export var robot_id := 0
@export var display_name := "Prototype Robot"
@export var team_id := 0
@export var archetype_config: RobotArchetypeConfig
@export var control_mode: ControlMode = ControlMode.EASY
@export var max_part_health := 100.0
@export var starting_energy_per_part := 25.0
@export_range(0.1, 1.0, 0.05) var restored_part_health_ratio := 0.35

@export_group("Prototype Controls")
@export var is_player_controlled := false
@export_range(1, 8) var player_index := 1
@export var keyboard_profile: KeyboardProfile = KeyboardProfile.WASD_SPACE
@export var joypad_device := -1
@export_range(0.0, 0.8, 0.05) var joystick_deadzone := 0.25
@export_range(0.0, 0.8, 0.05) var hard_aim_deadzone := 0.3

@export_group("Prototype Movement")
@export var max_move_speed := 7.5
@export var move_acceleration := 16.5
@export var glide_damping := 2.9
@export var turn_speed := 10.0
@export var torso_turn_speed := 12.0
@export var gravity := 28.0

@export_group("Prototype Mobility Pickup")
@export_range(1.0, 2.0, 0.05) var mobility_pickup_drive_multiplier := 1.22
@export_range(1.0, 2.0, 0.05) var mobility_pickup_control_multiplier := 1.18

@export_group("Prototype Stability Pickup")
@export_range(0.2, 3.0, 0.05) var stability_pickup_duration := 1.7
@export_range(0.2, 1.0, 0.01) var stability_pickup_received_impulse_multiplier := 0.76

@export_group("Prototype Energy")
@export var focused_part_energy := 40.0
@export var focused_pair_energy := 30.0
@export var unfocused_part_energy := 15.0
@export var overdrive_part_energy := 55.0
@export var overdrive_pair_energy := 20.0
@export var overdrive_other_part_energy := 12.5
@export var overdrive_recovery_part_energy := 10.0
@export var overdrive_recovery_pair_energy := 20.0
@export var overdrive_recovery_other_part_energy := 35.0
@export var energy_shift_cooldown := 0.6
@export var overdrive_duration := 1.2
@export var overdrive_recovery_duration := 0.7
@export var overdrive_cooldown := 2.0
@export_range(0.2, 2.0, 0.05) var minimum_energy_multiplier := 0.55
@export_range(0.2, 2.0, 0.05) var maximum_energy_multiplier := 1.35
@export_range(1.0, 1.5, 0.05) var energy_pickup_pair_multiplier := 1.12

@export_group("Prototype Utility Item")
@export var pulse_charge_projectile_speed := 13.5
@export var pulse_charge_projectile_lifetime := 1.0
@export var pulse_charge_impulse := 8.8
@export var pulse_charge_damage := 18.0
@export var pulse_charge_spawn_distance := 1.0
@export var pulse_charge_spawn_height := 0.72

@export_group("Prototype Control Skill")
@export var control_beacon_duration := 3.2
@export var control_beacon_radius := 1.75
@export var control_beacon_spawn_distance := 1.1
@export var control_beacon_spawn_height := 0.05
@export_range(0.2, 1.0, 0.01) var control_zone_drive_multiplier := 0.72
@export_range(0.2, 1.0, 0.01) var control_zone_control_multiplier := 0.64
@export_range(0.05, 0.4, 0.01) var control_zone_refresh_window := 0.16
@export var recovery_skill_pickup_range := 3.0

@export_group("Prototype Combat")
@export var passive_push_strength := 4.4
@export var attack_impulse_strength := 11.0
@export var attack_range := 2.3
@export var attack_cooldown := 0.42
@export var attack_damage := 28.0
@export var collision_damage_threshold := 3.9
@export var collision_damage_scale := 6.3
@export var collision_damage_cooldown := 0.3
@export var detached_part_launch_speed := 5.2
@export var detached_part_throw_speed := 8.0
@export var detached_part_pickup_range := 1.4
@export var carried_part_return_range := 1.8
@export_group("Prototype Carry Visual")
@export var carry_indicator_radius := 0.09
@export var carry_indicator_base_height := 0.95
@export var carry_indicator_bob_height := 0.09
@export var carry_indicator_pulse_speed := 6.5
@export var carry_indicator_pulse_amount := 0.18
@export var carry_indicator_rotation_speed := 1.3
@export var carry_return_indicator_height := 1.06
@export var carry_return_indicator_offset := 0.34
@export_range(0.0, 0.3, 0.01) var carry_return_indicator_width := 0.1
@export_range(0.0, 0.4, 0.01) var carry_return_indicator_length := 0.22
@export var core_skill_ready_pulse_speed := 4.2
@export var core_skill_ready_pulse_amount := 0.18
@export var core_skill_ready_emission_boost := 0.28
@export_group("Prototype Recovery Target Readability")
@export var recovery_target_indicator_radius := 0.22
@export var recovery_target_indicator_base_height := 1.18
@export var recovery_target_indicator_bob_height := 0.06
@export var recovery_target_indicator_pulse_speed := 4.8
@export var recovery_target_indicator_pulse_amount := 0.12
@export var recovery_target_floor_indicator_height := 0.04
@export var recovery_target_floor_indicator_radius := 0.58
@export_range(0.01, 0.12, 0.01) var recovery_target_floor_indicator_thickness := 0.03
@export_range(0.0, 0.2, 0.01) var recovery_target_floor_indicator_pulse_amount := 0.08
@export_group("Prototype Lab Readability")
@export var lab_selection_indicator_radius := 0.88
@export var lab_selection_indicator_height := 0.04
@export_range(0.0, 0.2, 0.01) var lab_selection_indicator_pulse_amount := 0.08
@export_range(1.0, 10.0, 0.5) var lab_selection_indicator_pulse_speed := 4.0
@export_group("Prototype Round Intro Readability")
@export var round_intro_indicator_radius := 0.78
@export var round_intro_indicator_height := 0.035
@export_range(0.01, 0.12, 0.01) var round_intro_indicator_thickness := 0.03
@export_range(0.0, 0.2, 0.01) var round_intro_indicator_pulse_amount := 0.07
@export_range(1.0, 10.0, 0.5) var round_intro_indicator_pulse_speed := 4.6
@export_group("Prototype Energy Readability")
@export_range(0.02, 0.2, 0.01) var energy_focus_indicator_thickness := 0.05
@export_range(0.05, 0.4, 0.01) var energy_focus_indicator_length := 0.18
@export_range(0.0, 0.2, 0.01) var energy_focus_indicator_pulse_amount := 0.1
@export_range(1.0, 12.0, 0.5) var energy_focus_indicator_pulse_speed := 5.0
@export_group("Prototype Status Readability")
@export_range(0.12, 0.8, 0.01) var status_effect_indicator_radius := 0.3
@export_range(0.01, 0.12, 0.01) var status_effect_indicator_thickness := 0.04
@export_range(0.2, 1.6, 0.05) var status_effect_indicator_height := 0.74
@export_range(0.0, 0.2, 0.01) var status_effect_indicator_pulse_amount := 0.08
@export_range(1.0, 12.0, 0.5) var status_effect_indicator_pulse_speed := 4.6
@export_group("Prototype Damage Readability")
@export_range(0.4, 1.0, 0.05) var damage_feedback_threshold := 0.8
@export_range(0.1, 0.8, 0.05) var critical_damage_feedback_threshold := 0.45
@export var damage_feedback_height := 0.24
@export_range(0.1, 2.0, 0.05) var damaged_part_bonus_highlight_duration := 0.8
@export_range(0.0, 0.2, 0.01) var damaged_part_pose_drop := 0.08
@export_range(0.0, 0.15, 0.01) var damaged_arm_pose_side_offset := 0.05
@export_range(0.0, 0.15, 0.01) var damaged_leg_pose_back_offset := 0.08
@export_range(0.0, 20.0, 0.5) var damaged_arm_pose_roll_degrees := 12.0
@export_range(0.0, 20.0, 0.5) var damaged_leg_pose_pitch_degrees := 10.0
@export_range(0.0, 15.0, 0.5) var damaged_part_pose_splay_degrees := 6.0
@export_group("Prototype Disabled Explosion Readability")
@export var disabled_warning_indicator_height := 0.03
@export_range(0.01, 0.15, 0.01) var disabled_warning_indicator_thickness := 0.04
@export_range(0.0, 0.2, 0.01) var disabled_warning_indicator_pulse_amount := 0.05
@export_range(1.0, 12.0, 0.5) var disabled_warning_indicator_pulse_speed := 5.5
@export var disabled_explosion_delay := 1.6
@export var disabled_explosion_radius := 3.6
@export var disabled_explosion_impulse := 12.0
@export var disabled_explosion_damage := 24.0
@export_range(1.0, 2.0, 0.05) var unstable_disabled_explosion_radius_multiplier := 1.2
@export_range(1.0, 2.0, 0.05) var unstable_disabled_explosion_impulse_multiplier := 1.35
@export_range(1.0, 2.0, 0.05) var unstable_disabled_explosion_damage_multiplier := 1.35
@export_group("Prototype Elimination Attribution")
@export_range(0.2, 5.0, 0.1) var elimination_attribution_window := 2.4

@export_group("Prototype Void")
@export var void_fall_y := -6.0

var part_health: Dictionary = {}
var part_energy: Dictionary = {}
var external_impulse := Vector3.ZERO

var _spawn_transform := Transform3D.IDENTITY
var _planar_velocity := Vector3.ZERO
var _attack_cooldown_remaining := 0.0
var _is_respawning := false
var _is_disabled := false
var _held_for_round_reset := false
var _starting_collision_layer := 1
var _starting_collision_mask := 1
var _respawn_timer: Timer = null
var _was_joypad_attack_pressed := false
var _was_joypad_energy_prev_pressed := false
var _was_joypad_energy_next_pressed := false
var _was_joypad_overdrive_pressed := false
var _was_joypad_throw_pressed := false
var _part_visual_nodes: Dictionary = {}
var _part_flash_strength: Dictionary = {}
var _core_visual_nodes: Array[MeshInstance3D] = []
var _archetype_accent_visual_nodes: Array[MeshInstance3D] = []
var _material_base_values: Dictionary = {}
var _part_visual_base_transforms: Dictionary = {}
var _damage_feedback_nodes: Dictionary = {}
var _collision_damage_ready_at: Dictionary = {}
var _damaged_part_bonus_remaining := 0.0
var _damaged_part_bonus_cue_remaining: Dictionary = {}
var _carried_part: DetachedPart = null
var _carried_item_name := ""
var _carry_indicator: MeshInstance3D = null
var _carry_owner_indicator: MeshInstance3D = null
var _carry_return_indicator: MeshInstance3D = null
var _carry_indicator_animation_time := 0.0
var _recovery_target_indicator: MeshInstance3D = null
var _recovery_target_floor_indicator: MeshInstance3D = null
var _recovery_target_indicator_animation_time := 0.0
var _lab_selection_indicator: MeshInstance3D = null
var _lab_selection_indicator_animation_time := 0.0
var _round_intro_indicator: MeshInstance3D = null
var _round_intro_indicator_animation_time := 0.0
var _energy_readability_root: Node3D = null
var _energy_focus_indicator_nodes: Dictionary = {}
var _energy_focus_indicator_animation_time := 0.0
var _status_effect_indicator: MeshInstance3D = null
var _status_effect_indicator_animation_time := 0.0
var _disabled_warning_indicator: MeshInstance3D = null
var _disabled_warning_indicator_animation_time := 0.0
var _recoverable_detached_part_ids: Dictionary = {}
var _last_indicator_payload_name := ""
var _core_skill_visual_time := 0.0
var _selected_energy_part_name := "left_arm"
var _energy_shift_cooldown_remaining := 0.0
var _overdrive_part_name := ""
var _overdrive_duration_remaining := 0.0
var _overdrive_recovery_remaining := 0.0
var _overdrive_cooldown_remaining := 0.0
var _energy_surge_part_name := ""
var _energy_surge_remaining := 0.0
var _mobility_boost_remaining := 0.0
var _stability_boost_remaining := 0.0
var _ram_skill_remaining := 0.0
var _mobility_skill_remaining := 0.0
var _stability_received_impulse_state_multiplier := 1.0
var _core_skill_charges := 0
var _core_skill_recharge_remaining := 0.0
var _hard_torso_world_direction := Vector3.FORWARD
var _control_zone_suppression_remaining := 0.0
var _control_zone_drive_state_multiplier := 1.0
var _control_zone_control_state_multiplier := 1.0
var _active_control_beacon: Node = null
var _disabled_explosion_is_unstable := false
var _last_disabled_explosion_was_unstable := false
var _round_intro_locked := false
var _archetype_base_values: Dictionary = {}
var _archetype_accent_root: Node3D = null
var _is_lab_selected := false
var _recent_elimination_source_robot: RobotBase = null
var _recent_elimination_source_remaining := 0.0

@onready var disabled_explosion_timer: Timer = $DisabledExplosionTimer
@onready var upper_body_pivot: Node3D = $UpperBodyPivot


static func get_part_display_name(part_name: String) -> String:
	return BODY_PART_LABELS.get(part_name, part_name)


func get_team_identity() -> int:
	if team_id > 0:
		return team_id
	if robot_id > 0:
		return robot_id

	return get_instance_id()


func get_identity_color() -> Color:
	var identity_index := 0
	if team_id > 0:
		identity_index = team_id - 1
	elif player_index > 0:
		identity_index = player_index - 1
	elif robot_id > 0:
		identity_index = robot_id - 1
	else:
		identity_index = int(get_instance_id())

	return IDENTITY_COLORS[wrapi(identity_index, 0, IDENTITY_COLORS.size())]


func uses_keyboard_input() -> bool:
	return keyboard_profile != KeyboardProfile.NONE


func is_ally_of(other_robot: RobotBase) -> bool:
	if other_robot == null:
		return false

	return get_team_identity() == other_robot.get_team_identity()


func is_disabled_state() -> bool:
	return _is_disabled


func get_disabled_explosion_time_left() -> float:
	if not _is_disabled:
		return 0.0

	return maxf(disabled_explosion_timer.time_left, 0.0)


func is_disabled_explosion_unstable() -> bool:
	return _is_disabled and _disabled_explosion_is_unstable


func was_last_disabled_explosion_unstable() -> bool:
	return _last_disabled_explosion_was_unstable


func is_carrying_part() -> bool:
	return is_instance_valid(_carried_part)


func get_carried_part_name() -> String:
	if not is_instance_valid(_carried_part):
		return ""

	return _carried_part.part_name


func has_carried_item() -> bool:
	return _carried_item_name != ""


func get_carried_item_name() -> String:
	return _carried_item_name


func has_recoverable_detached_parts() -> bool:
	_prune_recoverable_detached_part_ids()
	return not _recoverable_detached_part_ids.is_empty()


func is_carried_part_return_ready() -> bool:
	return _is_carried_part_return_ready_with_owner(_get_carried_part_owner())


func get_carried_item_display_name() -> String:
	return str(CARRIED_ITEM_LABELS.get(_carried_item_name, _carried_item_name))


func get_archetype_label() -> String:
	if archetype_config == null:
		return ""

	return archetype_config.archetype_label


func get_archetype_visual_signature() -> String:
	if archetype_config == null:
		return ""

	return "%s:%s" % [get_archetype_label(), int(archetype_config.accent_style)]


func get_roster_display_name() -> String:
	var archetype_label := get_archetype_label()
	if archetype_label == "":
		return display_name

	return "%s / %s" % [display_name, archetype_label]


func set_lab_selected(is_selected: bool) -> void:
	_is_lab_selected = is_selected
	_refresh_lab_selection_indicator()


func is_lab_selected() -> bool:
	return _is_lab_selected


func get_active_part_count() -> int:
	var active_parts := 0
	for part_name in BODY_PARTS:
		if get_part_health(part_name) > 0.0:
			active_parts += 1

	return active_parts


func get_part_energy_amount(part_name: String) -> float:
	return float(part_energy.get(part_name, starting_energy_per_part))


func get_energy_focus_part_name() -> String:
	return _selected_energy_part_name


func get_energy_state_summary() -> String:
	var part_label := get_part_display_name(_selected_energy_part_name)
	if is_overdrive_active():
		return "OD %s" % part_label
	if _overdrive_recovery_remaining > 0.0:
		return "Rec %s" % part_label
	if _is_energy_balanced():
		return "Eq"
	return "Foco %s" % part_label


func is_energy_balanced() -> bool:
	return _is_energy_balanced()


func get_combat_forward_vector() -> Vector3:
	return _get_combat_forward_vector()


func set_torso_world_direction(world_direction: Vector3) -> void:
	var planar_direction := world_direction
	planar_direction.y = 0.0
	if planar_direction.length_squared() <= 0.0001:
		return

	_hard_torso_world_direction = planar_direction.normalized()
	_refresh_upper_body_pose(true)


func get_effective_leg_drive_multiplier() -> float:
	return (
		_get_leg_health_multiplier()
		* _get_leg_energy_multiplier()
		* _get_mobility_pickup_drive_multiplier()
		* _get_control_zone_drive_multiplier()
		* _get_mobility_skill_drive_multiplier()
		* _get_ram_skill_drive_multiplier()
	)


func get_effective_arm_power_multiplier() -> float:
	return _get_arm_health_multiplier() * _get_arm_energy_multiplier() * _get_ram_skill_arm_power_multiplier()


func get_received_impulse_multiplier() -> float:
	var archetype_multiplier := 1.0
	if archetype_config != null:
		archetype_multiplier = maxf(archetype_config.received_impulse_multiplier, 0.1)

	return (
		archetype_multiplier
		* _get_stability_received_impulse_multiplier()
		* _get_ram_skill_received_impulse_multiplier()
	)


func get_recent_elimination_source() -> RobotBase:
	if _recent_elimination_source_remaining <= 0.0:
		return null
	if not is_instance_valid(_recent_elimination_source_robot):
		return null
	if _recent_elimination_source_robot == self:
		return null

	return _recent_elimination_source_robot


func get_damaged_part_bonus_damage_multiplier() -> float:
	if archetype_config == null:
		return 1.0

	return maxf(archetype_config.damaged_part_bonus_damage_multiplier, 1.0)


func get_passive_status_summary() -> String:
	if _damaged_part_bonus_remaining <= 0.0:
		return ""

	return "corte"


func get_return_support_repair_ratio() -> float:
	if archetype_config == null:
		return 0.0

	return maxf(archetype_config.return_support_repair_ratio, 0.0)


func get_mobility_boost_duration_multiplier() -> float:
	if archetype_config == null:
		return 1.0

	return maxf(archetype_config.mobility_boost_duration_multiplier, 1.0)


func is_overdrive_active() -> bool:
	return _overdrive_duration_remaining > 0.0


func is_overdrive_cooling_down() -> bool:
	return _overdrive_cooldown_remaining > 0.0


func is_mobility_boost_active() -> bool:
	return _mobility_boost_remaining > 0.0


func get_mobility_boost_time_left() -> float:
	return maxf(_mobility_boost_remaining, 0.0)


func is_mobility_skill_active() -> bool:
	return _mobility_skill_remaining > 0.0


func is_control_zone_suppressed() -> bool:
	return _control_zone_suppression_remaining > 0.0


func is_stability_boost_active() -> bool:
	return _stability_boost_remaining > 0.0


func get_stability_boost_time_left() -> float:
	return maxf(_stability_boost_remaining, 0.0)


func is_ram_skill_active() -> bool:
	return _ram_skill_remaining > 0.0


func get_ram_skill_time_left() -> float:
	return maxf(_ram_skill_remaining, 0.0)


func get_control_zone_suppression_time_left() -> float:
	return maxf(_control_zone_suppression_remaining, 0.0)


func apply_control_zone_suppression(
	duration: float,
	drive_multiplier: float,
	control_multiplier: float
) -> bool:
	if duration <= 0.0:
		return false
	if _is_respawning or _is_disabled:
		return false
	if is_stability_boost_active():
		return false

	var previous_remaining := _control_zone_suppression_remaining
	_control_zone_suppression_remaining = maxf(_control_zone_suppression_remaining, duration)
	_control_zone_drive_state_multiplier = minf(
		_control_zone_drive_state_multiplier,
		clampf(drive_multiplier, 0.2, 1.0)
	)
	_control_zone_control_state_multiplier = minf(
		_control_zone_control_state_multiplier,
		clampf(control_multiplier, 0.2, 1.0)
	)
	if _control_zone_suppression_remaining > previous_remaining:
		_refresh_visual_state()
	return true


func apply_stability_boost(
	duration: float,
	received_impulse_multiplier: float = -1.0
) -> bool:
	if duration <= 0.0:
		return false
	if _is_respawning or _is_disabled:
		return false

	if received_impulse_multiplier <= 0.0:
		received_impulse_multiplier = stability_pickup_received_impulse_multiplier

	_clear_control_zone_suppression()
	var previous_remaining := _stability_boost_remaining
	_stability_boost_remaining = maxf(_stability_boost_remaining, duration)
	_stability_received_impulse_state_multiplier = minf(
		_stability_received_impulse_state_multiplier,
		clampf(received_impulse_multiplier, 0.2, 1.0)
	)
	if _stability_boost_remaining > previous_remaining:
		_refresh_visual_state()

	return true


func has_core_skill() -> bool:
	if archetype_config == null:
		return false

	return (
		archetype_config.core_skill_type != RobotArchetypeConfig.CoreSkillType.NONE
		and get_core_skill_max_charges() > 0
		and get_core_skill_label() != ""
	)


func get_core_skill_label() -> String:
	if archetype_config == null:
		return ""

	return archetype_config.core_skill_label


func get_core_skill_charge_count() -> int:
	return _core_skill_charges


func get_core_skill_max_charges() -> int:
	if archetype_config == null:
		return 0

	return maxi(archetype_config.core_skill_max_charges, 0)


func restore_core_skill_charges(charge_amount: int = 1) -> bool:
	if not has_core_skill():
		return false
	if charge_amount <= 0:
		return false

	var max_charges := get_core_skill_max_charges()
	if _core_skill_charges >= max_charges:
		return false

	var previous_charges := _core_skill_charges
	_core_skill_charges = mini(_core_skill_charges + charge_amount, max_charges)
	if _core_skill_charges >= max_charges:
		_core_skill_recharge_remaining = 0.0
	elif _core_skill_recharge_remaining <= 0.0:
		_core_skill_recharge_remaining = _get_core_skill_recharge_seconds()

	if _core_skill_charges == previous_charges:
		return false

	_refresh_visual_state()
	return true


func get_core_skill_status_summary() -> String:
	if not has_core_skill():
		return ""

	return "skill %s %s/%s" % [
		get_core_skill_label(),
		get_core_skill_charge_count(),
		get_core_skill_max_charges(),
	]


func use_core_skill() -> bool:
	if not has_core_skill():
		return false
	if _is_respawning or _is_disabled:
		return false
	if is_instance_valid(_carried_part):
		return false
	if _core_skill_charges <= 0:
		return false

	var used := false
	match archetype_config.core_skill_type:
		RobotArchetypeConfig.CoreSkillType.PULSE_SHOT:
			used = _spawn_core_skill_pulse()
		RobotArchetypeConfig.CoreSkillType.CONTROL_BEACON:
			used = _spawn_control_beacon()
		RobotArchetypeConfig.CoreSkillType.RECOVERY_GRAB:
			used = _use_recovery_grab()
		RobotArchetypeConfig.CoreSkillType.RAM_BOOST:
			used = _use_ram_boost()
		RobotArchetypeConfig.CoreSkillType.MOBILITY_BURST:
			used = _use_mobility_burst()
		_:
			used = false

	if not used:
		return false

	_core_skill_charges = maxi(_core_skill_charges - 1, 0)
	if _core_skill_charges < get_core_skill_max_charges() and _core_skill_recharge_remaining <= 0.0:
		_core_skill_recharge_remaining = _get_core_skill_recharge_seconds()
	_refresh_visual_state()
	return true


func is_energy_surge_active() -> bool:
	return _energy_surge_remaining > 0.0


func get_energy_surge_time_left() -> float:
	return maxf(_energy_surge_remaining, 0.0)


func get_input_hint() -> String:
	if uses_keyboard_input():
		var move_label := str(KEYBOARD_PROFILE_LABELS.get(keyboard_profile, "teclado"))
		if control_mode == ControlMode.HARD:
			var aim_label := str(KEYBOARD_PROFILE_HARD_AIM_LABELS.get(keyboard_profile, "stick derecho"))
			return "%s + aim %s" % [move_label, aim_label]

		return move_label

	if joypad_device >= 0:
		return "joy %s" % joypad_device

	return "sin dispositivo"


func get_support_input_hint() -> String:
	if uses_keyboard_input():
		match keyboard_profile:
			KeyboardProfile.WASD_SPACE:
				return "usa C | objetivo Q/E"
			KeyboardProfile.ARROWS_ENTER:
				return "usa / | objetivo ,/."
			KeyboardProfile.NUMPAD:
				return "usa KP+ | objetivo KP1/KP3"
			KeyboardProfile.IJKL:
				return "usa N | objetivo Y/H"
			_:
				return "usa apoyo | objetivo previo/siguiente"

	return "usa X | objetivo LB/RB"


func get_control_reference_hint() -> String:
	if uses_keyboard_input():
		var segments: Array[String] = [
			"mueve %s" % str(KEYBOARD_PROFILE_LABELS.get(keyboard_profile, "teclado")),
		]
		if control_mode == ControlMode.HARD:
			segments.append(
				"aim %s" % str(KEYBOARD_PROFILE_HARD_AIM_LABELS.get(keyboard_profile, "stick derecho"))
			)
		segments.append("ataca %s" % str(KEYBOARD_PROFILE_ATTACK_LABELS.get(keyboard_profile, "?")))
		segments.append("energia %s" % str(KEYBOARD_PROFILE_ENERGY_LABELS.get(keyboard_profile, "?/?")))
		segments.append("overdrive %s" % str(KEYBOARD_PROFILE_OVERDRIVE_LABELS.get(keyboard_profile, "?")))
		segments.append("suelta %s" % str(KEYBOARD_PROFILE_THROW_LABELS.get(keyboard_profile, "?")))
		return " | ".join(segments)

	if control_mode == ControlMode.HARD:
		return "mueve stick izq | aim stick der | ataca Sur | energia LB/RB | overdrive Norte | suelta Oeste"

	return "mueve stick izq | ataca Sur | energia LB/RB | overdrive Norte | suelta Oeste"


func get_player_move_input_vector() -> Vector2:
	return _get_move_input_vector()


func is_player_support_action_just_pressed() -> bool:
	return _is_throw_part_just_pressed()


func is_player_support_prev_just_pressed() -> bool:
	return _is_energy_prev_just_pressed()


func is_player_support_next_just_pressed() -> bool:
	return _is_energy_next_just_pressed()


func apply_runtime_loadout(
	next_archetype_config: RobotArchetypeConfig,
	next_control_mode: ControlMode
) -> void:
	archetype_config = next_archetype_config
	control_mode = next_control_mode
	_restore_archetype_base_values()
	_apply_archetype_config()
	_setup_archetype_accent_visuals()
	disabled_explosion_timer.wait_time = disabled_explosion_delay
	reset_modular_state()
	if is_player_controlled:
		refresh_input_setup()


func set_energy_focus(part_name: String) -> bool:
	if not BODY_PARTS.has(part_name):
		return false
	if is_overdrive_active() or _overdrive_recovery_remaining > 0.0:
		return false
	if _energy_shift_cooldown_remaining > 0.0:
		return false

	_selected_energy_part_name = part_name
	_energy_shift_cooldown_remaining = energy_shift_cooldown
	_apply_focus_energy_distribution(_selected_energy_part_name)
	_refresh_visual_state()
	return true


func activate_overdrive() -> bool:
	if _is_disabled:
		return false
	if is_instance_valid(_carried_part):
		return false
	if _selected_energy_part_name == "":
		return false
	if is_overdrive_active() or _overdrive_recovery_remaining > 0.0 or is_overdrive_cooling_down():
		return false

	_overdrive_part_name = _selected_energy_part_name
	_overdrive_duration_remaining = overdrive_duration
	_overdrive_cooldown_remaining = overdrive_cooldown
	_apply_overdrive_energy_distribution(_overdrive_part_name)
	_refresh_visual_state()
	return true


func apply_mobility_boost(duration: float) -> bool:
	if duration <= 0.0:
		return false
	if _is_respawning or _is_disabled:
		return false

	duration *= get_mobility_boost_duration_multiplier()
	var previous_remaining := _mobility_boost_remaining
	_mobility_boost_remaining = maxf(_mobility_boost_remaining, duration)
	if _mobility_boost_remaining > previous_remaining:
		_refresh_visual_state()

	return true


func _use_ram_boost() -> bool:
	var duration := _get_core_skill_active_duration()
	if duration <= 0.0:
		return false

	var previous_remaining := _ram_skill_remaining
	_ram_skill_remaining = maxf(_ram_skill_remaining, duration)
	if _ram_skill_remaining > previous_remaining:
		_refresh_visual_state()

	return true


func _use_mobility_burst() -> bool:
	var duration := _get_core_skill_active_duration()
	if duration <= 0.0:
		return false

	var burst_direction := _get_mobility_skill_direction()
	if burst_direction.length_squared() <= 0.0001:
		return false

	var burst_speed := maxf(max_move_speed * _get_core_skill_impulse_multiplier(), 0.1)
	var previous_remaining := _mobility_skill_remaining
	_mobility_skill_remaining = maxf(_mobility_skill_remaining, duration)
	_planar_velocity += burst_direction * burst_speed
	external_impulse += burst_direction * burst_speed * 0.32
	if _mobility_skill_remaining > previous_remaining:
		_refresh_visual_state()

	return true


func apply_energy_surge(duration: float) -> bool:
	if duration <= 0.0:
		return false
	if _is_respawning or _is_disabled:
		return false
	if is_overdrive_active():
		return false

	_overdrive_recovery_remaining = 0.0
	_energy_surge_part_name = _selected_energy_part_name
	_energy_surge_remaining = maxf(_energy_surge_remaining, duration)
	_apply_focus_energy_distribution(_selected_energy_part_name)
	_refresh_visual_state()
	return true


func store_carried_item(item_name: String) -> bool:
	if item_name == "":
		return false
	if not CARRIED_ITEM_LABELS.has(item_name):
		return false
	if _is_respawning or _is_disabled:
		return false
	if is_instance_valid(_carried_part) or has_carried_item():
		return false

	_carried_item_name = item_name
	_refresh_visual_state()
	return true


func register_recoverable_detached_part(detached_part: DetachedPart) -> void:
	if detached_part == null:
		return

	_recoverable_detached_part_ids[detached_part.get_instance_id()] = true
	_refresh_recovery_target_indicator()


func unregister_recoverable_detached_part(detached_part: DetachedPart) -> void:
	if detached_part == null:
		return

	_recoverable_detached_part_ids.erase(detached_part.get_instance_id())
	_refresh_recovery_target_indicator()


func _prune_recoverable_detached_part_ids() -> void:
	var stale_ids: Array[int] = []
	for detached_part_id in _recoverable_detached_part_ids.keys():
		var detached_part := instance_from_id(int(detached_part_id))
		if detached_part != null and is_instance_valid(detached_part):
			continue
		stale_ids.append(int(detached_part_id))

	for detached_part_id in stale_ids:
		_recoverable_detached_part_ids.erase(detached_part_id)


func use_carried_item() -> bool:
	if not has_carried_item():
		return false
	if _is_respawning or _is_disabled:
		return false
	if is_instance_valid(_carried_part):
		return false

	var item_name := _carried_item_name
	var used := false
	match item_name:
		"pulse_charge":
			used = _spawn_pulse_charge()
		_:
			used = false

	if not used:
		return false

	_carried_item_name = ""
	_refresh_visual_state()
	return true


func _ready() -> void:
	_spawn_transform = global_transform
	_starting_collision_layer = collision_layer
	_starting_collision_mask = collision_mask
	_ensure_respawn_timer()
	add_to_group("robots")
	_cache_archetype_base_values()
	_apply_archetype_config()
	_cache_visual_references()
	_setup_archetype_accent_visuals()
	_cache_part_visual_base_transforms()
	_prepare_visual_materials()
	_setup_damage_feedback_nodes()
	_setup_carry_indicator()
	_setup_recovery_target_indicator()
	_setup_lab_selection_indicator()
	_setup_round_intro_indicator()
	_setup_energy_focus_indicators()
	_setup_status_effect_indicator()
	_setup_disabled_warning_indicator()
	disabled_explosion_timer.wait_time = disabled_explosion_delay
	_reset_control_pose()
	reset_modular_state()
	if is_player_controlled:
		refresh_input_setup()


func _cache_archetype_base_values() -> void:
	if not _archetype_base_values.is_empty():
		return

	for field_name in ARCHETYPE_BASE_FIELDS:
		_archetype_base_values[field_name] = get(field_name)


func _restore_archetype_base_values() -> void:
	if _archetype_base_values.is_empty():
		_cache_archetype_base_values()

	for field_name in ARCHETYPE_BASE_FIELDS:
		if _archetype_base_values.has(field_name):
			set(field_name, _archetype_base_values[field_name])


func _apply_archetype_config() -> void:
	if archetype_config == null:
		return

	max_move_speed = maxf(max_move_speed * archetype_config.max_move_speed_multiplier, 0.1)
	move_acceleration = maxf(move_acceleration * archetype_config.move_acceleration_multiplier, 0.1)
	glide_damping = maxf(glide_damping * archetype_config.glide_damping_multiplier, 0.1)
	max_part_health = maxf(max_part_health * archetype_config.max_part_health_multiplier, 1.0)
	restored_part_health_ratio = clampf(
		restored_part_health_ratio * archetype_config.restored_part_health_ratio_multiplier,
		0.1,
		1.0
	)
	passive_push_strength = maxf(passive_push_strength * archetype_config.passive_push_strength_multiplier, 0.1)
	attack_impulse_strength = maxf(
		attack_impulse_strength * archetype_config.attack_impulse_strength_multiplier,
		0.1
	)
	attack_damage = maxf(attack_damage * archetype_config.attack_damage_multiplier, 0.1)
	collision_damage_scale = maxf(
		collision_damage_scale * archetype_config.collision_damage_scale_multiplier,
		0.1
	)
	detached_part_pickup_range = maxf(
		detached_part_pickup_range * archetype_config.detached_part_pickup_range_multiplier,
		0.1
	)
	carried_part_return_range = maxf(
		carried_part_return_range * archetype_config.carried_part_return_range_multiplier,
		0.1
	)


func _physics_process(delta: float) -> void:
	if _is_respawning:
		return

	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	_update_passive_status_state(delta)
	_update_recent_elimination_source(delta)
	_update_energy_state(delta)
	_update_control_zone_state(delta)
	_update_temporary_boosts(delta)
	_update_core_skill_state(delta)
	_update_energy_controls()
	_update_prototype_movement(delta)
	_update_control_mode_orientation(delta)
	_update_detached_part_interactions()
	_update_prototype_attack()
	_update_damage_visual_feedback(delta)
	_update_carry_indicator_animation(delta)

	if global_position.y <= void_fall_y:
		fall_into_void()


func _process(delta: float) -> void:
	_refresh_carry_return_indicator()
	_refresh_recovery_target_indicator()
	_refresh_disabled_warning_indicator()
	_update_recovery_target_indicator_animation(delta)
	_update_lab_selection_indicator(delta)
	_update_round_intro_indicator(delta)
	_update_energy_focus_indicator_animation(delta)
	_update_status_effect_indicator(delta)
	_update_disabled_warning_indicator(delta)
	_update_core_skill_readiness_visuals(delta)


func reset_modular_state() -> void:
	_is_disabled = false
	disabled_explosion_timer.stop()
	_part_flash_strength.clear()
	_collision_damage_ready_at.clear()
	_damaged_part_bonus_remaining = 0.0
	_damaged_part_bonus_cue_remaining.clear()
	_selected_energy_part_name = "left_arm"
	_energy_shift_cooldown_remaining = 0.0
	_overdrive_part_name = ""
	_overdrive_duration_remaining = 0.0
	_overdrive_recovery_remaining = 0.0
	_overdrive_cooldown_remaining = 0.0
	_energy_surge_part_name = ""
	_energy_surge_remaining = 0.0
	_mobility_boost_remaining = 0.0
	_stability_boost_remaining = 0.0
	_ram_skill_remaining = 0.0
	_mobility_skill_remaining = 0.0
	_stability_received_impulse_state_multiplier = 1.0
	_reset_core_skill_state()
	_clear_control_zone_suppression()
	_clear_active_control_beacon()
	_disabled_explosion_is_unstable = false
	_last_disabled_explosion_was_unstable = false
	_recent_elimination_source_robot = null
	_recent_elimination_source_remaining = 0.0
	_recoverable_detached_part_ids.clear()
	_carried_item_name = ""
	for part_name in BODY_PARTS:
		part_health[part_name] = max_part_health
		part_energy[part_name] = starting_energy_per_part
		_part_flash_strength[part_name] = 0.0
		_damaged_part_bonus_cue_remaining[part_name] = 0.0

	_apply_balanced_energy_distribution()
	_reset_control_pose()
	_refresh_visual_state()


func get_part_health(part_name: String) -> float:
	return float(part_health.get(part_name, 0.0))


func get_part_health_ratio(part_name: String) -> float:
	if max_part_health <= 0.0:
		return 0.0

	return clampf(get_part_health(part_name) / max_part_health, 0.0, 1.0)


func set_part_energy(part_name: String, value: float) -> void:
	if not BODY_PARTS.has(part_name):
		push_warning("Parte desconocida: %s" % part_name)
		return

	part_energy[part_name] = maxf(value, 0.0)


func capture_spawn_transform() -> void:
	_spawn_transform = global_transform


func refresh_input_setup() -> void:
	if not is_player_controlled:
		return

	_ensure_default_input_actions()
	_report_joypad_status()


func set_round_intro_locked(value: bool) -> void:
	_round_intro_locked = value
	_refresh_visual_state()
	if not _round_intro_locked:
		return

	_attack_cooldown_remaining = 0.0
	_planar_velocity = Vector3.ZERO
	external_impulse = Vector3.ZERO


func is_round_intro_locked() -> bool:
	return _round_intro_locked


func get_restored_part_health_amount() -> float:
	return maxf(max_part_health * restored_part_health_ratio, 1.0)


func restore_part_from_return(part_name: String, restored_by: RobotBase) -> bool:
	return restore_part(part_name, get_restored_part_health_amount(), restored_by)


func repair_part(part_name: String, repair_amount: float) -> bool:
	if not BODY_PARTS.has(part_name):
		return false
	if repair_amount <= 0.0:
		return false

	var current_health := get_part_health(part_name)
	if current_health <= 0.0 or current_health >= max_part_health:
		return false

	part_health[part_name] = minf(current_health + repair_amount, max_part_health)
	_part_flash_strength[part_name] = 1.0
	_refresh_visual_state()
	return true


func repair_most_damaged_part(repair_amount: float) -> String:
	if repair_amount <= 0.0:
		return ""

	var target_part := ""
	var lowest_health_ratio := 1.01
	for part_name in BODY_PARTS:
		var current_health := get_part_health(part_name)
		if current_health <= 0.0 or current_health >= max_part_health:
			continue

		var health_ratio := get_part_health_ratio(part_name)
		if health_ratio >= lowest_health_ratio:
			continue

		lowest_health_ratio = health_ratio
		target_part = part_name

	if target_part == "":
		return ""
	if not repair_part(target_part, repair_amount):
		return ""

	return target_part


func repair_most_damaged_part_excluding(excluded_part_name: String, repair_amount: float) -> String:
	if repair_amount <= 0.0:
		return ""

	var target_part := ""
	var lowest_health_ratio := 1.01
	for part_name in BODY_PARTS:
		if part_name == excluded_part_name:
			continue

		var current_health := get_part_health(part_name)
		if current_health <= 0.0 or current_health >= max_part_health:
			continue

		var health_ratio := get_part_health_ratio(part_name)
		if health_ratio >= lowest_health_ratio:
			continue

		lowest_health_ratio = health_ratio
		target_part = part_name

	if target_part == "":
		return repair_most_damaged_part(repair_amount)
	if not repair_part(target_part, repair_amount):
		return ""

	return target_part


func restore_part(part_name: String, restored_health: float, restored_by: RobotBase = self) -> bool:
	if not BODY_PARTS.has(part_name):
		return false
	if restored_health <= 0.0:
		return false
	if get_part_health(part_name) > 0.0:
		return false

	part_health[part_name] = clampf(restored_health, 0.0, max_part_health)
	_part_flash_strength[part_name] = 1.0
	if _is_disabled and not is_fully_disabled():
		_exit_disabled_state()

	var support_repair_amount := 0.0
	if is_instance_valid(restored_by):
		support_repair_amount = max_part_health * restored_by.get_return_support_repair_ratio()
	if support_repair_amount > 0.0:
		repair_most_damaged_part_excluding(part_name, support_repair_amount)

	_refresh_visual_state()
	part_restored.emit(self, part_name, restored_by)
	return true


func try_pick_up_detached_part(detached_part: DetachedPart) -> bool:
	if detached_part == null:
		return false
	if _is_respawning or _is_disabled:
		return false
	if has_carried_item():
		return false
	if is_instance_valid(_carried_part):
		return false

	_carried_part = detached_part
	_refresh_visual_state()
	return true


func release_detached_part(detached_part: DetachedPart = null) -> void:
	if detached_part == null or _carried_part == detached_part:
		_carried_part = null
	_refresh_visual_state()


func hold_for_round_reset() -> void:
	if _held_for_round_reset:
		return

	_cancel_respawn_timer()
	_held_for_round_reset = true
	_is_respawning = true
	_attack_cooldown_remaining = 0.0
	_planar_velocity = Vector3.ZERO
	external_impulse = Vector3.ZERO
	_clear_active_control_beacon()
	_clear_control_zone_suppression()
	_clear_carried_item()
	_deny_carried_part_if_any()
	_exit_disabled_state()
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)


func is_held_for_round_reset() -> bool:
	return _held_for_round_reset


func is_fully_disabled() -> bool:
	for part_name in BODY_PARTS:
		if get_part_health(part_name) > 0.0:
			return false

	return true


func apply_impulse(impulse: Vector3, source_robot: RobotBase = null) -> void:
	impulse.y = 0.0
	_remember_recent_elimination_source(source_robot)
	external_impulse += impulse * get_received_impulse_multiplier()


func receive_collision_hit(impact_direction: Vector3, damage_amount: float) -> void:
	receive_collision_hit_from_robot(impact_direction, damage_amount)


func receive_collision_hit_from_robot(
	impact_direction: Vector3,
	damage_amount: float,
	source_robot: RobotBase = null
) -> void:
	if damage_amount <= 0.0 or is_fully_disabled():
		return

	var hit_part := _select_part_from_world_direction(impact_direction)
	apply_damage_to_part(hit_part, damage_amount, impact_direction, source_robot)


func receive_attack_hit(impact_direction: Vector3, damage_amount: float) -> void:
	receive_attack_hit_from_robot(impact_direction, damage_amount)


func receive_attack_hit_from_robot(
	impact_direction: Vector3,
	damage_amount: float,
	source_robot: RobotBase = null
) -> void:
	if damage_amount <= 0.0 or is_fully_disabled():
		return

	var hit_part := _select_part_from_world_direction(impact_direction)
	apply_damage_to_part(hit_part, damage_amount, impact_direction, source_robot)


func apply_damage_to_part(
	part_name: String,
	damage_amount: float,
	impact_direction: Vector3 = Vector3.ZERO,
	source_robot: RobotBase = null
) -> void:
	if not BODY_PARTS.has(part_name):
		return
	if damage_amount <= 0.0:
		return
	var current_health := get_part_health(part_name)
	if current_health <= 0.0:
		return

	var effective_damage := damage_amount
	if is_instance_valid(source_robot) and current_health < max_part_health:
		effective_damage *= source_robot.get_damaged_part_bonus_damage_multiplier()
		source_robot._trigger_damaged_part_bonus_feedback()
		_trigger_damaged_part_bonus_victim_feedback(part_name)
	_remember_recent_elimination_source(source_robot)

	part_health[part_name] = maxf(current_health - effective_damage, 0.0)
	_part_flash_strength[part_name] = 1.0

	if is_zero_approx(get_part_health(part_name)):
		_spawn_detached_part(part_name, impact_direction)
		if is_fully_disabled():
			_enter_disabled_state()

	_refresh_visual_state()


func fall_into_void() -> void:
	if _is_respawning:
		return

	_cancel_respawn_timer()
	_is_respawning = true
	_clear_active_control_beacon()
	_clear_control_zone_suppression()
	_clear_carried_item()
	_deny_carried_part_if_any()
	fell_into_void.emit(self)
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	_schedule_respawn(0.75)


func reset_to_spawn() -> void:
	_cancel_respawn_timer()
	_cleanup_owned_detached_parts()
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	_planar_velocity = Vector3.ZERO
	external_impulse = Vector3.ZERO
	_attack_cooldown_remaining = 0.0
	_clear_active_control_beacon()
	_clear_control_zone_suppression()
	_carried_part = null
	_carried_item_name = ""
	_held_for_round_reset = false
	visible = true
	collision_layer = _starting_collision_layer
	collision_mask = _starting_collision_mask
	_is_respawning = false
	_reset_control_pose()
	reset_modular_state()
	set_physics_process(true)
	respawned.emit(self)


func _remember_recent_elimination_source(source_robot: RobotBase) -> void:
	if not is_instance_valid(source_robot):
		return
	if source_robot == self:
		return

	_recent_elimination_source_robot = source_robot
	_recent_elimination_source_remaining = elimination_attribution_window


func _update_recent_elimination_source(delta: float) -> void:
	if _recent_elimination_source_remaining <= 0.0:
		_recent_elimination_source_robot = null
		_recent_elimination_source_remaining = 0.0
		return

	_recent_elimination_source_remaining = maxf(_recent_elimination_source_remaining - delta, 0.0)
	if _recent_elimination_source_remaining == 0.0 or not is_instance_valid(_recent_elimination_source_robot):
		_recent_elimination_source_robot = null
		_recent_elimination_source_remaining = 0.0


func _update_prototype_movement(delta: float) -> void:
	var input_vector := _get_move_input_vector()
	var move_direction := Vector3(input_vector.x, 0.0, input_vector.y)
	var leg_drive_multiplier := get_effective_leg_drive_multiplier()
	var leg_control_multiplier := _get_effective_leg_control_multiplier()

	if move_direction.length_squared() > 0.0:
		var input_strength := clampf(input_vector.length(), 0.0, 1.0)
		move_direction = move_direction.normalized()
		var target_velocity := move_direction * max_move_speed * leg_drive_multiplier * input_strength
		_planar_velocity = _planar_velocity.move_toward(target_velocity, move_acceleration * leg_control_multiplier * delta)
		if not _is_disabled:
			_face_direction(move_direction, delta * leg_control_multiplier)
	else:
		_planar_velocity = _planar_velocity.move_toward(Vector3.ZERO, glide_damping * leg_control_multiplier * delta)

	external_impulse = external_impulse.move_toward(Vector3.ZERO, glide_damping * 0.75 * delta)

	velocity.x = _planar_velocity.x + external_impulse.x
	velocity.z = _planar_velocity.z + external_impulse.z
	velocity.y -= gravity * delta

	move_and_slide()

	if is_on_floor() and velocity.y < 0.0:
		velocity.y = 0.0

	_planar_velocity = Vector3(velocity.x, 0.0, velocity.z) - external_impulse
	_apply_passive_collision_pushes()


func _update_prototype_attack() -> void:
	if not is_player_controlled or _is_disabled:
		return
	if _round_intro_locked:
		return
	if is_instance_valid(_carried_part):
		return

	if not _is_attack_just_pressed():
		return

	if has_carried_item():
		use_carried_item()
		return

	if _attack_cooldown_remaining > 0.0:
		return

	_attack_cooldown_remaining = attack_cooldown
	prototype_attack_used.emit(self)

	var forward := _get_combat_forward_vector()
	var arm_power := get_effective_arm_power_multiplier()
	apply_impulse(forward * attack_impulse_strength * arm_power * 0.25)

	for node in get_tree().get_nodes_in_group("robots"):
		if node == self or not (node is RobotBase):
			continue

		var other := node as RobotBase
		var offset := other.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance <= 0.0 or distance > attack_range:
			continue

		var direction_to_other := offset / distance
		if forward.dot(direction_to_other) < 0.25:
			continue

		other.apply_impulse(direction_to_other * attack_impulse_strength * arm_power, self)
		other.receive_attack_hit_from_robot(direction_to_other, attack_damage * arm_power, self)


func _spawn_pulse_charge() -> bool:
	return _spawn_pulse_bolt(
		pulse_charge_projectile_speed,
		pulse_charge_projectile_lifetime,
		pulse_charge_impulse,
		pulse_charge_damage
	)


func _spawn_core_skill_pulse() -> bool:
	return _spawn_pulse_bolt(
		pulse_charge_projectile_speed * _get_core_skill_projectile_speed_multiplier(),
		pulse_charge_projectile_lifetime * _get_core_skill_projectile_lifetime_multiplier(),
		pulse_charge_impulse * _get_core_skill_impulse_multiplier(),
		pulse_charge_damage * _get_core_skill_damage_multiplier()
	)


func _spawn_control_beacon() -> bool:
	var scene_instance := CONTROL_BEACON_SCENE.instantiate()
	if not (scene_instance is Node3D):
		return false

	if is_instance_valid(_active_control_beacon):
		_active_control_beacon.queue_free()
		_active_control_beacon = null

	var control_beacon := scene_instance as Node3D
	var beacon_parent := get_parent()
	if beacon_parent == null:
		beacon_parent = get_tree().current_scene
	if beacon_parent == null:
		return false

	var forward := _get_combat_forward_vector()
	var spawn_position := global_position + Vector3.UP * control_beacon_spawn_height + forward * control_beacon_spawn_distance
	beacon_parent.add_child(control_beacon)
	control_beacon.call(
		"configure",
		self,
		spawn_position,
		control_beacon_radius,
		control_beacon_duration,
		control_zone_drive_multiplier,
		control_zone_control_multiplier,
		control_zone_refresh_window
	)
	_active_control_beacon = control_beacon
	return true


func _use_recovery_grab() -> bool:
	var detached_part := _find_recovery_skill_target()
	if detached_part == null:
		return false

	return detached_part.try_pick_up(self)


func _spawn_pulse_bolt(projectile_speed: float, lifetime: float, push_impulse: float, damage: float) -> bool:
	var scene_instance := PULSE_BOLT_SCENE.instantiate()
	if not (scene_instance is PulseBolt):
		return false

	var pulse_bolt := scene_instance as PulseBolt
	var projectile_parent := get_parent()
	if projectile_parent == null:
		projectile_parent = get_tree().current_scene
	if projectile_parent == null:
		return false

	var forward := _get_combat_forward_vector()
	var spawn_position := global_position + Vector3.UP * pulse_charge_spawn_height + forward * pulse_charge_spawn_distance
	projectile_parent.add_child(pulse_bolt)
	pulse_bolt.configure(
		self,
		spawn_position,
		forward,
		projectile_speed,
		lifetime,
		push_impulse,
		damage
	)
	return true


func _apply_passive_collision_pushes() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var other := collision.get_collider()
		if not (other is RobotBase):
			continue

		var other_robot := other as RobotBase
		var push_direction := global_position.direction_to(other_robot.global_position)
		push_direction.y = 0.0
		if push_direction.length_squared() == 0.0:
			push_direction = _get_combat_forward_vector()

		push_direction = push_direction.normalized()
		other_robot.apply_impulse(
			push_direction * passive_push_strength * get_effective_arm_power_multiplier(),
			self
		)
		_try_apply_collision_damage(other_robot, push_direction)


func _try_apply_collision_damage(other_robot: RobotBase, push_direction: Vector3) -> void:
	if _is_disabled:
		return
	if not _is_collision_damage_ready(other_robot):
		return

	var closing_speed := _planar_velocity.dot(push_direction)
	if closing_speed < collision_damage_threshold:
		return

	var damage_amount := (closing_speed - collision_damage_threshold) * collision_damage_scale * get_effective_arm_power_multiplier()
	if damage_amount <= 0.0:
		return

	_mark_collision_damage_cooldown(other_robot)
	other_robot.receive_collision_hit_from_robot(push_direction, damage_amount, self)


func _is_collision_damage_ready(other_robot: RobotBase) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	return now >= float(_collision_damage_ready_at.get(other_robot.get_instance_id(), 0.0))


func _mark_collision_damage_cooldown(other_robot: RobotBase) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_collision_damage_ready_at[other_robot.get_instance_id()] = now + collision_damage_cooldown


func _enter_disabled_state() -> void:
	if _is_disabled:
		return

	_is_disabled = true
	_disabled_explosion_is_unstable = is_overdrive_active()
	_attack_cooldown_remaining = 0.0
	_planar_velocity = Vector3.ZERO
	disabled_explosion_timer.start(disabled_explosion_delay)
	_refresh_disabled_warning_indicator()
	robot_disabled.emit(self)


func _exit_disabled_state() -> void:
	if not _is_disabled:
		return

	_is_disabled = false
	_disabled_explosion_is_unstable = false
	disabled_explosion_timer.stop()
	_refresh_disabled_warning_indicator()


func _spawn_detached_part(part_name: String, impact_direction: Vector3) -> void:
	var scene_instance := DETACHED_PART_SCENE.instantiate()
	if not (scene_instance is DetachedPart):
		return

	var detached_part := scene_instance as DetachedPart
	var source_visuals: Array[MeshInstance3D] = []
	for visual_node in _part_visual_nodes.get(part_name, []):
		if visual_node is MeshInstance3D:
			source_visuals.append(visual_node as MeshInstance3D)
	if source_visuals.is_empty():
		return

	var launch_direction := impact_direction
	if launch_direction.length_squared() == 0.0:
		launch_direction = _get_combat_forward_vector()

	launch_direction.y = 0.35
	launch_direction = launch_direction.normalized()
	var initial_velocity := _planar_velocity + external_impulse + launch_direction * detached_part_launch_speed

	var detach_parent := get_parent()
	if detach_parent == null:
		detach_parent = get_tree().current_scene
	if detach_parent == null:
		return

	detached_part.configure_from_visuals(self, part_name, source_visuals, initial_velocity)
	detach_parent.add_child(detached_part)
	detached_part.global_transform = global_transform
	part_destroyed.emit(self, part_name, detached_part)


func _update_detached_part_interactions() -> void:
	if _is_respawning:
		return

	if is_instance_valid(_carried_part):
		_try_deliver_carried_part()
		return

	var nearby_part := _find_nearby_detached_part()
	if nearby_part == null:
		return

	if nearby_part.try_deliver_to_robot(self):
		return

	nearby_part.try_pick_up(self)


func _try_deliver_carried_part() -> void:
	if not is_instance_valid(_carried_part):
		_carried_part = null
		return

	var owner_node := _carried_part.get_original_robot()
	if not (owner_node is RobotBase):
		return

	var owner_robot := owner_node as RobotBase
	if not is_ally_of(owner_robot):
		return
	if global_position.distance_to(owner_robot.global_position) > carried_part_return_range:
		return

	_carried_part.try_deliver_to_robot(owner_robot, self)


func _find_nearby_detached_part() -> DetachedPart:
	var nearest_part: DetachedPart = null
	var nearest_distance := detached_part_pickup_range

	for node in get_tree().get_nodes_in_group("detached_parts"):
		if not (node is DetachedPart):
			continue

		var detached_part := node as DetachedPart
		if detached_part.is_carried():
			continue

		var distance := global_position.distance_to(detached_part.global_position)
		if distance > nearest_distance:
			continue

		nearest_part = detached_part
		nearest_distance = distance

	return nearest_part


func _find_recovery_skill_target() -> DetachedPart:
	var best_part: DetachedPart = null
	var best_priority := 99
	var nearest_distance := recovery_skill_pickup_range

	for node in get_tree().get_nodes_in_group("detached_parts"):
		if not (node is DetachedPart):
			continue

		var detached_part := node as DetachedPart
		if detached_part.is_carried() or not detached_part.is_pickup_ready():
			continue

		var distance := global_position.distance_to(detached_part.global_position)
		if distance > recovery_skill_pickup_range:
			continue

		var priority := _get_recovery_skill_priority(detached_part)
		if priority > best_priority:
			continue
		if priority == best_priority and distance >= nearest_distance:
			continue

		best_part = detached_part
		best_priority = priority
		nearest_distance = distance

	return best_part


func _get_recovery_skill_priority(detached_part: DetachedPart) -> int:
	var owner_node := detached_part.get_original_robot()
	if owner_node == self:
		return 0
	if owner_node is RobotBase and is_ally_of(owner_node as RobotBase):
		return 1
	if owner_node is RobotBase:
		return 2

	return 3


func _update_energy_state(delta: float) -> void:
	_energy_shift_cooldown_remaining = maxf(_energy_shift_cooldown_remaining - delta, 0.0)
	_overdrive_cooldown_remaining = maxf(_overdrive_cooldown_remaining - delta, 0.0)

	if is_overdrive_active():
		_overdrive_duration_remaining = maxf(_overdrive_duration_remaining - delta, 0.0)
		if _overdrive_duration_remaining == 0.0:
			_overdrive_recovery_remaining = overdrive_recovery_duration
			_apply_overdrive_recovery_distribution(_overdrive_part_name)
			_refresh_visual_state()
		return

	if _overdrive_recovery_remaining <= 0.0:
		return

	_overdrive_recovery_remaining = maxf(_overdrive_recovery_remaining - delta, 0.0)
	if _overdrive_recovery_remaining == 0.0:
		_apply_focus_energy_distribution(_selected_energy_part_name)
		_refresh_visual_state()


func _update_temporary_boosts(delta: float) -> void:
	var visuals_dirty := false
	if _energy_surge_remaining > 0.0:
		_energy_surge_remaining = maxf(_energy_surge_remaining - delta, 0.0)
		if _energy_surge_remaining == 0.0:
			_energy_surge_part_name = ""
			visuals_dirty = true

	if _mobility_boost_remaining > 0.0:
		_mobility_boost_remaining = maxf(_mobility_boost_remaining - delta, 0.0)
		if _mobility_boost_remaining == 0.0:
			visuals_dirty = true

	if _stability_boost_remaining > 0.0:
		_stability_boost_remaining = maxf(_stability_boost_remaining - delta, 0.0)
		if _stability_boost_remaining == 0.0:
			_stability_received_impulse_state_multiplier = 1.0
			visuals_dirty = true

	if _ram_skill_remaining > 0.0:
		_ram_skill_remaining = maxf(_ram_skill_remaining - delta, 0.0)
		if _ram_skill_remaining == 0.0:
			visuals_dirty = true

	if _mobility_skill_remaining > 0.0:
		_mobility_skill_remaining = maxf(_mobility_skill_remaining - delta, 0.0)
		if _mobility_skill_remaining == 0.0:
			visuals_dirty = true

	if visuals_dirty:
		_refresh_visual_state()


func _update_control_zone_state(delta: float) -> void:
	if _control_zone_suppression_remaining <= 0.0:
		_clear_control_zone_suppression()
		return

	_control_zone_suppression_remaining = maxf(_control_zone_suppression_remaining - delta, 0.0)
	if _control_zone_suppression_remaining == 0.0:
		_clear_control_zone_suppression()


func _update_core_skill_state(delta: float) -> void:
	if not has_core_skill():
		_core_skill_charges = 0
		_core_skill_recharge_remaining = 0.0
		return

	var max_charges := get_core_skill_max_charges()
	if _core_skill_charges >= max_charges:
		_core_skill_charges = max_charges
		_core_skill_recharge_remaining = 0.0
		return

	var recharge_seconds := _get_core_skill_recharge_seconds()
	if recharge_seconds <= 0.0:
		return

	_core_skill_recharge_remaining = maxf(_core_skill_recharge_remaining - delta, 0.0)
	if _core_skill_recharge_remaining > 0.0:
		return

	_core_skill_charges = mini(_core_skill_charges + 1, max_charges)
	if _core_skill_charges < max_charges:
		_core_skill_recharge_remaining = recharge_seconds
	_refresh_visual_state()


func _update_energy_controls() -> void:
	if not is_player_controlled or _is_disabled:
		return
	if _round_intro_locked:
		return

	if _is_throw_part_just_pressed():
		if is_instance_valid(_carried_part):
			throw_carried_part(_get_move_input_vector())
		else:
			use_core_skill()

	if _energy_shift_cooldown_remaining <= 0.0:
		if _is_energy_prev_just_pressed():
			_cycle_energy_focus(-1)
		elif _is_energy_next_just_pressed():
			_cycle_energy_focus(1)

	if _is_overdrive_just_pressed():
		activate_overdrive()


func _cycle_energy_focus(direction: int) -> void:
	if BODY_PARTS.is_empty():
		return

	var current_index := BODY_PARTS.find(_selected_energy_part_name)
	if current_index < 0:
		current_index = 0
	var target_index := posmod(current_index + direction, BODY_PARTS.size())
	set_energy_focus(BODY_PARTS[target_index])


func throw_carried_part(throw_direction: Vector2 = Vector2.ZERO, throw_speed: float = detached_part_throw_speed) -> bool:
	if _is_disabled or not is_instance_valid(_carried_part):
		return false

	var carried_part := _carried_part
	_carried_part = null

	var world_throw_direction := Vector3(throw_direction.x, 0.0, throw_direction.y)
	if world_throw_direction.length_squared() <= 0.0001:
		world_throw_direction = _get_combat_forward_vector()

	var launched := carried_part.throw_from(self, world_throw_direction, throw_speed)
	if not launched:
		_carried_part = carried_part
		return false

	_refresh_visual_state()
	return true


func _get_move_input_vector() -> Vector2:
	if not is_player_controlled or _is_disabled:
		return Vector2.ZERO
	if _round_intro_locked:
		return Vector2.ZERO

	var keyboard_vector := Input.get_vector(
		_player_action_name("move_left"),
		_player_action_name("move_right"),
		_player_action_name("move_forward"),
		_player_action_name("move_back")
	)
	var joypad_vector := _get_joypad_move_vector()
	if joypad_vector.length_squared() > keyboard_vector.length_squared():
		return joypad_vector

	return keyboard_vector


func _get_aim_input_vector() -> Vector2:
	if not is_player_controlled or _is_disabled or control_mode != ControlMode.HARD:
		return Vector2.ZERO
	if _round_intro_locked:
		return Vector2.ZERO

	var keyboard_vector := Input.get_vector(
		_player_action_name("aim_left"),
		_player_action_name("aim_right"),
		_player_action_name("aim_forward"),
		_player_action_name("aim_back")
	)
	var best_vector := keyboard_vector
	for device in _get_joypad_devices_to_read():
		var raw_vector := Vector2(
			Input.get_joy_axis(device, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
		)
		var filtered_vector := _apply_radial_deadzone(raw_vector, hard_aim_deadzone)
		if filtered_vector.length_squared() > best_vector.length_squared():
			best_vector = filtered_vector

	return best_vector


func _get_leg_health_multiplier() -> float:
	return lerpf(0.22, 1.0, _get_pair_health_ratio("left_leg", "right_leg"))


func _get_effective_leg_control_multiplier() -> float:
	return (
		_get_leg_control_health_multiplier()
		* _get_leg_energy_multiplier()
		* _get_mobility_pickup_control_multiplier()
		* _get_control_zone_control_multiplier()
		* _get_mobility_skill_control_multiplier()
	)


func _get_leg_control_health_multiplier() -> float:
	return lerpf(0.4, 1.0, _get_pair_health_ratio("left_leg", "right_leg"))


func _get_arm_health_multiplier() -> float:
	if _is_disabled:
		return 0.0

	return lerpf(0.3, 1.0, _get_pair_health_ratio("left_arm", "right_arm"))


func _get_leg_energy_multiplier() -> float:
	return _get_pair_energy_multiplier("left_leg", "right_leg")


func _get_mobility_pickup_drive_multiplier() -> float:
	if not is_mobility_boost_active():
		return 1.0

	return mobility_pickup_drive_multiplier


func _get_mobility_pickup_control_multiplier() -> float:
	if not is_mobility_boost_active():
		return 1.0

	return mobility_pickup_control_multiplier


func _get_mobility_skill_drive_multiplier() -> float:
	if not is_mobility_skill_active():
		return 1.0
	if archetype_config == null:
		return 1.0

	return maxf(archetype_config.core_skill_drive_multiplier, 1.0)


func _get_mobility_skill_control_multiplier() -> float:
	if not is_mobility_skill_active():
		return 1.0
	if archetype_config == null:
		return 1.0

	return maxf(archetype_config.core_skill_control_multiplier, 1.0)


func _get_control_zone_drive_multiplier() -> float:
	if not is_control_zone_suppressed():
		return 1.0

	return clampf(_control_zone_drive_state_multiplier, 0.2, 1.0)


func _get_control_zone_control_multiplier() -> float:
	if not is_control_zone_suppressed():
		return 1.0

	return clampf(_control_zone_control_state_multiplier, 0.2, 1.0)


func _get_stability_received_impulse_multiplier() -> float:
	if not is_stability_boost_active():
		return 1.0

	return clampf(_stability_received_impulse_state_multiplier, 0.2, 1.0)


func _get_arm_energy_multiplier() -> float:
	if _is_disabled:
		return 0.0

	return _get_pair_energy_multiplier("left_arm", "right_arm")


func _get_pair_health_ratio(part_a: String, part_b: String) -> float:
	var part_a_ratio := get_part_health_ratio(part_a)
	var part_b_ratio := get_part_health_ratio(part_b)
	return clampf((part_a_ratio + part_b_ratio) * 0.5, 0.0, 1.0)


func _get_pair_energy_multiplier(part_a: String, part_b: String) -> float:
	var part_a_multiplier := _get_part_energy_multiplier(part_a)
	var part_b_multiplier := _get_part_energy_multiplier(part_b)
	return clampf(
		(part_a_multiplier + part_b_multiplier) * 0.5,
		minimum_energy_multiplier,
		maximum_energy_multiplier
	) * _get_energy_surge_pair_multiplier(part_a, part_b)


func _get_part_energy_multiplier(part_name: String) -> float:
	if starting_energy_per_part <= 0.0:
		return 1.0

	return clampf(
		get_part_energy_amount(part_name) / starting_energy_per_part,
		minimum_energy_multiplier,
		maximum_energy_multiplier
	)


func _is_energy_balanced() -> bool:
	for part_name in BODY_PARTS:
		if not is_equal_approx(get_part_energy_amount(part_name), starting_energy_per_part):
			return false

	return true


func _get_energy_surge_pair_multiplier(part_a: String, part_b: String) -> float:
	if not is_energy_surge_active():
		return 1.0

	var surged_pair: Array = ENERGY_LIMB_PAIRS.get(_energy_surge_part_name, [])
	if surged_pair.has(part_a) or surged_pair.has(part_b):
		return energy_pickup_pair_multiplier

	return 1.0


func _get_energy_focus_color() -> Color:
	if _selected_energy_part_name.contains("leg"):
		return Color(0.2, 0.64, 0.92, 1.0)
	return Color(0.98, 0.58, 0.14, 1.0)


func _reset_core_skill_state() -> void:
	_core_skill_charges = get_core_skill_max_charges()
	_core_skill_recharge_remaining = 0.0


func _clear_control_zone_suppression() -> void:
	var had_suppression := _control_zone_suppression_remaining > 0.0
	_control_zone_suppression_remaining = 0.0
	_control_zone_drive_state_multiplier = 1.0
	_control_zone_control_state_multiplier = 1.0
	if had_suppression:
		_refresh_visual_state()


func _clear_active_control_beacon() -> void:
	if is_instance_valid(_active_control_beacon):
		_active_control_beacon.queue_free()

	_active_control_beacon = null


func _get_core_skill_recharge_seconds() -> float:
	if archetype_config == null:
		return 0.0

	return maxf(archetype_config.core_skill_recharge_seconds, 0.0)


func _get_core_skill_projectile_speed_multiplier() -> float:
	if archetype_config == null:
		return 1.0

	return maxf(archetype_config.core_skill_projectile_speed_multiplier, 0.1)


func _get_core_skill_projectile_lifetime_multiplier() -> float:
	if archetype_config == null:
		return 1.0

	return maxf(archetype_config.core_skill_projectile_lifetime_multiplier, 0.1)


func _get_core_skill_impulse_multiplier() -> float:
	if archetype_config == null:
		return 1.0

	return maxf(archetype_config.core_skill_impulse_multiplier, 0.1)


func _get_core_skill_damage_multiplier() -> float:
	if archetype_config == null:
		return 1.0

	return maxf(archetype_config.core_skill_damage_multiplier, 0.1)


func _get_core_skill_active_duration() -> float:
	if archetype_config == null:
		return 0.0

	return maxf(archetype_config.core_skill_active_duration, 0.0)


func _get_mobility_skill_direction() -> Vector3:
	var move_input := _get_move_input_vector()
	var planar_direction := Vector3(move_input.x, 0.0, move_input.y)
	if planar_direction.length_squared() > 0.0001:
		return planar_direction.normalized()

	var velocity_direction := _planar_velocity + external_impulse
	velocity_direction.y = 0.0
	if velocity_direction.length_squared() > 0.0001:
		return velocity_direction.normalized()

	return _get_combat_forward_vector()


func _get_ram_skill_drive_multiplier() -> float:
	if not is_ram_skill_active():
		return 1.0
	if archetype_config == null:
		return 1.0

	return maxf(archetype_config.core_skill_drive_multiplier, 1.0)


func _get_ram_skill_arm_power_multiplier() -> float:
	if not is_ram_skill_active():
		return 1.0
	if archetype_config == null:
		return 1.0

	return maxf(archetype_config.core_skill_arm_power_multiplier, 1.0)


func _get_ram_skill_received_impulse_multiplier() -> float:
	if not is_ram_skill_active():
		return 1.0
	if archetype_config == null:
		return 1.0

	return clampf(archetype_config.core_skill_received_impulse_multiplier, 0.2, 1.0)


func _get_energy_visual_blend() -> float:
	if is_overdrive_active():
		return 0.85
	if _overdrive_recovery_remaining > 0.0:
		return 0.45
	if _is_energy_balanced():
		return 0.0
	return 0.28


func _apply_balanced_energy_distribution() -> void:
	for part_name in BODY_PARTS:
		part_energy[part_name] = starting_energy_per_part


func _apply_focus_energy_distribution(part_name: String) -> void:
	if not BODY_PARTS.has(part_name):
		return

	var focused_parts: Array = ENERGY_LIMB_PAIRS.get(part_name, [])
	for body_part in BODY_PARTS:
		part_energy[body_part] = unfocused_part_energy

	for focused_part in focused_parts:
		part_energy[focused_part] = focused_pair_energy

	part_energy[part_name] = focused_part_energy


func _apply_overdrive_energy_distribution(part_name: String) -> void:
	if not BODY_PARTS.has(part_name):
		return

	var focused_parts: Array = ENERGY_LIMB_PAIRS.get(part_name, [])
	for body_part in BODY_PARTS:
		part_energy[body_part] = overdrive_other_part_energy

	for focused_part in focused_parts:
		part_energy[focused_part] = overdrive_pair_energy

	part_energy[part_name] = overdrive_part_energy


func _apply_overdrive_recovery_distribution(part_name: String) -> void:
	if not BODY_PARTS.has(part_name):
		return

	var focused_parts: Array = ENERGY_LIMB_PAIRS.get(part_name, [])
	for body_part in BODY_PARTS:
		part_energy[body_part] = overdrive_recovery_other_part_energy

	for focused_part in focused_parts:
		part_energy[focused_part] = overdrive_recovery_pair_energy

	part_energy[part_name] = overdrive_recovery_part_energy


func _select_part_from_world_direction(world_direction: Vector3) -> String:
	var planar_direction := world_direction
	planar_direction.y = 0.0
	if planar_direction.length_squared() == 0.0:
		return "left_leg"

	var local_direction := _get_damage_orientation_basis().inverse() * planar_direction.normalized()
	var hits_front_half := local_direction.z <= 0.05
	var hits_left_side := local_direction.x < 0.0
	if hits_front_half:
		return "left_arm" if hits_left_side else "right_arm"

	return "left_leg" if hits_left_side else "right_leg"


func _cache_visual_references() -> void:
	_part_visual_nodes.clear()
	for part_name in BODY_PARTS:
		var nodes: Array[MeshInstance3D] = []
		for relative_path in PART_VISUAL_PATHS.get(part_name, []):
			var node := get_node_or_null(relative_path)
			if node is MeshInstance3D:
				nodes.append(node as MeshInstance3D)
		_part_visual_nodes[part_name] = nodes

	_core_visual_nodes.clear()
	for relative_path in CORE_VISUAL_PATHS:
		var node := get_node_or_null(relative_path)
		if node is MeshInstance3D:
			_core_visual_nodes.append(node as MeshInstance3D)


func _cache_part_visual_base_transforms() -> void:
	_part_visual_base_transforms.clear()
	for part_name in BODY_PARTS:
		for visual_node in _part_visual_nodes.get(part_name, []):
			if visual_node is MeshInstance3D:
				var mesh_instance := visual_node as MeshInstance3D
				_part_visual_base_transforms[_material_key(mesh_instance)] = mesh_instance.transform


func _setup_archetype_accent_visuals() -> void:
	for visual_node in _archetype_accent_visual_nodes:
		if visual_node == null:
			continue
		_material_base_values.erase(_material_key(visual_node))
	_archetype_accent_visual_nodes.clear()
	if is_instance_valid(_archetype_accent_root):
		var accent_parent := _archetype_accent_root.get_parent()
		if accent_parent != null:
			accent_parent.remove_child(_archetype_accent_root)
		_archetype_accent_root.free()
	_archetype_accent_root = null

	if upper_body_pivot == null or archetype_config == null:
		return
	if archetype_config.accent_style == RobotArchetypeConfig.AccentStyle.NONE:
		return

	var accent_root := Node3D.new()
	accent_root.name = "ArchetypeAccent"
	upper_body_pivot.add_child(accent_root)
	_archetype_accent_root = accent_root

	var accent_color := archetype_config.accent_color
	match archetype_config.accent_style:
		RobotArchetypeConfig.AccentStyle.BUMPER:
			_add_archetype_accent_box(
				accent_root,
				"RamCrossbar",
				Vector3(0.62, 0.1, 0.12),
				Vector3(0.0, 0.46, -0.72),
				accent_color
			)
			_add_archetype_accent_box(
				accent_root,
				"RamPillarLeft",
				Vector3(0.08, 0.22, 0.12),
				Vector3(-0.23, 0.39, -0.72),
				accent_color
			)
			_add_archetype_accent_box(
				accent_root,
				"RamPillarRight",
				Vector3(0.08, 0.22, 0.12),
				Vector3(0.23, 0.39, -0.72),
				accent_color
			)
		RobotArchetypeConfig.AccentStyle.LIFT:
			_add_archetype_accent_box(
				accent_root,
				"LiftMast",
				Vector3(0.1, 0.48, 0.1),
				Vector3(0.0, 0.64, -0.02),
				accent_color
			)
			_add_archetype_accent_box(
				accent_root,
				"LiftBeam",
				Vector3(0.42, 0.08, 0.08),
				Vector3(0.0, 0.86, -0.02),
				accent_color
			)
		RobotArchetypeConfig.AccentStyle.BLADES:
			_add_archetype_accent_box(
				accent_root,
				"BladeLeft",
				Vector3(0.1, 0.08, 0.46),
				Vector3(-0.28, 0.5, -0.2),
				accent_color,
				Vector3(0.0, 0.0, deg_to_rad(26.0))
			)
			_add_archetype_accent_box(
				accent_root,
				"BladeRight",
				Vector3(0.1, 0.08, 0.46),
				Vector3(0.28, 0.5, -0.2),
				accent_color,
				Vector3(0.0, 0.0, deg_to_rad(-26.0))
			)
		RobotArchetypeConfig.AccentStyle.FIN:
			_add_archetype_accent_box(
				accent_root,
				"SkateFin",
				Vector3(0.12, 0.34, 0.1),
				Vector3(0.0, 0.64, 0.38),
				accent_color,
				Vector3(deg_to_rad(-18.0), 0.0, 0.0)
			)
			_add_archetype_accent_box(
				accent_root,
				"SkateTail",
				Vector3(0.34, 0.06, 0.12),
				Vector3(0.0, 0.46, 0.5),
				accent_color
			)
		RobotArchetypeConfig.AccentStyle.SPIKE:
			_add_archetype_accent_box(
				accent_root,
				"NeedleSpike",
				Vector3(0.08, 0.08, 0.72),
				Vector3(0.0, 0.5, -0.52),
				accent_color
			)
		RobotArchetypeConfig.AccentStyle.HALO:
			_add_archetype_accent_ring(
				accent_root,
				"AnchorHalo",
				0.28,
				0.04,
				Vector3(0.0, 0.66, -0.02),
				accent_color
			)
			_add_archetype_accent_box(
				accent_root,
				"AnchorStem",
				Vector3(0.08, 0.26, 0.08),
				Vector3(0.0, 0.46, -0.02),
				accent_color
			)

	for visual_node in _archetype_accent_visual_nodes:
		_register_material_base_values(visual_node)


func _add_archetype_accent_box(
	parent: Node3D,
	node_name: String,
	size: Vector3,
	position: Vector3,
	accent_color: Color,
	rotation: Vector3 = Vector3.ZERO
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := _build_archetype_accent_visual(node_name, mesh, position, accent_color, rotation)
	parent.add_child(visual)
	_archetype_accent_visual_nodes.append(visual)


func _add_archetype_accent_ring(
	parent: Node3D,
	node_name: String,
	radius: float,
	thickness: float,
	position: Vector3,
	accent_color: Color
) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = thickness
	mesh.radial_segments = 24
	mesh.rings = 1
	var visual := _build_archetype_accent_visual(node_name, mesh, position, accent_color)
	parent.add_child(visual)
	_archetype_accent_visual_nodes.append(visual)


func _build_archetype_accent_visual(
	node_name: String,
	mesh: PrimitiveMesh,
	position: Vector3,
	accent_color: Color,
	rotation: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.position = position
	visual.rotation = rotation
	var material := StandardMaterial3D.new()
	material.albedo_color = accent_color
	material.roughness = 0.28
	material.metallic = 0.1
	material.emission_enabled = true
	material.emission = accent_color
	material.emission_energy_multiplier = 0.4
	visual.material_override = material
	return visual


func _prepare_visual_materials() -> void:
	_material_base_values.clear()
	for part_name in BODY_PARTS:
		for visual_node in _part_visual_nodes.get(part_name, []):
			_register_material_base_values(visual_node)

	for visual_node in _core_visual_nodes:
		_register_material_base_values(visual_node)

	for visual_node in _archetype_accent_visual_nodes:
		_register_material_base_values(visual_node)


func _register_material_base_values(mesh_instance: MeshInstance3D) -> void:
	var material := mesh_instance.material_override
	if material == null or not (material is StandardMaterial3D):
		return

	var duplicated_material := (material as StandardMaterial3D).duplicate()
	mesh_instance.material_override = duplicated_material
	_material_base_values[_material_key(mesh_instance)] = {
		"albedo": duplicated_material.albedo_color,
		"emission": duplicated_material.emission,
		"emission_energy": duplicated_material.emission_energy_multiplier,
	}


func _refresh_visual_state() -> void:
	_refresh_carry_indicator()
	_refresh_carry_return_indicator()
	_refresh_recovery_target_indicator()
	_refresh_lab_selection_indicator()
	_refresh_round_intro_indicator()
	_refresh_energy_focus_indicators()
	_refresh_status_effect_indicator()
	_refresh_disabled_warning_indicator()
	for part_name in BODY_PARTS:
		_refresh_part_visual_state(part_name)

	_refresh_core_visuals()
	_refresh_archetype_accent_visuals()


func _setup_damage_feedback_nodes() -> void:
	_damage_feedback_nodes.clear()
	for part_name in BODY_PARTS:
		var visuals: Array[MeshInstance3D] = _part_visual_nodes.get(part_name, [])
		if visuals.is_empty():
			continue

		var anchor := visuals[0]
		if anchor == null:
			continue

		var feedback_root := Node3D.new()
		feedback_root.name = "DamageFeedback"
		feedback_root.position = Vector3(0.0, damage_feedback_height, 0.0)
		feedback_root.visible = false
		anchor.add_child(feedback_root)

		var smoke_mesh := CylinderMesh.new()
		smoke_mesh.top_radius = 0.035
		smoke_mesh.bottom_radius = 0.085
		smoke_mesh.height = 0.24

		var smoke_material := StandardMaterial3D.new()
		smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke_material.albedo_color = Color(0.3, 0.3, 0.3, 0.65)

		var smoke := MeshInstance3D.new()
		smoke.name = "Smoke"
		smoke.mesh = smoke_mesh
		smoke.material_override = smoke_material
		smoke.visible = false
		feedback_root.add_child(smoke)

		var spark_mesh := SphereMesh.new()
		spark_mesh.radius = 0.045
		spark_mesh.height = 0.09

		var spark_material := StandardMaterial3D.new()
		spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark_material.albedo_color = Color(1.0, 0.48, 0.12, 1.0)
		spark_material.emission_enabled = true
		spark_material.emission = Color(1.0, 0.4, 0.12, 1.0)
		spark_material.emission_energy_multiplier = 1.6

		var spark := MeshInstance3D.new()
		spark.name = "Spark"
		spark.mesh = spark_mesh
		spark.material_override = spark_material
		spark.position = Vector3(0.0, 0.15, 0.0)
		spark.visible = false
		feedback_root.add_child(spark)

		var dismantle_cue_mesh := BoxMesh.new()
		dismantle_cue_mesh.size = Vector3(0.03, 0.16, 0.05)

		var dismantle_cue_material := StandardMaterial3D.new()
		dismantle_cue_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dismantle_cue_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dismantle_cue_material.no_depth_test = true
		dismantle_cue_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		dismantle_cue_material.albedo_color = Color(1.0, 0.52, 0.18, 0.72)
		dismantle_cue_material.emission_enabled = true
		dismantle_cue_material.emission = Color(1.0, 0.4, 0.12, 1.0)
		dismantle_cue_material.emission_energy_multiplier = 1.4

		var dismantle_cue := MeshInstance3D.new()
		dismantle_cue.name = "DismantleCue"
		dismantle_cue.mesh = dismantle_cue_mesh
		dismantle_cue.material_override = dismantle_cue_material
		dismantle_cue.position = Vector3(0.0, 0.18, 0.0)
		dismantle_cue.rotation_degrees = Vector3(0.0, 0.0, -28.0 if part_name.begins_with("left") else 28.0)
		dismantle_cue.visible = false
		feedback_root.add_child(dismantle_cue)

		_damage_feedback_nodes[part_name] = {
			"root": feedback_root,
			"smoke": smoke,
			"spark": spark,
			"dismantle_cue": dismantle_cue,
		}


func _setup_carry_indicator() -> void:
	var indicator_mesh := SphereMesh.new()
	indicator_mesh.radius = carry_indicator_radius
	indicator_mesh.height = maxf(carry_indicator_radius * 1.6, 0.01)

	var indicator_material := StandardMaterial3D.new()
	indicator_material.albedo_color = Color(1.0, 0.57, 0.1, 1.0)
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(1.0, 0.45, 0.08, 1.0)
	indicator_material.emission_energy_multiplier = 2.2

	_carry_indicator = MeshInstance3D.new()
	_carry_indicator.name = "CarryIndicator"
	_carry_indicator.mesh = indicator_mesh
	_carry_indicator.material_override = indicator_material
	_carry_indicator.position = Vector3(0.0, carry_indicator_base_height, 0.0)
	_carry_indicator.visible = false
	add_child(_carry_indicator)

	var owner_indicator_mesh := CylinderMesh.new()
	owner_indicator_mesh.top_radius = carry_indicator_radius * 1.75
	owner_indicator_mesh.bottom_radius = carry_indicator_radius * 1.75
	owner_indicator_mesh.height = 0.02
	owner_indicator_mesh.radial_segments = 20
	owner_indicator_mesh.rings = 1

	var owner_indicator_material := StandardMaterial3D.new()
	owner_indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	owner_indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	owner_indicator_material.no_depth_test = true
	owner_indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	owner_indicator_material.albedo_color = Color(1.0, 1.0, 1.0, 0.75)
	owner_indicator_material.emission_enabled = true
	owner_indicator_material.emission = Color(1.0, 1.0, 1.0, 1.0)
	owner_indicator_material.emission_energy_multiplier = 1.3

	_carry_owner_indicator = MeshInstance3D.new()
	_carry_owner_indicator.name = "CarryOwnerIndicator"
	_carry_owner_indicator.mesh = owner_indicator_mesh
	_carry_owner_indicator.material_override = owner_indicator_material
	_carry_owner_indicator.position = Vector3(0.0, carry_indicator_base_height - carry_indicator_radius * 0.55, 0.0)
	_carry_owner_indicator.visible = false
	add_child(_carry_owner_indicator)

	var return_indicator_mesh := BoxMesh.new()
	return_indicator_mesh.size = Vector3(
		maxf(carry_return_indicator_width, 0.01),
		maxf(carry_indicator_radius * 0.85, 0.01),
		maxf(carry_return_indicator_length, 0.01)
	)

	var return_indicator_material := StandardMaterial3D.new()
	return_indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return_indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return_indicator_material.no_depth_test = true
	return_indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return_indicator_material.albedo_color = Color(1.0, 1.0, 1.0, 0.7)
	return_indicator_material.emission_enabled = true
	return_indicator_material.emission = Color(1.0, 1.0, 1.0, 1.0)
	return_indicator_material.emission_energy_multiplier = 1.45

	_carry_return_indicator = MeshInstance3D.new()
	_carry_return_indicator.name = "CarryReturnIndicator"
	_carry_return_indicator.mesh = return_indicator_mesh
	_carry_return_indicator.material_override = return_indicator_material
	_carry_return_indicator.position = Vector3(0.0, carry_return_indicator_height, -carry_return_indicator_offset)
	_carry_return_indicator.visible = false
	add_child(_carry_return_indicator)


func _setup_recovery_target_indicator() -> void:
	var indicator_mesh := CylinderMesh.new()
	indicator_mesh.top_radius = recovery_target_indicator_radius
	indicator_mesh.bottom_radius = recovery_target_indicator_radius
	indicator_mesh.height = 0.04
	indicator_mesh.radial_segments = 24
	indicator_mesh.rings = 1

	var identity_color := get_identity_color()
	var indicator_material := StandardMaterial3D.new()
	indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator_material.no_depth_test = true
	indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	indicator_material.albedo_color = Color(identity_color.r, identity_color.g, identity_color.b, 0.8)
	indicator_material.emission_enabled = true
	indicator_material.emission = identity_color
	indicator_material.emission_energy_multiplier = 0.95

	_recovery_target_indicator = MeshInstance3D.new()
	_recovery_target_indicator.name = "RecoveryTargetIndicator"
	_recovery_target_indicator.mesh = indicator_mesh
	_recovery_target_indicator.material_override = indicator_material
	_recovery_target_indicator.position = Vector3(0.0, recovery_target_indicator_base_height, 0.0)
	_recovery_target_indicator.visible = false
	add_child(_recovery_target_indicator)

	var floor_indicator_mesh := CylinderMesh.new()
	floor_indicator_mesh.top_radius = recovery_target_floor_indicator_radius
	floor_indicator_mesh.bottom_radius = recovery_target_floor_indicator_radius
	floor_indicator_mesh.height = recovery_target_floor_indicator_thickness
	floor_indicator_mesh.radial_segments = 28
	floor_indicator_mesh.rings = 1

	var floor_indicator_material := StandardMaterial3D.new()
	floor_indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	floor_indicator_material.no_depth_test = true
	floor_indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	floor_indicator_material.albedo_color = Color(identity_color.r, identity_color.g, identity_color.b, 0.28)
	floor_indicator_material.emission_enabled = true
	floor_indicator_material.emission = identity_color
	floor_indicator_material.emission_energy_multiplier = 0.82

	_recovery_target_floor_indicator = MeshInstance3D.new()
	_recovery_target_floor_indicator.name = "RecoveryTargetFloorIndicator"
	_recovery_target_floor_indicator.mesh = floor_indicator_mesh
	_recovery_target_floor_indicator.material_override = floor_indicator_material
	_recovery_target_floor_indicator.position = Vector3(0.0, recovery_target_floor_indicator_height, 0.0)
	_recovery_target_floor_indicator.visible = false
	add_child(_recovery_target_floor_indicator)
	_refresh_recovery_target_indicator()


func _setup_lab_selection_indicator() -> void:
	var indicator_mesh := CylinderMesh.new()
	indicator_mesh.top_radius = lab_selection_indicator_radius
	indicator_mesh.bottom_radius = lab_selection_indicator_radius
	indicator_mesh.height = 0.035
	indicator_mesh.radial_segments = 32
	indicator_mesh.rings = 1

	var indicator_material := StandardMaterial3D.new()
	indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator_material.no_depth_test = true
	indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	indicator_material.albedo_color = Color(0.9, 0.96, 1.0, 0.24)
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(0.72, 0.92, 1.0, 1.0)
	indicator_material.emission_energy_multiplier = 0.85

	_lab_selection_indicator = MeshInstance3D.new()
	_lab_selection_indicator.name = "LabSelectionIndicator"
	_lab_selection_indicator.mesh = indicator_mesh
	_lab_selection_indicator.material_override = indicator_material
	_lab_selection_indicator.position = Vector3(0.0, lab_selection_indicator_height, 0.0)
	_lab_selection_indicator.visible = false
	add_child(_lab_selection_indicator)


func _setup_round_intro_indicator() -> void:
	var indicator_mesh := CylinderMesh.new()
	indicator_mesh.top_radius = round_intro_indicator_radius
	indicator_mesh.bottom_radius = round_intro_indicator_radius
	indicator_mesh.height = round_intro_indicator_thickness
	indicator_mesh.radial_segments = 32
	indicator_mesh.rings = 1

	var indicator_material := StandardMaterial3D.new()
	indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator_material.no_depth_test = true
	indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	indicator_material.albedo_color = Color(0.94, 0.98, 1.0, 0.18)
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(0.82, 0.94, 1.0, 1.0)
	indicator_material.emission_energy_multiplier = 0.65

	_round_intro_indicator = MeshInstance3D.new()
	_round_intro_indicator.name = "RoundIntroIndicator"
	_round_intro_indicator.mesh = indicator_mesh
	_round_intro_indicator.material_override = indicator_material
	_round_intro_indicator.position = Vector3(0.0, round_intro_indicator_height, 0.0)
	_round_intro_indicator.visible = false
	add_child(_round_intro_indicator)


func _setup_energy_focus_indicators() -> void:
	_energy_focus_indicator_nodes.clear()
	if _energy_readability_root == null:
		_energy_readability_root = Node3D.new()
		_energy_readability_root.name = "EnergyReadability"
		add_child(_energy_readability_root)

	for part_name in BODY_PARTS:
		var anchor := _get_energy_indicator_anchor(part_name)
		if anchor == null:
			continue

		var indicator_mesh := BoxMesh.new()
		indicator_mesh.size = _get_energy_indicator_size(part_name)

		var indicator_material := StandardMaterial3D.new()
		indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		indicator_material.no_depth_test = true
		indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		indicator_material.albedo_color = Color(0.98, 0.68, 0.2, 0.72)
		indicator_material.emission_enabled = true
		indicator_material.emission = Color(1.0, 0.72, 0.24, 1.0)
		indicator_material.emission_energy_multiplier = 1.2

		var indicator := MeshInstance3D.new()
		indicator.name = "EnergyFocusIndicator"
		indicator.mesh = indicator_mesh
		indicator.material_override = indicator_material
		indicator.position = _get_energy_indicator_local_offset(part_name)
		indicator.rotation = _get_energy_indicator_local_rotation(part_name)
		indicator.visible = false
		anchor.add_child(indicator)
		_energy_focus_indicator_nodes[part_name] = indicator


func _setup_disabled_warning_indicator() -> void:
	var indicator_mesh := CylinderMesh.new()
	indicator_mesh.top_radius = 1.0
	indicator_mesh.bottom_radius = 1.0
	indicator_mesh.height = disabled_warning_indicator_thickness
	indicator_mesh.radial_segments = 40
	indicator_mesh.rings = 1

	var indicator_material := StandardMaterial3D.new()
	indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	indicator_material.albedo_color = Color(1.0, 0.48, 0.14, 0.32)
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(1.0, 0.56, 0.18, 1.0)
	indicator_material.emission_energy_multiplier = 1.2

	_disabled_warning_indicator = MeshInstance3D.new()
	_disabled_warning_indicator.name = "DisabledWarningIndicator"
	_disabled_warning_indicator.mesh = indicator_mesh
	_disabled_warning_indicator.material_override = indicator_material
	_disabled_warning_indicator.position = Vector3(0.0, disabled_warning_indicator_height, 0.0)
	_disabled_warning_indicator.visible = false
	add_child(_disabled_warning_indicator)


func _setup_status_effect_indicator() -> void:
	var indicator_mesh := CylinderMesh.new()
	indicator_mesh.top_radius = 1.0
	indicator_mesh.bottom_radius = 1.0
	indicator_mesh.height = status_effect_indicator_thickness
	indicator_mesh.radial_segments = 28
	indicator_mesh.rings = 1

	var indicator_material := StandardMaterial3D.new()
	indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator_material.no_depth_test = true
	indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	indicator_material.albedo_color = Color(0.32, 0.96, 0.84, 0.26)
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(0.26, 0.98, 0.88, 1.0)
	indicator_material.emission_energy_multiplier = 0.95

	_status_effect_indicator = MeshInstance3D.new()
	_status_effect_indicator.name = "StatusEffectIndicator"
	_status_effect_indicator.mesh = indicator_mesh
	_status_effect_indicator.material_override = indicator_material
	_status_effect_indicator.position = Vector3(0.0, status_effect_indicator_height, 0.0)
	_status_effect_indicator.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_status_effect_indicator.visible = false
	upper_body_pivot.add_child(_status_effect_indicator)


func _refresh_carry_indicator() -> void:
	if _carry_indicator == null:
		return

	var payload_name := _get_indicator_payload_name()
	if payload_name == "":
		_carry_indicator.visible = false
		_refresh_carry_owner_indicator()
		_last_indicator_payload_name = ""
		return

	if payload_name != _last_indicator_payload_name:
		_refresh_carry_indicator_color(payload_name)
		_last_indicator_payload_name = payload_name

	_carry_indicator.visible = true
	_refresh_carry_owner_indicator()


func _refresh_recovery_target_indicator() -> void:
	if _recovery_target_indicator == null:
		return

	var should_show := has_recoverable_detached_parts() and not _is_respawning
	_recovery_target_indicator.visible = should_show
	if _recovery_target_floor_indicator != null:
		_recovery_target_floor_indicator.visible = should_show


func _refresh_lab_selection_indicator() -> void:
	if _lab_selection_indicator == null:
		return

	var should_show := _is_lab_selected and not _is_respawning
	_lab_selection_indicator.visible = should_show
	if not should_show:
		_lab_selection_indicator.scale = Vector3.ONE
		_lab_selection_indicator.position.y = lab_selection_indicator_height
		return

	var indicator_material := _lab_selection_indicator.material_override as StandardMaterial3D
	if indicator_material == null:
		return

	var cue_color := get_identity_color().lerp(Color(0.96, 0.98, 1.0, 1.0), 0.45)
	indicator_material.albedo_color = Color(cue_color.r, cue_color.g, cue_color.b, 0.28)
	indicator_material.emission = cue_color
	indicator_material.emission_energy_multiplier = 0.95


func _refresh_round_intro_indicator() -> void:
	if _round_intro_indicator == null:
		return

	var should_show := _round_intro_locked and not _is_respawning and not _is_disabled
	_round_intro_indicator.visible = should_show
	if not should_show:
		_round_intro_indicator.scale = Vector3.ONE
		_round_intro_indicator.position.y = round_intro_indicator_height
		return

	var indicator_material := _round_intro_indicator.material_override as StandardMaterial3D
	if indicator_material == null:
		return

	var cue_color := get_identity_color().lerp(Color(0.96, 0.98, 1.0, 1.0), 0.35)
	indicator_material.albedo_color = Color(cue_color.r, cue_color.g, cue_color.b, 0.22)
	indicator_material.emission = cue_color
	indicator_material.emission_energy_multiplier = 0.78


func _refresh_energy_focus_indicators() -> void:
	var active_part_name := _get_energy_readability_part_name()
	var active_pair: Array = ENERGY_LIMB_PAIRS.get(active_part_name, [])
	var active_color := _get_energy_readability_color(active_part_name)
	var show_any := active_part_name != "" and not _is_respawning
	for part_name in BODY_PARTS:
		var indicator := _energy_focus_indicator_nodes.get(part_name) as MeshInstance3D
		if indicator == null:
			continue

		var should_show := (
			show_any
			and active_pair.has(part_name)
			and get_part_health(part_name) > 0.0
		)
		indicator.visible = should_show
		if not should_show:
			indicator.scale = Vector3.ONE
			continue

		var material := indicator.material_override as StandardMaterial3D
		if material == null:
			continue

		var focus_strength := _get_energy_indicator_focus_strength(part_name, active_part_name)
		var alpha := 0.34 + focus_strength * 0.34
		material.albedo_color = Color(active_color.r, active_color.g, active_color.b, alpha)
		material.emission = active_color
		material.emission_energy_multiplier = 0.9 + focus_strength * 1.65


func _refresh_disabled_warning_indicator() -> void:
	if _disabled_warning_indicator == null:
		return

	var should_show := _is_disabled and not _is_respawning and get_disabled_explosion_time_left() > 0.0
	_disabled_warning_indicator.visible = should_show
	if not should_show:
		_disabled_warning_indicator.scale = Vector3.ONE
		return

	var explosion_radius := _get_disabled_explosion_radius_for_current_state()
	_disabled_warning_indicator.position.y = disabled_warning_indicator_height
	_disabled_warning_indicator.scale = Vector3(explosion_radius, 1.0, explosion_radius)


func _refresh_status_effect_indicator() -> void:
	if _status_effect_indicator == null:
		return

	var show_stability := is_stability_boost_active() and not _is_respawning and not _is_disabled
	var show_suppression := is_control_zone_suppressed() and not _is_respawning and not _is_disabled
	var should_show := show_stability or show_suppression
	_status_effect_indicator.visible = should_show
	if not should_show:
		_status_effect_indicator.scale = Vector3.ONE
		_status_effect_indicator.position.y = status_effect_indicator_height
		return

	var material := _status_effect_indicator.material_override as StandardMaterial3D
	if material == null:
		return

	var cue_color := Color(0.24, 0.98, 0.86, 1.0)
	var alpha := 0.24
	var emission_boost := 0.92
	if show_suppression:
		cue_color = Color(1.0, 0.4, 0.24, 1.0)
		alpha = 0.2
		emission_boost = 0.72

	material.albedo_color = Color(cue_color.r, cue_color.g, cue_color.b, alpha)
	material.emission = cue_color
	material.emission_energy_multiplier = emission_boost

	var radius_multiplier := 1.0 if show_stability else 0.82
	_status_effect_indicator.position.y = status_effect_indicator_height
	_status_effect_indicator.scale = Vector3(
		status_effect_indicator_radius * 2.0 * radius_multiplier,
		1.0,
		status_effect_indicator_radius * 2.0 * radius_multiplier
	)


func _refresh_carry_indicator_color(part_name: String) -> void:
	if _carry_indicator == null:
		return

	var material := _carry_indicator.material_override as StandardMaterial3D
	if material == null:
		return

	var color: Color = CARRY_PART_COLORS.get(part_name, CARRIED_ITEM_COLORS.get(part_name, Color(1.0, 0.57, 0.1, 1.0)))
	material.albedo_color = color
	material.emission = color
	material.emission_energy_multiplier = 2.2


func _refresh_carry_owner_indicator() -> void:
	if _carry_owner_indicator == null:
		return

	var owner_robot := _get_carried_part_owner()
	if owner_robot == null:
		_carry_owner_indicator.visible = false
		return

	var owner_material := _carry_owner_indicator.material_override as StandardMaterial3D
	if owner_material == null:
		return

	var owner_color := owner_robot.get_identity_color()
	owner_material.albedo_color = Color(owner_color.r, owner_color.g, owner_color.b, 0.8)
	owner_material.emission = owner_color
	owner_material.emission_energy_multiplier = 1.3
	_carry_owner_indicator.visible = true


func _refresh_carry_return_indicator() -> void:
	if _carry_return_indicator == null:
		return

	var owner_robot := _get_carried_part_owner()
	if owner_robot == null or owner_robot == self:
		_carry_return_indicator.visible = false
		return

	var world_direction := owner_robot.global_position - global_position
	world_direction.y = 0.0
	if world_direction.length_squared() <= 0.0001:
		_carry_return_indicator.visible = false
		return

	var owner_material := _carry_return_indicator.material_override as StandardMaterial3D
	if owner_material != null:
		var owner_color := owner_robot.get_identity_color()
		var return_ready := _is_carried_part_return_ready_with_owner(owner_robot)
		var cue_color := owner_color
		var cue_alpha := 0.72
		var cue_emission := 1.45
		if return_ready:
			cue_color = owner_color.lerp(Color(1.0, 0.96, 0.78, 1.0), 0.35)
			cue_alpha = 0.92
			cue_emission = 2.35
		owner_material.albedo_color = Color(cue_color.r, cue_color.g, cue_color.b, cue_alpha)
		owner_material.emission = cue_color
		owner_material.emission_energy_multiplier = cue_emission

	var local_direction := global_transform.basis.inverse() * world_direction.normalized()
	local_direction.y = 0.0
	if local_direction.length_squared() <= 0.0001:
		_carry_return_indicator.visible = false
		return

	var normalized_local_direction := local_direction.normalized()
	var indicator_transform := _carry_return_indicator.transform
	indicator_transform.basis = Basis.looking_at(normalized_local_direction, Vector3.UP)
	_carry_return_indicator.transform = indicator_transform
	_carry_return_indicator.position = Vector3(
		normalized_local_direction.x * carry_return_indicator_offset,
		carry_return_indicator_height,
		normalized_local_direction.z * carry_return_indicator_offset
	)
	_carry_return_indicator.visible = true


func _update_carry_indicator_animation(delta: float) -> void:
	if _carry_indicator == null:
		return
	if _get_indicator_payload_name() == "":
		_carry_indicator_animation_time = 0.0
		_carry_indicator.scale = Vector3.ONE
		_carry_indicator.rotation = Vector3.ZERO
		_carry_indicator.position.y = carry_indicator_base_height
		if _carry_owner_indicator != null:
			_carry_owner_indicator.scale = Vector3.ONE
			_carry_owner_indicator.rotation = Vector3.ZERO
			_carry_owner_indicator.position.y = carry_indicator_base_height - carry_indicator_radius * 0.55
		if _carry_return_indicator != null:
			_carry_return_indicator.scale = Vector3.ONE
		return

	_carry_indicator_animation_time += delta
	var wave := (sin(_carry_indicator_animation_time * carry_indicator_pulse_speed) + 1.0) * 0.5
	var pulse := 1.0 + (wave - 0.5) * carry_indicator_pulse_amount * 2.0
	_carry_indicator.scale = Vector3(pulse, 1.0 + pulse * 0.25, pulse)
	_carry_indicator.position.y = carry_indicator_base_height + wave * carry_indicator_bob_height
	_carry_indicator.rotation.y = fmod(_carry_indicator.rotation.y + carry_indicator_rotation_speed * delta, TAU)
	if _carry_owner_indicator != null:
		var owner_pulse := 1.0 + (wave - 0.5) * carry_indicator_pulse_amount
		_carry_owner_indicator.scale = Vector3(owner_pulse, 1.0, owner_pulse)
		_carry_owner_indicator.position.y = (
			carry_indicator_base_height
			- carry_indicator_radius * 0.55
			+ wave * carry_indicator_bob_height * 0.35
		)
		_carry_owner_indicator.rotation.y = fmod(
			_carry_owner_indicator.rotation.y - carry_indicator_rotation_speed * delta * 0.55,
			TAU
		)
	if _carry_return_indicator != null and _carry_return_indicator.visible:
		var return_ready := is_carried_part_return_ready()
		var return_pulse := 1.0 + wave * carry_indicator_pulse_amount * (1.1 if return_ready else 0.65)
		if return_ready:
			return_pulse += 0.08
		_carry_return_indicator.scale = Vector3(return_pulse, 1.0, return_pulse)
		_carry_return_indicator.position.y = (
			carry_return_indicator_height
			+ wave * carry_indicator_bob_height * (0.7 if return_ready else 0.45)
		)


func _update_recovery_target_indicator_animation(delta: float) -> void:
	if _recovery_target_indicator == null:
		return
	if not _recovery_target_indicator.visible:
		_recovery_target_indicator_animation_time = 0.0
		_recovery_target_indicator.scale = Vector3.ONE
		_recovery_target_indicator.rotation = Vector3.ZERO
		_recovery_target_indicator.position.y = recovery_target_indicator_base_height
		if _recovery_target_floor_indicator != null:
			_recovery_target_floor_indicator.scale = Vector3.ONE
			_recovery_target_floor_indicator.rotation = Vector3.ZERO
			_recovery_target_floor_indicator.position.y = recovery_target_floor_indicator_height
		return

	_recovery_target_indicator_animation_time += delta
	var wave := (sin(_recovery_target_indicator_animation_time * recovery_target_indicator_pulse_speed) + 1.0) * 0.5
	var pulse := 1.0 + (wave - 0.5) * recovery_target_indicator_pulse_amount * 2.0
	_recovery_target_indicator.scale = Vector3(pulse, 1.0, pulse)
	_recovery_target_indicator.position.y = recovery_target_indicator_base_height + wave * recovery_target_indicator_bob_height
	_recovery_target_indicator.rotation.y = fmod(_recovery_target_indicator.rotation.y + delta * 0.7, TAU)
	if _recovery_target_floor_indicator != null:
		var return_ready := _has_return_ready_recoverable_detached_part()
		var floor_pulse_amount := recovery_target_floor_indicator_pulse_amount
		if return_ready:
			floor_pulse_amount *= 1.8
		var floor_pulse := 1.0 + (wave - 0.5) * floor_pulse_amount * 2.0
		if return_ready:
			floor_pulse += 0.08
		_recovery_target_floor_indicator.scale = Vector3(floor_pulse, 1.0, floor_pulse)
		_recovery_target_floor_indicator.position.y = recovery_target_floor_indicator_height
		_recovery_target_floor_indicator.rotation.y = fmod(
			_recovery_target_floor_indicator.rotation.y - delta * 0.45,
			TAU
		)
		var floor_material := _recovery_target_floor_indicator.material_override as StandardMaterial3D
		if floor_material != null:
			var identity_color := get_identity_color()
			var cue_color := identity_color
			var cue_alpha := 0.22 + wave * 0.12
			var cue_emission := 0.72 + wave * 0.26
			if return_ready:
				cue_color = identity_color.lerp(Color(1.0, 0.96, 0.78, 1.0), 0.28)
				cue_alpha = 0.34 + wave * 0.16
				cue_emission = 1.18 + wave * 0.42
			floor_material.albedo_color = Color(cue_color.r, cue_color.g, cue_color.b, cue_alpha)
			floor_material.emission = cue_color
			floor_material.emission_energy_multiplier = cue_emission


func _update_lab_selection_indicator(delta: float) -> void:
	if _lab_selection_indicator == null:
		return
	if not _lab_selection_indicator.visible:
		_lab_selection_indicator_animation_time = 0.0
		_lab_selection_indicator.scale = Vector3.ONE
		_lab_selection_indicator.rotation = Vector3.ZERO
		_lab_selection_indicator.position.y = lab_selection_indicator_height
		return

	_lab_selection_indicator_animation_time += delta
	var wave := (sin(_lab_selection_indicator_animation_time * lab_selection_indicator_pulse_speed) + 1.0) * 0.5
	var pulse := 1.0 + (wave - 0.5) * lab_selection_indicator_pulse_amount * 2.0
	_lab_selection_indicator.scale = Vector3(pulse, 1.0, pulse)
	_lab_selection_indicator.position.y = lab_selection_indicator_height + wave * 0.02
	_lab_selection_indicator.rotation.y = fmod(_lab_selection_indicator.rotation.y + delta * 0.55, TAU)

	var indicator_material := _lab_selection_indicator.material_override as StandardMaterial3D
	if indicator_material == null:
		return

	var cue_color := get_identity_color().lerp(Color(0.96, 0.98, 1.0, 1.0), 0.45)
	indicator_material.albedo_color = Color(cue_color.r, cue_color.g, cue_color.b, 0.22 + wave * 0.1)
	indicator_material.emission = cue_color
	indicator_material.emission_energy_multiplier = 0.95 + wave * 0.45


func _update_round_intro_indicator(delta: float) -> void:
	if _round_intro_indicator == null:
		return
	if not _round_intro_indicator.visible:
		_round_intro_indicator_animation_time = 0.0
		_round_intro_indicator.scale = Vector3.ONE
		_round_intro_indicator.rotation = Vector3.ZERO
		_round_intro_indicator.position.y = round_intro_indicator_height
		return

	_round_intro_indicator_animation_time += delta
	var wave := (sin(_round_intro_indicator_animation_time * round_intro_indicator_pulse_speed) + 1.0) * 0.5
	var pulse := 1.0 + (wave - 0.5) * round_intro_indicator_pulse_amount * 2.0
	_round_intro_indicator.scale = Vector3(pulse, 1.0, pulse)
	_round_intro_indicator.position.y = round_intro_indicator_height + wave * 0.01
	_round_intro_indicator.rotation.y = fmod(_round_intro_indicator.rotation.y + delta * 0.6, TAU)

	var indicator_material := _round_intro_indicator.material_override as StandardMaterial3D
	if indicator_material == null:
		return

	var cue_color := get_identity_color().lerp(Color(0.96, 0.98, 1.0, 1.0), 0.35)
	indicator_material.albedo_color = Color(cue_color.r, cue_color.g, cue_color.b, 0.16 + wave * 0.1)
	indicator_material.emission = cue_color
	indicator_material.emission_energy_multiplier = 0.78 + wave * 0.38


func _update_energy_focus_indicator_animation(delta: float) -> void:
	var active_part_name := _get_energy_readability_part_name()
	if active_part_name == "":
		_energy_focus_indicator_animation_time = 0.0
		for indicator in _energy_focus_indicator_nodes.values():
			if indicator is MeshInstance3D:
				(indicator as MeshInstance3D).scale = Vector3.ONE
		return

	_energy_focus_indicator_animation_time += delta
	var wave := (sin(_energy_focus_indicator_animation_time * energy_focus_indicator_pulse_speed) + 1.0) * 0.5
	for part_name in BODY_PARTS:
		var indicator := _energy_focus_indicator_nodes.get(part_name) as MeshInstance3D
		if indicator == null or not indicator.visible:
			continue

		var focus_strength := _get_energy_indicator_focus_strength(part_name, active_part_name)
		var pulse_strength := 1.0 + (wave - 0.5) * energy_focus_indicator_pulse_amount * 2.0 * focus_strength
		indicator.scale = Vector3(1.0, pulse_strength, 1.0 + (pulse_strength - 1.0) * 0.4)
		indicator.position = _get_energy_indicator_local_offset(part_name) + Vector3(0.0, wave * 0.012 * focus_strength, 0.0)

		var material := indicator.material_override as StandardMaterial3D
		if material == null:
			continue

		material.emission_energy_multiplier = (
			0.9
			+ focus_strength * 1.65
			+ wave * 0.35 * focus_strength
		)


func _update_disabled_warning_indicator(delta: float) -> void:
	if _disabled_warning_indicator == null:
		return
	if not _disabled_warning_indicator.visible:
		_disabled_warning_indicator_animation_time = 0.0
		_disabled_warning_indicator.scale.y = 1.0
		return

	_disabled_warning_indicator_animation_time += delta
	var warning_progress := 0.0
	if disabled_explosion_delay > 0.0:
		warning_progress = 1.0 - clampf(get_disabled_explosion_time_left() / disabled_explosion_delay, 0.0, 1.0)
	var wave := (sin(_disabled_warning_indicator_animation_time * disabled_warning_indicator_pulse_speed) + 1.0) * 0.5
	var pulse_scale := 1.0 + wave * disabled_warning_indicator_pulse_amount
	_disabled_warning_indicator.scale.y = pulse_scale

	var material := _disabled_warning_indicator.material_override as StandardMaterial3D
	if material == null:
		return

	var warning_color := Color(1.0, 0.48, 0.14, 0.3)
	if is_disabled_explosion_unstable():
		warning_color = Color(1.0, 0.28, 0.08, 0.38)
	material.albedo_color = warning_color
	material.emission = warning_color.lightened(0.18)
	material.emission_energy_multiplier = 1.2 + wave * 0.4 + warning_progress * 1.3


func _update_status_effect_indicator(delta: float) -> void:
	if _status_effect_indicator == null:
		return
	if not _status_effect_indicator.visible:
		_status_effect_indicator_animation_time = 0.0
		_status_effect_indicator.scale.y = 1.0
		_status_effect_indicator.position.y = status_effect_indicator_height
		return

	_status_effect_indicator_animation_time += delta
	var wave := (sin(_status_effect_indicator_animation_time * status_effect_indicator_pulse_speed) + 1.0) * 0.5
	var pulse_scale := 1.0 + (wave - 0.5) * status_effect_indicator_pulse_amount * 2.0
	var show_stability := is_stability_boost_active() and not _is_respawning and not _is_disabled
	var radius_multiplier := 1.0 if show_stability else 0.82
	_status_effect_indicator.scale.x = status_effect_indicator_radius * 2.0 * radius_multiplier * pulse_scale
	_status_effect_indicator.scale.z = status_effect_indicator_radius * 2.0 * radius_multiplier * pulse_scale
	_status_effect_indicator.scale.y = 1.0 + wave * 0.08
	_status_effect_indicator.position.y = status_effect_indicator_height + wave * 0.018

	var material := _status_effect_indicator.material_override as StandardMaterial3D
	if material == null:
		return

	var cue_color := Color(0.24, 0.98, 0.86, 1.0)
	var base_alpha := 0.24
	var base_emission := 0.92
	if is_control_zone_suppressed():
		cue_color = Color(1.0, 0.4, 0.24, 1.0)
		base_alpha = 0.2
		base_emission = 0.72

	material.albedo_color = Color(cue_color.r, cue_color.g, cue_color.b, base_alpha + wave * 0.08)
	material.emission = cue_color
	material.emission_energy_multiplier = base_emission + wave * 0.4


func _get_indicator_payload_name() -> String:
	if is_carrying_part():
		return get_carried_part_name()
	if has_carried_item():
		return get_carried_item_name()

	return ""


func _get_carried_part_owner() -> RobotBase:
	if not is_instance_valid(_carried_part):
		return null

	var owner_node := _carried_part.get_original_robot()
	if owner_node is RobotBase:
		return owner_node as RobotBase

	return null


func _is_carried_part_return_ready_with_owner(owner_robot: RobotBase) -> bool:
	if owner_robot == null or owner_robot == self:
		return false
	if not is_instance_valid(_carried_part):
		return false
	if not is_ally_of(owner_robot):
		return false

	return global_position.distance_to(owner_robot.global_position) <= carried_part_return_range


func _has_return_ready_recoverable_detached_part() -> bool:
	if _is_respawning:
		return false
	if get_tree() == null:
		return false

	for node in get_tree().get_nodes_in_group("detached_parts"):
		if not (node is DetachedPart):
			continue

		var detached_part := node as DetachedPart
		if detached_part.get_original_robot() != self:
			continue
		if not detached_part.is_carried():
			continue
		if not (detached_part.carrier_robot is RobotBase):
			continue

		var carrier_robot := detached_part.carrier_robot as RobotBase
		if not is_ally_of(carrier_robot):
			continue
		if carrier_robot.global_position.distance_to(global_position) <= carrier_robot.carried_part_return_range:
			return true

	return false


func _get_energy_readability_part_name() -> String:
	if _selected_energy_part_name == "":
		return ""
	if is_overdrive_active() and _overdrive_part_name != "":
		return _overdrive_part_name
	if _overdrive_recovery_remaining > 0.0 and _overdrive_part_name != "":
		return _overdrive_part_name
	if is_energy_surge_active() and _energy_surge_part_name != "":
		return _energy_surge_part_name
	if _is_energy_balanced():
		return ""
	return _selected_energy_part_name


func _get_energy_readability_color(part_name: String) -> Color:
	var base_color := _get_energy_focus_color()
	if part_name.contains("leg"):
		base_color = Color(0.22, 0.82, 1.0, 1.0)
	else:
		base_color = Color(1.0, 0.66, 0.18, 1.0)
	if is_overdrive_active() and part_name == _overdrive_part_name:
		return base_color.lerp(Color(1.0, 0.3, 0.12, 1.0), 0.65)
	if _overdrive_recovery_remaining > 0.0 and part_name == _overdrive_part_name:
		return base_color.lerp(Color(1.0, 0.88, 0.42, 1.0), 0.35)
	if is_energy_surge_active() and part_name == _energy_surge_part_name:
		return base_color.lerp(Color(0.95, 0.98, 1.0, 1.0), 0.25)
	return base_color


func _get_energy_indicator_focus_strength(part_name: String, active_part_name: String) -> float:
	if part_name == active_part_name:
		if is_overdrive_active():
			return 1.35
		if _overdrive_recovery_remaining > 0.0:
			return 1.0
		return 1.15
	if is_overdrive_active():
		return 0.78
	if _overdrive_recovery_remaining > 0.0:
		return 0.72
	return 0.68


func _get_energy_indicator_anchor(part_name: String) -> MeshInstance3D:
	var visuals: Array[MeshInstance3D] = _part_visual_nodes.get(part_name, [])
	if visuals.is_empty():
		return null
	return visuals[0]


func _get_energy_indicator_size(part_name: String) -> Vector3:
	if part_name.contains("arm"):
		return Vector3(
			maxf(energy_focus_indicator_thickness, 0.01),
			maxf(energy_focus_indicator_thickness * 0.9, 0.01),
			maxf(energy_focus_indicator_length, 0.01)
		)
	return Vector3(
		maxf(energy_focus_indicator_thickness * 1.1, 0.01),
		maxf(energy_focus_indicator_thickness * 0.9, 0.01),
		maxf(energy_focus_indicator_length * 0.82, 0.01)
	)


func _get_energy_indicator_local_offset(part_name: String) -> Vector3:
	if part_name == "left_arm":
		return Vector3(0.0, 0.18, -0.12)
	if part_name == "right_arm":
		return Vector3(0.0, 0.18, -0.12)
	if part_name == "left_leg":
		return Vector3(0.0, 0.2, 0.1)
	if part_name == "right_leg":
		return Vector3(0.0, 0.2, 0.1)
	return Vector3.ZERO


func _get_energy_indicator_local_rotation(part_name: String) -> Vector3:
	if part_name.contains("arm"):
		return Vector3(deg_to_rad(12.0), 0.0, 0.0)
	return Vector3(deg_to_rad(-12.0), 0.0, 0.0)


func _clear_carried_item() -> void:
	if not has_carried_item():
		return

	_carried_item_name = ""
	_refresh_visual_state()


func _refresh_part_visual_state(part_name: String) -> void:
	var visuals: Array[MeshInstance3D] = []
	for visual_node in _part_visual_nodes.get(part_name, []):
		if visual_node is MeshInstance3D:
			visuals.append(visual_node as MeshInstance3D)
	var health_ratio := get_part_health_ratio(part_name)
	var flash_strength := float(_part_flash_strength.get(part_name, 0.0))
	var should_be_visible := health_ratio > 0.0

	for visual_node in visuals:
		_apply_damaged_part_pose(visual_node, part_name, health_ratio if should_be_visible else 1.0)
		visual_node.visible = should_be_visible
		if should_be_visible:
			_apply_material_damage_tint(visual_node, health_ratio, flash_strength)

	_refresh_part_damage_feedback(part_name)


func _refresh_part_damage_feedback(part_name: String) -> void:
	var feedback_nodes: Dictionary = _damage_feedback_nodes.get(part_name, {})
	if feedback_nodes.is_empty():
		return

	var root := feedback_nodes.get("root") as Node3D
	var smoke := feedback_nodes.get("smoke") as MeshInstance3D
	var spark := feedback_nodes.get("spark") as MeshInstance3D
	var dismantle_cue := feedback_nodes.get("dismantle_cue") as MeshInstance3D
	if smoke == null or spark == null or dismantle_cue == null:
		return

	var health_ratio := get_part_health_ratio(part_name)
	var show_smoke := health_ratio > 0.0 and health_ratio < damage_feedback_threshold
	var show_spark := health_ratio > 0.0 and health_ratio <= critical_damage_feedback_threshold
	var dismantle_cue_blend := _get_damaged_part_bonus_cue_blend(part_name)
	var show_dismantle_cue := health_ratio > 0.0 and dismantle_cue_blend > 0.0

	if root != null:
		root.visible = show_smoke or show_spark or show_dismantle_cue

	if not show_smoke and not show_spark and not show_dismantle_cue:
		smoke.visible = false
		spark.visible = false
		dismantle_cue.visible = false
		return

	var damage_severity := 1.0 - clampf(health_ratio / maxf(damage_feedback_threshold, 0.01), 0.0, 1.0)
	smoke.visible = show_smoke
	smoke.scale = Vector3(
		0.8 + damage_severity * 0.55,
		0.95 + damage_severity * 1.15,
		0.8 + damage_severity * 0.55
	)
	var smoke_material := smoke.material_override as StandardMaterial3D
	if smoke_material != null:
		smoke_material.albedo_color = Color(
			0.26 + damage_severity * 0.18,
			0.26 - damage_severity * 0.05,
			0.26 - damage_severity * 0.08,
			0.52 + damage_severity * 0.22
		)

	spark.visible = show_spark
	if show_spark:
		var critical_severity := 1.0 - clampf(health_ratio / maxf(critical_damage_feedback_threshold, 0.01), 0.0, 1.0)
		spark.position = Vector3(0.0, 0.15 + critical_severity * 0.08, 0.0)
		spark.scale = Vector3.ONE * (0.85 + critical_severity * 0.95)
		var spark_material := spark.material_override as StandardMaterial3D
		if spark_material != null:
			var spark_color := Color(1.0, 0.46 + critical_severity * 0.14, 0.12, 1.0)
			spark_material.albedo_color = spark_color
			spark_material.emission = spark_color
			spark_material.emission_energy_multiplier = 1.6 + critical_severity * 2.0

	dismantle_cue.visible = show_dismantle_cue
	if not show_dismantle_cue:
		return

	var dismantle_wave := (sin(_carry_indicator_animation_time * 10.0) + 1.0) * 0.5
	var cue_scale := 0.82 + dismantle_cue_blend * 0.35 + dismantle_wave * 0.08
	dismantle_cue.scale = Vector3(1.0, cue_scale, 1.0 + dismantle_cue_blend * 0.3)
	dismantle_cue.position.y = 0.18 + dismantle_wave * 0.03
	var dismantle_cue_material := dismantle_cue.material_override as StandardMaterial3D
	if dismantle_cue_material != null:
		var cue_color := Color(1.0, 0.56 + dismantle_wave * 0.12, 0.18, 1.0)
		dismantle_cue_material.albedo_color = Color(cue_color.r, cue_color.g, cue_color.b, 0.42 + dismantle_cue_blend * 0.36)
		dismantle_cue_material.emission = cue_color
		dismantle_cue_material.emission_energy_multiplier = 1.2 + dismantle_cue_blend * 1.8


func _apply_damaged_part_pose(mesh_instance: MeshInstance3D, part_name: String, health_ratio: float) -> void:
	if mesh_instance == null:
		return

	var transform_key := _material_key(mesh_instance)
	var base_transform: Transform3D = _part_visual_base_transforms.get(transform_key, mesh_instance.transform)
	var damage_severity := _get_damaged_part_pose_severity(health_ratio)
	if damage_severity <= 0.0:
		mesh_instance.transform = base_transform
		return

	var side_sign := -1.0 if part_name.begins_with("left") else 1.0
	var pose_basis := Basis.IDENTITY
	var pose_offset := Vector3(0.0, -damaged_part_pose_drop * damage_severity, 0.0)
	if part_name.contains("arm"):
		pose_offset.x += damaged_arm_pose_side_offset * damage_severity * side_sign
		pose_basis = pose_basis.rotated(
			Vector3.FORWARD,
			deg_to_rad(damaged_arm_pose_roll_degrees * damage_severity * -side_sign)
		)
		pose_basis = pose_basis.rotated(
			Vector3.RIGHT,
			deg_to_rad(damaged_part_pose_splay_degrees * damage_severity)
		)
	else:
		pose_offset.z += damaged_leg_pose_back_offset * damage_severity
		pose_basis = pose_basis.rotated(
			Vector3.RIGHT,
			deg_to_rad(damaged_leg_pose_pitch_degrees * damage_severity)
		)
		pose_basis = pose_basis.rotated(
			Vector3.FORWARD,
			deg_to_rad(damaged_part_pose_splay_degrees * damage_severity * -side_sign)
		)

	var damaged_transform := base_transform
	damaged_transform.origin = base_transform.origin + pose_offset
	damaged_transform.basis = base_transform.basis * pose_basis
	mesh_instance.transform = damaged_transform


func _get_damaged_part_pose_severity(health_ratio: float) -> float:
	if health_ratio <= 0.0:
		return 0.0

	var threshold := maxf(damage_feedback_threshold, 0.01)
	if health_ratio >= threshold:
		return 0.0

	return 1.0 - clampf(health_ratio / threshold, 0.0, 1.0)


func _update_passive_status_state(delta: float) -> void:
	var should_refresh := false
	if _damaged_part_bonus_remaining > 0.0:
		_damaged_part_bonus_remaining = maxf(_damaged_part_bonus_remaining - delta, 0.0)
		should_refresh = true

	for part_name in BODY_PARTS:
		var cue_remaining := float(_damaged_part_bonus_cue_remaining.get(part_name, 0.0))
		if cue_remaining <= 0.0:
			continue

		_damaged_part_bonus_cue_remaining[part_name] = maxf(cue_remaining - delta, 0.0)
		should_refresh = true

	if should_refresh:
		_refresh_visual_state()


func _trigger_damaged_part_bonus_feedback() -> void:
	if get_damaged_part_bonus_damage_multiplier() <= 1.0:
		return

	var previous_remaining := _damaged_part_bonus_remaining
	_damaged_part_bonus_remaining = maxf(_damaged_part_bonus_remaining, damaged_part_bonus_highlight_duration)
	if _damaged_part_bonus_remaining > previous_remaining:
		_refresh_visual_state()


func _trigger_damaged_part_bonus_victim_feedback(part_name: String) -> void:
	if not BODY_PARTS.has(part_name):
		return

	var previous_remaining := float(_damaged_part_bonus_cue_remaining.get(part_name, 0.0))
	_damaged_part_bonus_cue_remaining[part_name] = maxf(previous_remaining, damaged_part_bonus_highlight_duration)
	if float(_damaged_part_bonus_cue_remaining.get(part_name, 0.0)) > previous_remaining:
		_refresh_visual_state()


func _refresh_archetype_accent_visuals() -> void:
	if _archetype_accent_visual_nodes.is_empty():
		return

	var archetype_color := _get_archetype_accent_color().lerp(get_identity_color(), 0.24)
	var core_skill_color := _get_core_skill_accent_color()
	var core_skill_ready_blend := _get_archetype_accent_core_skill_ready_blend()
	var core_skill_active_blend := _get_archetype_accent_core_skill_active_blend()
	var passive_color := Color(1.0, 0.42, 0.16, 1.0)
	var passive_blend := _get_passive_accent_blend()
	var intact_ratio := 1.0
	if not BODY_PARTS.is_empty():
		var alive_parts := 0.0
		for part_name in BODY_PARTS:
			alive_parts += get_part_health_ratio(part_name)
		intact_ratio = alive_parts / BODY_PARTS.size()

	var damage_blend := (1.0 - intact_ratio) * 0.22
	var disabled_blend := 0.4 if _is_disabled else 0.0
	for visual_node in _archetype_accent_visual_nodes:
		var material := visual_node.material_override as StandardMaterial3D
		var base_values: Dictionary = _material_base_values.get(_material_key(visual_node), {})
		if material == null or base_values.is_empty():
			continue

		var base_albedo: Color = base_values["albedo"]
		var base_emission: Color = base_values["emission"]
		material.albedo_color = base_albedo.lerp(archetype_color, 0.78)
		material.albedo_color = material.albedo_color.lerp(core_skill_color, core_skill_ready_blend * 0.12)
		material.albedo_color = material.albedo_color.lerp(core_skill_color.lightened(0.16), core_skill_active_blend * 0.18)
		material.albedo_color = material.albedo_color.lerp(passive_color, passive_blend * 0.22)
		material.albedo_color = material.albedo_color.lerp(Color(0.1, 0.1, 0.1, 1.0), damage_blend + disabled_blend)
		if material.emission_enabled:
			material.emission = base_emission.lerp(archetype_color, 0.95)
			material.emission = material.emission.lerp(core_skill_color, core_skill_ready_blend * 0.72)
			material.emission = material.emission.lerp(core_skill_color.lightened(0.2), core_skill_active_blend)
			material.emission = material.emission.lerp(passive_color, passive_blend)
			material.emission = material.emission.lerp(Color(0.18, 0.12, 0.1, 1.0), disabled_blend * 0.8)
			material.emission_energy_multiplier = maxf(
				0.18,
				0.52
				- damage_blend * 0.15
				- disabled_blend * 0.22
				+ core_skill_ready_blend * 0.28
				+ core_skill_active_blend * 0.62
				+ passive_blend * 0.55
			)


func _get_archetype_accent_color() -> Color:
	if archetype_config == null:
		return get_identity_color()

	return archetype_config.accent_color


func _get_core_skill_accent_color() -> Color:
	if not has_core_skill():
		return _get_archetype_accent_color()

	match archetype_config.core_skill_type:
		RobotArchetypeConfig.CoreSkillType.PULSE_SHOT:
			return Color(0.28, 0.9, 1.0, 1.0)
		RobotArchetypeConfig.CoreSkillType.CONTROL_BEACON:
			return Color(1.0, 0.78, 0.3, 1.0)
		RobotArchetypeConfig.CoreSkillType.RECOVERY_GRAB:
			return Color(0.66, 1.0, 0.72, 1.0)
		RobotArchetypeConfig.CoreSkillType.RAM_BOOST:
			return Color(1.0, 0.56, 0.18, 1.0)
		RobotArchetypeConfig.CoreSkillType.MOBILITY_BURST:
			return Color(0.22, 0.98, 0.76, 1.0)
		_:
			return _get_archetype_accent_color()


func _get_archetype_accent_core_skill_ready_blend() -> float:
	if not has_core_skill():
		return 0.0
	if get_core_skill_charge_count() <= 0 or get_core_skill_max_charges() <= 0:
		return 0.0

	var charge_ratio := clampf(
		float(get_core_skill_charge_count()) / float(get_core_skill_max_charges()),
		0.0,
		1.0
	)
	var wave := (sin(_core_skill_visual_time * core_skill_ready_pulse_speed) + 1.0) * 0.5
	var pulse := 1.0 + (wave - 0.5) * core_skill_ready_pulse_amount * 2.0
	return clampf(charge_ratio * pulse, 0.0, 1.0)


func _get_archetype_accent_core_skill_active_blend() -> float:
	if not has_core_skill():
		return 0.0
	if is_ram_skill_active():
		return 1.0
	if is_mobility_skill_active():
		return 0.92
	if is_instance_valid(_active_control_beacon):
		return 0.52

	return 0.0


func _get_passive_accent_blend() -> float:
	if _damaged_part_bonus_remaining <= 0.0:
		return 0.0
	if damaged_part_bonus_highlight_duration <= 0.0:
		return 1.0

	var time_ratio := clampf(_damaged_part_bonus_remaining / damaged_part_bonus_highlight_duration, 0.0, 1.0)
	var wave := (sin(_carry_indicator_animation_time * 8.0) + 1.0) * 0.5
	var pulse := 0.82 + wave * 0.18
	return clampf(time_ratio * pulse, 0.0, 1.0)


func _get_damaged_part_bonus_cue_blend(part_name: String) -> float:
	var cue_remaining := float(_damaged_part_bonus_cue_remaining.get(part_name, 0.0))
	if cue_remaining <= 0.0:
		return 0.0
	if damaged_part_bonus_highlight_duration <= 0.0:
		return 1.0

	var time_ratio := clampf(cue_remaining / damaged_part_bonus_highlight_duration, 0.0, 1.0)
	var wave := (sin(_carry_indicator_animation_time * 9.0) + 1.0) * 0.5
	var pulse := 0.86 + wave * 0.14
	return clampf(time_ratio * pulse, 0.0, 1.0)


func _refresh_core_visuals() -> void:
	var intact_ratio := 1.0
	if not BODY_PARTS.is_empty():
		var alive_parts := 0.0
		for part_name in BODY_PARTS:
			alive_parts += get_part_health_ratio(part_name)
		intact_ratio = alive_parts / BODY_PARTS.size()

	for visual_node in _core_visual_nodes:
		var material := visual_node.material_override as StandardMaterial3D
		var base_values: Dictionary = _material_base_values.get(_material_key(visual_node), {})
		if material == null or base_values.is_empty():
			continue

		var base_albedo: Color = base_values["albedo"]
		var base_emission: Color = base_values["emission"]
		var base_emission_energy: float = float(base_values["emission_energy"])
		var identity_strength := _get_identity_visual_strength(visual_node)
		if identity_strength > 0.0:
			var identity_color := get_identity_color()
			base_albedo = base_albedo.lerp(identity_color, identity_strength)
			base_emission = base_emission.lerp(identity_color, minf(identity_strength + 0.12, 1.0))
			base_emission_energy = maxf(base_emission_energy, 0.35 + identity_strength * 0.45)
		var damage_blend := (1.0 - intact_ratio) * 0.4
		var disabled_blend := 0.55 if _is_disabled else 0.0
		var unstable_blend := 0.35 if is_disabled_explosion_unstable() else 0.0
		var energy_color := _get_energy_focus_color()
		var energy_blend := _get_energy_visual_blend()
		var energy_surge_blend := 0.22 if is_energy_surge_active() else 0.0
		var mobility_color := Color(0.2, 0.92, 0.78, 1.0)
		var mobility_blend := 0.66 if is_mobility_skill_active() else (0.42 if is_mobility_boost_active() else 0.0)
		var ram_color := Color(1.0, 0.56, 0.18, 1.0)
		var ram_blend := 0.48 if is_ram_skill_active() else 0.0
		var core_skill_color := Color(0.22, 0.88, 1.0, 1.0)
		var core_skill_blend := _get_core_skill_visual_blend(visual_node)
		material.albedo_color = base_albedo.lerp(Color(0.09, 0.08, 0.08, 1.0), damage_blend + disabled_blend)
		material.albedo_color = material.albedo_color.lerp(energy_color, energy_blend * 0.18)
		material.albedo_color = material.albedo_color.lerp(Color(0.96, 0.97, 1.0, 1.0), energy_surge_blend * 0.12)
		material.albedo_color = material.albedo_color.lerp(mobility_color, mobility_blend * 0.12)
		material.albedo_color = material.albedo_color.lerp(ram_color, ram_blend * 0.18)
		material.albedo_color = material.albedo_color.lerp(core_skill_color, core_skill_blend * 0.1)
		material.albedo_color = material.albedo_color.lerp(Color(1.0, 0.62, 0.18, 1.0), unstable_blend * 0.18)
		if material.emission_enabled:
			var warning_color := Color(1.0, 0.28, 0.12, 1.0)
			material.emission = base_emission.lerp(warning_color, damage_blend + disabled_blend)
			material.emission = material.emission.lerp(energy_color, energy_blend)
			material.emission = material.emission.lerp(Color(0.96, 0.97, 1.0, 1.0), energy_surge_blend)
			material.emission = material.emission.lerp(mobility_color, mobility_blend)
			material.emission = material.emission.lerp(ram_color, ram_blend)
			material.emission = material.emission.lerp(core_skill_color, core_skill_blend)
			material.emission = material.emission.lerp(Color(1.0, 0.66, 0.18, 1.0), unstable_blend)
			material.emission_energy_multiplier = maxf(
				base_emission_energy + core_skill_blend * core_skill_ready_emission_boost,
				0.12
				+ disabled_blend * 0.85
				+ energy_blend * 0.75
				+ energy_surge_blend * 0.55
				+ mobility_blend * 0.7
				+ ram_blend * 0.8
				+ unstable_blend * 0.8
			)


func _get_identity_visual_strength(visual_node: MeshInstance3D) -> float:
	if visual_node == null:
		return 0.0

	match visual_node.name:
		"FacingMarker":
			return 0.9
		"LeftCoreLight", "RightCoreLight":
			return 1.0

	return 0.0


func _get_core_skill_visual_blend(visual_node: MeshInstance3D) -> float:
	if visual_node == null:
		return 0.0
	if not has_core_skill():
		return 0.0
	if get_core_skill_charge_count() <= 0 or get_core_skill_max_charges() <= 0:
		return 0.0
	if visual_node.name != "LeftCoreLight" and visual_node.name != "RightCoreLight":
		return 0.0

	var charge_ratio := clampf(float(get_core_skill_charge_count()) / float(get_core_skill_max_charges()), 0.0, 1.0)
	var wave := (sin(_core_skill_visual_time * core_skill_ready_pulse_speed) + 1.0) * 0.5
	var pulse := 1.0 + (wave - 0.5) * core_skill_ready_pulse_amount * 2.0
	return clampf(charge_ratio * pulse, 0.0, 1.0)


func _apply_material_damage_tint(mesh_instance: MeshInstance3D, health_ratio: float, flash_strength: float) -> void:
	var material := mesh_instance.material_override as StandardMaterial3D
	var base_values: Dictionary = _material_base_values.get(_material_key(mesh_instance), {})
	if material == null or base_values.is_empty():
		return

	var base_albedo: Color = base_values["albedo"]
	var base_emission: Color = base_values["emission"]
	var base_emission_energy: float = float(base_values["emission_energy"])
	var damage_color := Color(0.32, 0.1, 0.09, 1.0)
	var flash_color := Color(1.0, 0.45, 0.18, 1.0)
	var damage_blend := (1.0 - health_ratio) * 0.65

	material.albedo_color = base_albedo.lerp(damage_color, damage_blend).lerp(flash_color, flash_strength * 0.65)
	if material.emission_enabled:
		material.emission = base_emission.lerp(flash_color, flash_strength * 0.85)
		material.emission_energy_multiplier = maxf(base_emission_energy, flash_strength * 0.45)


func _update_damage_visual_feedback(delta: float) -> void:
	var any_flash_updated := false
	for part_name in BODY_PARTS:
		var flash_strength := float(_part_flash_strength.get(part_name, 0.0))
		if flash_strength <= 0.0:
			continue

		_part_flash_strength[part_name] = maxf(flash_strength - delta * 4.5, 0.0)
		any_flash_updated = true

	if any_flash_updated:
		_refresh_visual_state()


func _update_core_skill_readiness_visuals(delta: float) -> void:
	if not has_core_skill() or get_core_skill_charge_count() <= 0:
		if _core_skill_visual_time != 0.0:
			_core_skill_visual_time = 0.0
			_refresh_core_visuals()
		return

	_core_skill_visual_time += delta
	_refresh_core_visuals()


func _update_control_mode_orientation(delta: float) -> void:
	if control_mode != ControlMode.HARD:
		_refresh_upper_body_pose(true)
		return

	var aim_vector := _get_aim_input_vector()
	if aim_vector.length_squared() > 0.0:
		_hard_torso_world_direction = Vector3(aim_vector.x, 0.0, aim_vector.y).normalized()
	elif _hard_torso_world_direction.length_squared() <= 0.0001:
		_hard_torso_world_direction = _get_root_forward_vector()

	_refresh_upper_body_pose(false, delta)


func _reset_control_pose() -> void:
	_hard_torso_world_direction = _get_root_forward_vector()
	_refresh_upper_body_pose(true)


func _refresh_upper_body_pose(snap: bool = false, delta: float = 0.0) -> void:
	if upper_body_pivot == null:
		return

	if control_mode != ControlMode.HARD:
		var easy_transform := upper_body_pivot.transform
		easy_transform.basis = Basis.IDENTITY
		upper_body_pivot.transform = easy_transform
		return

	var target_world_direction := _hard_torso_world_direction
	target_world_direction.y = 0.0
	if target_world_direction.length_squared() <= 0.0001:
		target_world_direction = _get_root_forward_vector()

	var local_target_direction := global_transform.basis.inverse() * target_world_direction.normalized()
	local_target_direction.y = 0.0
	if local_target_direction.length_squared() <= 0.0001:
		return

	var target_basis := Basis.looking_at(local_target_direction.normalized(), Vector3.UP)
	var new_transform := upper_body_pivot.transform
	if snap:
		new_transform.basis = target_basis
	else:
		var weight := 1.0 - exp(-torso_turn_speed * maxf(delta, 0.0))
		new_transform.basis = new_transform.basis.slerp(target_basis, weight).orthonormalized()
	upper_body_pivot.transform = new_transform


func _material_key(mesh_instance: MeshInstance3D) -> String:
	return str(mesh_instance.get_path())


func _get_root_forward_vector() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return Vector3.FORWARD

	return forward.normalized()


func _get_combat_forward_vector() -> Vector3:
	if control_mode != ControlMode.HARD:
		return _get_root_forward_vector()

	var forward := _hard_torso_world_direction
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return _get_root_forward_vector()

	return forward.normalized()


func _get_damage_orientation_basis() -> Basis:
	if control_mode == ControlMode.HARD and upper_body_pivot != null:
		return upper_body_pivot.global_transform.basis

	return global_transform.basis


func _face_direction(direction: Vector3, delta: float) -> void:
	var target_basis := Basis.looking_at(direction, Vector3.UP)
	var new_transform := global_transform
	new_transform.basis = new_transform.basis.slerp(target_basis, 1.0 - exp(-turn_speed * delta)).orthonormalized()
	global_transform = new_transform


func _player_action_name(action_suffix: String) -> StringName:
	return StringName("p%s_%s" % [player_index, action_suffix])


func _ensure_default_input_actions() -> void:
	var bindings: Dictionary = KEYBOARD_PROFILE_BINDINGS.get(keyboard_profile, {})
	for action_suffix in INPUT_ACTION_SUFFIXES:
		var action_name := _player_action_name(action_suffix)
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, joystick_deadzone)
		else:
			InputMap.action_set_deadzone(action_name, joystick_deadzone)

		_replace_action_key_events(action_name, bindings.get(action_suffix, []))


func _replace_action_key_events(action_name: StringName, keycodes: Array) -> void:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			InputMap.action_erase_event(action_name, event)

	for keycode in keycodes:
		var input_event := InputEventKey.new()
		input_event.physical_keycode = int(keycode)
		_add_input_event_if_missing(action_name, input_event)


func _add_input_event_if_missing(action_name: StringName, event: InputEvent) -> void:
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)


func _get_joypad_move_vector() -> Vector2:
	var best_vector := Vector2.ZERO
	for device in _get_joypad_devices_to_read():
		var raw_vector := Vector2(
			Input.get_joy_axis(device, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		)
		var filtered_vector := _apply_radial_deadzone(raw_vector)
		var dpad_vector := _get_dpad_move_vector(device)
		var device_vector := filtered_vector
		if dpad_vector.length_squared() > device_vector.length_squared():
			device_vector = dpad_vector

		if device_vector.length_squared() > best_vector.length_squared():
			best_vector = device_vector

	return best_vector


func _is_attack_just_pressed() -> bool:
	var keyboard_pressed := Input.is_action_just_pressed(_player_action_name("attack"))
	var joypad_pressed := _is_joypad_attack_pressed()
	var joypad_just_pressed := joypad_pressed and not _was_joypad_attack_pressed
	_was_joypad_attack_pressed = joypad_pressed
	return keyboard_pressed or joypad_just_pressed


func _is_energy_prev_just_pressed() -> bool:
	var keyboard_pressed := Input.is_action_just_pressed(_player_action_name("energy_prev"))
	var joypad_pressed := _is_joypad_button_pressed(JOY_BUTTON_LEFT_SHOULDER)
	var joypad_just_pressed := joypad_pressed and not _was_joypad_energy_prev_pressed
	_was_joypad_energy_prev_pressed = joypad_pressed
	return keyboard_pressed or joypad_just_pressed


func _is_energy_next_just_pressed() -> bool:
	var keyboard_pressed := Input.is_action_just_pressed(_player_action_name("energy_next"))
	var joypad_pressed := _is_joypad_button_pressed(JOY_BUTTON_RIGHT_SHOULDER)
	var joypad_just_pressed := joypad_pressed and not _was_joypad_energy_next_pressed
	_was_joypad_energy_next_pressed = joypad_pressed
	return keyboard_pressed or joypad_just_pressed


func _is_overdrive_just_pressed() -> bool:
	var keyboard_pressed := Input.is_action_just_pressed(_player_action_name("overdrive"))
	var joypad_pressed := _is_joypad_button_pressed(JOY_BUTTON_Y)
	var joypad_just_pressed := joypad_pressed and not _was_joypad_overdrive_pressed
	_was_joypad_overdrive_pressed = joypad_pressed
	return keyboard_pressed or joypad_just_pressed


func _is_throw_part_just_pressed() -> bool:
	var keyboard_pressed := Input.is_action_just_pressed(_player_action_name("throw_part"))
	var joypad_pressed := _is_joypad_button_pressed(JOY_BUTTON_X)
	var joypad_just_pressed := joypad_pressed and not _was_joypad_throw_pressed
	_was_joypad_throw_pressed = joypad_pressed
	return keyboard_pressed or joypad_just_pressed


func _is_joypad_attack_pressed() -> bool:
	for device in _get_joypad_devices_to_read():
		if Input.is_joy_button_pressed(device, JOY_BUTTON_A):
			return true

	return false


func _is_joypad_button_pressed(button_index: JoyButton) -> bool:
	for device in _get_joypad_devices_to_read():
		if Input.is_joy_button_pressed(device, button_index):
			return true

	return false


func _get_joypad_devices_to_read() -> Array[int]:
	var connected_devices := Input.get_connected_joypads()
	var devices: Array[int] = []
	if joypad_device >= 0:
		if connected_devices.has(joypad_device):
			devices.append(joypad_device)
		return devices

	if uses_keyboard_input():
		return devices

	return devices


func _apply_radial_deadzone(raw_vector: Vector2, deadzone: float = joystick_deadzone) -> Vector2:
	var length := raw_vector.length()
	if length <= deadzone:
		return Vector2.ZERO

	var scaled_length := inverse_lerp(deadzone, 1.0, minf(length, 1.0))
	return raw_vector.normalized() * scaled_length


func _get_dpad_move_vector(device: int) -> Vector2:
	var dpad_vector := Vector2.ZERO
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT):
		dpad_vector.x -= 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT):
		dpad_vector.x += 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP):
		dpad_vector.y -= 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN):
		dpad_vector.y += 1.0

	return dpad_vector.normalized()


func _deny_carried_part_if_any() -> void:
	if not is_instance_valid(_carried_part):
		_carried_part = null
		return

	var carried_part := _carried_part
	_carried_part = null
	carried_part.deny_to_void()


func _cleanup_owned_detached_parts() -> void:
	for node in get_tree().get_nodes_in_group("detached_parts"):
		if not (node is DetachedPart):
			continue

		var detached_part := node as DetachedPart
		if detached_part.get_original_robot() == self:
			detached_part.queue_free()


func _on_disabled_explosion_timer_timeout() -> void:
	if not _is_disabled or _is_respawning:
		return

	_deny_carried_part_if_any()
	_last_disabled_explosion_was_unstable = _disabled_explosion_is_unstable
	_apply_disabled_explosion()
	robot_exploded.emit(self)
	_start_disabled_respawn()


func _apply_disabled_explosion() -> void:
	var explosion_radius := disabled_explosion_radius
	var explosion_impulse := disabled_explosion_impulse
	var explosion_damage := disabled_explosion_damage
	if _last_disabled_explosion_was_unstable:
		explosion_radius *= unstable_disabled_explosion_radius_multiplier
		explosion_impulse *= unstable_disabled_explosion_impulse_multiplier
		explosion_damage *= unstable_disabled_explosion_damage_multiplier

	for node in get_tree().get_nodes_in_group("robots"):
		if not (node is RobotBase):
			continue

		var other_robot := node as RobotBase
		if other_robot == self:
			continue

		var offset := other_robot.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > explosion_radius:
			continue

		var direction := Vector3.FORWARD
		if distance > 0.001:
			direction = offset / distance

		var distance_ratio := 1.0 - clampf(distance / explosion_radius, 0.0, 1.0)
		other_robot.apply_impulse(direction * explosion_impulse * distance_ratio, self)
		other_robot.receive_attack_hit_from_robot(direction, explosion_damage * distance_ratio, self)


func _get_disabled_explosion_radius_for_current_state() -> float:
	var explosion_radius := disabled_explosion_radius
	if is_disabled_explosion_unstable():
		explosion_radius *= unstable_disabled_explosion_radius_multiplier

	return explosion_radius


func _start_disabled_respawn() -> void:
	_cancel_respawn_timer()
	_is_respawning = true
	_exit_disabled_state()
	if _disabled_warning_indicator != null:
		_disabled_warning_indicator.visible = false
		_disabled_warning_indicator.scale = Vector3.ONE
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	_schedule_respawn(0.9)


func _ensure_respawn_timer() -> void:
	if is_instance_valid(_respawn_timer):
		return

	_respawn_timer = Timer.new()
	_respawn_timer.name = "RespawnTimer"
	_respawn_timer.one_shot = true
	add_child(_respawn_timer)
	_respawn_timer.timeout.connect(_on_respawn_timer_timeout)


func _schedule_respawn(delay_seconds: float) -> void:
	_ensure_respawn_timer()
	_respawn_timer.start(delay_seconds)


func _cancel_respawn_timer() -> void:
	if is_instance_valid(_respawn_timer):
		_respawn_timer.stop()


func _on_respawn_timer_timeout() -> void:
	if _held_for_round_reset:
		return
	reset_to_spawn()


func _report_joypad_status() -> void:
	if uses_keyboard_input() and joypad_device < 0:
		print("%s: perfil local por teclado activo." % display_name)
		return

	var connected_devices := Input.get_connected_joypads()
	if connected_devices.is_empty():
		print("%s: no hay joystick conectado para este slot." % display_name)
		return

	var device_names: Array[String] = []
	for device in connected_devices:
		device_names.append("%s:%s" % [device, Input.get_joy_name(int(device))])

	print("%s: joysticks detectados -> %s" % [display_name, device_names])
