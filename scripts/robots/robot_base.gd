extends CharacterBody3D
class_name RobotBase

const DetachedPart = preload("res://scripts/robots/detached_part.gd")

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
}

const ENERGY_LIMB_PAIRS := {
	"left_arm": ["left_arm", "right_arm"],
	"right_arm": ["left_arm", "right_arm"],
	"left_leg": ["left_leg", "right_leg"],
	"right_leg": ["left_leg", "right_leg"],
}

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
@export var glide_damping := 3.1
@export var turn_speed := 10.0
@export var torso_turn_speed := 12.0
@export var gravity := 28.0

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

@export_group("Prototype Combat")
@export var passive_push_strength := 4.0
@export var attack_impulse_strength := 11.0
@export var attack_range := 2.3
@export var attack_cooldown := 0.42
@export var attack_damage := 28.0
@export var collision_damage_threshold := 4.1
@export var collision_damage_scale := 6.0
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
@export_group("Prototype Damage Readability")
@export_range(0.4, 1.0, 0.05) var damage_feedback_threshold := 0.8
@export_range(0.1, 0.8, 0.05) var critical_damage_feedback_threshold := 0.45
@export var damage_feedback_height := 0.24
@export var disabled_explosion_delay := 1.6
@export var disabled_explosion_radius := 3.6
@export var disabled_explosion_impulse := 12.0
@export var disabled_explosion_damage := 24.0

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
var _was_joypad_attack_pressed := false
var _was_joypad_energy_prev_pressed := false
var _was_joypad_energy_next_pressed := false
var _was_joypad_overdrive_pressed := false
var _was_joypad_throw_pressed := false
var _part_visual_nodes: Dictionary = {}
var _part_flash_strength: Dictionary = {}
var _core_visual_nodes: Array[MeshInstance3D] = []
var _material_base_values: Dictionary = {}
var _damage_feedback_nodes: Dictionary = {}
var _collision_damage_ready_at: Dictionary = {}
var _carried_part: DetachedPart = null
var _carry_indicator: MeshInstance3D = null
var _carry_indicator_animation_time := 0.0
var _last_carried_part_name := ""
var _selected_energy_part_name := "left_arm"
var _energy_shift_cooldown_remaining := 0.0
var _overdrive_part_name := ""
var _overdrive_duration_remaining := 0.0
var _overdrive_recovery_remaining := 0.0
var _overdrive_cooldown_remaining := 0.0
var _hard_torso_world_direction := Vector3.FORWARD

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


func is_carrying_part() -> bool:
	return is_instance_valid(_carried_part)


func get_carried_part_name() -> String:
	if not is_instance_valid(_carried_part):
		return ""

	return _carried_part.part_name


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
	return _get_leg_health_multiplier() * _get_leg_energy_multiplier()


func get_effective_arm_power_multiplier() -> float:
	return _get_arm_health_multiplier() * _get_arm_energy_multiplier()


func is_overdrive_active() -> bool:
	return _overdrive_duration_remaining > 0.0


func is_overdrive_cooling_down() -> bool:
	return _overdrive_cooldown_remaining > 0.0


func get_input_hint() -> String:
	if uses_keyboard_input():
		var move_label := str(KEYBOARD_PROFILE_LABELS.get(keyboard_profile, "teclado"))
		if control_mode == ControlMode.HARD:
			var aim_label := str(KEYBOARD_PROFILE_HARD_AIM_LABELS.get(keyboard_profile, "stick derecho"))
			return "%s + aim %s" % [move_label, aim_label]

		return move_label

	if joypad_device >= 0:
		return "joy %s" % joypad_device

	return "joy slot %s" % max(player_index - 1, 0)


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


func _ready() -> void:
	_spawn_transform = global_transform
	_starting_collision_layer = collision_layer
	_starting_collision_mask = collision_mask
	add_to_group("robots")
	_cache_visual_references()
	_prepare_visual_materials()
	_setup_damage_feedback_nodes()
	_setup_carry_indicator()
	disabled_explosion_timer.wait_time = disabled_explosion_delay
	_reset_control_pose()
	reset_modular_state()
	if is_player_controlled:
		refresh_input_setup()


