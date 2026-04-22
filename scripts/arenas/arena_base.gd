extends Node3D
class_name ArenaBase

const RobotBase = preload("res://scripts/robots/robot_base.gd")
const EDGE_PICKUP_LAYOUT_PROFILE_TEAMS := "teams"
const EDGE_PICKUP_LAYOUT_PROFILE_FFA := "ffa"
const DEFAULT_EDGE_PICKUP_ALLOWED_IDS := ["repair", "mobility", "energy", "pulse", "utility"]
const EDGE_PICKUP_LABELS := {
	"repair": "reparacion",
	"mobility": "movilidad",
	"energy": "energia",
	"pulse": "pulso",
	"charge": "municion",
	"utility": "estabilidad",
}
const EDGE_PICKUP_LAYOUTS_BY_PROFILE := {
	EDGE_PICKUP_LAYOUT_PROFILE_TEAMS: [
		["repair", "mobility"],
		["energy", "mobility"],
		["repair", "pulse"],
		["energy", "pulse"],
		["repair", "utility"],
		["mobility", "utility"],
		["repair", "charge"],
		["energy", "charge"],
	],
	EDGE_PICKUP_LAYOUT_PROFILE_FFA: [
		["repair", "mobility", "pulse"],
		["repair", "energy", "pulse"],
		["energy", "mobility", "pulse"],
		["repair", "energy", "mobility"],
		["repair", "pulse", "utility"],
		["energy", "mobility", "utility"],
		["repair", "pulse", "charge"],
		["energy", "pulse", "charge"],
		["mobility", "pulse", "charge"],
	],
}

@export_enum("teams", "ffa") var edge_pickup_layout_profile := EDGE_PICKUP_LAYOUT_PROFILE_TEAMS

@export var arena_id := "blockout_arena"
@export var safe_play_area_size := Vector2(24.0, 16.0)
@export var lethal_edge_margin := 2.0
@export var edge_pickup_layout_seed := 11
@export_range(0.5, 6.0, 0.1) var support_lane_margin := 2.2
@export_range(0.4, 3.0, 0.1) var pressure_band_thickness := 1.4
@export_range(0.0, 2.5, 0.1) var pressure_band_inset := 0.7
@export_range(0.4, 1.0, 0.05) var pressure_band_length_ratio := 0.82
@export_range(0.3, 1.0, 0.05) var opening_lane_length_ratio := 0.68
@export_range(0.3, 1.8, 0.05) var opening_lane_thickness := 0.8
@export_range(0.0, 1.5, 0.05) var opening_lane_row_padding := 0.45

@onready var platform_collision_shape: CollisionShape3D = $Platform/CollisionShape3D
@onready var platform_visual: MeshInstance3D = $Platform/PlatformVisual
@onready var edge_markers: Node3D = $EdgeMarkers
@onready var north_edge: MeshInstance3D = $EdgeMarkers/NorthEdge
@onready var south_edge: MeshInstance3D = $EdgeMarkers/SouthEdge
@onready var west_edge: MeshInstance3D = $EdgeMarkers/WestEdge
@onready var east_edge: MeshInstance3D = $EdgeMarkers/EastEdge
@onready var cover_blocks_root: Node3D = $CoverBlocks
@onready var pressure_telegraph_root: Node3D = $PressureTelegraph
@onready var north_pressure_band: MeshInstance3D = $PressureTelegraph/NorthBand
@onready var south_pressure_band: MeshInstance3D = $PressureTelegraph/SouthBand
@onready var west_pressure_band: MeshInstance3D = $PressureTelegraph/WestBand
@onready var east_pressure_band: MeshInstance3D = $PressureTelegraph/EastBand

