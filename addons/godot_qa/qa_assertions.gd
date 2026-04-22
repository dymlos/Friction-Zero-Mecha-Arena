extends RefCounted

var _runtime: RefCounted = null
var _root_window: Window = null
var _runtime_errors: Array = []


func _init(runtime: RefCounted, root_window: Window, runtime_errors := []) -> void:
	_runtime = runtime
	_root_window = root_window
	_runtime_errors = runtime_errors if runtime_errors is Array else []


func execute(command_name: String, params := {}) -> Dictionary:
	var command_params: Dictionary = params if params is Dictionary else {}
	match command_name:
		"assert.exists":
			return _assert_exists(str(command_params.get("target", "")))
		"assert.not_exists":
			return _assert_not_exists(str(command_params.get("target", "")))
		"assert.visible":
			return _assert_visible(str(command_params.get("target", "")))
		"assert.hidden":
			return _assert_hidden(str(command_params.get("target", "")))
		"assert.enabled":
			return _assert_enabled(str(command_params.get("target", "")))
		"assert.disabled":
			return _assert_disabled(str(command_params.get("target", "")))
		"assert.focused":
			return _assert_focused(str(command_params.get("target", "")))
		"assert.text_equals":
			return _assert_text_equals(
				str(command_params.get("target", "")),
				str(command_params.get("expected", "")),
			)
		"assert.text_contains":
			return _assert_text_contains(
				str(command_params.get("target", "")),
				str(command_params.get("expected", "")),
			)
		"assert.inside_viewport":
			return _assert_inside_viewport(str(command_params.get("target", "")))
		"assert.no_overlap":
			return _assert_no_overlap(
				str(command_params.get("a", "")),
				str(command_params.get("b", "")),
			)
		"assert.no_errors":
			return _assert_no_errors()

	return _error(
		"unsupported_command",
		"QA bridge command is not supported in this milestone",
		{
			"command": command_name,
			"params": command_params.duplicate(true),
		},
	)


func _assert_exists(target: String) -> Dictionary:
	var resolution = _runtime.resolve_target(target)
	if not bool(resolution.get("ok", false)):
		return {
			"ok": false,
			"error": (resolution.get("error", {}) as Dictionary).duplicate(true),
		}
	return _success(target, resolution)


func _assert_not_exists(target: String) -> Dictionary:
	var matches: Array = _runtime.find_target_matches(target)
	if matches.size() > 1:
		return _ambiguous_target(target, matches)
	if matches.is_empty():
		return _ok({"target": target})
	return _error(
		"not_exists_mismatch",
		"target unexpectedly existed in the runtime",
		{
			"target": target,
			"expected": "missing",
			"actual": _runtime.describe_node(matches[0]),
		},
	)


func _assert_visible(target: String) -> Dictionary:
	var resolution = _require_target(target)
	if not resolution.get("ok", false):
		return resolution
	var node: Node = resolution.get("node")
	if _runtime.is_target_visible(node):
		return _success(target, resolution)
	return _error(
		"visible_mismatch",
		"target is not visible",
		{
			"target": target,
			"expected": true,
			"actual": false,
		},
	)


func _assert_hidden(target: String) -> Dictionary:
	var resolution = _require_target(target)
	if not resolution.get("ok", false):
		return resolution
	var node: Node = resolution.get("node")
	if not _runtime.is_target_visible(node):
		return _success(target, resolution)
	return _error(
		"hidden_mismatch",
		"target is not hidden",
		{
			"target": target,
			"expected": false,
			"actual": true,
		},
	)


func _assert_enabled(target: String) -> Dictionary:
	var control_resolution = _require_control(target)
	if not control_resolution.get("ok", false):
		return control_resolution
	var control: Control = control_resolution.get("control")
	var disabled := _control_disabled(control)
	if disabled == false:
		return _success(target, control_resolution)
	return _error(
		"enabled_mismatch",
		"target is not enabled",
		{
			"target": target,
			"expected": true,
			"actual": false if disabled == true else null,
		},
	)


func _assert_disabled(target: String) -> Dictionary:
	var control_resolution = _require_control(target)
	if not control_resolution.get("ok", false):
		return control_resolution
	var control: Control = control_resolution.get("control")
	var disabled := _control_disabled(control)
	if disabled == true:
		return _success(target, control_resolution)
	return _error(
		"disabled_mismatch",
		"target is not disabled",
		{
			"target": target,
			"expected": true,
			"actual": disabled,
		},
	)


func _assert_focused(target: String) -> Dictionary:
	var resolution = _require_target(target)
	if not resolution.get("ok", false):
		return resolution
	var focus_owner := _root_window.gui_get_focus_owner()
	var node: Node = resolution.get("node")
	if focus_owner == node:
		return _success(target, resolution)
	return _error(
		"focused_mismatch",
		"focus owner did not match the expected target",
		{
			"target": target,
			"expected": target,
			"actual": _runtime.describe_node(focus_owner),
		},
	)