func _physics_process(delta: float) -> void:
	if _is_respawning:
		return

	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	_update_energy_state(delta)
	_update_energy_controls()
	_update_prototype_movement(delta)
	_update_control_mode_orientation(delta)
	_update_detached_part_interactions()
	_update_prototype_attack()
	_update_damage_visual_feedback(delta)
	_update_carry_indicator_animation(delta)

	if global_position.y <= void_fall_y:
		fall_into_void()


func reset_modular_state() -> void:
	_is_disabled = false
	disabled_explosion_timer.stop()
	_part_flash_strength.clear()
	_collision_damage_ready_at.clear()
	_selected_energy_part_name = "left_arm"
	_energy_shift_cooldown_remaining = 0.0
	_overdrive_part_name = ""
	_overdrive_duration_remaining = 0.0
	_overdrive_recovery_remaining = 0.0
	_overdrive_cooldown_remaining = 0.0
	for part_name in BODY_PARTS:
		part_health[part_name] = max_part_health
		part_energy[part_name] = starting_energy_per_part
		_part_flash_strength[part_name] = 0.0

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

	_refresh_visual_state()
	part_restored.emit(self, part_name, restored_by)
	return true


func try_pick_up_detached_part(detached_part: DetachedPart) -> bool:
	if detached_part == null:
		return false
	if _is_respawning or _is_disabled:
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

	_held_for_round_reset = true
	_is_respawning = true
	_attack_cooldown_remaining = 0.0
	_planar_velocity = Vector3.ZERO
	external_impulse = Vector3.ZERO
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


func apply_impulse(impulse: Vector3) -> void:
	impulse.y = 0.0
	external_impulse += impulse


func receive_collision_hit(impact_direction: Vector3, damage_amount: float) -> void:
	if damage_amount <= 0.0 or is_fully_disabled():
		return

	var hit_part := _select_part_from_world_direction(impact_direction)
	apply_damage_to_part(hit_part, damage_amount, impact_direction)


func receive_attack_hit(impact_direction: Vector3, damage_amount: float) -> void:
	if damage_amount <= 0.0 or is_fully_disabled():
		return

	var hit_part := _select_part_from_world_direction(impact_direction)
	apply_damage_to_part(hit_part, damage_amount, impact_direction)


func apply_damage_to_part(part_name: String, damage_amount: float, impact_direction: Vector3 = Vector3.ZERO) -> void:
	if not BODY_PARTS.has(part_name):
		return
	if damage_amount <= 0.0:
		return
	if get_part_health(part_name) <= 0.0:
		return

	part_health[part_name] = maxf(get_part_health(part_name) - damage_amount, 0.0)
	_part_flash_strength[part_name] = 1.0

	if is_zero_approx(get_part_health(part_name)):
		_spawn_detached_part(part_name, impact_direction)
		if is_fully_disabled():
			_enter_disabled_state()

	_refresh_visual_state()


func fall_into_void() -> void:
	if _is_respawning:
		return

	_is_respawning = true
	_deny_carried_part_if_any()
	fell_into_void.emit(self)
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

	await get_tree().create_timer(0.75).timeout
	if _held_for_round_reset:
		return
	reset_to_spawn()


func reset_to_spawn() -> void:
	_cleanup_owned_detached_parts()
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	_planar_velocity = Vector3.ZERO
	external_impulse = Vector3.ZERO
	_attack_cooldown_remaining = 0.0
	_carried_part = null
	_held_for_round_reset = false
	visible = true
	collision_layer = _starting_collision_layer
	collision_mask = _starting_collision_mask
	_is_respawning = false
	_reset_control_pose()
	reset_modular_state()
	set_physics_process(true)
	respawned.emit(self)


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
	if is_instance_valid(_carried_part):
		return

	if not _is_attack_just_pressed():
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

		other.apply_impulse(direction_to_other * attack_impulse_strength * arm_power)
		other.receive_attack_hit(direction_to_other, attack_damage * arm_power)


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
		other_robot.apply_impulse(push_direction * passive_push_strength * get_effective_arm_power_multiplier())
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
	other_robot.receive_collision_hit(push_direction, damage_amount)


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
	_attack_cooldown_remaining = 0.0
	_planar_velocity = Vector3.ZERO
	disabled_explosion_timer.start(disabled_explosion_delay)
	robot_disabled.emit(self)


