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

	_assert(arena.has_method("get_diegetic_pressure_snapshot"), "ArenaBase debe exponer snapshot diegetico de presion M6.")
	if not arena.has_method("get_diegetic_pressure_snapshot"):
		await _cleanup_arena(arena)
		_finish()
		return

	arena.set_pressure_warning_strength(0.62)
	await process_frame

	var warning_snapshot: Dictionary = arena.call("get_diegetic_pressure_snapshot")
	_assert(bool(warning_snapshot.get("warning_visible", false)), "La presion final debe tener warning visible en arena antes de cerrar espacio.")
	_assert(int(warning_snapshot.get("visible_band_count", 0)) == 4, "La advertencia de presion debe cubrir cuatro bordes.")
	_assert(float(warning_snapshot.get("warning_strength", 0.0)) >= 0.6, "El snapshot debe conservar intensidad de warning.")
	_assert(bool(warning_snapshot.get("hud_is_secondary", false)), "La presion final se lee primero en arena, no en texto HUD.")

	arena.set_play_area_scale(0.68)
	await process_frame

	var shrink_snapshot: Dictionary = arena.call("get_diegetic_pressure_snapshot")
	_assert(bool(shrink_snapshot.get("contraction_visible", false)), "La contraccion debe mantener telegraph diegetico visible.")
	_assert(float(shrink_snapshot.get("play_area_scale", 1.0)) < 1.0, "El snapshot debe reportar escala actual del area jugable.")

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
