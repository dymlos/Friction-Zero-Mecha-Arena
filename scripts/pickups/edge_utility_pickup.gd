extends Area3D
class_name EdgeUtilityPickup

const RobotBase = preload("res://scripts/robots/robot_base.gd")

signal pickup_collected(robot: RobotBase, stability_duration: float)

@export var stability_duration := 1.7
@export_range(0.2, 1.0, 0.01) var received_impulse_multiplier := 0.76
@export var respawn_delay := 9.5
@export var bob_height := 0.12
@export var bob_speed := 2.2
@export var rotation_speed := 1.25

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visuals_root: Node3D = $Visuals
@onready var base_mesh: MeshInstance3D = $Visuals/Base
@onready var core_mesh: MeshInstance3D = $Visuals/Core
@onready var respawn_timer: Timer = $RespawnTimer

var _available := true
var _spawn_enabled := true
var _animation_time := 0.0
var _base_visual_position := Vector3.ZERO


func _ready() -> void:
	add_to_group("edge_pickups")
	add_to_group("edge_utility_pickups")
	_base_visual_position = visuals_root.position
	_set_available_state(true)


func _process(delta: float) -> void:
	if not _spawn_enabled or not _available:
		return

	_animation_time += delta
	var wave := sin(_animation_time * bob_speed)
	visuals_root.position = _base_visual_position + Vector3(0.0, wave * bob_height, 0.0)
	visuals_root.rotation.y = fmod(visuals_root.rotation.y + rotation_speed * delta, TAU)


func _on_body_entered(body: Node) -> void:
	if not _spawn_enabled or not _available:
		return
	if not (body is RobotBase):
		return

	var robot := body as RobotBase
	if not robot.apply_stability_boost(stability_duration, received_impulse_multiplier):
		return

	_set_available_state(false)
	respawn_timer.start(respawn_delay)
	pickup_collected.emit(robot, stability_duration)


func _on_respawn_timer_timeout() -> void:
	if not _spawn_enabled:
		return

	_set_available_state(true)


func is_spawn_enabled() -> bool:
	return _spawn_enabled


func set_spawn_enabled(is_enabled: bool) -> void:
	_spawn_enabled = is_enabled
	respawn_timer.stop()
	_set_available_state(is_enabled)


func _set_available_state(is_available: bool) -> void:
	_available = is_available
	var should_monitor := _spawn_enabled and is_available
	set_deferred("monitoring", should_monitor)
	collision_shape.set_deferred("disabled", not should_monitor)
	visuals_root.visible = _spawn_enabled
	base_mesh.visible = _spawn_enabled
	core_mesh.visible = _spawn_enabled and is_available
	_animation_time = 0.0
	visuals_root.position = _base_visual_position
	visuals_root.rotation = Vector3.ZERO
