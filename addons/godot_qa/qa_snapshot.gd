extends RefCounted

const FOCUS_MODE_NAMES := {
	Control.FOCUS_NONE: "none",
	Control.FOCUS_CLICK: "click",
	Control.FOCUS_ALL: "all",
	3: "accessibility",
}
const HEADLESS_FALLBACK_PNG_BASE64 := "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg=="
const MOUSE_FILTER_NAMES := {
	Control.MOUSE_FILTER_STOP: "stop",
	Control.MOUSE_FILTER_PASS: "pass",
	Control.MOUSE_FILTER_IGNORE: "ignore",
}
const FOCUS_NEIGHBOR_SIDES := {
	"left": SIDE_LEFT,
	"top": SIDE_TOP,
	"right": SIDE_RIGHT,
	"bottom": SIDE_BOTTOM,
}

static func node_to_dict(node: Node) -> Dictionary:
	var result := {
		"path": str(node.get_path()),
		"name": str(node.name),
		"type": node.get_class(),
		"qa_id": str(node.get_meta("qa_id", "")),
		"groups": _groups_to_array(node.get_groups()),
		"inside_tree": node.is_inside_tree(),
		"child_count": node.get_child_count(),
	}
	if node is CanvasItem:
		result["visible"] = (node as CanvasItem).is_visible_in_tree()
	else:
		result["visible"] = true
	return result

static func node_summary_to_dict(node: Node, locator := "") -> Dictionary:
	var result := {
		"path": str(node.get_path()),
		"name": str(node.name),
		"type": node.get_class(),
		"qa_id": str(node.get_meta("qa_id", "")),
	}
	if locator != "":
		result["locator"] = locator
	return result

static func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false

static func _groups_to_array(groups: Array) -> Array[String]:
	var normalized: Array[String] = []
	for group_name in groups:
		var group_string := str(group_name)
		if group_string.begins_with("_"):
			continue
		normalized.append(group_string)
	normalized.sort()
	return normalized

static func _vector2_to_array(value: Vector2) -> Array[float]:
	return [float(value.x), float(value.y)]

static func _rect2_to_array(value: Rect2) -> Array[float]:
	var position := _vector2_to_array(value.position)
	var size := _vector2_to_array(value.size)
	return [position[0], position[1], size[0], size[1]]

static func node_tree_to_dict(root: Node) -> Dictionary:
	return {
		"root": _node_tree_entry(root),
	}

static func visible_controls(root: Node) -> Array[Control]:
	var controls: Array[Control] = []
	_collect_visible_controls(root, controls)
	return controls

static func all_controls(root: Node) -> Array[Control]:
	var controls: Array[Control] = []
	_collect_all_controls(root, controls)
	return controls

static func control_to_dict(control: Control) -> Dictionary:
	var result := node_to_dict(control)
	if _has_property(control, "disabled"):
		result["disabled"] = bool(control.get("disabled"))
	if _has_property(control, "text"):
		result["text"] = str(control.get("text"))
	result["global_rect"] = _rect2_to_array(control.get_global_rect())
	result["minimum_size"] = _vector2_to_array(control.get_combined_minimum_size())
	result["anchors"] = _anchors_to_array(control)
	result["offsets"] = _offsets_to_array(control)
	result["focus_mode"] = _focus_mode_to_string(control.focus_mode)
	result["has_focus"] = control.has_focus()
	result["mouse_filter"] = _mouse_filter_to_string(control.mouse_filter)
	if control.theme_type_variation != "":
		result["theme_type_variation"] = control.theme_type_variation
	return result

static func control_state_to_dict(control: Control) -> Dictionary:
	var result := control_to_dict(control)
	for key in ["path", "name", "type", "qa_id", "groups", "inside_tree", "child_count", "visible"]:
		result.erase(key)
	return result

static func visible_controls_to_dict(root: Node, controls: Array[Control] = []) -> Dictionary:
	var visible := controls
	if visible.is_empty():
		visible = visible_controls(root)
	var viewport_rect := root.get_viewport().get_visible_rect()
	var entries: Array[Dictionary] = []
	for control in visible:
		entries.append(control_to_dict(control))
	return {
		"viewport": _vector2_to_array(viewport_rect.size),
		"controls": entries,
	}

static func all_controls_to_dict(root: Node, controls: Array[Control] = []) -> Dictionary:
	var all := controls
	if all.is_empty():
		all = all_controls(root)
	var viewport_rect := root.get_viewport().get_visible_rect()
	var entries: Array[Dictionary] = []
	for control in all:
		entries.append(control_to_dict(control))
	return {
		"viewport": _vector2_to_array(viewport_rect.size),
		"controls": entries,
	}