var _current_play_area_size := Vector2.ZERO
var _platform_shape: BoxShape3D = null
var _platform_mesh: BoxMesh = null
var _cover_block_nodes: Array[Node3D] = []
var _cover_block_original_positions: Dictionary = {}
var _edge_pickup_nodes: Array[Node3D] = []
var _edge_pickup_original_local_positions: Dictionary = {}
var _support_lane_nodes: Array[Node3D] = []
var _support_lane_original_local_positions: Dictionary = {}
var _edge_pickup_layout_cycle: Array[PackedStringArray] = []
var _edge_pickup_allowed_ids := PackedStringArray(DEFAULT_EDGE_PICKUP_ALLOWED_IDS)
var _active_edge_pickup_layout := PackedStringArray()
var _pressure_band_materials: Array[StandardMaterial3D] = []
var _pressure_warning_strength := 0.0
var _opening_telegraph_root: Node3D = null
var _opening_lane_meshes: Array[MeshInstance3D] = []
var _opening_lane_materials: Array[StandardMaterial3D] = []
var _opening_lane_rows := PackedFloat32Array()
var _opening_telegraph_active := false


func _ready() -> void:
	_current_play_area_size = safe_play_area_size
	_prepare_runtime_resources()
	_setup_opening_telegraph()
	_cache_cover_block_positions()
	_cache_edge_pickup_positions()
	_cache_support_lane_node_positions()
	_build_edge_pickup_layout_cycle()
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


func set_pressure_warning_strength(warning_strength: float) -> void:
	var next_warning_strength := clampf(warning_strength, 0.0, 1.0)
	if is_equal_approx(_pressure_warning_strength, next_warning_strength):
		return

	_pressure_warning_strength = next_warning_strength
	_update_pressure_telegraph(get_safe_play_area_size())


func set_opening_lane_rows(team_rows: PackedFloat32Array, active: bool) -> void:
	var next_active := active and team_rows.size() >= 2
	var next_rows := PackedFloat32Array()
	if next_active:
		next_rows = team_rows.duplicate()
		next_rows.sort()

	if _opening_telegraph_active == next_active and _opening_lane_rows == next_rows:
		return

	_opening_telegraph_active = next_active
	_opening_lane_rows = next_rows
	_update_opening_telegraph(get_safe_play_area_size())


func set_current_play_area_size(new_size: Vector2) -> void:
	var target_size := Vector2(
		clampf(new_size.x, safe_play_area_size.x * 0.35, safe_play_area_size.x),
		clampf(new_size.y, safe_play_area_size.y * 0.35, safe_play_area_size.y)
	)
	if target_size.is_equal_approx(get_safe_play_area_size()):
		return

	_current_play_area_size = target_size
	_update_play_area_visuals()


func activate_edge_pickup_layout_for_round(round_number: int) -> void:
	if _edge_pickup_nodes.is_empty():
		_cache_edge_pickup_positions()
	if _edge_pickup_layout_cycle.is_empty():
		_build_edge_pickup_layout_cycle()
	if _edge_pickup_layout_cycle.is_empty():
		return

	var layout_index := posmod(maxi(round_number - 1, 0), _edge_pickup_layout_cycle.size())
	var active_layout := _edge_pickup_layout_cycle[layout_index]
	_active_edge_pickup_layout = active_layout.duplicate()
	for pickup in _edge_pickup_nodes:
		if not is_instance_valid(pickup):
			continue
		if not pickup.has_method("set_spawn_enabled"):
			continue

		pickup.call("set_spawn_enabled", active_layout.has(_get_edge_pickup_layout_id(pickup)))


func set_edge_pickup_layout_profile(profile_name: String) -> void:
	var next_profile := profile_name if EDGE_PICKUP_LAYOUTS_BY_PROFILE.has(profile_name) else EDGE_PICKUP_LAYOUT_PROFILE_TEAMS
	if edge_pickup_layout_profile == next_profile and not _edge_pickup_layout_cycle.is_empty():
		return

	edge_pickup_layout_profile = next_profile
	_active_edge_pickup_layout = PackedStringArray()
	_build_edge_pickup_layout_cycle()


