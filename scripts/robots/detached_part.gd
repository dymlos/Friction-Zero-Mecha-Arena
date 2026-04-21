extends RigidBody3D
class_name DetachedPart

signal recovery_lost(detached_part: DetachedPart, reason: String)

const PART_COLLISION_SIZES := {
	"left_arm": Vector3(0.45, 0.35, 0.7),
	"right_arm": Vector3(0.45, 0.35, 0.7),
	"left_leg": Vector3(0.55, 0.8, 1.15),
	"right_leg": Vector3(0.55, 0.8, 1.15),
}

const PART_RECOVERY_COLORS := {
	"left_arm": Color(0.98, 0.45, 0.12, 0.85),
	"right_arm": Color(0.98, 0.58, 0.15, 0.85),
	"left_leg": Color(0.22, 0.56, 0.94, 0.85),
	"right_leg": Color(0.29, 0.72, 1.0, 0.85),
}

@export var cleanup_time := 10.0
@export var pickup_delay := 0.4
@export var throw_pickup_delay := 0.82
@export var carried_hover_height := 1.4
@export var carried_forward_offset := 0.7
@export_group("Recovery Readability")
@export var recovery_indicator_height := 0.08
@export var recovery_indicator_radius := 0.32
@export_range(0.2, 1.0, 0.05) var recovery_indicator_min_scale := 0.35

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visuals_root: Node3D = $Visuals
@onready var lifetime_timer: Timer = $LifetimeTimer

var part_name := ""
var original_robot: Node = null
var carrier_robot: Node = null
var _cleanup_time_left := 0.0
var _starting_collision_layer := 1
var _starting_collision_mask := 1
var _pickup_ready_at := 0.0
var _recovery_indicator: MeshInstance3D = null
var _ownership_indicator: MeshInstance3D = null
var _last_recovery_loss_source: Node = null


func _ready() -> void:
	add_to_group("detached_parts")
	_starting_collision_layer = collision_layer
	_starting_collision_mask = collision_mask
	_pickup_ready_at = Time.get_ticks_msec() / 1000.0 + pickup_delay
	_cleanup_time_left = maxf(cleanup_time, 0.0)
	_setup_recovery_indicator()
	_notify_owner_recovery_tracking(true)
	_refresh_recovery_indicator()


func _exit_tree() -> void:
	_notify_owner_recovery_tracking(false)


func _physics_process(_delta: float) -> void:
	_update_cleanup_timer(_delta)
	_refresh_recovery_indicator()
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
	_refresh_recovery_indicator()


func get_original_robot() -> Node:
	return original_robot


func is_carried() -> bool:
	return carrier_robot != null and is_instance_valid(carrier_robot)


func get_cleanup_time_left() -> float:
	return maxf(_cleanup_time_left, 0.0)


func get_cleanup_progress_ratio() -> float:
	if cleanup_time <= 0.0:
		return 0.0

	return clampf(get_cleanup_time_left() / cleanup_time, 0.0, 1.0)


func get_last_recovery_loss_source() -> Node:
	return _last_recovery_loss_source


func is_pickup_ready() -> bool:
	return _is_pickup_ready()


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

	_last_recovery_loss_source = null
	carrier_robot = robot
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	set_physics_process(true)
	_refresh_recovery_indicator()
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
	_last_recovery_loss_source = null
	linear_velocity = world_direction * throw_speed
	angular_velocity = Vector3(
		randf_range(-3.0, 3.0),
		randf_range(-4.5, 4.5),
		randf_range(-3.0, 3.0)
	)
	collision_layer = _starting_collision_layer
	collision_mask = _starting_collision_mask
	_pickup_ready_at = Time.get_ticks_msec() / 1000.0 + maxf(pickup_delay, throw_pickup_delay)
	carrier_robot = null
	set_physics_process(true)
	_refresh_recovery_indicator()
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

	_notify_owner_recovery_tracking(false)
	queue_free()
	return true


func deny_to_void() -> void:
	_last_recovery_loss_source = carrier_robot if carrier_robot != null and is_instance_valid(carrier_robot) else null
	if carrier_robot != null and is_instance_valid(carrier_robot) and carrier_robot.has_method("release_detached_part"):
		carrier_robot.release_detached_part(self)

	recovery_lost.emit(self, "void")
	_notify_owner_recovery_tracking(false)
	queue_free()


func _ensure_runtime_nodes() -> void:
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape3D")
	if visuals_root == null:
		visuals_root = get_node_or_null("Visuals")
	if lifetime_timer == null:
		lifetime_timer = get_node_or_null("LifetimeTimer")


func _notify_owner_recovery_tracking(should_register: bool) -> void:
	if original_robot == null or not is_instance_valid(original_robot):
		return

	if should_register:
		if original_robot.has_method("register_recoverable_detached_part"):
			original_robot.register_recoverable_detached_part(self)
		return

	if original_robot.has_method("unregister_recoverable_detached_part"):
		original_robot.unregister_recoverable_detached_part(self)


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


