extends Node3D
class_name PilotSupportPickup

const PAYLOAD_STABILIZER := "stabilizer"
const PAYLOAD_SURGE := "surge"
const PAYLOAD_MOBILITY := "mobility"
const PAYLOAD_LABELS := {
	PAYLOAD_STABILIZER: "estabilizador",
	PAYLOAD_SURGE: "energia",
	PAYLOAD_MOBILITY: "movilidad",
}

@export var pickup_radius := 0.85
@export var payload_name := PAYLOAD_STABILIZER

var _support_active := false
var _collected := false

@onready var core_visual: MeshInstance3D = $CoreVisual
@onready var pedestal_visual: MeshInstance3D = $PedestalVisual


func _ready() -> void:
	add_to_group("pilot_support_pickups")
	add_to_group("support_lane_nodes")
	_duplicate_runtime_material(pedestal_visual)
	_duplicate_runtime_material(core_visual)
	_refresh_visual_state()


func set_support_active(is_active: bool) -> void:
	_support_active = is_active
	_refresh_visual_state()


func reset_pickup() -> void:
	_collected = false
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
	_refresh_visual_state()
	return true


func _refresh_visual_state() -> void:
	_apply_payload_colors()
	var should_show := _support_active and not _collected
	visible = should_show
	if pedestal_visual != null:
		pedestal_visual.visible = should_show
	if core_visual != null:
		core_visual.visible = should_show


func _apply_payload_colors() -> void:
	var accent_color := _get_payload_accent_color()
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


func _get_payload_accent_color() -> Color:
	if payload_name == PAYLOAD_SURGE:
		return Color(0.22, 0.84, 0.96, 1.0)
	if payload_name == PAYLOAD_MOBILITY:
		return Color(0.2, 0.9, 0.74, 1.0)

	return Color(0.96, 0.78, 0.22, 1.0)


func _duplicate_runtime_material(visual: MeshInstance3D) -> void:
	if visual == null:
		return

	var material := visual.material_override as StandardMaterial3D
	if material == null:
		return

	visual.material_override = material.duplicate()