func set_edge_pickup_allowed_ids(allowed_ids: PackedStringArray) -> void:
	var next_allowed_ids := PackedStringArray()
	for layout_id in allowed_ids:
		if not EDGE_PICKUP_LABELS.has(layout_id):
			continue
		if next_allowed_ids.has(layout_id):
			continue

		next_allowed_ids.append(layout_id)

	if next_allowed_ids.is_empty():
		next_allowed_ids = PackedStringArray(DEFAULT_EDGE_PICKUP_ALLOWED_IDS)
	if _edge_pickup_allowed_ids == next_allowed_ids:
		return

	_edge_pickup_allowed_ids = next_allowed_ids
	_active_edge_pickup_layout = PackedStringArray()
	_build_edge_pickup_layout_cycle()


func get_active_edge_pickup_layout_ids() -> PackedStringArray:
	return _active_edge_pickup_layout.duplicate()


func get_active_edge_pickup_layout_summary() -> String:
	if _active_edge_pickup_layout.is_empty():
		return ""

	var labels: PackedStringArray = []
	for layout_id in _active_edge_pickup_layout:
		labels.append(String(EDGE_PICKUP_LABELS.get(layout_id, layout_id)))

	return ", ".join(labels)


func is_position_inside_play_area(world_position: Vector3) -> bool:
	var local_position := to_local(world_position)
	var half_size := get_safe_play_area_size() * 0.5
	return absf(local_position.x) <= half_size.x and absf(local_position.z) <= half_size.y


func get_support_lane_spawn_position_near(world_position: Vector3) -> Vector3:
	return get_support_lane_position_from_progress(get_support_lane_progress_near(world_position))


func get_support_lane_progress_near(world_position: Vector3) -> float:
	var local_position := to_local(world_position)
	var lane_extents := _get_support_lane_extents()
	var corner_candidates := [
		{"distance_squared": Vector2(local_position.x - lane_extents.x, local_position.z + lane_extents.y).length_squared(), "progress": lane_extents.x * 2.0},
		{"distance_squared": Vector2(local_position.x + lane_extents.x, local_position.z + lane_extents.y).length_squared(), "progress": 0.0},
		{"distance_squared": Vector2(local_position.x - lane_extents.x, local_position.z - lane_extents.y).length_squared(), "progress": lane_extents.x * 2.0 + lane_extents.y * 2.0},
		{"distance_squared": Vector2(local_position.x + lane_extents.x, local_position.z - lane_extents.y).length_squared(), "progress": lane_extents.x * 2.0 + lane_extents.y * 4.0},
	]
	var edge_candidates := [
		{"distance_squared": absf(local_position.z + lane_extents.y), "progress": clampf(local_position.x + lane_extents.x, 0.0, lane_extents.x * 2.0)},
		{"distance_squared": absf(local_position.x - lane_extents.x), "progress": lane_extents.x * 2.0 + clampf(local_position.z + lane_extents.y, 0.0, lane_extents.y * 2.0)},
		{"distance_squared": absf(local_position.z - lane_extents.y), "progress": lane_extents.x * 2.0 + lane_extents.y * 2.0 + clampf(lane_extents.x - local_position.x, 0.0, lane_extents.x * 2.0)},
		{"distance_squared": absf(local_position.x + lane_extents.x), "progress": lane_extents.x * 4.0 + lane_extents.y * 2.0 + clampf(lane_extents.y - local_position.z, 0.0, lane_extents.y * 2.0)},
	]
	var best_progress := 0.0
	var best_distance_squared := INF
	for candidate in corner_candidates:
		var candidate_distance := float(candidate["distance_squared"])
		if candidate_distance >= best_distance_squared:
			continue

		best_distance_squared = candidate_distance
		best_progress = float(candidate["progress"])
	for candidate in edge_candidates:
		var candidate_distance := float(candidate["distance_squared"])
		if candidate_distance >= best_distance_squared:
			continue

		best_distance_squared = candidate_distance
		best_progress = float(candidate["progress"])

	return fposmod(best_progress, get_support_lane_perimeter_length())


