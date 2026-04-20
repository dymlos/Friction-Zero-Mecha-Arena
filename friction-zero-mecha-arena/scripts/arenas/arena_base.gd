extends Node3D
class_name ArenaBase

@export var arena_id := "blockout_arena"
@export var safe_play_area_size := Vector2(24.0, 16.0)
@export var lethal_edge_margin := 2.0


func get_spawn_points() -> Array[Marker3D]:
	# Los puntos de spawn estan como hijos para que puedan moverse desde el editor.
	var points: Array[Marker3D] = []
	for child in get_children():
		if child is Marker3D:
			points.append(child)

	return points


func get_safe_play_area_size() -> Vector2:
	# Valor simple para prototipos. Mas adelante puede salir de un recurso de datos.
	return safe_play_area_size


func is_position_inside_play_area(world_position: Vector3) -> bool:
	var local_position := to_local(world_position)
	var half_size := safe_play_area_size * 0.5
	return absf(local_position.x) <= half_size.x and absf(local_position.z) <= half_size.y
