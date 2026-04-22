extends Area3D
class_name EdgeEnergyPickup

const RobotBase = preload("res://scripts/robots/robot_base.gd")

signal pickup_collected(robot: RobotBase, surge_duration: float)

@export var surge_duration := 2.6
@export var respawn_delay := 9.5
@export var bob_height := 0.12
@export var bob_speed := 2.4
@export var rotation_speed := 1.25

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visuals_root: Node3D = $Visuals
@onready var base_mesh: MeshInstance3D = $Visuals/Base
@onready var core_mesh: MeshInstance3D = $Visuals/Core
@onready var respawn_timer: Timer = $RespawnTimer

var _available := true
var _spawn_enabled := true
var _collection_enabled := true
var _animation_time := 0.0
var _base_visual_position := Vector3.ZERO


func _ready() -> void:
	add_to_group("edge_pickups")
	add_to_group("edge_energy_pickups")
	_base_visual_position = visuals_root.position
	_set_available_state(true)


func _process(delta: float) -> void:
	if not _spawn_enabled or not _available:
		return

	_animation_time += delta
	var wave := sin(_animation_time * bob_speed)
	visuals_root.position = _base_visual_position + Vector3(0.0, wave * bob_height, 0.0)
	visuals_root.rotation.y = fmod(visuals_root.rotation.y + rotation_speed * delta, TAU)
	if not _collection_enabled or not monitoring:
		return

	for body in get_overlapping_bodies():
		if _try_collect_robot(body):
			return


func _on_body_entered(body: Node) -> void:
	_try_collect_robot(body)


func _try_collect_robot(body: Node) -> bool:
	if not _spawn_enabled or not _available or not _collection_enabled:
		return false
	if not (body is RobotBase):
		return false

	var robot := body as RobotBase
	if not robot.apply_energy_surge(surge_duration):
		return false

	_set_available_state(false)
	respawn_timer.start(respawn_delay)
	pickup_collected.emit(robot, surge_duration)
	return true


func is_collection_enabled() -> bool:
	return _collection_enabled


func set_collection_enabled(is_enabled: bool) -> void:
	_collection_enabled = is_enabled
	_set_available_state(_available)


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