func get_support_lane_position_from_progress(progress: float) -> Vector3:
	var lane_extents := _get_support_lane_extents()
	var perimeter := get_support_lane_perimeter_length()
	if perimeter <= 0.0:
		return global_position

	var remaining := fposmod(progress, perimeter)
	var horizontal_length := lane_extents.x * 2.0
	var vertical_length := lane_extents.y * 2.0
	var local_position := Vector3(-lane_extents.x, 0.55, -lane_extents.y)
	if remaining <= horizontal_length:
		local_position.x = -lane_extents.x + remaining
		return to_global(local_position)

	remaining -= horizontal_length
	local_position = Vector3(lane_extents.x, 0.55, -lane_extents.y)
	if remaining <= vertical_length:
		local_position.z = -lane_extents.y + remaining
		return to_global(local_position)

	remaining -= vertical_length
	local_position = Vector3(lane_extents.x, 0.55, lane_extents.y)
	if remaining <= horizontal_length:
		local_position.x = lane_extents.x - remaining
		return to_global(local_position)

	remaining -= horizontal_length
	local_position = Vector3(-lane_extents.x, 0.55, lane_extents.y)
	local_position.z = lane_extents.y - remaining
	return to_global(local_position)


func get_support_lane_tangent_from_progress(progress: float) -> Vector2:
	var lane_extents := _get_support_lane_extents()
	var perimeter := get_support_lane_perimeter_length()
	if perimeter <= 0.0:
		return Vector2.RIGHT

	var remaining := fposmod(progress, perimeter)
	var horizontal_length := lane_extents.x * 2.0
	var vertical_length := lane_extents.y * 2.0
	if remaining < horizontal_length:
		return Vector2.RIGHT
	if remaining < horizontal_length + vertical_length:
		return Vector2.DOWN
	if remaining < horizontal_length * 2.0 + vertical_length:
		return Vector2.LEFT
	return Vector2.UP


func advance_support_lane_progress(progress: float, signed_distance: float) -> float:
	return fposmod(progress + signed_distance, get_support_lane_perimeter_length())


func get_support_lane_perimeter_length() -> float:
	var lane_extents := _get_support_lane_extents()
	return (lane_extents.x + lane_extents.y) * 4.0


func get_support_lane_blocking_gate_progress(progress: float, signed_distance: float) -> float:
	if signed_distance == 0.0:
		return -1.0

	var perimeter := get_support_lane_perimeter_length()
	if perimeter <= 0.0:
		return -1.0

	var direction := 1.0 if signed_distance > 0.0 else -1.0
	var travel_distance := absf(signed_distance)
	var start_progress := fposmod(progress, perimeter)
	var best_gate_progress := -1.0
	var best_travel_to_gate := INF
	for node in get_tree().get_nodes_in_group("support_lane_gates"):
		if not (node is Node3D):
			continue
		if not is_ancestor_of(node):
			continue
		if not node.has_method("is_blocking") or not bool(node.call("is_blocking")):
			continue
		if not node.has_method("get_blocking_radius"):
			continue

		var gate_node := node as Node3D
		var gate_progress := get_support_lane_progress_near(gate_node.global_position)
		var gate_radius := maxf(float(node.call("get_blocking_radius")), 0.05)
		var signed_delta_to_gate := _get_support_lane_signed_distance(start_progress, gate_progress)
		if direction < 0.0:
			signed_delta_to_gate *= -1.0
		if signed_delta_to_gate < -gate_radius:
			continue

		var distance_to_gate := maxf(signed_delta_to_gate - gate_radius, 0.0)
		if distance_to_gate > travel_distance:
			continue
		if distance_to_gate >= best_travel_to_gate:
			continue

		best_travel_to_gate = distance_to_gate
		best_gate_progress = gate_progress

	return best_gate_progress


func _get_support_lane_extents() -> Vector2:
	var half_size := get_safe_play_area_size() * 0.5
	var edge_margin := maxf(support_lane_margin, 0.5)
	return Vector2(half_size.x + edge_margin, half_size.y + edge_margin)


func _prepare_runtime_resources() -> void:
	if platform_collision_shape.shape is BoxShape3D:
		_platform_shape = (platform_collision_shape.shape as BoxShape3D).duplicate()
		platform_collision_shape.shape = _platform_shape

	if platform_visual.mesh is BoxMesh:
		_platform_mesh = (platform_visual.mesh as BoxMesh).duplicate()
		platform_visual.mesh = _platform_mesh

	_prepare_pressure_telegraph_materials()


