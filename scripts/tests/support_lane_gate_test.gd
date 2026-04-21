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

	var gates := get_nodes_in_group("support_lane_gates")
	_assert(
		gates.size() >= 2,
		"El carril externo deberia exponer varios obstaculos discretos para la nave de apoyo."
	)
	_assert(
		arena.has_method("get_support_lane_blocking_gate_progress"),
		"El arena deberia poder resolver si un gate bloquea un tramo del carril externo."
	)
	if gates.size() < 2 or not arena.has_method("get_support_lane_blocking_gate_progress"):
		await _cleanup_arena(arena)
		_finish()
		return

	var gate := gates[0]
	_assert(
		gate.has_method("set_support_active"),
		"Cada gate del carril deberia poder activarse solo cuando exista soporte post-muerte."
	)
	_assert(
		gate.has_method("set_forced_blocking_state"),
		"Los gates del carril deberian poder forzar su estado para validacion headless."
	)
	if gate.has_method("set_support_active"):
		gate.call("set_support_active", true)
	if gate.has_method("set_forced_blocking_state"):
		gate.call("set_forced_blocking_state", true)

	var gate_position := (gate as Node3D).global_position
	var gate_progress := float(arena.call("get_support_lane_progress_near", gate_position))
	var approach_progress := float(arena.call("advance_support_lane_progress", gate_progress, -2.2))
	var blocking_progress := float(arena.call("get_support_lane_blocking_gate_progress", approach_progress, 4.4))
	_assert(
		absf(blocking_progress - gate_progress) < 0.35,
		"Recorrer un tramo que cruza un gate cerrado deberia devolver el progreso del bloqueo."
	)

	if gate.has_method("set_forced_blocking_state"):
		gate.call("set_forced_blocking_state", false)

	var clear_progress := float(arena.call("get_support_lane_blocking_gate_progress", approach_progress, 4.4))
	_assert(
		clear_progress < 0.0,
		"Si el gate esta abierto, el mismo tramo del carril no deberia marcar bloqueo."
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
