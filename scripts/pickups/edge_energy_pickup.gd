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
var _animation_time := 0.0
var _base_visual_position := Vector3.ZERO


func _ready() -> void:
	add_to_group("edge_pickups")
	add_to_group("edge_energy_pickups")
	_base_visual_position = visuals_root.position
	_set_available_state(true)


func _process(delta: float) -> void:
	if not _available:
		return

	_animation_time += delta
	var wave := sin(_animation_time * bob_speed)
	visuals_root.position = _base_visual_position + Vector3(0.0, wave * bob_height, 0.0)
	visuals_root.rotation.y = fmod(visuals_root.rotation.y + rotation_speed * delta, TAU)


func _on_body_entered(body: Node) -> void:
	if not _available:
		return
	if not (body is RobotBase):
		return

	var robot := body as RobotBase
	if not robot.apply_energy_surge(surge_duration):
		return

	_set_available_state(false)
	respawn_timer.start(respawn_delay)
	pickup_collected.emit(robot, surge_duration)


func _on_respawn_timer_timeout() -> void:
	_set_available_state(true)


func _set_available_state(is_available: bool) -> void:
	_available = is_available
	set_deferred("monitoring", is_available)
	collision_shape.set_deferred("disabled", not is_available)
	visuals_root.visible = true
	base_mesh.visible = true
	core_mesh.visible = is_available
	_animation_time = 0.0
	visuals_root.position = _base_visual_position
	visuals_root.rotation = Vector3.ZERO
