extends Node3D
class_name ArenaBase

@export var arena_id := "blockout_arena"
@export var safe_play_area_size := Vector2(24.0, 16.0)
@export var lethal_edge_margin := 2.0

@onready var platform_collision_shape: CollisionShape3D = $Platform/CollisionShape3D
@onready var platform_visual: MeshInstance3D = $Platform/PlatformVisual
@onready var edge_markers: Node3D = $EdgeMarkers
@onready var north_edge: MeshInstance3D = $EdgeMarkers/NorthEdge
@onready var south_edge: MeshInstance3D = $EdgeMarkers/SouthEdge
@onready var west_edge: MeshInstance3D = $EdgeMarkers/WestEdge
@onready var east_edge: MeshInstance3D = $EdgeMarkers/EastEdge

var _current_play_area_size := Vector2.ZERO
var _platform_shape: BoxShape3D = null
var _platform_mesh: BoxMesh = null


func _ready() -> void:
	_current_play_area_size = safe_play_area_size
	_prepare_runtime_resources()
	_update_play_area_visuals()


func get_spawn_points() -> Array[Marker3D]:
	# Los puntos de spawn estan como hijos para que puedan moverse desde el editor.
	var points: Array[Marker3D] = []
	for child in get_children():
		if child is Marker3D:
			points.append(child)

	return points


func get_safe_play_area_size() -> Vector2:
	return _current_play_area_size if _current_play_area_size != Vector2.ZERO else safe_play_area_size


func set_play_area_scale(scale_ratio: float) -> void:
	var clamped_ratio := clampf(scale_ratio, 0.35, 1.0)
	set_current_play_area_size(safe_play_area_size * clamped_ratio)


func set_current_play_area_size(new_size: Vector2) -> void:
	var target_size := Vector2(
		clampf(new_size.x, safe_play_area_size.x * 0.35, safe_play_area_size.x),
		clampf(new_size.y, safe_play_area_size.y * 0.35, safe_play_area_size.y)
	)
	if target_size.is_equal_approx(get_safe_play_area_size()):
		return

	_current_play_area_size = target_size
	_update_play_area_visuals()


func is_position_inside_play_area(world_position: Vector3) -> bool:
	var local_position := to_local(world_position)
	var half_size := get_safe_play_area_size() * 0.5
	return absf(local_position.x) <= half_size.x and absf(local_position.z) <= half_size.y


func _prepare_runtime_resources() -> void:
	if platform_collision_shape.shape is BoxShape3D:
		_platform_shape = (platform_collision_shape.shape as BoxShape3D).duplicate()
		platform_collision_shape.shape = _platform_shape

	if platform_visual.mesh is BoxMesh:
		_platform_mesh = (platform_visual.mesh as BoxMesh).duplicate()
		platform_visual.mesh = _platform_mesh


func _update_play_area_visuals() -> void:
	var current_size := get_safe_play_area_size()
	if _platform_shape != null:
		_platform_shape.size = Vector3(current_size.x, _platform_shape.size.y, current_size.y)

	if _platform_mesh != null:
		_platform_mesh.size = Vector3(current_size.x, _platform_mesh.size.y, current_size.y)

	var edge_height := north_edge.position.y
	var half_width := current_size.x * 0.5
	var half_depth := current_size.y * 0.5
	north_edge.transform = Transform3D(Basis().scaled(Vector3(current_size.x, 1.0, 0.14)), Vector3(0.0, edge_height, -half_depth))
	south_edge.transform = Transform3D(Basis().scaled(Vector3(current_size.x, 1.0, 0.14)), Vector3(0.0, edge_height, half_depth))
	west_edge.transform = Transform3D(Basis().scaled(Vector3(0.14, 1.0, current_size.y)), Vector3(-half_width, edge_height, 0.0))
	east_edge.transform = Transform3D(Basis().scaled(Vector3(0.14, 1.0, current_size.y)), Vector3(half_width, edge_height, 0.0))
