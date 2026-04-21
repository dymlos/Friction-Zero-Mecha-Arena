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

	var telegraph_root := arena.get_node_or_null("PressureTelegraph")
	_assert(
		telegraph_root is Node3D,
		"El arena blockout deberia exponer un root diegetico para telegraphar la contraccion."
	)
	if not (telegraph_root is Node3D):
		await _cleanup_arena(arena)
		_finish()
		return

	var band_names := ["NorthBand", "SouthBand", "WestBand", "EastBand"]
	var bands: Array[MeshInstance3D] = []
	for band_name in band_names:
		var band := telegraph_root.get_node_or_null(band_name)
		_assert(
			band is MeshInstance3D,
			"La advertencia de contraccion deberia cubrir los cuatro bordes del arena."
		)
		if band is MeshInstance3D:
			bands.append(band as MeshInstance3D)
			_assert(
				not (band as MeshInstance3D).visible,
				"El telegraph no deberia ensuciar la arena mientras el borde vivo siga en su tamano completo."
			)

	arena.set_play_area_scale(0.65)
	await process_frame

	var shrunk_half_size := arena.get_safe_play_area_size() * 0.5
	for band in bands:
		_assert(
			band.visible,
			"La advertencia diegetica deberia hacerse visible cuando la arena entra en contraccion."
		)
		var local_position := arena.to_local(band.global_position)
		if absf(local_position.x) > absf(local_position.z):
			_assert(
				absf(local_position.x) >= shrunk_half_size.x * 0.7,
				"Las bandas laterales deberian seguir pegadas al borde vivo durante la contraccion."
			)
		else:
			_assert(
				absf(local_position.z) >= shrunk_half_size.y * 0.7,
				"Las bandas frontal/trasera deberian seguir pegadas al borde vivo durante la contraccion."
			)

	arena.set_play_area_scale(1.0)
	await process_frame

	for band in bands:
		_assert(
			not band.visible,
			"Al restaurar el tamano completo del arena, el telegraph de contraccion deberia apagarse."
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
