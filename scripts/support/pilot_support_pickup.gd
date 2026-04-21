extends Node3D
class_name PilotSupportPickup

const PAYLOAD_STABILIZER := "stabilizer"
const PAYLOAD_SURGE := "surge"
const PAYLOAD_MOBILITY := "mobility"
const PAYLOAD_INTERFERENCE := "interference"
const PAYLOAD_LABELS := {
	PAYLOAD_STABILIZER: "estabilizador",
	PAYLOAD_SURGE: "energia",
	PAYLOAD_MOBILITY: "movilidad",
	PAYLOAD_INTERFERENCE: "interferencia",
}

@export var pickup_radius := 0.85
@export var payload_name := PAYLOAD_STABILIZER
@export_range(0.5, 8.0, 0.1) var respawn_delay := 3.0
@export_group("Respawn Readability")
@export_range(0.4, 1.8, 0.05) var respawn_visual_width := 0.7
@export_range(0.04, 0.24, 0.01) var respawn_visual_height := 0.07
@export_range(0.04, 0.24, 0.01) var respawn_visual_depth := 0.07
@export_range(0.0, 0.5, 0.01) var respawn_visual_vertical_offset := 0.28

var _support_active := false
var _collected := false
var _respawn_time_left := 0.0

@onready var core_visual: MeshInstance3D = $CoreVisual
@onready var pedestal_visual: MeshInstance3D = $PedestalVisual
var _respawn_visual: MeshInstance3D = null
var _payload_accent_visual: MeshInstance3D = null


func _ready() -> void:
	add_to_group("pilot_support_pickups")
	add_to_group("support_lane_nodes")
	_duplicate_runtime_material(pedestal_visual)
	_duplicate_runtime_material(core_visual)
	_ensure_respawn_visual()
	_ensure_payload_accent_visual()
	_duplicate_runtime_material(_respawn_visual)
	_duplicate_runtime_material(_payload_accent_visual)
	_refresh_visual_state()


func set_support_active(is_active: bool) -> void:
	_support_active = is_active
	_refresh_visual_state()


func _process(delta: float) -> void:
	if not _support_active or not _collected:
		return

	_respawn_time_left = maxf(_respawn_time_left - maxf(delta, 0.0), 0.0)
	if _respawn_time_left <= 0.0:
		_collected = false
	_refresh_visual_state()


func reset_pickup() -> void:
	_collected = false
	_respawn_time_left = 0.0
	_refresh_visual_state()


func try_collect(ship: Node) -> bool:
	if ship == null or not _support_active or _collected:
		return false
	if not ship.has_method("store_support_payload"):
		return false
	if global_position.distance_to(ship.global_position) > pickup_radius:
		return false
	if not bool(ship.call("store_support_payload", payload_name)):
		return false

	_collected = true
	_respawn_time_left = maxf(respawn_delay, 0.0)
	_refresh_visual_state()
	return true


func get_time_until_respawn() -> float:
	if not _collected:
		return 0.0

	return maxf(_respawn_time_left, 0.0)


func get_respawn_progress_ratio() -> float:
	if not _collected:
		return 1.0

	var duration := maxf(respawn_delay, 0.001)
	return clampf(1.0 - (get_time_until_respawn() / duration), 0.0, 1.0)


func _refresh_visual_state() -> void:
	_apply_payload_colors()
	var should_show := _support_active
	visible = should_show
	if pedestal_visual != null:
		pedestal_visual.visible = should_show
	if core_visual != null:
		core_visual.visible = should_show and not _collected
	if _payload_accent_visual != null:
		_payload_accent_visual.visible = should_show
	if _respawn_visual != null:
		_respawn_visual.visible = should_show and _collected
		if _respawn_visual.visible:
			var respawn_ratio := get_respawn_progress_ratio()
			var respawn_width := maxf(respawn_visual_width, 0.2)
			_respawn_visual.scale = Vector3(maxf(respawn_ratio, 0.08), 1.0, 1.0)
			_respawn_visual.position = Vector3(
				-(respawn_width * (1.0 - respawn_ratio)) * 0.5,
				respawn_visual_vertical_offset,
				0.0
			)
			var respawn_material := _respawn_visual.material_override as StandardMaterial3D
			if respawn_material != null:
				var accent_color := _get_payload_accent_color().lightened(0.08)
				accent_color.a = 0.75
				respawn_material.albedo_color = accent_color
				respawn_material.emission_enabled = true
				respawn_material.emission = accent_color
				respawn_material.emission_energy_multiplier = 0.55
				respawn_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				respawn_material.roughness = 0.18


