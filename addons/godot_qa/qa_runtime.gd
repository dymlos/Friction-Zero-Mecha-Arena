extends RefCounted

const QaAssertions = preload("res://addons/godot_qa/qa_assertions.gd")
const QaSnapshot = preload("res://addons/godot_qa/qa_snapshot.gd")

const SUPPORTED_KEYS := {
	"enter": {"name": "Enter", "keycode": KEY_ENTER},
	"return": {"name": "Enter", "keycode": KEY_ENTER},
	"escape": {"name": "Escape", "keycode": KEY_ESCAPE},
	"esc": {"name": "Escape", "keycode": KEY_ESCAPE},
	"space": {"name": "Space", "keycode": KEY_SPACE},
	"tab": {"name": "Tab", "keycode": KEY_TAB},
	"backspace": {"name": "Backspace", "keycode": KEY_BACKSPACE},
	"up": {"name": "Up", "keycode": KEY_UP},
	"arrowup": {"name": "Up", "keycode": KEY_UP},
	"down": {"name": "Down", "keycode": KEY_DOWN},
	"arrowdown": {"name": "Down", "keycode": KEY_DOWN},
	"left": {"name": "Left", "keycode": KEY_LEFT},
	"arrowleft": {"name": "Left", "keycode": KEY_LEFT},
	"right": {"name": "Right", "keycode": KEY_RIGHT},
	"arrowright": {"name": "Right", "keycode": KEY_RIGHT},
	"0": {"name": "0", "keycode": KEY_0},
	"1": {"name": "1", "keycode": KEY_1},
	"2": {"name": "2", "keycode": KEY_2},
	"3": {"name": "3", "keycode": KEY_3},
	"4": {"name": "4", "keycode": KEY_4},
	"5": {"name": "5", "keycode": KEY_5},
	"6": {"name": "6", "keycode": KEY_6},
	"7": {"name": "7", "keycode": KEY_7},
	"8": {"name": "8", "keycode": KEY_8},
	"9": {"name": "9", "keycode": KEY_9},
	"a": {"name": "A", "keycode": KEY_A},
	"b": {"name": "B", "keycode": KEY_B},
	"c": {"name": "C", "keycode": KEY_C},
	"d": {"name": "D", "keycode": KEY_D},
	"e": {"name": "E", "keycode": KEY_E},
	"f": {"name": "F", "keycode": KEY_F},
	"g": {"name": "G", "keycode": KEY_G},
	"h": {"name": "H", "keycode": KEY_H},
	"i": {"name": "I", "keycode": KEY_I},
	"j": {"name": "J", "keycode": KEY_J},
	"k": {"name": "K", "keycode": KEY_K},
	"l": {"name": "L", "keycode": KEY_L},
	"m": {"name": "M", "keycode": KEY_M},
	"n": {"name": "N", "keycode": KEY_N},
	"o": {"name": "O", "keycode": KEY_O},
	"p": {"name": "P", "keycode": KEY_P},
	"q": {"name": "Q", "keycode": KEY_Q},
	"r": {"name": "R", "keycode": KEY_R},
	"s": {"name": "S", "keycode": KEY_S},
	"t": {"name": "T", "keycode": KEY_T},
	"u": {"name": "U", "keycode": KEY_U},
	"v": {"name": "V", "keycode": KEY_V},
	"w": {"name": "W", "keycode": KEY_W},
	"x": {"name": "X", "keycode": KEY_X},
	"y": {"name": "Y", "keycode": KEY_Y},
	"z": {"name": "Z", "keycode": KEY_Z},
}