func _exit_disabled_state() -> void:
	if not _is_disabled:
		return

	_is_disabled = false
	disabled_explosion_timer.stop()


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

	detach_parent.add_child(detached_part)
	detached_part.global_transform = global_transform
	detached_part.configure_from_visuals(self, part_name, source_visuals, initial_velocity)
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


func _update_energy_controls() -> void:
	if not is_player_controlled or _is_disabled:
		return

	if is_instance_valid(_carried_part) and _is_throw_part_just_pressed():
		throw_carried_part(_get_move_input_vector())

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
	return _get_leg_control_health_multiplier() * _get_leg_energy_multiplier()


func _get_leg_control_health_multiplier() -> float:
	return lerpf(0.4, 1.0, _get_pair_health_ratio("left_leg", "right_leg"))


func _get_arm_health_multiplier() -> float:
	if _is_disabled:
		return 0.0

	return lerpf(0.3, 1.0, _get_pair_health_ratio("left_arm", "right_arm"))


func _get_leg_energy_multiplier() -> float:
	return _get_pair_energy_multiplier("left_leg", "right_leg")


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
	return clampf((part_a_multiplier + part_b_multiplier) * 0.5, minimum_energy_multiplier, maximum_energy_multiplier)


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


func _get_energy_focus_color() -> Color:
	if _selected_energy_part_name.contains("leg"):
		return Color(0.2, 0.64, 0.92, 1.0)
	return Color(0.98, 0.58, 0.14, 1.0)


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


