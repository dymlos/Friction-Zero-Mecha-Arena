extends RigidBody3D
class_name DetachedPart

const PART_COLLISION_SIZES := {
	"left_arm": Vector3(0.45, 0.35, 0.7),
	"right_arm": Vector3(0.45, 0.35, 0.7),
	"left_leg": Vector3(0.55, 0.8, 1.15),
	"right_leg": Vector3(0.55, 0.8, 1.15),
}

@export var cleanup_time := 10.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visuals_root: Node3D = $Visuals
@onready var lifetime_timer: Timer = $LifetimeTimer

var part_name := ""


func _ready() -> void:
	add_to_group("detached_parts")
	lifetime_timer.start(cleanup_time)


func configure_from_visuals(part_id: String, source_visuals: Array[MeshInstance3D], initial_velocity: Vector3) -> void:
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


func _rebuild_visuals(source_visuals: Array[MeshInstance3D]) -> void:
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
	var box_shape := BoxShape3D.new()
	box_shape.size = PART_COLLISION_SIZES.get(part_name, Vector3.ONE * 0.6)
	collision_shape.shape = box_shape


func _on_lifetime_timer_timeout() -> void:
	queue_free()
