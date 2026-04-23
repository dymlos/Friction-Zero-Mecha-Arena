extends Area3D
class_name EdgeChargePickup

const RobotBase = preload("res://scripts/robots/robot_base.gd")

signal pickup_collected(robot: RobotBase, restored_charges: int)

@export_range(1, 3, 1) var charge_amount := 1
@export var respawn_delay := 9.0
@export var bob_height := 0.12
@export var bob_speed := 2.35
@export var rotation_speed := 1.3
@export_range(0.0, 1.5, 0.05) var core_emission_pulse_amount := 0.34
@export_range(0.0, 1.5, 0.05) var accent_emission_pulse_amount := 0.22

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visuals_root: Node3D = $Visuals
@onready var base_mesh: MeshInstance3D = $Visuals/Base
@onready var core_mesh: MeshInstance3D = $Visuals/Core
@onready var accent_mesh: MeshInstance3D = $Visuals/Accent
@onready var respawn_timer: Timer = $RespawnTimer

var _available := true
var _spawn_enabled := true
var _collection_enabled := true
var _animation_time := 0.0
var _base_visual_position := Vector3.ZERO
var _core_material: StandardMaterial3D = null
var _accent_material: StandardMaterial3D = null
var _core_base_emission_energy := 0.0
var _accent_base_emission_energy := 0.0


func _ready() -> void:
	add_to_group("edge_pickups")
	add_to_group("edge_charge_pickups")
	_base_visual_position = visuals_root.position
	_prepare_runtime_materials()
	_set_available_state(true)


func _process(delta: float) -> void:
	if not _spawn_enabled or not _available:
		return

	_animation_time += delta
	var wave := sin(_animation_time * bob_speed)
	visuals_root.position = _base_visual_position + Vector3(0.0, wave * bob_height, 0.0)
	visuals_root.rotation.y = fmod(visuals_root.rotation.y + rotation_speed * delta, TAU)
	_update_emissive_pulse()
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
	var previous_charges := robot.get_core_skill_charge_count()
	if not robot.restore_core_skill_charges(charge_amount):
		return false

	var restored_charges := maxi(robot.get_core_skill_charge_count() - previous_charges, 0)
	_set_available_state(false)
	respawn_timer.start(respawn_delay)
	pickup_collected.emit(robot, restored_charges)
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


func _prepare_runtime_materials() -> void:
	if core_mesh.material_override is StandardMaterial3D:
		_core_material = (core_mesh.material_override as StandardMaterial3D).duplicate()
		core_mesh.material_override = _core_material
		_core_material.emission_enabled = true
		_core_base_emission_energy = _core_material.emission_energy_multiplier
	if accent_mesh.material_override is StandardMaterial3D:
		_accent_material = (accent_mesh.material_override as StandardMaterial3D).duplicate()
		accent_mesh.material_override = _accent_material
		_accent_material.emission_enabled = true
		_accent_base_emission_energy = _accent_material.emission_energy_multiplier


func _update_emissive_pulse() -> void:
	var glow_wave := (sin(_animation_time * bob_speed * 0.72) + 1.0) * 0.5
	if _core_material != null:
		_core_material.emission_energy_multiplier = _core_base_emission_energy * (
			1.0 + glow_wave * core_emission_pulse_amount
		)
	if _accent_material != null:
		_accent_material.emission_energy_multiplier = _accent_base_emission_energy * (
			0.92 + glow_wave * accent_emission_pulse_amount
		)


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
	_update_emissive_pulse()
