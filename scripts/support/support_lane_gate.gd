extends Node3D
class_name SupportLaneGate

@export_range(0.2, 3.0, 0.1) var blocking_radius := 1.15
@export_range(0.2, 6.0, 0.1) var closed_duration := 1.2
@export_range(0.2, 6.0, 0.1) var open_duration := 1.0
@export_range(0.0, 6.0, 0.1) var phase_offset := 0.0
@export_group("Timing Readability")
@export_range(0.2, 2.0, 0.05) var timing_visual_width := 1.4
@export_range(0.04, 0.3, 0.01) var timing_visual_height := 0.08
@export_range(0.04, 0.3, 0.01) var timing_visual_depth := 0.08
@export_range(0.0, 0.6, 0.01) var timing_visual_vertical_offset := 0.18

var _support_active := false
var _cycle_time := 0.0
var _forced_blocking_override := -1

@onready var beam_visual: MeshInstance3D = $BeamVisual
var _timing_visual: MeshInstance3D = null


func _ready() -> void:
	add_to_group("support_lane_gates")
	add_to_group("support_lane_nodes")
	_duplicate_runtime_material(beam_visual)
	_ensure_timing_visual()
	_duplicate_runtime_material(_timing_visual)
	_cycle_time = maxf(phase_offset, 0.0)
	_refresh_visual_state()


func _process(delta: float) -> void:
	if not _support_active:
		return

	_cycle_time += maxf(delta, 0.0)
	_refresh_visual_state()


func set_support_active(is_active: bool) -> void:
	_support_active = is_active
	if not _support_active:
		_cycle_time = maxf(phase_offset, 0.0)
	_refresh_visual_state()


func reset_gate() -> void:
	_cycle_time = maxf(phase_offset, 0.0)
	_forced_blocking_override = -1
	_refresh_visual_state()


func set_forced_blocking_state(is_blocking: bool) -> void:
	_forced_blocking_override = 1 if is_blocking else 0
	_refresh_visual_state()


func clear_forced_blocking_state() -> void:
	_forced_blocking_override = -1
	_refresh_visual_state()


func is_support_active() -> bool:
	return _support_active


func is_blocking() -> bool:
	if not _support_active:
		return false
	if _forced_blocking_override >= 0:
		return _forced_blocking_override == 1

	return _is_cycle_in_closed_window()


func get_blocking_radius() -> float:
	return maxf(blocking_radius, 0.1)


func get_time_until_state_change() -> float:
	if not _support_active:
		return 0.0
	if _forced_blocking_override >= 0:
		return 0.0

	var cycle_length := closed_duration + open_duration
	if cycle_length <= 0.0:
		return 0.0

	var cycle_position := fposmod(_cycle_time, cycle_length)
	if cycle_position < closed_duration:
		return maxf(closed_duration - cycle_position, 0.0)

	return maxf(cycle_length - cycle_position, 0.0)


func get_transition_progress_ratio() -> float:
	if not _support_active:
		return 0.0
	if _forced_blocking_override >= 0:
		return 1.0

	var window_duration := _get_current_window_duration()
	if window_duration <= 0.0:
		return 1.0

	return clampf(get_time_until_state_change() / window_duration, 0.0, 1.0)


func _is_cycle_in_closed_window() -> bool:
	var cycle_length := closed_duration + open_duration
	if cycle_length <= 0.0:
		return true

	return fposmod(_cycle_time, cycle_length) < closed_duration


func _refresh_visual_state() -> void:
	var should_show := _support_active
	visible = should_show
	var blocking := is_blocking()
	var beam_color := _get_beam_color(blocking)
	if beam_visual != null:
		beam_visual.visible = should_show
		var beam_material := beam_visual.material_override as StandardMaterial3D
		if beam_material != null:
			beam_material.albedo_color = beam_color
			beam_material.emission_enabled = blocking
			beam_material.emission = beam_color
			beam_material.emission_energy_multiplier = 1.25 if blocking else 0.0
			beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			beam_material.roughness = 0.2

	if _timing_visual == null:
		return

	_timing_visual.visible = should_show
	if not should_show:
		return

	var timing_ratio := get_transition_progress_ratio()
	var timing_width := maxf(timing_visual_width, 0.2)
	_timing_visual.scale = Vector3(maxf(timing_ratio, 0.08), 1.0, 1.0)
	_timing_visual.position = Vector3(
		-(timing_width * (1.0 - timing_ratio)) * 0.5,
		timing_visual_vertical_offset,
		0.0
	)
	var timing_material := _timing_visual.material_override as StandardMaterial3D
	if timing_material == null:
		return

	var timing_color := Color(0.28, 0.82, 0.72, 0.7)
	if blocking:
		timing_color = Color(0.98, 0.68, 0.28, 0.78)
	timing_material.albedo_color = timing_color
	timing_material.emission_enabled = true
	timing_material.emission = timing_color
	timing_material.emission_energy_multiplier = 0.75 if blocking else 0.38
	timing_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	timing_material.roughness = 0.15


func _get_beam_color(blocking: bool) -> Color:
	if blocking:
		return Color(0.94, 0.42, 0.22, 0.9)

	return Color(0.3, 0.36, 0.42, 0.45)


func _get_current_window_duration() -> float:
	if _forced_blocking_override >= 0:
		return 0.0
	if _is_cycle_in_closed_window():
		return maxf(closed_duration, 0.0)

	return maxf(open_duration, 0.0)


func _ensure_timing_visual() -> void:
	if get_node_or_null("TimingVisual") != null:
		_timing_visual = get_node("TimingVisual") as MeshInstance3D
		return

	var timing_visual := MeshInstance3D.new()
	timing_visual.name = "TimingVisual"
	var timing_mesh := BoxMesh.new()
	timing_mesh.size = Vector3(
		maxf(timing_visual_width, 0.2),
		maxf(timing_visual_height, 0.04),
		maxf(timing_visual_depth, 0.04)
	)
	timing_visual.mesh = timing_mesh
	timing_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	timing_visual.position = Vector3(0.0, timing_visual_vertical_offset, 0.0)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	timing_visual.material_override = material
	add_child(timing_visual)
	_timing_visual = timing_visual


func _duplicate_runtime_material(visual: MeshInstance3D) -> void:
	if visual == null:
		return

	var material := visual.material_override as StandardMaterial3D
	if material == null:
		return

	visual.material_override = material.duplicate()
