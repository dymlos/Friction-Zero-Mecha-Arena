extends Resource
class_name RobotArchetypeConfig

enum CoreSkillType { NONE, PULSE_SHOT, CONTROL_BEACON, RECOVERY_GRAB, RAM_BOOST, MOBILITY_BURST }
enum AccentStyle { NONE, BUMPER, LIFT, BLADES, FIN, SPIKE, HALO }

@export var archetype_label := ""
@export var accent_style: AccentStyle = AccentStyle.NONE
@export var accent_color := Color(0.92, 0.78, 0.24, 1.0)

@export_group("Player Facing")
@export var role_label := ""
@export_multiline var fantasy_line := ""
@export_multiline var strength_line := ""
@export_multiline var risk_line := ""
@export_multiline var signature_line := ""
@export_multiline var body_read_line := ""
@export_multiline var easy_line := ""
@export_multiline var hard_line := ""

@export_group("Movement")
@export_range(0.6, 1.6, 0.01) var max_move_speed_multiplier := 1.0
@export_range(0.6, 1.6, 0.01) var move_acceleration_multiplier := 1.0
@export_range(0.6, 1.6, 0.01) var glide_damping_multiplier := 1.0

@export_group("Durability")
@export_range(0.6, 1.6, 0.01) var max_part_health_multiplier := 1.0
@export_range(0.5, 1.8, 0.01) var restored_part_health_ratio_multiplier := 1.0

@export_group("Combat")
@export_range(0.6, 1.6, 0.01) var passive_push_strength_multiplier := 1.0
@export_range(0.6, 1.6, 0.01) var attack_impulse_strength_multiplier := 1.0
@export_range(0.6, 1.6, 0.01) var attack_damage_multiplier := 1.0
@export_range(0.6, 1.6, 0.01) var collision_damage_scale_multiplier := 1.0

@export_group("Recovery")
@export_range(0.6, 1.6, 0.01) var detached_part_pickup_range_multiplier := 1.0
@export_range(0.6, 1.6, 0.01) var carried_part_return_range_multiplier := 1.0

@export_group("Identity Hooks")
@export_range(0.4, 1.2, 0.01) var received_impulse_multiplier := 1.0
@export_range(1.0, 1.8, 0.01) var damaged_part_bonus_damage_multiplier := 1.0
@export_range(0.0, 0.5, 0.01) var return_support_repair_ratio := 0.0
@export_range(1.0, 2.0, 0.01) var mobility_boost_duration_multiplier := 1.0

@export_group("Core Skill")
@export var core_skill_type: CoreSkillType = CoreSkillType.NONE
@export var core_skill_label := ""
@export_range(0, 4, 1) var core_skill_max_charges := 0
@export_range(0.0, 12.0, 0.1) var core_skill_recharge_seconds := 0.0
@export_range(0.6, 1.6, 0.01) var core_skill_projectile_speed_multiplier := 1.0
@export_range(0.6, 1.6, 0.01) var core_skill_projectile_lifetime_multiplier := 1.0
@export_range(0.6, 1.6, 0.01) var core_skill_impulse_multiplier := 1.0
@export_range(0.6, 1.6, 0.01) var core_skill_damage_multiplier := 1.0
@export_range(0.1, 4.0, 0.05) var core_skill_active_duration := 0.0
@export_range(1.0, 2.0, 0.05) var core_skill_drive_multiplier := 1.0
@export_range(1.0, 2.0, 0.05) var core_skill_arm_power_multiplier := 1.0
@export_range(1.0, 2.0, 0.05) var core_skill_control_multiplier := 1.0
@export_range(0.2, 1.0, 0.05) var core_skill_received_impulse_multiplier := 1.0