const SUPPORTED_JOY_BUTTONS := {
	"a": {"name": "a", "button_index": JOY_BUTTON_A},
	"b": {"name": "b", "button_index": JOY_BUTTON_B},
	"x": {"name": "x", "button_index": JOY_BUTTON_X},
	"y": {"name": "y", "button_index": JOY_BUTTON_Y},
	"back": {"name": "back", "button_index": JOY_BUTTON_BACK},
	"select": {"name": "back", "button_index": JOY_BUTTON_BACK},
	"guide": {"name": "guide", "button_index": JOY_BUTTON_GUIDE},
	"start": {"name": "start", "button_index": JOY_BUTTON_START},
	"menu": {"name": "start", "button_index": JOY_BUTTON_START},
	"left_shoulder": {"name": "left_shoulder", "button_index": JOY_BUTTON_LEFT_SHOULDER},
	"right_shoulder": {"name": "right_shoulder", "button_index": JOY_BUTTON_RIGHT_SHOULDER},
	"left_stick": {"name": "left_stick", "button_index": JOY_BUTTON_LEFT_STICK},
	"right_stick": {"name": "right_stick", "button_index": JOY_BUTTON_RIGHT_STICK},
	"dpad_up": {"name": "dpad_up", "button_index": JOY_BUTTON_DPAD_UP},
	"dpad_down": {"name": "dpad_down", "button_index": JOY_BUTTON_DPAD_DOWN},
	"dpad_left": {"name": "dpad_left", "button_index": JOY_BUTTON_DPAD_LEFT},
	"dpad_right": {"name": "dpad_right", "button_index": JOY_BUTTON_DPAD_RIGHT},
}

var _scene_root: Node = null
var _root_window: Window = null
var _runtime_errors: Array = []
var _held_actions: Dictionary = {}
var _assertions: RefCounted = null


func _init(scene_root: Node, root_window: Window, runtime_errors := [], held_actions := {}) -> void:
	_scene_root = scene_root
	_root_window = root_window
	_runtime_errors = runtime_errors if runtime_errors is Array else []
	_held_actions = held_actions if held_actions is Dictionary else {}
	_assertions = QaAssertions.new(self, _root_window, _runtime_errors)


func execute(command_name: String, params := {}) -> Dictionary:
	var command_params: Dictionary = params if params is Dictionary else {}
	if _scene_root == null or _root_window == null:
		return _error(
			"scene_unavailable",
			"QA runtime scene is not ready",
			{
				"command": command_name,
			},
		)

	match command_name:
		"tree.dump":
			return _ok(QaSnapshot.node_tree_to_dict(_scene_root))
		"ui.dump":
			return _ok(QaSnapshot.all_controls_to_dict(_scene_root))
		"focus.get":
			var visible_controls: Array[Control] = QaSnapshot.visible_controls(_scene_root)
			return _ok(QaSnapshot.focus_to_dict(_root_window, visible_controls))
		"focus.graph":
			var visible_controls: Array[Control] = QaSnapshot.visible_controls(_scene_root)
			return _ok(QaSnapshot.focus_to_dict(_root_window, visible_controls))
		"node.inspect":
			return _inspect_node(str(command_params.get("target", "")))
		"errors.read":
			return _ok(QaSnapshot.errors_to_dict(_runtime_errors))
		"input.tap_action":
			return await _tap_action(str(command_params.get("action", "")))
		"input.hold_action":
			return await _hold_action(str(command_params.get("action", "")), command_params.get("frames", 0))
		"input.release_action":
			return await _release_action(str(command_params.get("action", "")))
		"input.click_target":
			return await _click_target(str(command_params.get("target", "")))
		"input.mouse_click":
			return await _mouse_click(command_params.get("x", null), command_params.get("y", null))
		"input.key":
			return await _press_key(str(command_params.get("key", "")))
		"input.joy_button":
			return await _press_joy_button(str(command_params.get("button", "")))
		"assert.exists", "assert.not_exists", "assert.visible", "assert.hidden", "assert.enabled", "assert.disabled", "assert.focused", "assert.text_equals", "assert.text_contains", "assert.inside_viewport", "assert.no_overlap", "assert.no_errors":
			return _assertions.execute(command_name, command_params)

	return _error(
		"unsupported_command",
		"QA bridge command is not supported in this milestone",
		{
			"command": command_name,
			"params": command_params.duplicate(true),
		},
	)


