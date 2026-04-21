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
@export_group("Target Readability")
@export_range(0.6, 2.4, 0.05) var target_indicator_height := 1.3
@export_range(0.0, 0.4, 0.01) var target_indicator_bob_height := 0.08
@export_range(1.0, 12.0, 0.5) var target_indicator_pulse_speed := 4.8
@export_range(0.0, 0.3, 0.01) var target_indicator_pulse_amount := 0.18
@export_range(0.05, 0.5, 0.01) var target_indicator_size := 0.18
@export_group("Interference Readability")
@export_range(-1.0, 0.2, 0.01) var interference_range_indicator_height := -0.5
@export_range(0.01, 0.12, 0.01) var interference_range_indicator_thickness := 0.03

var owner_robot: RobotBase = null
var allied_robot: RobotBase = null
var arena: ArenaBase = null
var _support_payload_name := ""
var _lane_progress := 0.0
var _gate_disruption_time_left := 0.0
var _status_pulse_phase := 0.0
var _selected_target_robot: RobotBase = null
var _target_indicator_phase := 0.0

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
	_ensure_support_target_indicator()
	_ensure_interference_range_indicator()
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
	_refresh_target_selection(true)
	_refresh_visuals()


func belongs_to_owner(robot: RobotBase) -> bool:
	return owner_robot == robot


func get_status_summary() -> String:
	var summary := "apoyo"
	if is_instance_valid(owner_robot):
		summary += " %s" % owner_robot.get_support_input_hint()
	if is_gate_disrupted():
		summary += " interferido"
	var payload_label := get_support_payload_label()
	if payload_label != "":
		summary += " %s" % payload_label
		var target_label := _get_selected_target_label()
		if target_label != "":
			summary += " > %s" % target_label

	return summary


func get_selected_target_robot() -> RobotBase:
	if not is_instance_valid(_selected_target_robot):
		return null

	return _selected_target_robot


func get_support_payload_label() -> String:
	return str(PilotSupportPickup.PAYLOAD_LABELS.get(_support_payload_name, ""))


func has_support_payload() -> bool:
	return _support_payload_name != ""


func store_support_payload(payload_name: String) -> bool:
	if payload_name == "" or has_support_payload():
		return false

	_support_payload_name = payload_name
	_refresh_target_selection(true)
	_refresh_visuals()
	state_changed.emit(self)
	return true


func use_support_payload() -> bool:
	var target_robot := _resolve_support_target_for_payload()
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
		PilotSupportPickup.PAYLOAD_INTERFERENCE:
			if not target_robot.apply_control_zone_suppression(
				support_interference_duration,
				support_interference_drive_multiplier,
				support_interference_control_multiplier
			):
				return false
		_:
			return false

	_support_payload_name = ""
	_set_selected_target(null)
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
	var target_selection_changed := _update_target_selection_from_input()
	target_selection_changed = _refresh_target_selection() or target_selection_changed
	_update_status_beacon(delta)
	_update_target_indicator(delta)
	_update_interference_range_indicator()
	_try_collect_support_pickup()
	if owner_robot.is_player_support_action_just_pressed():
		use_support_payload()
	if was_gate_disrupted != is_gate_disrupted():
		_refresh_visuals()
		state_changed.emit(self)
	elif target_selection_changed:
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


func _resolve_support_target_for_payload() -> RobotBase:
	var target_robot := get_selected_target_robot()
	if target_robot == null:
		return null
	if _support_payload_name == PilotSupportPickup.PAYLOAD_INTERFERENCE:
		if not _is_target_in_interference_range(target_robot):
			return null

	return target_robot


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
	_update_interference_range_indicator()


func _get_support_payload_color() -> Color:
	if _support_payload_name == PilotSupportPickup.PAYLOAD_SURGE:
		return Color(0.22, 0.84, 0.96, 1.0)
	if _support_payload_name == PilotSupportPickup.PAYLOAD_MOBILITY:
		return Color(0.2, 0.9, 0.74, 1.0)
	if _support_payload_name == PilotSupportPickup.PAYLOAD_INTERFERENCE:
		return Color(0.96, 0.38, 0.3, 1.0)

	return Color(0.98, 0.8, 0.28, 1.0)


