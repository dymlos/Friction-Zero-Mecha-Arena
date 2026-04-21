extends Resource
class_name RobotArchetypeConfig

@export var archetype_label := ""

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