func find_target_matches(target: String) -> Array:
	var matches: Array = []
	if target.begins_with("qa:"):
		_collect_by_qa_id(_scene_root, target.trim_prefix("qa:"), matches)
	elif target.begins_with("path:"):
		var node := _root_window.get_node_or_null(NodePath(target.trim_prefix("path:")))
		if node != null:
			matches.append(node)
	elif target.begins_with("name:"):
		_collect_by_name(_scene_root, target.trim_prefix("name:"), matches)
	return matches


func resolve_target(target: String) -> Dictionary:
	var matches: Array = find_target_matches(target)

	if matches.size() > 1:
		return {
			"ok": false,
			"error": _error_payload(
				"ambiguous_target",
				"Multiple nodes matched the requested target",
				{
					"target": target,
					"expected": "unique runtime node",
					"actual": describe_matches(matches),
				},
			),
		}
	if matches.is_empty():
		return {
			"ok": false,
			"error": _error_payload(
				"target_not_found",
				"No node matched the requested target",
				{
					"target": target,
					"expected": "existing runtime node",
					"actual": "missing",
				},
			),
		}
	return {
		"ok": true,
		"node": matches[0],
		"resolved": "path:%s" % str((matches[0] as Node).get_path()),
	}


func is_target_visible(node: Node) -> bool:
	if node is CanvasItem:
		return (node as CanvasItem).is_visible_in_tree()
	return false


func viewport_rect() -> Rect2:
	if _scene_root != null and _scene_root.get_viewport() != null:
		return _scene_root.get_viewport().get_visible_rect()
	if _root_window != null:
		return _root_window.get_visible_rect()
	return Rect2()


func ok(data := {}) -> Dictionary:
	return _ok(data)


func error(error_type: String, message: String, data := {}) -> Dictionary:
	return _error(error_type, message, data)


func process_frames(count: int) -> void:
	await _process_frames(count)


func describe_node(node: Variant) -> String:
	if node == null:
		return "none"
	if node is Node:
		var locator := stable_locator_for_node(node as Node)
		if locator != "":
			return locator
	return str(node)


func stable_locator_for_node(node: Node) -> String:
	if node == null:
		return ""
	if node.has_meta("qa_id"):
		var qa_id := str(node.get_meta("qa_id"))
		if qa_id != "":
			return "qa:%s" % qa_id
	var node_name := str(node.name)
	if node_name != "":
		var name_matches: Array = []
		_collect_by_name(_scene_root, node_name, name_matches)
		if name_matches.size() == 1 and name_matches[0] == node:
			return "name:%s" % node_name
	return "path:%s" % str(node.get_path())


func release_held_actions() -> Array[Dictionary]:
	var failures: Array[Dictionary] = []
	var held_actions: Array = _held_actions.keys()
	for action_name in held_actions:
		var result := await execute(
			"input.release_action",
			{
				"action": str(action_name),
			},
		)
		if not bool(result.get("ok", false)):
			failures.append((result.get("error", {}) as Dictionary).duplicate(true))
	return failures


func teardown() -> void:
	if _assertions != null and _assertions.has_method("teardown"):
		_assertions.call("teardown")
	_assertions = null
	_scene_root = null
	_root_window = null
	_runtime_errors = []
	_held_actions = {}


func _tap_action(action: String) -> Dictionary:
	if not InputMap.has_action(action):
		return _action_missing_error(action)

	_emit_action_event(action, true)
	await _process_frames(1)
	_emit_action_event(action, false)
	await _process_frames(1)
	return _ok({"action": action})


func _hold_action(action: String, frames: Variant) -> Dictionary:
	if not InputMap.has_action(action):
		return _action_missing_error(action)
	var frame_count = _coerce_frame_count(frames)
	if frame_count == null:
		return _error(
			"invalid_params",
			"input.hold_action requires a non-negative integer frame count",
			{
				"command": "input.hold_action",
				"expected": "non-negative integer frames",
				"actual": frames,
			},
		)

	_emit_action_event(action, true)
	_held_actions[action] = true
	await _process_frames(frame_count)
	return _ok(
		{
			"action": action,
			"frames": frame_count,
			"held": true,
		}
	)


