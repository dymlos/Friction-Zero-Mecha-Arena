extends SceneTree

const ARENA_SCENE := preload("res://scenes/arenas/arena_blockout.tscn")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arena := ARENA_SCENE.instantiate() as ArenaBase
	root.add_child(arena)

	await process_frame
	await physics_frame

	_assert(
		arena.has_method("get_support_lane_progress_near"),
		"El arena deberia exponer un progreso continuo para el carril de apoyo."
	)
	_assert(
		arena.has_method("get_support_lane_position_from_progress"),
		"El carril de apoyo deberia poder reconstruir una posicion desde ese progreso."
	)
	_assert(
		arena.has_method("advance_support_lane_progress"),
		"El carril de apoyo deberia poder avanzar sobre una ruta continua."
	)
	if not arena.has_method("get_support_lane_progress_near") \
	or not arena.has_method("get_support_lane_position_from_progress") \
	or not arena.has_method("advance_support_lane_progress"):
		await _cleanup_arena(arena)
		_finish()
		return

	var top_progress := float(arena.call("get_support_lane_progress_near", Vector3(0.0, 0.0, -20.0)))
	var top_position := arena.call("get_support_lane_position_from_progress", top_progress) as Vector3
	var top_advanced_progress := float(arena.call("advance_support_lane_progress", top_progress, 4.0))
	var top_advanced_position := arena.call("get_support_lane_position_from_progress", top_advanced_progress) as Vector3

	_assert(
		top_advanced_position.x > top_position.x + 0.5,
		"Avanzar por el tramo norte deberia mover la nave lateralmente por el borde superior."
	)
	_assert(
		absf(top_advanced_position.z - top_position.z) < 0.05,
		"Avanzar por el tramo norte no deberia sacar la nave del carril superior."
	)

	var half_size := arena.get_safe_play_area_size() * 0.5
	var corner_seed := Vector3(
		half_size.x + arena.support_lane_margin,
		0.0,
		-half_size.y - arena.support_lane_margin
	)
	var corner_progress := float(arena.call("get_support_lane_progress_near", corner_seed))
	var corner_position := arena.call("get_support_lane_position_from_progress", corner_progress) as Vector3
	var wrapped_progress := float(arena.call("advance_support_lane_progress", corner_progress, 5.0))
	var wrapped_position := arena.call("get_support_lane_position_from_progress", wrapped_progress) as Vector3

	_assert(
		wrapped_position.z > corner_position.z + 0.5,
		"Al pasar una esquina, el carril deberia continuar por el siguiente lateral en vez de re-snapear."
	)
	_assert(
		absf(wrapped_position.x - (half_size.x + arena.support_lane_margin)) < 0.05,
		"Al girar sobre la esquina noreste, la nave deberia quedar pegada al lateral este."
	)

	await _cleanup_arena(arena)
	_finish()


func _cleanup_arena(arena: ArenaBase) -> void:
	if not is_instance_valid(arena):
		return

	var parent := arena.get_parent()
	if parent != null:
		parent.remove_child(arena)
	arena.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
