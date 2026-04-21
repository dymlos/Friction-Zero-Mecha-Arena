extends Area3D
class_name EdgeRepairPickup

const RobotBase = preload("res://scripts/robots/robot_base.gd")

signal pickup_collected(robot: RobotBase, repaired_part_name: String)

@export var repair_amount := 25.0
@export var respawn_delay := 8.0
@export var bob_height := 0.12
@export var bob_speed := 2.2
@export var rotation_speed := 1.1

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
	add_to_group("edge_repair_pickups")
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
	var repaired_part_name := robot.repair_most_damaged_part(repair_amount)
	if repaired_part_name == "":
		return

	_set_available_state(false)
	respawn_timer.start(respawn_delay)
	pickup_collected.emit(robot, repaired_part_name)


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
