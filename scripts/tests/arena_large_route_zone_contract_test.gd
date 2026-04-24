extends SceneTree

const ArenaBase = preload("res://scripts/arenas/arena_base.gd")

const TEAM_SCENE := "res://scenes/main/main_teams_large.tscn"
const FFA_SCENE := "res://scenes/main/main_ffa_large.tscn"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _assert_teams_large_routes()
	await _assert_ffa_large_routes()
	_finish()


func _assert_teams_large_routes() -> void:
	var arena := await _load_arena(TEAM_SCENE)
	if arena == null:
		return
	var zones: Dictionary = arena.get_map_zone_local_planar_positions()
	_assert(zones.has("center_transition"), "Teams large debe marcar centro de transicion.")
	_assert(zones.has("west_rescue_route"), "Teams large debe marcar ruta lateral oeste de rescate.")
	_assert(zones.has("east_rescue_route"), "Teams large debe marcar ruta lateral este de rescate.")
	_assert(zones.has("north_edge_value"), "Teams large debe marcar borde norte valioso.")
	_assert(zones.has("south_edge_value"), "Teams large debe marcar borde sur valioso.")

	var center := zones["center_transition"] as Vector2
	_assert(absf(center.x) <= 1.0 and absf(center.y) <= 1.0, "El centro de transicion debe vivir cerca del centro real.")
	_assert(absf((zones["west_rescue_route"] as Vector2).x) >= 5.5, "La ruta oeste Teams debe ser lateral, no centro vacio.")
	_assert(absf((zones["east_rescue_route"] as Vector2).x) >= 5.5, "La ruta este Teams debe ser lateral, no centro vacio.")
	_assert(absf((zones["north_edge_value"] as Vector2).y) >= 7.0, "El valor norte Teams debe vivir cerca del borde.")
	_assert(absf((zones["south_edge_value"] as Vector2).y) >= 7.0, "El valor sur Teams debe vivir cerca del borde.")


func _assert_ffa_large_routes() -> void:
	var arena := await _load_arena(FFA_SCENE)
	if arena == null:
		return
	var zones: Dictionary = arena.get_map_zone_local_planar_positions()
	_assert(zones.has("center_transition"), "FFA large debe marcar centro de transicion.")
	_assert(zones.has("north_rotation"), "FFA large debe marcar rotacion norte.")
	_assert(zones.has("south_rotation"), "FFA large debe marcar rotacion sur.")
	_assert(zones.has("west_third_party_entry"), "FFA large debe marcar entrada third-party oeste.")
	_assert(zones.has("east_third_party_entry"), "FFA large debe marcar entrada third-party este.")

	var center := zones["center_transition"] as Vector2
	_assert(absf(center.x) <= 1.0 and absf(center.y) <= 1.0, "El centro FFA debe seguir siendo transicion.")
	_assert(absf((zones["north_rotation"] as Vector2).y) >= 5.0, "La rotacion norte FFA debe crear ruta util.")
	_assert(absf((zones["south_rotation"] as Vector2).y) >= 5.0, "La rotacion sur FFA debe crear ruta util.")
	_assert(absf((zones["west_third_party_entry"] as Vector2).x) >= 5.0, "La entrada oeste FFA debe facilitar third-party lateral.")
	_assert(absf((zones["east_third_party_entry"] as Vector2).x) >= 5.0, "La entrada este FFA debe facilitar third-party lateral.")


func _load_arena(scene_path: String) -> ArenaBase:
	var packed_scene := load(scene_path) as PackedScene
	_assert(packed_scene != null, "La escena debe existir: %s" % scene_path)
	if packed_scene == null:
		return null
	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var arena := _find_arena(main)
	_assert(arena != null, "La escena debe montar un ArenaBase: %s" % scene_path)
	root.remove_child(main)
	main.free()
	await process_frame
	return arena


func _find_arena(node: Node) -> ArenaBase:
	if node is ArenaBase:
		return node as ArenaBase
	for child in node.get_children():
		var found := _find_arena(child)
		if found != null:
			return found
	return null


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