func _release_action(action: String) -> Dictionary:
	if not _held_actions.has(action):
		return _error(
			"action_not_held",
			"input.release_action requires a currently held action",
			{
				"action": action,
				"expected": "held action tracked by the runtime",
				"actual": "not_held",
			},
		)

	_emit_action_event(action, false)
	_held_actions.erase(action)
	await _process_frames(1)
	return _ok(
		{
			"action": action,
			"held": false,
		}
	)


func _click_target(target: String) -> Dictionary:
	var resolution := resolve_target(target)
	if not bool(resolution.get("ok", false)):
		return {
			"ok": false,
			"error": (resolution.get("error", {}) as Dictionary).duplicate(true),
		}

	var target_node = resolution.get("node")
	if not target_node is Control:
		return _error(
			"target_not_clickable",
			"Resolved target is not a clickable Control",
			{
				"target": target,
				"resolved": resolution.get("resolved", ""),
				"actual": describe_node(target_node),
			},
		)

	var control := target_node as Control
	var rect := control.get_global_rect()
	if not control.is_visible_in_tree() or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return _error(
			"target_not_clickable",
			"Resolved target is not a visible Control with positive size",
			{
				"target": target,
				"resolved": resolution.get("resolved", ""),
				"actual": {
					"visible": control.is_visible_in_tree(),
					"global_rect": QaSnapshot.control_to_dict(control).get("global_rect", []),
				},
			},
		)

	var center := rect.position + (rect.size / 2.0)
	await _emit_left_click(center)
	return _ok(
		{
			"target": target,
			"resolved": resolution.get("resolved", ""),
		}
	)


func _inspect_node(target: String) -> Dictionary:
	var resolution := resolve_target(target)
	if not bool(resolution.get("ok", false)):
		return {
			"ok": false,
			"error": (resolution.get("error", {}) as Dictionary).duplicate(true),
		}

	var node := resolution.get("node") as Node
	var node_payload := QaSnapshot.node_to_dict(node)
	node_payload["locator"] = stable_locator_for_node(node)
	node_payload["script_path"] = _script_path_for_node(node)

	var parent := node.get_parent()
	if parent != null:
		node_payload["parent"] = QaSnapshot.node_summary_to_dict(parent, stable_locator_for_node(parent))
	else:
		node_payload["parent"] = {}

	var children: Array[Dictionary] = []
	for child in node.get_children():
		var child_node := child as Node
		if child_node == null:
			continue
		children.append(QaSnapshot.node_summary_to_dict(child_node, stable_locator_for_node(child_node)))
	node_payload["children"] = children

	if node is Control:
		node_payload["control"] = QaSnapshot.control_state_to_dict(node as Control)

	return _ok(
		{
			"target": target,
			"resolved": resolution.get("resolved", ""),
			"node": node_payload,
		}
	)


func _script_path_for_node(node: Node) -> String:
	var script = node.get_script()
	if script == null or not script is Script:
		return ""
	return str((script as Script).resource_path)


func _mouse_click(raw_x: Variant, raw_y: Variant) -> Dictionary:
	var x := _coerce_coordinate(raw_x)
	var y := _coerce_coordinate(raw_y)
	if x == null or y == null:
		return _error(
			"invalid_params",
			"input.mouse_click requires integer viewport coordinates",
			{
				"command": "input.mouse_click",
				"expected": "integer --x and --y viewport coordinates",
				"actual": {
					"x": raw_x,
					"y": raw_y,
				},
			},
		)
	var position := Vector2(float(x), float(y))
	var visible_rect := viewport_rect()
	if visible_rect.size.x <= 0.0 or visible_rect.size.y <= 0.0 or not visible_rect.has_point(position):
		return _error(
			"invalid_params",
			"input.mouse_click requires coordinates inside the visible viewport",
			{
				"command": "input.mouse_click",
				"expected": _rect_to_array(visible_rect),
				"actual": {
					"x": x,
					"y": y,
				},
			},
		)

	var hovered := _hovered_control_at_position(position)
	await _emit_left_click(position)
	var data := {
		"device": "mouse",
		"button": "left",
		"position": {
			"x": x,
			"y": y,
		},
	}
	if hovered != null:
		data["target"] = stable_locator_for_node(hovered)
		data["resolved"] = "path:%s" % str(hovered.get_path())
	return _ok(data)


