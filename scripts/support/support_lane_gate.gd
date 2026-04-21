extends Node3D
class_name SupportLaneGate

@export_range(0.2, 3.0, 0.1) var blocking_radius := 1.15
@export_range(0.2, 6.0, 0.1) var closed_duration := 1.2
@export_range(0.2, 6.0, 0.1) var open_duration := 1.0
@export_range(0.0, 6.0, 0.1) var phase_offset := 0.0

var _support_active := false
var _cycle_time := 0.0
var _forced_blocking_override := -1

@onready var beam_visual: MeshInstance3D = $BeamVisual


func _ready() -> void:
	add_to_group("support_lane_gates")
	add_to_group("support_lane_nodes")
	_duplicate_runtime_material(beam_visual)
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


func _is_cycle_in_closed_window() -> bool:
	var cycle_length := closed_duration + open_duration
	if cycle_length <= 0.0:
		return true

	return fposmod(_cycle_time, cycle_length) < closed_duration


func _refresh_visual_state() -> void:
	var should_show := _support_active
	visible = should_show
	if beam_visual == null:
		return

	beam_visual.visible = should_show
	var material := beam_visual.material_override as StandardMaterial3D
	if material == null:
		return

	var blocking := is_blocking()
	var beam_color := Color(0.3, 0.36, 0.42, 0.45)
	if blocking:
		beam_color = Color(0.94, 0.42, 0.22, 0.9)

	material.albedo_color = beam_color
	material.emission_enabled = blocking
	material.emission = beam_color
	material.emission_energy_multiplier = 1.25 if blocking else 0.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.2


func _duplicate_runtime_material(visual: MeshInstance3D) -> void:
	if visual == null:
		return

	var material := visual.material_override as StandardMaterial3D
	if material == null:
		return

	visual.material_override = material.duplicate()
