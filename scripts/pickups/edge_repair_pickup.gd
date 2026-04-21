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
var _animation_time := 0.0
var _base_visual_position := Vector3.ZERO


func _ready() -> void:
	add_to_group("edge_repair_pickups")
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
	var repaired_part_name := robot.repair_most_damaged_part(repair_amount)
	if repaired_part_name == "":
		return

	_set_available_state(false)
	respawn_timer.start(respawn_delay)
	pickup_collected.emit(robot, repaired_part_name)


func _on_respawn_timer_timeout() -> void:
	_set_available_state(true)


func _set_available_state(is_available: bool) -> void:
	_available = is_available
	monitoring = is_available
	collision_shape.disabled = not is_available
	visuals_root.visible = true
	base_mesh.visible = true
	core_mesh.visible = is_available
	_animation_time = 0.0
	visuals_root.position = _base_visual_position
	visuals_root.rotation = Vector3.ZERO