func _press_key(raw_key: String) -> Dictionary:
	var normalized := _normalize_key(raw_key)
	if normalized.is_empty():
		return _error(
			"invalid_params",
			"input.key requires a supported named key",
			{
				"command": "input.key",
				"expected": _supported_key_names(),
				"actual": raw_key,
			},
		)

	var key_name := str(normalized.get("name", ""))
	var keycode := int(normalized.get("keycode", 0))
	_emit_key_event(keycode, true)
	await _process_frames(1)
	_emit_key_event(keycode, false)
	await _process_frames(1)
	var data := {
		"device": "keyboard",
		"key": key_name,
	}
	_append_focus_owner(data)
	return _ok(data)


func _press_joy_button(raw_button: String) -> Dictionary:
	var normalized := _normalize_joy_button(raw_button)
	if normalized.is_empty():
		return _error(
			"invalid_params",
			"input.joy_button requires a supported named joypad button",
			{
				"command": "input.joy_button",
				"expected": _supported_joy_button_names(),
				"actual": raw_button,
			},
		)

	var button_name := str(normalized.get("name", ""))
	var button_index := int(normalized.get("button_index", -1))
	_emit_joy_button_event(0, button_index, true)
	await _process_frames(1)
	_emit_joy_button_event(0, button_index, false)
	await _process_frames(1)
	var data := {
		"device": "joypad",
		"device_id": 0,
		"button": button_name,
	}
	_append_focus_owner(data)
	return _ok(data)


