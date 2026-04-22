extends Camera3D
class_name SharedArenaCamera

@export var target_root_path: NodePath = NodePath("../RobotRoot")
@export var extra_target_root_paths: Array[NodePath] = [NodePath("../SupportRoot")]
@export var camera_height := 18.0
@export var camera_back_offset := 14.0
@export var base_orthographic_size := 18.0
@export var target_padding := 5.0
@export var follow_smoothing := 8.0
@export var zoom_smoothing := 6.0

var _smoothed_center := Vector3.ZERO


func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	_smoothed_center = _get_targets_center()
	_place_camera(_smoothed_center)
	size = base_orthographic_size


func _process(delta: float) -> void:
	var target_center := _get_targets_center()
	var center_shift := _smoothed_center.distance_to(target_center)
	if center_shift > target_padding:
		_smoothed_center = target_center
	else:
		var follow_weight := 1.0 - exp(-follow_smoothing * delta)
		_smoothed_center = _smoothed_center.lerp(target_center, follow_weight)
	_place_camera(_smoothed_center)

	var target_size := _get_target_orthographic_size()
	if target_size > size:
		size = target_size
	else:
		var zoom_weight := 1.0 - exp(-zoom_smoothing * delta)
		size = lerpf(size, target_size, zoom_weight)


func _place_camera(center: Vector3) -> void:
	var look_target := Vector3(center.x, 0.0, center.z)
	global_position = look_target + Vector3(0.0, camera_height, camera_back_offset)
	look_at(look_target, Vector3.UP)


func _get_targets_center() -> Vector3:
	var targets := _get_camera_targets()
	if targets.is_empty():
		return Vector3.ZERO

	var min_position := targets[0].global_position
	var max_position := targets[0].global_position
	for target in targets:
		min_position.x = minf(min_position.x, target.global_position.x)
		min_position.z = minf(min_position.z, target.global_position.z)
		max_position.x = maxf(max_position.x, target.global_position.x)
		max_position.z = maxf(max_position.z, target.global_position.z)

	return Vector3(
		(min_position.x + max_position.x) * 0.5,
		0.0,
		(min_position.z + max_position.z) * 0.5
	)


func _get_target_orthographic_size() -> float:
	var targets := _get_camera_targets()
	if targets.size() <= 1:
		return base_orthographic_size

	var min_position := targets[0].global_position
	var max_position := targets[0].global_position
	for target in targets:
		min_position.x = minf(min_position.x, target.global_position.x)
		min_position.z = minf(min_position.z, target.global_position.z)
		max_position.x = maxf(max_position.x, target.global_position.x)
		max_position.z = maxf(max_position.z, target.global_position.z)

	var viewport_size := get_viewport().get_visible_rect().size
	var aspect_ratio := maxf(viewport_size.x / maxf(viewport_size.y, 1.0), 0.1)
	var needed_height := absf(max_position.z - min_position.z) + target_padding
	var needed_width := (absf(max_position.x - min_position.x) + target_padding) / aspect_ratio

	return maxf(base_orthographic_size, maxf(needed_height, needed_width))


func _get_camera_targets() -> Array[Node3D]:
	var targets: Array[Node3D] = []
	_collect_targets_from_root(target_root_path, targets)
	for root_path in extra_target_root_paths:
		_collect_targets_from_root(root_path, targets)
	return targets


func _collect_targets_from_root(root_path: NodePath, targets: Array[Node3D]) -> void:
	var target_root := get_node_or_null(root_path)
	if target_root == null:
		return

	for child in target_root.get_children():
		if not (child is Node3D):
			continue

		var target := child as Node3D
		if target.visible:
			targets.append(target)
