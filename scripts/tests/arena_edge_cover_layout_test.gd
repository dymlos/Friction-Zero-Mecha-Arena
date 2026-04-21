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

	var cover_root := arena.get_node_or_null("CoverBlocks")
	_assert(cover_root is Node3D, "El arena blockout deberia exponer un root de coberturas simple.")
	if not (cover_root is Node3D):
		await _cleanup_arena(arena)
		_finish()
		return

	var cover_blocks: Array[Node3D] = []
	for child in cover_root.get_children():
		if child is Node3D:
			cover_blocks.append(child as Node3D)

	_assert(cover_blocks.size() >= 2, "Los incentivos de borde deberian tener al menos dos coberturas blockout.")
	if cover_blocks.size() < 2:
		await _cleanup_arena(arena)
		_finish()
		return

	var initial_half_size := arena.get_safe_play_area_size() * 0.5
	var initial_abs_x: Array[float] = []
	for cover_block in cover_blocks:
		var local_position := arena.to_local(cover_block.global_position)
		initial_abs_x.append(absf(local_position.x))
		_assert(
			absf(local_position.x) >= initial_half_size.x * 0.45,
			"Las coberturas nuevas deberian vivir cerca del riesgo de borde y no tapar el centro limpio."
		)

	arena.set_play_area_scale(0.5)
	await process_frame

	var shrunk_half_size := arena.get_safe_play_area_size() * 0.5
	for index in range(cover_blocks.size()):
		var local_position := arena.to_local(cover_blocks[index].global_position)
		_assert(
			absf(local_position.x) < initial_abs_x[index],
			"Las coberturas de borde deberian acompañar la contraccion del arena y moverse hacia adentro."
		)
		_assert(
			absf(local_position.x) >= shrunk_half_size.x * 0.45,
			"Al contraerse el arena, la cobertura deberia seguir cerca del nuevo borde util."
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