func _apply_payload_colors() -> void:
	var accent_color := _get_payload_accent_color()
	_apply_payload_accent_shape()
	if pedestal_visual != null:
		var pedestal_material := pedestal_visual.material_override as StandardMaterial3D
		if pedestal_material != null:
			pedestal_material.albedo_color = accent_color.darkened(0.48)
			pedestal_material.emission_enabled = false
			pedestal_material.roughness = 0.55

	if core_visual != null:
		var core_material := core_visual.material_override as StandardMaterial3D
		if core_material != null:
			core_material.albedo_color = accent_color
			core_material.emission_enabled = true
			core_material.emission = accent_color
			core_material.emission_energy_multiplier = 1.45
			core_material.roughness = 0.2
	if _payload_accent_visual != null:
		var accent_material := _payload_accent_visual.material_override as StandardMaterial3D
		if accent_material != null:
			var silhouette_color := accent_color.lightened(0.12)
			accent_material.albedo_color = silhouette_color
			accent_material.emission_enabled = true
			accent_material.emission = silhouette_color
			accent_material.emission_energy_multiplier = 0.85
			accent_material.roughness = 0.18
			accent_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _ensure_respawn_visual() -> void:
	if get_node_or_null("RespawnVisual") != null:
		_respawn_visual = get_node("RespawnVisual") as MeshInstance3D
		return

	var respawn_visual := MeshInstance3D.new()
	respawn_visual.name = "RespawnVisual"
	var respawn_mesh := BoxMesh.new()
	respawn_mesh.size = Vector3(
		maxf(respawn_visual_width, 0.2),
		maxf(respawn_visual_height, 0.04),
		maxf(respawn_visual_depth, 0.04)
	)
	respawn_visual.mesh = respawn_mesh
	respawn_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	respawn_visual.position = Vector3(0.0, respawn_visual_vertical_offset, 0.0)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	respawn_visual.material_override = material
	add_child(respawn_visual)
	_respawn_visual = respawn_visual


func _ensure_payload_accent_visual() -> void:
	if get_node_or_null("PayloadAccentVisual") != null:
		_payload_accent_visual = get_node("PayloadAccentVisual") as MeshInstance3D
		return

	var accent_visual := MeshInstance3D.new()
	accent_visual.name = "PayloadAccentVisual"
	accent_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	accent_visual.material_override = material
	add_child(accent_visual)
	_payload_accent_visual = accent_visual


func _apply_payload_accent_shape() -> void:
	if _payload_accent_visual == null:
		return

	var accent_mesh: PrimitiveMesh = BoxMesh.new()
	var accent_scale := Vector3.ONE
	var accent_rotation := Vector3.ZERO
	var accent_position := Vector3(0.0, 0.36, 0.0)

	match payload_name:
		PAYLOAD_SURGE:
			accent_mesh = BoxMesh.new()
			accent_scale = Vector3(0.42, 0.08, 0.08)
			accent_position = Vector3(0.0, 0.32, 0.0)
		PAYLOAD_MOBILITY:
			accent_mesh = BoxMesh.new()
			accent_scale = Vector3(0.34, 0.06, 0.14)
			accent_rotation = Vector3(0.0, 0.0, 30.0)
			accent_position = Vector3(0.0, 0.34, 0.0)
		PAYLOAD_INTERFERENCE:
			accent_mesh = SphereMesh.new()
			accent_scale = Vector3(0.22, 0.22, 0.22)
			accent_position = Vector3(0.0, 0.4, 0.0)
		_:
			accent_mesh = CylinderMesh.new()
			accent_scale = Vector3(0.18, 0.34, 0.18)
			accent_position = Vector3(0.0, 0.36, 0.0)

	_payload_accent_visual.mesh = accent_mesh
	_payload_accent_visual.scale = accent_scale
	_payload_accent_visual.rotation_degrees = accent_rotation
	_payload_accent_visual.position = accent_position


func _get_payload_accent_color() -> Color:
	if payload_name == PAYLOAD_SURGE:
		return Color(0.22, 0.84, 0.96, 1.0)
	if payload_name == PAYLOAD_MOBILITY:
		return Color(0.2, 0.9, 0.74, 1.0)
	if payload_name == PAYLOAD_INTERFERENCE:
		return Color(0.96, 0.38, 0.3, 1.0)

	return Color(0.96, 0.78, 0.22, 1.0)


func _duplicate_runtime_material(visual: MeshInstance3D) -> void:
	if visual == null:
		return

	var material := visual.material_override as StandardMaterial3D
	if material == null:
		return

	visual.material_override = material.duplicate()