func _assert_text_equals(target: String, expected: String) -> Dictionary:
	var control_resolution = _require_control(target)
	if not control_resolution.get("ok", false):
		return control_resolution
	var control: Control = control_resolution.get("control")
	var actual := _control_text(control)
	if actual == expected:
		return _success(target, control_resolution)
	return _error(
		"text_equals_mismatch",
		"target text did not match the expected value",
		{
			"target": target,
			"expected": expected,
			"actual": actual,
		},
	)


func _assert_text_contains(target: String, expected: String) -> Dictionary:
	var control_resolution = _require_control(target)
	if not control_resolution.get("ok", false):
		return control_resolution
	var control: Control = control_resolution.get("control")
	var actual := _control_text(control)
	if actual.contains(expected):
		return _success(target, control_resolution)
	return _error(
		"text_contains_mismatch",
		"target text did not contain the expected substring",
		{
			"target": target,
			"expected": expected,
			"actual": actual,
		},
	)


func _assert_inside_viewport(target: String) -> Dictionary:
	var control_resolution = _require_control(target)
	if not control_resolution.get("ok", false):
		return control_resolution
	var control: Control = control_resolution.get("control")
	var rect := control.get_global_rect()
	var viewport_rect := control.get_viewport_rect()
	if (
		rect.position.x >= viewport_rect.position.x
		and rect.position.y >= viewport_rect.position.y
		and rect.end.x <= viewport_rect.end.x
		and rect.end.y <= viewport_rect.end.y
	):
		return _success(target, control_resolution)
	return _error(
		"inside_viewport_mismatch",
		"target rectangle was not fully inside the viewport",
		{
			"target": target,
			"expected": true,
			"actual": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		},
	)


func _assert_no_overlap(a: String, b: String) -> Dictionary:
	var left_resolution = _require_control(a)
	if not left_resolution.get("ok", false):
		return left_resolution
	var right_resolution = _require_control(b)
	if not right_resolution.get("ok", false):
		return right_resolution
	var left: Control = left_resolution.get("control")
	var right: Control = right_resolution.get("control")
	if not left.get_global_rect().intersects(right.get_global_rect()):
		return _ok(
			{
				"target": "%s vs %s" % [a, b],
				"a_resolved": left_resolution.get("resolved", ""),
				"b_resolved": right_resolution.get("resolved", ""),
			}
		)
	return _error(
		"no_overlap_mismatch",
		"targets overlapped within the viewport",
		{
			"target": "%s vs %s" % [a, b],
			"expected": false,
			"actual": true,
		},
	)


func _assert_no_errors() -> Dictionary:
	if _runtime_errors.is_empty():
		return _ok({"count": 0})
	return _error(
		"runtime_errors_present",
		"runner recorded runtime errors",
		{
			"target": "runtime",
			"expected": [],
			"actual": _runtime_errors.duplicate(true),
		},
	)


func _require_target(target: String) -> Dictionary:
	var resolution = _runtime.resolve_target(target)
	if not bool(resolution.get("ok", false)):
		return {
			"ok": false,
			"error": (resolution.get("error", {}) as Dictionary).duplicate(true),
		}
	return resolution


func _require_control(target: String) -> Dictionary:
	var resolution = _require_target(target)
	if not resolution.get("ok", false):
		return resolution
	var node = resolution.get("node")
	if node is Control:
		var success := resolution.duplicate(true)
		success["control"] = node
		return success
	return _error(
		"target_not_control",
		"Resolved target is not a Control",
		{
			"target": target,
			"actual": _runtime.describe_node(node),
		},
	)


func _success(target: String, resolution: Dictionary) -> Dictionary:
	return _ok(
		{
			"target": target,
			"resolved": resolution.get("resolved", ""),
		}
	)


func _ambiguous_target(target: String, matches: Array) -> Dictionary:
	return _error(
		"ambiguous_target",
		"Multiple nodes matched the requested target",
		{
			"target": target,
			"expected": "unique runtime node",
			"actual": _runtime.describe_matches(matches),
		},
	)


func _control_disabled(control: Control) -> Variant:
	if control == null:
		return null
	if _has_property(control, "disabled"):
		return bool(control.get("disabled"))
	return null


func _control_text(control: Control) -> String:
	if control == null:
		return ""
	if _has_property(control, "text"):
		return str(control.get("text"))
	return ""


func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false


func _ok(data := {}) -> Dictionary:
	return {
		"ok": true,
		"data": data if data is Dictionary else {},
	}


func _error(error_type: String, message: String, data := {}) -> Dictionary:
	var error_data: Dictionary = data if data is Dictionary else {}
	if not error_data.has("severity"):
		error_data["severity"] = "error"
	return {
		"ok": false,
		"error": {
			"type": error_type,
			"message": message,
			"data": error_data,
		},
	}