func _setup_recovery_indicator() -> void:
	if _recovery_indicator != null:
		_setup_ownership_indicator()
		return

	var indicator_mesh := CylinderMesh.new()
	indicator_mesh.top_radius = recovery_indicator_radius
	indicator_mesh.bottom_radius = recovery_indicator_radius
	indicator_mesh.height = 0.03
	indicator_mesh.radial_segments = 24
	indicator_mesh.rings = 1

	var indicator_material := StandardMaterial3D.new()
	indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator_material.no_depth_test = true
	indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	indicator_material.albedo_color = Color(0.95, 0.62, 0.18, 0.8)
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(1.0, 0.7, 0.22)
	indicator_material.emission_energy_multiplier = 0.5

	_recovery_indicator = MeshInstance3D.new()
	_recovery_indicator.name = "RecoveryIndicator"
	_recovery_indicator.mesh = indicator_mesh
	_recovery_indicator.material_override = indicator_material
	_recovery_indicator.top_level = true
	_recovery_indicator.visible = false
	add_child(_recovery_indicator)
	_setup_ownership_indicator()


func _setup_ownership_indicator() -> void:
	if _ownership_indicator != null:
		return

	var indicator_mesh := CylinderMesh.new()
	indicator_mesh.top_radius = recovery_indicator_radius * 1.18
	indicator_mesh.bottom_radius = recovery_indicator_radius * 1.18
	indicator_mesh.height = 0.015
	indicator_mesh.radial_segments = 24
	indicator_mesh.rings = 1

	var indicator_material := StandardMaterial3D.new()
	indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator_material.no_depth_test = true
	indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	indicator_material.albedo_color = _get_owner_identity_color()
	indicator_material.emission_enabled = true
	indicator_material.emission = _get_owner_identity_color()
	indicator_material.emission_energy_multiplier = 0.85

	_ownership_indicator = MeshInstance3D.new()
	_ownership_indicator.name = "OwnershipIndicator"
	_ownership_indicator.mesh = indicator_mesh
	_ownership_indicator.material_override = indicator_material
	_ownership_indicator.top_level = true
	_ownership_indicator.visible = false
	add_child(_ownership_indicator)


func _refresh_recovery_indicator() -> void:
	if _recovery_indicator == null:
		return

	var should_show := not is_carried() and get_cleanup_time_left() > 0.0 and cleanup_time > 0.0
	_recovery_indicator.visible = should_show
	if _ownership_indicator != null:
		_ownership_indicator.visible = should_show
	if not should_show:
		return

	var ratio := get_cleanup_progress_ratio()
	var base_color: Color = PART_RECOVERY_COLORS.get(part_name, Color(0.95, 0.62, 0.18, 0.85))
	var urgency_color := Color(1.0, 0.24, 0.18, 0.95)
	var display_scale := lerpf(recovery_indicator_min_scale, 1.0, ratio)
	var material := _recovery_indicator.material_override as StandardMaterial3D
	if material != null:
		var indicator_color := urgency_color.lerp(base_color, ratio)
		material.albedo_color = indicator_color
		material.emission = indicator_color

	_recovery_indicator.global_position = global_position + Vector3.UP * recovery_indicator_height
	_recovery_indicator.global_rotation = Vector3.ZERO
	_recovery_indicator.scale = Vector3(display_scale, 1.0, display_scale)
	_refresh_ownership_indicator()


func _refresh_ownership_indicator() -> void:
	if _ownership_indicator == null:
		return

	var material := _ownership_indicator.material_override as StandardMaterial3D
	var owner_color := _get_owner_identity_color()
	if material != null:
		material.albedo_color = owner_color
		material.emission = owner_color

	_ownership_indicator.global_position = global_position + Vector3.UP * (recovery_indicator_height + 0.012)
	_ownership_indicator.global_rotation = Vector3.ZERO
	_ownership_indicator.scale = Vector3.ONE


func _get_owner_identity_color() -> Color:
	if original_robot != null and is_instance_valid(original_robot) and original_robot.has_method("get_identity_color"):
		return original_robot.call("get_identity_color") as Color

	return PART_RECOVERY_COLORS.get(part_name, Color(0.95, 0.62, 0.18, 0.85))


func _update_cleanup_timer(delta: float) -> void:
	if cleanup_time <= 0.0 or is_carried():
		return
	if _cleanup_time_left <= 0.0:
		return

	_cleanup_time_left = maxf(_cleanup_time_left - maxf(delta, 0.0), 0.0)
	if _cleanup_time_left > 0.0:
		return

	_expire_recovery_window()


func _expire_recovery_window() -> void:
	_last_recovery_loss_source = null
	recovery_lost.emit(self, "timeout")
	_notify_owner_recovery_tracking(false)
	queue_free()


func _on_lifetime_timer_timeout() -> void:
	_expire_recovery_window()