static func focus_to_dict(root_window: Window, controls: Array[Control]) -> Dictionary:
	var focus_owner := root_window.gui_get_focus_owner()
	return {
		"focus_owner": _describe_control_target(focus_owner),
		"focus_owner_path": str(focus_owner.get_path()) if focus_owner != null else "",
		"graph": focus_graph_to_dict(controls),
	}

static func focus_graph_to_dict(controls: Array[Control]) -> Array[Dictionary]:
	var visible_lookup := {}
	for control in controls:
		visible_lookup[control.get_instance_id()] = control

	var graph: Array[Dictionary] = []
	for control in controls:
		if int(control.focus_mode) == Control.FOCUS_NONE:
			continue
		var neighbors := _focus_neighbors_to_dict(control, visible_lookup)
		if neighbors.is_empty():
			continue
		graph.append({
			"target": _describe_control_target(control),
			"path": str(control.get_path()),
			"neighbors": neighbors,
		})
	return graph

static func errors_to_dict(runtime_errors: Array) -> Dictionary:
	var errors: Array[Dictionary] = []
	for entry in runtime_errors:
		if entry is Dictionary:
			errors.append((entry as Dictionary).duplicate(true))
	return {
		"count": errors.size(),
		"errors": errors,
	}

static func save_viewport_screenshot(viewport: Viewport, path: String) -> int:
	var image := viewport.get_texture().get_image()
	if image == null:
		return _write_fallback_screenshot(viewport, path)
	if image.get_width() <= 0 or image.get_height() <= 0:
		return _write_fallback_screenshot(viewport, path)
	var png_image := Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	png_image.blit_rect(
		image,
		Rect2i(0, 0, image.get_width(), image.get_height()),
		Vector2i.ZERO,
	)
	var png_buffer := png_image.save_png_to_buffer()
	if png_buffer.is_empty():
		return _write_fallback_screenshot(viewport, path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_buffer(png_buffer)
	return OK

static func snapshot_paths(snapshot_dir: String) -> Dictionary:
	return {
		"root": snapshot_dir,
		"screenshot": "%s/screenshot.png" % snapshot_dir,
		"tree": "%s/tree.json" % snapshot_dir,
		"ui": "%s/ui.json" % snapshot_dir,
		"focus": "%s/focus.json" % snapshot_dir,
		"errors": "%s/errors.json" % snapshot_dir,
	}

static func capture_screenshot(root_window: Window, output_path: String) -> Dictionary:
	var screenshot_dir := output_path.get_base_dir()
	var dir_error := DirAccess.make_dir_recursive_absolute(screenshot_dir)
	if dir_error != OK:
		return {
			"ok": false,
			"failures": [
				{
					"type": "screenshot_write_failed",
					"message": "screenshot artifact directory could not be created",
					"expected": "writable screenshot artifact directory",
					"actual": screenshot_dir,
				},
			],
			"artifacts": {
				"screenshot": output_path,
			},
		}

	await root_window.get_tree().process_frame
	RenderingServer.force_draw(false)
	await root_window.get_tree().process_frame

	var screenshot_error := save_viewport_screenshot(root_window, output_path)
	if screenshot_error != OK:
		return {
			"ok": false,
			"failures": [
				{
					"type": "screenshot_write_failed",
					"message": "screenshot PNG could not be written",
					"expected": "writable screenshot artifact path",
					"actual": output_path,
				},
			],
			"artifacts": {
				"screenshot": output_path,
			},
		}

	return {
		"ok": true,
		"artifacts": {
			"screenshot": output_path,
		},
	}

static func capture_snapshot_bundle(
	scene_root: Node,
	root_window: Window,
	runtime_errors: Array,
	snapshot_dir: String,
) -> Dictionary:
	var paths := snapshot_paths(snapshot_dir)
	var dir_error := DirAccess.make_dir_recursive_absolute(snapshot_dir)
	if dir_error != OK:
		return {
			"ok": false,
			"failures": [
				{
					"type": "snapshot_write_failed",
					"message": "snapshot artifact directory could not be created",
					"target": "%s.root" % snapshot_dir.get_file(),
					"expected": "writable snapshot artifact directory",
					"actual": snapshot_dir,
				},
			],
			"artifacts": paths,
		}

	await root_window.get_tree().process_frame
	RenderingServer.force_draw(false)
	await root_window.get_tree().process_frame

	var visible := visible_controls(scene_root)
	var all := all_controls(scene_root)
	var failures: Array[Dictionary] = []
	for job in [
		{
			"key": "tree",
			"path": str(paths["tree"]),
			"payload": node_tree_to_dict(scene_root),
		},
		{
			"key": "ui",
			"path": str(paths["ui"]),
			"payload": all_controls_to_dict(scene_root, all),
		},
		{
			"key": "focus",
			"path": str(paths["focus"]),
			"payload": focus_to_dict(root_window, visible),
		},
		{
			"key": "errors",
			"path": str(paths["errors"]),
			"payload": errors_to_dict(runtime_errors),
		},
	]:
		var save_error := _write_json_file(str(job["path"]), job["payload"])
		if save_error != OK:
			failures.append(
				{
					"type": "snapshot_write_failed",
					"message": "snapshot artifact could not be written",
					"target": "%s.%s" % [snapshot_dir.get_file(), str(job["key"])],
					"expected": "writable snapshot artifact file",
					"actual": str(job["path"]),
				}
			)

	var screenshot_error := save_viewport_screenshot(root_window, str(paths["screenshot"]))
	if screenshot_error != OK:
		failures.append(
			{
				"type": "screenshot_capture_failed",
				"message": "screenshot artifact could not be written",
				"target": "%s.screenshot" % snapshot_dir.get_file(),
				"expected": "PNG screenshot written to the snapshot directory",
				"actual": screenshot_error,
			}
		)

	return {
		"ok": failures.is_empty(),
		"artifacts": paths,
		"failures": failures,
	}

static func _write_fallback_screenshot(viewport: Viewport, path: String) -> int:
	var fallback_size := viewport.get_visible_rect().size
	var fallback_image := Image.create(
		max(int(fallback_size.x), 1),
		max(int(fallback_size.y), 1),
		false,
		Image.FORMAT_RGBA8,
	)
	fallback_image.fill(Color(0, 0, 0, 0))
	var png_buffer := fallback_image.save_png_to_buffer()
	if png_buffer.is_empty():
		png_buffer = Marshalls.base64_to_raw(HEADLESS_FALLBACK_PNG_BASE64)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_buffer(png_buffer)
	return OK

static func _write_json_file(path: String, payload: Dictionary) -> int:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_string(JSON.stringify(payload))
	return OK

static func _node_tree_entry(node: Node) -> Dictionary:
	var entry := {
		"path": str(node.get_path()),
		"name": str(node.name),
		"type": node.get_class(),
		"qa_id": str(node.get_meta("qa_id", "")),
		"visible": _node_visible(node),
		"children": [],
	}
	var children: Array[Dictionary] = []
	for child in node.get_children():
		var child_node := child as Node
		if child_node == null:
			continue
		children.append(_node_tree_entry(child_node))
	entry["children"] = children
	return entry

static func _node_visible(node: Node) -> bool:
	if node is CanvasItem:
		return (node as CanvasItem).is_visible_in_tree()
	return true

static func _collect_visible_controls(node: Node, controls: Array[Control]) -> void:
	if node is Control:
		var control := node as Control
		if control.is_visible_in_tree():
			controls.append(control)
	for child in node.get_children():
		var child_node := child as Node
		if child_node == null:
			continue
		_collect_visible_controls(child_node, controls)

static func _collect_all_controls(node: Node, controls: Array[Control]) -> void:
	if node is Control:
		controls.append(node as Control)
	for child in node.get_children():
		var child_node := child as Node
		if child_node == null:
			continue
		_collect_all_controls(child_node, controls)

static func _anchors_to_array(control: Control) -> Array[float]:
	return [
		float(control.get_anchor(SIDE_LEFT)),
		float(control.get_anchor(SIDE_TOP)),
		float(control.get_anchor(SIDE_RIGHT)),
		float(control.get_anchor(SIDE_BOTTOM)),
	]

static func _offsets_to_array(control: Control) -> Array[float]:
	return [
		float(control.get_offset(SIDE_LEFT)),
		float(control.get_offset(SIDE_TOP)),
		float(control.get_offset(SIDE_RIGHT)),
		float(control.get_offset(SIDE_BOTTOM)),
	]

static func _focus_mode_to_string(value: int) -> String:
	return str(FOCUS_MODE_NAMES.get(value, str(value)))

static func _mouse_filter_to_string(value: int) -> String:
	return str(MOUSE_FILTER_NAMES.get(value, str(value)))

static func _describe_control_target(control: Control) -> String:
	if control == null:
		return ""
	if control.has_meta("qa_id"):
		var qa_id := str(control.get_meta("qa_id"))
		if qa_id != "":
			return "qa:%s" % qa_id
	return "path:%s" % str(control.get_path())

static func _focus_neighbors_to_dict(control: Control, visible_lookup: Dictionary) -> Dictionary:
	var neighbors := {}
	for direction in FOCUS_NEIGHBOR_SIDES.keys():
		var side = int(FOCUS_NEIGHBOR_SIDES[direction])
		var neighbor_path := control.get_focus_neighbor(side)
		if neighbor_path == NodePath(""):
			continue
		var neighbor := control.get_node_or_null(neighbor_path) as Control
		if neighbor == null:
			continue
		if not visible_lookup.has(neighbor.get_instance_id()):
			continue
		neighbors[direction] = _describe_control_target(neighbor)
	return neighbors
