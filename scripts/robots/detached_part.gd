extends RigidBody3D
class_name DetachedPart

const PART_COLLISION_SIZES := {
	"left_arm": Vector3(0.45, 0.35, 0.7),
	"right_arm": Vector3(0.45, 0.35, 0.7),
	"left_leg": Vector3(0.55, 0.8, 1.15),
	"right_leg": Vector3(0.55, 0.8, 1.15),
}

@export var cleanup_time := 10.0
@export var pickup_delay := 0.4
@export var throw_pickup_delay := 0.82
@export var carried_hover_height := 1.4
@export var carried_forward_offset := 0.7

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visuals_root: Node3D = $Visuals
@onready var lifetime_timer: Timer = $LifetimeTimer

var part_name := ""
var original_robot: Node = null
var carrier_robot: Node = null
var _starting_collision_layer := 1
var _starting_collision_mask := 1
var _pickup_ready_at := 0.0


func _ready() -> void:
	add_to_group("detached_parts")
	_starting_collision_layer = collision_layer
	_starting_collision_mask = collision_mask
	_pickup_ready_at = Time.get_ticks_msec() / 1000.0 + pickup_delay
	lifetime_timer.start(cleanup_time)


func _physics_process(_delta: float) -> void:
	if carrier_robot == null or not is_instance_valid(carrier_robot):
		return

	var carrier_node := carrier_robot as Node3D
	if carrier_node == null:
		return

	var carry_offset := Vector3.UP * carried_hover_height
	carry_offset += -carrier_node.global_basis.z * carried_forward_offset
	global_position = carrier_node.global_position + carry_offset
	global_rotation = carrier_node.global_rotation


func configure_from_visuals(owner_robot: Node, part_id: String, source_visuals: Array[MeshInstance3D], initial_velocity: Vector3) -> void:
	_ensure_runtime_nodes()
	original_robot = owner_robot
	part_name = part_id
	name = "%sDetached" % part_id.capitalize()
	_rebuild_visuals(source_visuals)
	_configure_collision_shape()
	linear_velocity = initial_velocity
	angular_velocity = Vector3(
		randf_range(-3.0, 3.0),
		randf_range(-4.5, 4.5),
		randf_range(-3.0, 3.0)
	)


func get_original_robot() -> Node:
	return original_robot


func is_carried() -> bool:
	return carrier_robot != null and is_instance_valid(carrier_robot)


func try_pick_up(robot: Node) -> bool:
	if not _is_pickup_ready():
		return false
	if robot == null or not is_instance_valid(robot):
		return false
	if is_carried():
		return false
	if not robot.has_method("try_pick_up_detached_part"):
		return false
	if not bool(robot.try_pick_up_detached_part(self)):
		return false

	carrier_robot = robot
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	lifetime_timer.stop()
	set_physics_process(true)
	return true


func throw_from(carrier: Node, throw_direction: Vector3, throw_speed: float = 6.0) -> bool:
	if not (carrier is Node3D):
		return false
	if not is_carried() or carrier_robot != carrier:
		return false
	if not is_instance_valid(carrier_robot):
		return false

	var carrier_node := carrier_robot as Node3D
	var world_direction := throw_direction
	world_direction.y = 0.0
	if world_direction.length_squared() <= 0.001:
		world_direction = -carrier_node.global_basis.z
	world_direction = world_direction.normalized()

	carrier_robot.release_detached_part(self)
	global_position = carrier_node.global_position + Vector3.UP * carried_hover_height - carrier_node.global_basis.z * carried_forward_offset
	global_rotation = carrier_node.global_rotation
	freeze = false
	linear_velocity = world_direction * throw_speed
	angular_velocity = Vector3(
		randf_range(-3.0, 3.0),
		randf_range(-4.5, 4.5),
		randf_range(-3.0, 3.0)
	)
	collision_layer = _starting_collision_layer
	collision_mask = _starting_collision_mask
	_pickup_ready_at = Time.get_ticks_msec() / 1000.0 + maxf(pickup_delay, throw_pickup_delay)
	if lifetime_timer.is_stopped():
		lifetime_timer.start(cleanup_time)
	carrier_robot = null
	set_physics_process(true)
	return true


func try_deliver_to_robot(target_robot: Node, delivered_by: Node = null) -> bool:
	if not _is_pickup_ready():
		return false
	if target_robot == null or not is_instance_valid(target_robot):
		return false
	if original_robot == null or not is_instance_valid(original_robot):
		return false
	if target_robot != original_robot:
		return false
	if delivered_by == null:
		delivered_by = target_robot
	if delivered_by == null or not is_instance_valid(delivered_by):
		return false
	if not delivered_by.has_method("is_ally_of"):
		return false
	if not bool(delivered_by.is_ally_of(original_robot)):
		return false
	if not target_robot.has_method("restore_part_from_return"):
		return false

	var restored := bool(target_robot.restore_part_from_return(part_name, delivered_by))
	if not restored:
		return false

	if carrier_robot != null and is_instance_valid(carrier_robot) and carrier_robot.has_method("release_detached_part"):
		carrier_robot.release_detached_part(self)

	queue_free()
	return true


func deny_to_void() -> void:
	if carrier_robot != null and is_instance_valid(carrier_robot) and carrier_robot.has_method("release_detached_part"):
		carrier_robot.release_detached_part(self)

	queue_free()


func _ensure_runtime_nodes() -> void:
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape3D")
	if visuals_root == null:
		visuals_root = get_node_or_null("Visuals")
	if lifetime_timer == null:
		lifetime_timer = get_node_or_null("LifetimeTimer")


func _is_pickup_ready() -> bool:
	return Time.get_ticks_msec() / 1000.0 >= _pickup_ready_at


func _rebuild_visuals(source_visuals: Array[MeshInstance3D]) -> void:
	_ensure_runtime_nodes()
	for child in visuals_root.get_children():
		child.queue_free()

	for source_visual in source_visuals:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.transform = source_visual.transform
		mesh_instance.mesh = source_visual.mesh
		mesh_instance.cast_shadow = source_visual.cast_shadow
		mesh_instance.visible = true
		if source_visual.material_override != null:
			mesh_instance.material_override = source_visual.material_override.duplicate()

		visuals_root.add_child(mesh_instance)


func _configure_collision_shape() -> void:
	_ensure_runtime_nodes()
	var box_shape := BoxShape3D.new()
	box_shape.size = PART_COLLISION_SIZES.get(part_name, Vector3.ONE * 0.6)
	collision_shape.shape = box_shape


func _on_lifetime_timer_timeout() -> void:
	queue_free()
