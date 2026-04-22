extends SceneTree

const VALIDATION_SCENE := "res://scenes/qa/match_hud_overlay_validation.tscn"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _apply_viewport(Vector2i(1280, 720))
	var main := await _instantiate_scene(VALIDATION_SCENE)
	var status_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/StatusLabel") as Label
	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var roster_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RosterLabel") as Label
	_assert(status_label != null, "La escena de validacion HUD deberia exponer StatusLabel.")
	_assert(round_label != null, "La escena de validacion HUD deberia exponer RoundLabel.")
	_assert(roster_label != null, "La escena de validacion HUD deberia exponer RosterLabel.")
	if status_label == null or round_label == null or roster_label == null:
		await _cleanup_main(main)
		_finish()
		return

	var viewport_rect := get_root().get_visible_rect()
	_assert(
		_is_rect_inside_viewport(status_label.get_global_rect(), viewport_rect),
		"StatusLabel deberia quedar completamente dentro del viewport en el stress HUD."
	)
	_assert(
		_is_rect_inside_viewport(round_label.get_global_rect(), viewport_rect),
		"RoundLabel deberia quedar completamente dentro del viewport en el stress HUD."
	)
	_assert(
		_is_rect_inside_viewport(roster_label.get_global_rect(), viewport_rect),
		"RosterLabel deberia quedar completamente dentro del viewport en el stress HUD."
	)
	_assert(
		not status_label.get_global_rect().intersects(round_label.get_global_rect()),
		"StatusLabel y RoundLabel no deberian superponerse en el stress HUD."
	)
	_assert(
		not round_label.get_global_rect().intersects(roster_label.get_global_rect()),
		"RoundLabel y RosterLabel no deberian superponerse en el stress HUD."
	)

	await _cleanup_main(main)
	_finish()


func _apply_viewport(size: Vector2i) -> void:
	var root_window := get_root()
	if root_window.has_method("set_size_2d_override"):
		root_window.call("set_size_2d_override", size)
	if root_window.has_method("set_size_2d_override_stretch"):
		root_window.call("set_size_2d_override_stretch", true)
	root_window.min_size = size
	root_window.size = size
	root_window.content_scale_size = size
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia existir." % scene_path)
	if not (packed_scene is PackedScene):
		return Node.new()

	var main := (packed_scene as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	return main


func _is_rect_inside_viewport(rect: Rect2, viewport_rect: Rect2) -> bool:
	return (
		rect.position.x >= viewport_rect.position.x
		and rect.position.y >= viewport_rect.position.y
		and rect.end.x <= viewport_rect.end.x
		and rect.end.y <= viewport_rect.end.y
	)


func _cleanup_main(main: Node) -> void:
	if not is_instance_valid(main):
		return

	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