func _prepare_visual_materials() -> void:
	_material_base_values.clear()
	for part_name in BODY_PARTS:
		for visual_node in _part_visual_nodes.get(part_name, []):
			_register_material_base_values(visual_node)

	for visual_node in _core_visual_nodes:
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
	for part_name in BODY_PARTS:
		_refresh_part_visual_state(part_name)

	_refresh_core_visuals()


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

		_damage_feedback_nodes[part_name] = {
			"root": feedback_root,
			"smoke": smoke,
			"spark": spark,
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


func _refresh_carry_indicator() -> void:
	if _carry_indicator == null:
		return

	if not is_carrying_part():
		_carry_indicator.visible = false
		_last_carried_part_name = ""
		return

	var carried_part_name := get_carried_part_name()
	if carried_part_name != _last_carried_part_name:
		_refresh_carry_indicator_color(carried_part_name)
		_last_carried_part_name = carried_part_name

	_carry_indicator.visible = true


func _refresh_carry_indicator_color(part_name: String) -> void:
	if _carry_indicator == null:
		return

	var material := _carry_indicator.material_override as StandardMaterial3D
	if material == null:
		return

	var color: Color = CARRY_PART_COLORS.get(part_name, Color(1.0, 0.57, 0.1, 1.0))
	material.albedo_color = color
	material.emission = color
	material.emission_energy_multiplier = 2.2


func _update_carry_indicator_animation(delta: float) -> void:
	if _carry_indicator == null:
		return
	if not is_carrying_part():
		_carry_indicator_animation_time = 0.0
		_carry_indicator.scale = Vector3.ONE
		_carry_indicator.rotation = Vector3.ZERO
		_carry_indicator.position.y = carry_indicator_base_height
		return

	_carry_indicator_animation_time += delta
	var wave := (sin(_carry_indicator_animation_time * carry_indicator_pulse_speed) + 1.0) * 0.5
	var pulse := 1.0 + (wave - 0.5) * carry_indicator_pulse_amount * 2.0
	_carry_indicator.scale = Vector3(pulse, 1.0 + pulse * 0.25, pulse)
	_carry_indicator.position.y = carry_indicator_base_height + wave * carry_indicator_bob_height
	_carry_indicator.rotation.y = fmod(_carry_indicator.rotation.y + carry_indicator_rotation_speed * delta, TAU)


func _refresh_part_visual_state(part_name: String) -> void:
	var visuals: Array[MeshInstance3D] = []
	for visual_node in _part_visual_nodes.get(part_name, []):
		if visual_node is MeshInstance3D:
			visuals.append(visual_node as MeshInstance3D)
	var health_ratio := get_part_health_ratio(part_name)
	var flash_strength := float(_part_flash_strength.get(part_name, 0.0))
	var should_be_visible := health_ratio > 0.0

	for visual_node in visuals:
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
	if smoke == null or spark == null:
		return

	var health_ratio := get_part_health_ratio(part_name)
	var show_smoke := health_ratio > 0.0 and health_ratio < damage_feedback_threshold
	var show_spark := health_ratio > 0.0 and health_ratio <= critical_damage_feedback_threshold

	if root != null:
		root.visible = show_smoke or show_spark

	if not show_smoke and not show_spark:
		smoke.visible = false
		spark.visible = false
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
	if not show_spark:
		return

	var critical_severity := 1.0 - clampf(health_ratio / maxf(critical_damage_feedback_threshold, 0.01), 0.0, 1.0)
	spark.position = Vector3(0.0, 0.15 + critical_severity * 0.08, 0.0)
	spark.scale = Vector3.ONE * (0.85 + critical_severity * 0.95)
	var spark_material := spark.material_override as StandardMaterial3D
	if spark_material != null:
		var spark_color := Color(1.0, 0.46 + critical_severity * 0.14, 0.12, 1.0)
		spark_material.albedo_color = spark_color
		spark_material.emission = spark_color
		spark_material.emission_energy_multiplier = 1.6 + critical_severity * 2.0


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
		var damage_blend := (1.0 - intact_ratio) * 0.4
		var disabled_blend := 0.55 if _is_disabled else 0.0
		var energy_color := _get_energy_focus_color()
		var energy_blend := _get_energy_visual_blend()
		material.albedo_color = base_albedo.lerp(Color(0.09, 0.08, 0.08, 1.0), damage_blend + disabled_blend)
		material.albedo_color = material.albedo_color.lerp(energy_color, energy_blend * 0.18)
		if material.emission_enabled:
			var warning_color := Color(1.0, 0.28, 0.12, 1.0)
			material.emission = base_emission.lerp(warning_color, damage_blend + disabled_blend)
			material.emission = material.emission.lerp(energy_color, energy_blend)
			material.emission_energy_multiplier = maxf(base_emission_energy, 0.12 + disabled_blend * 0.85 + energy_blend * 0.75)


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

	var fallback_device := player_index - 1
	if fallback_device >= 0 and connected_devices.has(fallback_device):
		devices.append(fallback_device)

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
	_apply_disabled_explosion()
	robot_exploded.emit(self)
	_start_disabled_respawn()


func _apply_disabled_explosion() -> void:
	for node in get_tree().get_nodes_in_group("robots"):
		if not (node is RobotBase):
			continue

		var other_robot := node as RobotBase
		if other_robot == self:
			continue

		var offset := other_robot.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > disabled_explosion_radius:
			continue

		var direction := Vector3.FORWARD
		if distance > 0.001:
			direction = offset / distance

		var distance_ratio := 1.0 - clampf(distance / disabled_explosion_radius, 0.0, 1.0)
		other_robot.apply_impulse(direction * disabled_explosion_impulse * distance_ratio)
		other_robot.receive_attack_hit(direction, disabled_explosion_damage * distance_ratio)


func _start_disabled_respawn() -> void:
	_is_respawning = true
	_exit_disabled_state()
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	await get_tree().create_timer(0.9).timeout
	if _held_for_round_reset:
		return
	reset_to_spawn()


func _report_joypad_status() -> void:
	if uses_keyboard_input() and joypad_device < 0:
		print("%s: perfil local por teclado activo." % display_name)
		return

	var connected_devices := Input.get_connected_joypads()
	if connected_devices.is_empty():
		print("%s: no hay joystick conectado; queda teclado como fallback." % display_name)
		return

	var device_names: Array[String] = []
	for device in connected_devices:
		device_names.append("%s:%s" % [device, Input.get_joy_name(int(device))])

	print("%s: joysticks detectados -> %s" % [display_name, device_names])