func _setup_opening_telegraph() -> void:
	if _opening_telegraph_root != null:
		return

	_opening_telegraph_root = Node3D.new()
	_opening_telegraph_root.name = "OpeningTelegraph"
	_opening_telegraph_root.visible = false
	add_child(_opening_telegraph_root)

	_opening_lane_meshes.clear()
	_opening_lane_materials.clear()
	for lane_name in ["LaneA", "LaneB"]:
		var lane_mesh := BoxMesh.new()
		lane_mesh.size = Vector3(1.0, 0.03, 1.0)
		var lane_material := StandardMaterial3D.new()
		lane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lane_material.albedo_color = Color(0.98, 0.7, 0.24, 0.14)
		lane_material.emission_enabled = true
		lane_material.emission = Color(1.0, 0.78, 0.24, 1.0)
		lane_material.emission_energy_multiplier = 0.3
		lane_material.roughness = 0.84

		var lane_instance := MeshInstance3D.new()
		lane_instance.name = lane_name
		lane_instance.mesh = lane_mesh
		lane_instance.material_override = lane_material
		lane_instance.visible = false
		_opening_telegraph_root.add_child(lane_instance)
		_opening_lane_meshes.append(lane_instance)
		_opening_lane_materials.append(lane_material)


func _prepare_pressure_telegraph_materials() -> void:
	_pressure_band_materials.clear()
	for band in [
		north_pressure_band,
		south_pressure_band,
		west_pressure_band,
		east_pressure_band,
	]:
		if band == null:
			continue
		if band.material_override is StandardMaterial3D:
			var duplicated_material := (band.material_override as StandardMaterial3D).duplicate()
			band.material_override = duplicated_material
			_pressure_band_materials.append(duplicated_material)


func _cache_cover_block_positions() -> void:
	_cover_block_nodes.clear()
	_cover_block_original_positions.clear()
	if cover_blocks_root == null:
		return

	for child in cover_blocks_root.get_children():
		if not (child is Node3D):
			continue

		var cover_block := child as Node3D
		_cover_block_nodes.append(cover_block)
		_cover_block_original_positions[cover_block.get_instance_id()] = cover_block.position


func _cache_edge_pickup_positions() -> void:
	_edge_pickup_nodes.clear()
	_edge_pickup_original_local_positions.clear()

	for node in get_tree().get_nodes_in_group("edge_pickups"):
		if not (node is Node3D):
			continue

		var pickup := node as Node3D
		if not is_ancestor_of(pickup):
			continue

		_edge_pickup_nodes.append(pickup)
		_edge_pickup_original_local_positions[pickup.get_instance_id()] = to_local(pickup.global_position)


func _cache_support_lane_node_positions() -> void:
	_support_lane_nodes.clear()
	_support_lane_original_local_positions.clear()

	for node in get_tree().get_nodes_in_group("support_lane_nodes"):
		if not (node is Node3D):
			continue

		var lane_node := node as Node3D
		if not is_ancestor_of(lane_node):
			continue

		_support_lane_nodes.append(lane_node)
		_support_lane_original_local_positions[lane_node.get_instance_id()] = to_local(lane_node.global_position)


