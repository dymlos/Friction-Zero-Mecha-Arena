extends Area3D
class_name ControlBeacon

const RobotBase = preload("res://scripts/robots/robot_base.gd")

@export var effect_duration := 3.2
@export var suppression_window := 0.16
@export_range(0.2, 1.0, 0.01) var drive_multiplier := 0.72
@export_range(0.2, 1.0, 0.01) var control_multiplier := 0.64

var _source_robot: RobotBase = null
var _lifetime_remaining := 0.0
var _animation_time := 0.0
var _configured_radius := 1.75
var _runtime_ready := false
var _collision_shape_resource: CylinderShape3D = null
var _ring_mesh_resource: CylinderMesh = null

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ring_visual: MeshInstance3D = $RingVisual
@onready var core_visual: MeshInstance3D = $CoreVisual


func _ready() -> void:
	add_to_group("temporary_control_beacons")
	_prepare_runtime_resources()
	_runtime_ready = true
	_lifetime_remaining = maxf(_lifetime_remaining, effect_duration)
	_apply_runtime_configuration()
	_refresh_animation()


func _physics_process(delta: float) -> void:
	_lifetime_remaining = maxf(_lifetime_remaining - delta, 0.0)
	if _lifetime_remaining == 0.0:
		queue_free()
		return

	_animation_time += delta
	_refresh_animation()
	for body in get_overlapping_bodies():
		if not (body is RobotBase):
			continue

		var robot := body as RobotBase
		if robot == _source_robot:
			continue
		if is_instance_valid(_source_robot) and robot.is_ally_of(_source_robot):
			continue

		robot.apply_control_zone_suppression(suppression_window, drive_multiplier, control_multiplier)


func configure(
	source_robot: RobotBase,
	world_position: Vector3,
	radius: float,
	lifetime: float,
	zone_drive_multiplier: float,
	zone_control_multiplier: float,
	refresh_window: float
) -> void:
	_source_robot = source_robot
	global_position = world_position
	effect_duration = maxf(lifetime, 0.1)
	_lifetime_remaining = effect_duration
	drive_multiplier = clampf(zone_drive_multiplier, 0.2, 1.0)
	control_multiplier = clampf(zone_control_multiplier, 0.2, 1.0)
	suppression_window = maxf(refresh_window, 0.05)
	_configured_radius = maxf(radius, 0.5)
	if _runtime_ready:
		_apply_runtime_configuration()


func _prepare_runtime_resources() -> void:
	if collision_shape.shape is CylinderShape3D:
		_collision_shape_resource = (collision_shape.shape as CylinderShape3D).duplicate()
		collision_shape.shape = _collision_shape_resource

	if ring_visual.mesh is CylinderMesh:
		_ring_mesh_resource = (ring_visual.mesh as CylinderMesh).duplicate()
		ring_visual.mesh = _ring_mesh_resource


func _apply_runtime_configuration() -> void:
	_set_radius(_configured_radius)
	_refresh_radius_visuals()


func _set_radius(radius: float) -> void:
	if _collision_shape_resource != null:
		_collision_shape_resource.radius = radius
		_collision_shape_resource.height = 1.8

	if _ring_mesh_resource != null:
		_ring_mesh_resource.top_radius = radius
		_ring_mesh_resource.bottom_radius = radius

	if core_visual != null:
		core_visual.scale = Vector3.ONE * maxf(radius * 0.22, 0.18)


func _refresh_radius_visuals() -> void:
	if _ring_mesh_resource == null:
		return

	var current_radius := _ring_mesh_resource.top_radius
	ring_visual.scale = Vector3.ONE * 1.0
	core_visual.scale = Vector3.ONE * maxf(current_radius * 0.22, 0.18)


func _refresh_animation() -> void:
	var pulse := 1.0 + sin(_animation_time * TAU * 0.85) * 0.06
	var remaining_ratio := clampf(_lifetime_remaining / maxf(effect_duration, 0.01), 0.0, 1.0)
	ring_visual.scale = Vector3(pulse, 1.0, pulse)
	core_visual.scale = Vector3.ONE * maxf((0.18 + remaining_ratio * 0.08) * pulse, 0.14)
