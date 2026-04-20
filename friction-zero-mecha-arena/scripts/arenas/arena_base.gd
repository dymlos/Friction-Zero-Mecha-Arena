extends Node3D
class_name ArenaBase

@export var arena_id := "blockout_arena"
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
	return Vector2(24.0, 16.0)