func _build_edge_pickup_layout_cycle() -> void:
	_edge_pickup_layout_cycle.clear()
	var profile_layouts: Array = EDGE_PICKUP_LAYOUTS_BY_PROFILE.get(edge_pickup_layout_profile, EDGE_PICKUP_LAYOUTS_BY_PROFILE[EDGE_PICKUP_LAYOUT_PROFILE_TEAMS])
	for layout in profile_layouts:
		var packed_layout := PackedStringArray(layout)
		var layout_allowed := true
		for layout_id in packed_layout:
			if _edge_pickup_allowed_ids.has(layout_id):
				continue

			layout_allowed = false
			break

		if layout_allowed:
			_edge_pickup_layout_cycle.append(packed_layout)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(edge_pickup_layout_seed)
	for index in range(_edge_pickup_layout_cycle.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var current_layout := _edge_pickup_layout_cycle[index]
		_edge_pickup_layout_cycle[index] = _edge_pickup_layout_cycle[swap_index]
		_edge_pickup_layout_cycle[swap_index] = current_layout


func _get_edge_pickup_layout_id(pickup: Node) -> String:
	if pickup.is_in_group("edge_repair_pickups"):
		return "repair"
	if pickup.is_in_group("edge_mobility_pickups"):
		return "mobility"
	if pickup.is_in_group("edge_energy_pickups"):
		return "energy"
	if pickup.is_in_group("edge_pulse_pickups"):
		return "pulse"
	if pickup.is_in_group("edge_charge_pickups"):
		return "charge"
	if pickup.is_in_group("edge_utility_pickups"):
		return "utility"

	return ""


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
	_update_pressure_telegraph(current_size)
	_update_opening_telegraph(current_size)
	_update_cover_block_positions(current_size)
	_update_edge_pickup_positions(current_size)
	_update_support_lane_node_positions(current_size)


func _update_pressure_telegraph(current_size: Vector2) -> void:
	if pressure_telegraph_root == null:
		return

	var shrink_strength := _get_pressure_telegraph_strength(current_size)
	var telegraph_strength := maxf(shrink_strength, _pressure_warning_strength)
	var telegraph_visible := telegraph_strength > 0.001
	pressure_telegraph_root.visible = telegraph_visible
	for band in [
		north_pressure_band,
		south_pressure_band,
		west_pressure_band,
		east_pressure_band,
	]:
		if band != null:
			band.visible = telegraph_visible

	if not telegraph_visible:
		return

	var half_width := current_size.x * 0.5
	var half_depth := current_size.y * 0.5
	var inset := minf(pressure_band_inset, maxf(minf(half_width, half_depth) - pressure_band_thickness * 0.5, 0.0))
	var horizontal_length := maxf(current_size.x * pressure_band_length_ratio, pressure_band_thickness)
	var vertical_length := maxf(current_size.y * pressure_band_length_ratio, pressure_band_thickness)
	var band_height := 0.32
	north_pressure_band.transform = Transform3D(
		Basis().scaled(Vector3(horizontal_length, 1.0, pressure_band_thickness)),
		Vector3(0.0, band_height, -half_depth + inset)
	)
	south_pressure_band.transform = Transform3D(
		Basis().scaled(Vector3(horizontal_length, 1.0, pressure_band_thickness)),
		Vector3(0.0, band_height, half_depth - inset)
	)
	west_pressure_band.transform = Transform3D(
		Basis().scaled(Vector3(pressure_band_thickness, 1.0, vertical_length)),
		Vector3(-half_width + inset, band_height, 0.0)
	)
	east_pressure_band.transform = Transform3D(
		Basis().scaled(Vector3(pressure_band_thickness, 1.0, vertical_length)),
		Vector3(half_width - inset, band_height, 0.0)
	)
	_update_pressure_telegraph_materials(telegraph_strength, shrink_strength > 0.001)


func _update_pressure_telegraph_materials(telegraph_strength: float, shrinking: bool) -> void:
	var alpha := lerpf(0.08, 0.28, telegraph_strength)
	var emission_energy := lerpf(0.16, 0.9, telegraph_strength)
	if not shrinking:
		alpha = minf(alpha, 0.18)
		emission_energy = minf(emission_energy, 0.42)
	for material in _pressure_band_materials:
		if material == null:
			continue

		var next_color := material.albedo_color
		next_color.a = alpha
		material.albedo_color = next_color
		material.emission_energy_multiplier = emission_energy


func _update_opening_telegraph(current_size: Vector2) -> void:
	if _opening_telegraph_root == null:
		return

	var should_show := _opening_telegraph_active and _opening_lane_rows.size() >= 2
	_opening_telegraph_root.visible = should_show
	for lane_mesh in _opening_lane_meshes:
		if lane_mesh != null:
			lane_mesh.visible = should_show

	if not should_show:
		return

	var lane_length := maxf(current_size.x * opening_lane_length_ratio, opening_lane_thickness)
	var max_depth := current_size.y * 0.5 - opening_lane_row_padding
	for index in range(mini(_opening_lane_meshes.size(), _opening_lane_rows.size())):
		var lane_mesh := _opening_lane_meshes[index]
		if lane_mesh == null:
			continue
		var lane_row := clampf(_opening_lane_rows[index], -max_depth, max_depth)
		lane_mesh.transform = Transform3D(
			Basis().scaled(Vector3(lane_length, 1.0, opening_lane_thickness)),
			Vector3(0.0, 0.26, lane_row)
		)

	var lane_separation := absf(_opening_lane_rows[1] - _opening_lane_rows[0])
	var lane_strength := clampf(remap(lane_separation, 1.4, 4.0, 0.35, 1.0), 0.35, 1.0)
	var alpha := lerpf(0.1, 0.22, lane_strength)
	var emission_energy := lerpf(0.24, 0.58, lane_strength)
	for material in _opening_lane_materials:
		if material == null:
			continue
		var next_color := material.albedo_color
		next_color.a = alpha
		material.albedo_color = next_color
		material.emission_energy_multiplier = emission_energy


func _get_pressure_telegraph_strength(current_size: Vector2) -> float:
	var width_ratio := current_size.x / maxf(safe_play_area_size.x, 0.01)
	var depth_ratio := current_size.y / maxf(safe_play_area_size.y, 0.01)
	return clampf(1.0 - minf(width_ratio, depth_ratio), 0.0, 1.0)


func _update_cover_block_positions(current_size: Vector2) -> void:
	if _cover_block_nodes.is_empty():
		return

	var width_ratio := current_size.x / maxf(safe_play_area_size.x, 0.01)
	var depth_ratio := current_size.y / maxf(safe_play_area_size.y, 0.01)
	for cover_block in _cover_block_nodes:
		if not is_instance_valid(cover_block):
			continue

		var original_position: Variant = _cover_block_original_positions.get(cover_block.get_instance_id(), cover_block.position)
		if not (original_position is Vector3):
			continue

		var position := original_position as Vector3
		cover_block.position = Vector3(position.x * width_ratio, position.y, position.z * depth_ratio)


func _update_edge_pickup_positions(current_size: Vector2) -> void:
	if _edge_pickup_nodes.is_empty():
		return

	var width_ratio := current_size.x / maxf(safe_play_area_size.x, 0.01)
	var depth_ratio := current_size.y / maxf(safe_play_area_size.y, 0.01)
	for pickup in _edge_pickup_nodes:
		if not is_instance_valid(pickup):
			continue

		var original_position: Variant = _edge_pickup_original_local_positions.get(pickup.get_instance_id(), to_local(pickup.global_position))
		if not (original_position is Vector3):
			continue

		var local_position := original_position as Vector3
		var scaled_local_position := Vector3(local_position.x * width_ratio, local_position.y, local_position.z * depth_ratio)
		pickup.global_position = to_global(scaled_local_position)


func _update_support_lane_node_positions(current_size: Vector2) -> void:
	if _support_lane_nodes.is_empty():
		return

	var width_ratio := current_size.x / maxf(safe_play_area_size.x, 0.01)
	var depth_ratio := current_size.y / maxf(safe_play_area_size.y, 0.01)
	for lane_node in _support_lane_nodes:
		if not is_instance_valid(lane_node):
			continue

		var original_position: Variant = _support_lane_original_local_positions.get(lane_node.get_instance_id(), to_local(lane_node.global_position))
		if not (original_position is Vector3):
			continue

		var local_position := original_position as Vector3
		var scaled_local_position := Vector3(local_position.x * width_ratio, local_position.y, local_position.z * depth_ratio)
		lane_node.global_position = to_global(scaled_local_position)


func _get_support_lane_signed_distance(from_progress: float, to_progress: float) -> float:
	var perimeter := get_support_lane_perimeter_length()
	if perimeter <= 0.0:
		return 0.0

	var forward_distance := fposmod(to_progress - from_progress, perimeter)
	if forward_distance > perimeter * 0.5:
		return forward_distance - perimeter
	return forward_distance