func _get_selected_target_label() -> String:
	var target_robot := get_selected_target_robot()
	if target_robot == null:
		return ""

	return target_robot.display_name


func _update_target_selection_from_input() -> bool:
	if not has_support_payload():
		return false
	if owner_robot == null:
		return false

	var selection_direction := 0
	if owner_robot.is_player_support_prev_just_pressed():
		selection_direction = -1
	elif owner_robot.is_player_support_next_just_pressed():
		selection_direction = 1
	if selection_direction == 0:
		return false

	return _cycle_selected_target(selection_direction)


func _refresh_target_selection(force_default: bool = false) -> bool:
	if not has_support_payload():
		return _set_selected_target(null)

	var candidates := _get_support_target_candidates()
	if candidates.is_empty():
		return _set_selected_target(null)
	if force_default or not _contains_support_target(candidates, _selected_target_robot):
		return _set_selected_target(_get_default_support_target(candidates))

	return false


func _cycle_selected_target(direction: int) -> bool:
	var candidates := _get_support_target_candidates()
	if candidates.is_empty():
		return _set_selected_target(null)
	if candidates.size() == 1:
		return _set_selected_target(candidates[0])
	if not _contains_support_target(candidates, _selected_target_robot):
		return _set_selected_target(_get_default_support_target(candidates))

	var current_index := candidates.find(_selected_target_robot)
	if current_index < 0:
		return _set_selected_target(_get_default_support_target(candidates))

	var next_index := wrapi(current_index + direction, 0, candidates.size())
	return _set_selected_target(candidates[next_index])


func _get_support_target_candidates() -> Array[RobotBase]:
	var candidates: Array[RobotBase] = []
	if owner_robot == null or owner_robot.get_parent() == null:
		return candidates

	var wants_enemy_target := _support_payload_name == PilotSupportPickup.PAYLOAD_INTERFERENCE
	for sibling in owner_robot.get_parent().get_children():
		if not (sibling is RobotBase):
			continue

		var candidate := sibling as RobotBase
		if candidate == owner_robot:
			continue
		if candidate.is_held_for_round_reset() or candidate.is_disabled_state():
			continue
		if wants_enemy_target:
			if owner_robot.is_ally_of(candidate):
				continue
		elif not owner_robot.is_ally_of(candidate):
			continue

		candidates.append(candidate)

	candidates.sort_custom(_compare_support_targets)
	return candidates


func _get_default_support_target(candidates: Array[RobotBase]) -> RobotBase:
	if candidates.is_empty():
		return null
	if _support_payload_name != PilotSupportPickup.PAYLOAD_INTERFERENCE:
		if _contains_support_target(candidates, allied_robot):
			return allied_robot
		return candidates[0]

	var nearest_target := candidates[0]
	var nearest_distance := INF
	for candidate in candidates:
		var planar_offset := candidate.global_position - global_position
		planar_offset.y = 0.0
		var distance := planar_offset.length_squared()
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_target = candidate

	return nearest_target


func _contains_support_target(candidates: Array[RobotBase], target_robot: RobotBase) -> bool:
	if not is_instance_valid(target_robot):
		return false

	return candidates.find(target_robot) >= 0


func _set_selected_target(target_robot: RobotBase) -> bool:
	if not is_instance_valid(target_robot):
		target_robot = null
	if _selected_target_robot == target_robot:
		return false

	_selected_target_robot = target_robot
	if target_robot != null and owner_robot != null and owner_robot.is_ally_of(target_robot):
		allied_robot = target_robot
	return true


func _compare_support_targets(left: RobotBase, right: RobotBase) -> bool:
	if left == null:
		return false
	if right == null:
		return true
	if left.player_index != right.player_index:
		return left.player_index < right.player_index

	return left.get_instance_id() < right.get_instance_id()


