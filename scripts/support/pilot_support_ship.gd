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
@export_range(0.2, 3.5, 0.1) var support_interference_duration := 1.5
@export_range(1.0, 5.0, 0.1) var support_interference_range := 2.8
@export_range(0.2, 1.0, 0.01) var support_interference_drive_multiplier := 0.78
@export_range(0.2, 1.0, 0.01) var support_interference_control_multiplier := 0.72
@export_range(0.1, 2.5, 0.1) var gate_disruption_duration := 0.65

var owner_robot: RobotBase = null
var allied_robot: RobotBase = null
var arena: ArenaBase = null
var _support_payload_name := ""
var _lane_progress := 0.0
var _gate_disruption_time_left := 0.0
var _status_pulse_phase := 0.0

@onready var hull_visual: MeshInstance3D = $HullVisual
@onready var glow_visual: MeshInstance3D = $GlowVisual
@onready var status_beacon: Node3D = $StatusBeacon
@onready var status_ring_visual: MeshInstance3D = $StatusBeacon/RingVisual
@onready var status_pulse_visual: MeshInstance3D = $StatusBeacon/PulseVisual


func _ready() -> void:
	_duplicate_runtime_material(hull_visual)
	_duplicate_runtime_material(glow_visual)
	_duplicate_runtime_material(status_ring_visual)
	_duplicate_runtime_material(status_pulse_visual)
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
	if is_gate_disrupted():
		summary += " interferido"
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
	var target_robot: RobotBase = null

	match _support_payload_name:
		PilotSupportPickup.PAYLOAD_STABILIZER:
			target_robot = _resolve_support_target()
			if target_robot == null:
				return false
			var repaired_part := target_robot.repair_most_damaged_part(target_robot.max_part_health * support_repair_ratio)
			if repaired_part == "":
				return false
		PilotSupportPickup.PAYLOAD_SURGE:
			target_robot = _resolve_support_target()
			if target_robot == null:
				return false
			if not target_robot.apply_energy_surge(support_energy_surge_duration):
				return false
		PilotSupportPickup.PAYLOAD_MOBILITY:
			target_robot = _resolve_support_target()
			if target_robot == null:
				return false
			if not target_robot.apply_mobility_boost(support_mobility_boost_duration):
				return false
		PilotSupportPickup.PAYLOAD_INTERFERENCE:
			target_robot = _resolve_enemy_interference_target()
			if target_robot == null:
				return false
			if not target_robot.apply_control_zone_suppression(
				support_interference_duration,
				support_interference_drive_multiplier,
				support_interference_control_multiplier
			):
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

	var was_gate_disrupted := is_gate_disrupted()
	_gate_disruption_time_left = maxf(_gate_disruption_time_left - delta, 0.0)
	_update_movement(delta)
	_update_status_beacon(delta)
	_try_collect_support_pickup()
	if owner_robot.is_player_support_action_just_pressed():
		use_support_payload()
	if was_gate_disrupted != is_gate_disrupted():
		_refresh_visuals()
		state_changed.emit(self)


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

	if is_gate_disrupted():
		return

	var signed_distance := signed_input * move_speed * delta
	var blocking_gate_progress := arena.get_support_lane_blocking_gate_progress(_lane_progress, signed_distance)
	if blocking_gate_progress >= 0.0:
		_gate_disruption_time_left = gate_disruption_duration
		_refresh_visuals()
		state_changed.emit(self)
		return

	_lane_progress = arena.advance_support_lane_progress(_lane_progress, signed_distance)
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
	if is_gate_disrupted():
		var disruption_color := Color(0.96, 0.4, 0.24, 1.0)
		hull_color = hull_color.lerp(disruption_color.darkened(0.3), 0.52)
		glow_color = glow_color.lerp(disruption_color, 0.8)
	elif has_support_payload():
		var payload_color := _get_support_payload_color()
		hull_color = hull_color.lerp(payload_color.darkened(0.18), 0.42)
		glow_color = glow_color.lerp(payload_color, 0.68)

	_apply_color_to_visual(hull_visual, hull_color, false)
	_apply_color_to_visual(glow_visual, glow_color, true)
	_apply_status_beacon_visuals(glow_color)


func _get_support_payload_color() -> Color:
	if _support_payload_name == PilotSupportPickup.PAYLOAD_SURGE:
		return Color(0.22, 0.84, 0.96, 1.0)
	if _support_payload_name == PilotSupportPickup.PAYLOAD_MOBILITY:
		return Color(0.2, 0.9, 0.74, 1.0)
	if _support_payload_name == PilotSupportPickup.PAYLOAD_INTERFERENCE:
		return Color(0.96, 0.38, 0.3, 1.0)

	return Color(0.98, 0.8, 0.28, 1.0)


func _resolve_enemy_interference_target() -> RobotBase:
	if owner_robot == null:
		return null
	if owner_robot.get_parent() == null:
		return null

	var nearest_enemy: RobotBase = null
	var nearest_distance := support_interference_range
	for sibling in owner_robot.get_parent().get_children():
		if not (sibling is RobotBase):
			continue

		var enemy_candidate := sibling as RobotBase
		if enemy_candidate == owner_robot:
			continue
		if enemy_candidate.is_held_for_round_reset() or enemy_candidate.is_disabled_state():
			continue
		if owner_robot.is_ally_of(enemy_candidate):
			continue

		var planar_offset := enemy_candidate.global_position - global_position
		planar_offset.y = 0.0
		var distance := planar_offset.length()
		if distance > nearest_distance:
			continue

		nearest_enemy = enemy_candidate
		nearest_distance = distance

	return nearest_enemy


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


func _apply_status_beacon_visuals(accent_color: Color) -> void:
	if status_ring_visual != null:
		status_ring_visual.visible = true
		var ring_material := status_ring_visual.material_override as StandardMaterial3D
		if ring_material != null:
			ring_material.albedo_color = accent_color.lightened(0.08)
			ring_material.emission_enabled = true
			ring_material.emission = accent_color
			ring_material.emission_energy_multiplier = 1.15

	if status_pulse_visual != null:
		var highlight_visible := has_support_payload() or is_gate_disrupted()
		status_pulse_visual.visible = highlight_visible
		var pulse_material := status_pulse_visual.material_override as StandardMaterial3D
		if pulse_material != null:
			pulse_material.albedo_color = accent_color.lightened(0.18)
			pulse_material.emission_enabled = true
			pulse_material.emission = accent_color.lightened(0.12)
			pulse_material.emission_energy_multiplier = 1.55 if highlight_visible else 0.0


func _update_status_beacon(delta: float) -> void:
	if status_beacon == null:
		return

	_status_pulse_phase = wrapf(_status_pulse_phase + delta * 5.4, 0.0, TAU)
	status_beacon.rotation.y = _status_pulse_phase * 0.35
	if status_pulse_visual == null:
		return

	if not status_pulse_visual.visible:
		status_pulse_visual.scale = Vector3.ONE * 0.72
		return

	var pulse_scale := 0.72 + sin(_status_pulse_phase) * 0.12
	status_pulse_visual.scale = Vector3.ONE * pulse_scale


func _duplicate_runtime_material(visual: MeshInstance3D) -> void:
	if visual == null:
		return

	var material := visual.material_override as StandardMaterial3D
	if material == null:
		return

	visual.material_override = material.duplicate()


func is_gate_disrupted() -> bool:
	return _gate_disruption_time_left > 0.0
