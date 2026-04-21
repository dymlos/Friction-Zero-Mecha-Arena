extends Node3D
class_name PilotSupportShip

const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const PilotSupportPickup = preload("res://scripts/support/pilot_support_pickup.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

signal state_changed(support_ship: PilotSupportShip)

@export var move_speed := 8.5
@export_range(0.05, 0.5, 0.01) var support_repair_ratio := 0.22
@export_range(0.2, 3.0, 0.1) var support_energy_surge_duration := 1.6
@export_range(0.2, 3.0, 0.1) var support_mobility_boost_duration := 1.9

var owner_robot: RobotBase = null
var allied_robot: RobotBase = null
var arena: ArenaBase = null
var _support_payload_name := ""
var _lane_progress := 0.0

@onready var hull_visual: MeshInstance3D = $HullVisual
@onready var glow_visual: MeshInstance3D = $GlowVisual


func _ready() -> void:
	_duplicate_runtime_material(hull_visual)
	_duplicate_runtime_material(glow_visual)
	_refresh_visuals()


func configure(
	next_owner_robot: RobotBase,
	next_allied_robot: RobotBase,
	spawn_position: Vector3,
	next_arena: ArenaBase
) -> void:
	owner_robot = next_owner_robot
	allied_robot = next_allied_robot
	arena = next_arena
	if arena != null:
		_lane_progress = arena.get_support_lane_progress_near(spawn_position)
		global_position = arena.get_support_lane_position_from_progress(_lane_progress)
	else:
		global_position = spawn_position
	_refresh_visuals()


func belongs_to_owner(robot: RobotBase) -> bool:
	return owner_robot == robot


func get_status_summary() -> String:
	var summary := "apoyo"
	var payload_label := get_support_payload_label()
	if payload_label != "":
		summary += " %s" % payload_label

	return summary


func get_support_payload_label() -> String:
	return str(PilotSupportPickup.PAYLOAD_LABELS.get(_support_payload_name, ""))


func has_support_payload() -> bool:
	return _support_payload_name != ""


func store_support_payload(payload_name: String) -> bool:
	if payload_name == "" or has_support_payload():
		return false

	_support_payload_name = payload_name
	_refresh_visuals()
	state_changed.emit(self)
	return true


func use_support_payload() -> bool:
	var target_robot := _resolve_support_target()
	if target_robot == null:
		return false

	match _support_payload_name:
		PilotSupportPickup.PAYLOAD_STABILIZER:
			var repaired_part := target_robot.repair_most_damaged_part(target_robot.max_part_health * support_repair_ratio)
			if repaired_part == "":
				return false
		PilotSupportPickup.PAYLOAD_SURGE:
			if not target_robot.apply_energy_surge(support_energy_surge_duration):
				return false
		PilotSupportPickup.PAYLOAD_MOBILITY:
			if not target_robot.apply_mobility_boost(support_mobility_boost_duration):
				return false
		_:
			return false

	_support_payload_name = ""
	_refresh_visuals()
	state_changed.emit(self)
	return true


func _physics_process(delta: float) -> void:
	if owner_robot == null or not is_instance_valid(owner_robot):
		return
	if not owner_robot.is_held_for_round_reset():
		return

	_update_movement(delta)
	_try_collect_support_pickup()
	if owner_robot.is_player_support_action_just_pressed():
		use_support_payload()


func _update_movement(delta: float) -> void:
	if arena == null:
		return

	var move_input := owner_robot.get_player_move_input_vector()
	if move_input.length_squared() <= 0.0:
		return

	var tangent := arena.get_support_lane_tangent_from_progress(_lane_progress)
	var signed_input := move_input.normalized().dot(tangent)
	if absf(signed_input) <= 0.2:
		return

	_lane_progress = arena.advance_support_lane_progress(_lane_progress, signed_input * move_speed * delta)
	global_position = arena.get_support_lane_position_from_progress(_lane_progress)


func _try_collect_support_pickup() -> void:
	if has_support_payload():
		return

	for node in get_tree().get_nodes_in_group("pilot_support_pickups"):
		if not (node is PilotSupportPickup):
			continue

		var support_pickup := node as PilotSupportPickup
		if support_pickup.try_collect(self):
			return


func _resolve_support_target() -> RobotBase:
	if is_instance_valid(allied_robot) and allied_robot.is_held_for_round_reset() == false:
		return allied_robot

	if owner_robot == null:
		return null
	if owner_robot.get_parent() == null:
		return null

	for sibling in owner_robot.get_parent().get_children():
		if not (sibling is RobotBase):
			continue
		if sibling == owner_robot:
			continue

		var allied_candidate := sibling as RobotBase
		if allied_candidate.is_held_for_round_reset():
			continue
		if owner_robot.is_ally_of(allied_candidate):
			allied_robot = allied_candidate
			return allied_robot

	return null


func _refresh_visuals() -> void:
	var identity_color := Color(0.78, 0.88, 0.96, 1.0)
	if is_instance_valid(owner_robot):
		identity_color = owner_robot.get_identity_color()

	var hull_color := identity_color.darkened(0.32)
	var glow_color := identity_color
	if has_support_payload():
		var payload_color := _get_support_payload_color()
		hull_color = hull_color.lerp(payload_color.darkened(0.18), 0.42)
		glow_color = glow_color.lerp(payload_color, 0.68)

	_apply_color_to_visual(hull_visual, hull_color, false)
	_apply_color_to_visual(glow_visual, glow_color, true)


func _get_support_payload_color() -> Color:
	if _support_payload_name == PilotSupportPickup.PAYLOAD_SURGE:
		return Color(0.22, 0.84, 0.96, 1.0)
	if _support_payload_name == PilotSupportPickup.PAYLOAD_MOBILITY:
		return Color(0.2, 0.9, 0.74, 1.0)

	return Color(0.98, 0.8, 0.28, 1.0)


func _apply_color_to_visual(visual: MeshInstance3D, color: Color, enable_emission: bool) -> void:
	if visual == null:
		return

	var material := visual.material_override as StandardMaterial3D
	if material == null:
		return

	material.albedo_color = color
	material.emission_enabled = enable_emission
	if enable_emission:
		material.emission = color
		material.emission_energy_multiplier = 1.35


func _duplicate_runtime_material(visual: MeshInstance3D) -> void:
	if visual == null:
		return

	var material := visual.material_override as StandardMaterial3D
	if material == null:
		return

	visual.material_override = material.duplicate()