func _ensure_support_target_indicator() -> void:
	if get_node_or_null("SupportTargetIndicator") != null:
		return

	var indicator := MeshInstance3D.new()
	indicator.name = "SupportTargetIndicator"
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3.ONE * target_indicator_size
	indicator.mesh = box_mesh
	indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	indicator.rotation_degrees = Vector3(0.0, 45.0, 45.0)
	indicator.visible = false
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.roughness = 0.15
	indicator.material_override = material
	add_child(indicator)


func _ensure_interference_range_indicator() -> void:
	if get_node_or_null("InterferenceRangeIndicator") != null:
		return

	var indicator := MeshInstance3D.new()
	indicator.name = "InterferenceRangeIndicator"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.5
	mesh.bottom_radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 48
	mesh.rings = 1
	indicator.mesh = mesh
	indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	indicator.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	indicator.position = Vector3(0.0, interference_range_indicator_height, 0.0)
	indicator.visible = false
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.roughness = 0.22
	indicator.material_override = material
	add_child(indicator)


func _update_target_indicator(delta: float) -> void:
	var indicator := get_node_or_null("SupportTargetIndicator") as MeshInstance3D
	if indicator == null:
		return

	var target_robot := get_selected_target_robot()
	if not has_support_payload() or target_robot == null:
		indicator.visible = false
		_target_indicator_phase = 0.0
		return

	_target_indicator_phase = wrapf(
		_target_indicator_phase + delta * target_indicator_pulse_speed,
		0.0,
		TAU
	)
	var bob_offset := sin(_target_indicator_phase) * target_indicator_bob_height
	var pulse_scale := 1.0 + sin(_target_indicator_phase) * target_indicator_pulse_amount
	indicator.visible = true
	indicator.global_position = target_robot.global_position + Vector3(0.0, target_indicator_height + bob_offset, 0.0)
	indicator.scale = Vector3.ONE * pulse_scale
	indicator.rotation_degrees = Vector3(0.0, 45.0 + rad_to_deg(_target_indicator_phase) * 0.12, 45.0)

	var accent_color := _get_support_payload_color()
	var in_range := _support_payload_name != PilotSupportPickup.PAYLOAD_INTERFERENCE or _is_target_in_interference_range(target_robot)
	var material := indicator.material_override as StandardMaterial3D
	if material == null:
		return

	var indicator_color := accent_color
	var emission_boost := 1.3
	if not in_range:
		indicator_color = accent_color.darkened(0.38)
		indicator_color.a = 0.65
		emission_boost = 0.45

	material.albedo_color = indicator_color
	material.emission = indicator_color
	material.emission_energy_multiplier = emission_boost


func _update_interference_range_indicator() -> void:
	var indicator := get_node_or_null("InterferenceRangeIndicator") as MeshInstance3D
	if indicator == null:
		return

	var is_interference_payload := _support_payload_name == PilotSupportPickup.PAYLOAD_INTERFERENCE
	indicator.visible = is_interference_payload
	if not is_interference_payload:
		return

	indicator.position = Vector3(0.0, interference_range_indicator_height, 0.0)
	indicator.scale = Vector3(
		support_interference_range * 2.0,
		interference_range_indicator_thickness,
		support_interference_range * 2.0
	)

	var target_robot := get_selected_target_robot()
	var in_range := target_robot != null and _is_target_in_interference_range(target_robot)
	var accent_color := _get_support_payload_color()
	var indicator_color := accent_color.darkened(0.2)
	var emission_boost := 0.48
	if in_range:
		indicator_color = accent_color.lightened(0.06)
		emission_boost = 0.92

	var material := indicator.material_override as StandardMaterial3D
	if material == null:
		return

	indicator_color.a = 0.24 if in_range else 0.12
	material.albedo_color = indicator_color
	material.emission = accent_color
	material.emission_energy_multiplier = emission_boost


func _is_target_in_interference_range(target_robot: RobotBase) -> bool:
	if target_robot == null:
		return false

	var planar_offset := target_robot.global_position - global_position
	planar_offset.y = 0.0
	return planar_offset.length() <= support_interference_range


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