func _emit_action_event(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _emit_mouse_button_event(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)


func _emit_mouse_motion_event(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	Input.parse_input_event(event)


func _emit_key_event(keycode: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = false
	Input.parse_input_event(event)


func _emit_joy_button_event(device: int, button_index: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button_index
	event.pressed = pressed
	event.pressure = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _process_frames(count: int) -> void:
	for _i in range(max(count, 0)):
		await _root_window.get_tree().process_frame


func _emit_left_click(position: Vector2) -> void:
	_emit_mouse_motion_event(position)
	await _process_frames(1)
	_emit_mouse_button_event(position, true)
	await _process_frames(1)
	_emit_mouse_button_event(position, false)
	await _process_frames(1)


func _hovered_control_at_position(position: Vector2) -> Control:
	var visible_controls: Array[Control] = QaSnapshot.visible_controls(_scene_root)
	var best_control: Control = null
	var best_area := INF
	var best_depth := -1
	for control in visible_controls:
		if control == null:
			continue
		var rect := control.get_global_rect()
		if not rect.has_point(position):
			continue
		var area := rect.size.x * rect.size.y
		var depth := str(control.get_path()).count("/")
		if best_control == null or area < best_area or (is_equal_approx(area, best_area) and depth > best_depth):
			best_control = control
			best_area = area
			best_depth = depth
	if best_control != null:
		return best_control
	if _root_window != null and _root_window.has_method("gui_get_hovered_control"):
		var hovered = _root_window.gui_get_hovered_control()
		if hovered is Control:
			return hovered as Control
	return best_control


func _collect_by_qa_id(node: Node, qa_id: String, matches: Array) -> void:
	if node == null:
		return
	if node.has_meta("qa_id") and str(node.get_meta("qa_id")) == qa_id:
		matches.append(node)
	for group_name in ["qa.id.%s" % qa_id, "qa.%s" % qa_id]:
		if node.is_in_group(group_name) and not matches.has(node):
			matches.append(node)
	for child in node.get_children():
		var child_node := child as Node
		if child_node == null:
			continue
		_collect_by_qa_id(child_node, qa_id, matches)


func _collect_by_name(node: Node, target_name: String, matches: Array) -> void:
	if node == null:
		return
	if str(node.name) == target_name:
		matches.append(node)
	for child in node.get_children():
		var child_node := child as Node
		if child_node == null:
			continue
		_collect_by_name(child_node, target_name, matches)


func describe_matches(matches: Array) -> Array[String]:
	var described: Array[String] = []
	for match in matches:
		if match is Node:
			described.append("path:%s" % str((match as Node).get_path()))
		else:
			described.append(str(match))
	return described


func _coerce_frame_count(value: Variant) -> Variant:
	match typeof(value):
		TYPE_INT:
			return null if int(value) < 0 else int(value)
		TYPE_FLOAT:
			var number := float(value)
			if number < 0.0 or floor(number) != number:
				return null
			return int(number)
	return null


func _coerce_coordinate(value: Variant) -> Variant:
	match typeof(value):
		TYPE_INT:
			return int(value)
		TYPE_FLOAT:
			var numeric_value := float(value)
			if floor(numeric_value) != numeric_value:
				return null
			return int(numeric_value)
	return null


func _rect_to_array(value: Rect2) -> Array[float]:
	return [value.position.x, value.position.y, value.size.x, value.size.y]


func _normalize_key(raw_key: String) -> Dictionary:
	var key_name := raw_key.strip_edges().to_lower()
	if key_name == "":
		return {}
	return (SUPPORTED_KEYS.get(key_name, {}) as Dictionary).duplicate(true)


func _normalize_joy_button(raw_button: String) -> Dictionary:
	var button_name := raw_button.strip_edges().to_lower()
	if button_name == "":
		return {}
	return (SUPPORTED_JOY_BUTTONS.get(button_name, {}) as Dictionary).duplicate(true)


func _supported_key_names() -> Array[String]:
	var canonical_names: Array[String] = []
	var seen := {}
	for entry in SUPPORTED_KEYS.values():
		if not entry is Dictionary:
			continue
		var name := str((entry as Dictionary).get("name", ""))
		if name == "" or seen.has(name):
			continue
		seen[name] = true
		canonical_names.append(name)
	canonical_names.sort()
	return canonical_names


func _supported_joy_button_names() -> Array[String]:
	var canonical_names: Array[String] = []
	var seen := {}
	for entry in SUPPORTED_JOY_BUTTONS.values():
		if not entry is Dictionary:
			continue
		var name := str((entry as Dictionary).get("name", ""))
		if name == "" or seen.has(name):
			continue
		seen[name] = true
		canonical_names.append(name)
	canonical_names.sort()
	return canonical_names


func _append_focus_owner(data: Dictionary) -> void:
	if _root_window == null:
		return
	var focus_owner = _root_window.gui_get_focus_owner()
	if focus_owner == null:
		return
	data["focus_owner"] = stable_locator_for_node(focus_owner)
	data["focus_owner_path"] = str(focus_owner.get_path())


func _action_missing_error(action: String) -> Dictionary:
	return _error(
		"input_action_missing",
		"Input action is not defined in InputMap",
		{
			"action": action,
			"expected": "defined InputMap action",
			"actual": "missing",
		},
	)


func _ok(data := {}) -> Dictionary:
	return {
		"ok": true,
		"data": data if data is Dictionary else {},
	}


func _error(error_type: String, message: String, data := {}) -> Dictionary:
	return {
		"ok": false,
		"error": _error_payload(error_type, message, data),
	}


func _error_payload(error_type: String, message: String, data := {}) -> Dictionary:
	return {
		"type": error_type,
		"message": message,
		"data": data if data is Dictionary else {},
	}
