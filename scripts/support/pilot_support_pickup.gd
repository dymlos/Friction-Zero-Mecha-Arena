extends Node3D
class_name PilotSupportPickup

const PAYLOAD_STABILIZER := "stabilizer"

@export var pickup_radius := 0.85
@export var payload_name := PAYLOAD_STABILIZER

var _support_active := false
var _collected := false

@onready var core_visual: MeshInstance3D = $CoreVisual
@onready var pedestal_visual: MeshInstance3D = $PedestalVisual


func _ready() -> void:
	add_to_group("pilot_support_pickups")
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
	var should_show := _support_active and not _collected
	visible = should_show
	if pedestal_visual != null:
		pedestal_visual.visible = should_show
	if core_visual != null:
		core_visual.visible = should_show


func _duplicate_runtime_material(visual: MeshInstance3D) -> void:
	if visual == null:
		return

	var material := visual.material_override as StandardMaterial3D
	if material == null:
		return

	visual.material_override = material.duplicate()
