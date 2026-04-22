extends Node

const QaArgs = preload("res://addons/godot_qa/qa_args.gd")
const QaProtocol = preload("res://addons/godot_qa/qa_protocol.gd")
const QaRuntime = preload("res://addons/godot_qa/qa_runtime.gd")
const QaLiveEdit = preload("res://addons/godot_qa/qa_live_edit.gd")
const QaRecorder = preload("res://addons/godot_qa/qa_recorder.gd")
const QaSnapshot = preload("res://addons/godot_qa/qa_snapshot.gd")

var enabled := false
var activation_source := "disabled"
var runtime_options := {}
var _held_actions := {}
var _runtime_errors: Array = []
var _live_session := {}
var _live_edit: RefCounted = null
var _recorder: Node = null
var _session_logs: Array[Dictionary] = []
var _stop_requested := false

func _ready() -> void:
	var parsed_args := QaArgs.parse_user_args(OS.get_cmdline_user_args())
	runtime_options = parsed_args.get("options", {})

	if parsed_args.get("enabled", false):
		enabled = true
		activation_source = "user_args"
	elif bool(ProjectSettings.get_setting(QaArgs.ENABLE_SETTING, false)):
		enabled = true
		activation_source = "project_settings"
	else:
		enabled = false
		activation_source = "disabled"

	if enabled:
		print("[godot-qa] runtime bridge enabled")

func get_status() -> Dictionary:
	return {
		"enabled": enabled,
		"activation_source": activation_source,
		"options": runtime_options,
	}

func configure_live_session(session_state: Dictionary) -> void:
	_live_session = session_state.duplicate(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_live_edit = QaLiveEdit.new()
	if bool(_live_session.get("recorder_enabled", false)):
		_recorder = QaRecorder.new(
			_resolve_scene_root(),
			get_tree().get_root(),
			QaRuntime.new(_resolve_scene_root(), get_tree().get_root(), _runtime_errors, _held_actions),
		)
		_recorder.name = "GodotQaRecorder"
		get_tree().get_root().add_child(_recorder)
	_record_log(
		"info",
		"session_started",
		"live session initialized",
		{
			"session_id": str(_live_session.get("session_id", "")),
			"scene": str(_live_session.get("scene", "")),
		},
	)

func consume_stop_requested() -> bool:
	if not _stop_requested:
		return false
	_stop_requested = false
	return true

func _request_id_from_command(command: Dictionary) -> String:
	if not command.has("id"):
		return ""
	var request_id = command.get("id", "")
	if request_id == null:
		return ""
	return str(request_id)

func _configured_session_token() -> String:
	return str(runtime_options.get("session_token", ""))

func _sanitized_command(command: Dictionary) -> Dictionary:
	var sanitized := command.duplicate(true)
	sanitized.erase("token")
	return sanitized

func handle_command(command: Dictionary) -> Dictionary:
	var request_id := _request_id_from_command(command)
	if not enabled:
		return QaProtocol.error(
			"bridge_inactive",
			"QA mode is not enabled",
			{"command": command},
			request_id,
		)
	var expected_token := _configured_session_token()
	if expected_token == "":
		return QaProtocol.error(
			"session_token_unconfigured",
			"QA bridge requires --qa-session-token for live commands",
			{"command": _sanitized_command(command)},
			request_id,
		)
	var command_token := str(command.get("token", ""))
	if command_token == "":
		return QaProtocol.error(
			"session_token_required",
			"QA bridge command requires a session token",
			{"command": _sanitized_command(command)},
			request_id,
		)
	if command_token != expected_token:
		return QaProtocol.error(
			"invalid_session_token",
			"QA bridge session token did not match",
			{"command": _sanitized_command(command)},
			request_id,
		)
	var runtime := QaRuntime.new(_resolve_scene_root(), get_tree().get_root(), _runtime_errors, _held_actions)
	var command_name := str(command.get("command", ""))
	var params := command.get("params", {})
	var live_session_enabled := not _live_session.is_empty()
	if live_session_enabled and command_name == "session.status":
		return QaProtocol.ok(_session_status_payload(), request_id)
	if live_session_enabled and command_name == "session.pause":
		return _handle_session_pause(request_id)
	if live_session_enabled and command_name == "session.resume":
		return _handle_session_resume(request_id)
	if live_session_enabled and command_name == "session.step":
		return await _handle_session_step(params, request_id)
	if live_session_enabled and command_name == "session.wait_frames":
		var frame_count = int(params.get("frames", 0))
		for _index in range(max(frame_count, 0)):
			await get_tree().process_frame
		if _recorder != null and _recorder.has_method("note_wait_frames"):
			_recorder.call("note_wait_frames", frame_count)
		_record_log(
			"info",
			"session_wait_frames",
			"processed requested frames",
			{"frames": frame_count},
		)
		return QaProtocol.ok({"frames": frame_count}, request_id)
	if live_session_enabled and command_name == "session.stop":
		_stop_requested = true
		_record_log("info", "session_stop", "live session stop requested", {})
		return QaProtocol.ok({"stopping": true}, request_id)
	if live_session_enabled and command_name == "snapshot.capture":
		var snapshot_name := str(params.get("name", "current"))
		var snapshot_dir := "%s/%s" % [str(_live_session.get("snapshots_dir", "")), snapshot_name]
		var capture_result: Dictionary = await QaSnapshot.capture_snapshot_bundle(
			_resolve_scene_root(),
			get_tree().get_root(),
			_runtime_errors,
			snapshot_dir,
		)
		if bool(capture_result.get("ok", false)):
			if _recorder != null and _recorder.has_method("note_snapshot"):
				_recorder.call("note_snapshot", snapshot_name)
			_record_log(
				"info",
				"snapshot_capture",
				"captured live snapshot",
				{
					"name": snapshot_name,
					"artifacts": capture_result.get("artifacts", {}),
				},
			)
			return QaProtocol.ok(
				{
					"name": snapshot_name,
					"artifacts": capture_result.get("artifacts", {}),
				},
				request_id,
			)
		for failure in capture_result.get("failures", []):
			if failure is Dictionary:
				var failure_dict: Dictionary = (failure as Dictionary).duplicate(true)
				_record_runtime_error(str(failure_dict.get("message", "snapshot artifact failed")), "snapshot")
		var first_failure := {}
		var failures = capture_result.get("failures", [])
		if failures is Array and not failures.is_empty() and failures[0] is Dictionary:
			first_failure = (failures[0] as Dictionary).duplicate(true)
		first_failure["artifacts"] = capture_result.get("artifacts", {})
		return QaProtocol.error(
			str(first_failure.get("type", "snapshot_write_failed")),
			str(first_failure.get("message", "snapshot capture failed")),
			first_failure,
			request_id,
		)
	if live_session_enabled and command_name == "screenshot.capture":
		var screenshot_name := _sanitize_capture_name(str(params.get("name", "current")))
		var screenshots_dir := str(_live_session.get("screenshots_dir", ""))
		var screenshot_path := "%s/%s.png" % [screenshots_dir, screenshot_name]
		var screenshot_result: Dictionary = await QaSnapshot.capture_screenshot(
			get_tree().get_root(),
			screenshot_path,
		)
		if bool(screenshot_result.get("ok", false)):
			_record_log(
				"info",
				"screenshot_capture",
				"captured live screenshot",
				{
					"name": screenshot_name,
					"artifacts": screenshot_result.get("artifacts", {}),
				},
			)
			return QaProtocol.ok(
				{
					"name": screenshot_name,
					"artifacts": screenshot_result.get("artifacts", {}),
				},
				request_id,
			)
		var screenshot_failure := {}
		var screenshot_failures = screenshot_result.get("failures", [])
		if screenshot_failures is Array and not screenshot_failures.is_empty() and screenshot_failures[0] is Dictionary:
			screenshot_failure = (screenshot_failures[0] as Dictionary).duplicate(true)
		screenshot_failure["artifacts"] = screenshot_result.get("artifacts", {})
		_record_runtime_error(str(screenshot_failure.get("message", "screenshot capture failed")), "screenshot")
		return QaProtocol.error(
			str(screenshot_failure.get("type", "screenshot_write_failed")),
			str(screenshot_failure.get("message", "screenshot capture failed")),
			screenshot_failure,
			request_id,
		)
	if live_session_enabled and command_name == "logs.read":
		return QaProtocol.ok(_read_logs(str(params.get("since", ""))), request_id)
	if live_session_enabled and command_name == "record.export":
		if _recorder != null and _recorder.has_method("export"):
			return QaProtocol.ok(_recorder.call("export"), request_id)
		return QaProtocol.error(
			"unsupported_command",
			"QA bridge command is not supported in this milestone",
			{"command": _sanitized_command(command)},
			request_id,
		)
	if live_session_enabled and command_name == "edit.set_property":
		var live_edit_result: Dictionary = await _live_edit.set_property(
			runtime,
			_resolve_scene_root(),
			str(params.get("target", "")),
			str(params.get("property", "")),
			str(params.get("value_input", "")),
		)
		return _live_edit_protocol_response(command_name, live_edit_result, request_id)
	if live_session_enabled and command_name == "edit.call_method":
		var live_call_result: Dictionary = await _live_edit.call_method(
			runtime,
			_resolve_scene_root(),
			str(params.get("target", "")),
			str(params.get("method", "")),
		)
		return _live_edit_protocol_response(command_name, live_call_result, request_id)
	if live_session_enabled and command_name == "edit.diff":
		return _live_edit_protocol_response(command_name, _live_edit.diff(runtime), request_id)
	if live_session_enabled and command_name == "edit.export_patch":
		return _live_edit_protocol_response(command_name, _live_edit.export_patch(runtime, _resolve_scene_root()), request_id)
	var result: Dictionary = await runtime.execute(command_name, params)
	if not bool(result.get("ok", false)):
		_record_log(
			"error",
			"runtime_error",
			str((result.get("error", {}) as Dictionary).get("message", "Runtime command failed")),
			(result.get("error", {}) as Dictionary).get("data", {}),
		)
	else:
		_record_log("info", "runtime_command", "live command completed", {"command": command_name})
	if bool(result.get("ok", false)):
		if command_name == "input.click_target" and _recorder != null and _recorder.has_method("note_click_target"):
			var result_data := (result.get("data", {}) as Dictionary).duplicate(true)
			_recorder.call(
				"note_click_target",
				str(result_data.get("target", str(params.get("target", "")))),
				str(result_data.get("resolved", "")),
			)
		return QaProtocol.ok(result.get("data", {}), request_id)

	var error_data = result.get("error", {})
	if not error_data is Dictionary:
		error_data = {}
	var error_payload = error_data.get("data", {})
	if str(error_data.get("type", "")) == "unsupported_command":
		error_payload = {"command": _sanitized_command(command)}
	return QaProtocol.error(
		str(error_data.get("type", "runtime_error")),
		str(error_data.get("message", "Runtime command failed")),
		error_payload,
		request_id,
	)


func _resolve_scene_root() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	if tree.current_scene != null:
		return tree.current_scene

	var root := tree.get_root()
	for child_index in range(root.get_child_count() - 1, -1, -1):
		var child := root.get_child(child_index) as Node
		if child == null:
			continue
		if child == self:
			continue
		if str(child.name) in ["GodotQaBridge", "GodotQaRecorder"]:
			continue
		return child
	return null

func _sanitize_capture_name(raw_name: String) -> String:
	var input_name := raw_name.strip_edges().to_lower()
	if input_name == "":
		return "current"
	var sanitized := ""
	for character in input_name:
		var codepoint := character.unicode_at(0)
		var keep := (
			(codepoint >= 48 and codepoint <= 57)
			or (codepoint >= 97 and codepoint <= 122)
			or character in ["-", "_"]
		)
		sanitized += character if keep else "-"
	var collapsed: PackedStringArray = []
	for segment in sanitized.split("-"):
		if segment != "":
			collapsed.append(segment)
	return "-".join(collapsed) if not collapsed.is_empty() else "current"

func _session_status_payload() -> Dictionary:
	return {
		"session_id": str(_live_session.get("session_id", "")),
		"scene": str(_live_session.get("scene", "")),
		"viewport": _live_session.get("viewport", []),
		"started_at": str(_live_session.get("started_at", "")),
		"stop_requested": _stop_requested,
		"paused": _is_session_paused(),
	}


func _is_session_paused() -> bool:
	var tree := get_tree()
	return tree != null and tree.paused


func _handle_session_pause(request_id: String) -> Dictionary:
	var tree := get_tree()
	if tree == null:
		return QaProtocol.error(
			"scene_unavailable",
			"QA runtime scene is not ready",
			{"command": "session.pause"},
			request_id,
		)
	if tree.paused:
		return QaProtocol.error(
			"session_already_paused",
			"live session is already paused",
			{
				"command": "session.pause",
				"expected": "running live session",
				"actual": "paused",
				"target": "session",
			},
			request_id,
		)
	tree.paused = true
	_record_log("info", "session_pause", "live session paused", {"paused": true})
	return QaProtocol.ok({"paused": true}, request_id)


func _handle_session_resume(request_id: String) -> Dictionary:
	var tree := get_tree()
	if tree == null:
		return QaProtocol.error(
			"scene_unavailable",
			"QA runtime scene is not ready",
			{"command": "session.resume"},
			request_id,
		)
	if not tree.paused:
		return QaProtocol.error(
			"session_not_paused",
			"live session is not paused",
			{
				"command": "session.resume",
				"expected": "paused live session",
				"actual": "running",
				"target": "session",
			},
			request_id,
		)
	tree.paused = false
	_record_log("info", "session_resume", "live session resumed", {"paused": false})
	return QaProtocol.ok({"paused": false}, request_id)


func _handle_session_step(params: Variant, request_id: String) -> Dictionary:
	var tree := get_tree()
	if tree == null:
		return QaProtocol.error(
			"scene_unavailable",
			"QA runtime scene is not ready",
			{"command": "session.step"},
			request_id,
		)
	var command_params: Dictionary = params if params is Dictionary else {}
	var frame_count := _coerce_positive_frame_count(command_params.get("frames", null))
	if frame_count == null:
		return QaProtocol.error(
			"invalid_params",
			"session.step requires a positive integer frame count",
			{
				"command": "session.step",
				"expected": "positive integer frames",
				"actual": command_params.get("frames", null),
			},
			request_id,
		)
	if not tree.paused:
		return QaProtocol.error(
			"session_not_paused",
			"live session must be paused before stepping frames",
			{
				"command": "session.step",
				"expected": "paused live session",
				"actual": "running",
				"target": "session",
			},
			request_id,
		)
	tree.paused = false
	for _index in range(frame_count):
		await tree.process_frame
	RenderingServer.force_draw(false)
	tree.paused = true
	_record_log(
		"info",
		"session_step",
		"processed requested paused-session frames",
		{"frames": frame_count, "paused": true},
	)
	return QaProtocol.ok({"paused": true, "frames": frame_count}, request_id)


func _coerce_positive_frame_count(value: Variant) -> Variant:
	if not value is int and not value is float:
		return null
	var numeric_value := float(value)
	if floor(numeric_value) != numeric_value:
		return null
	var frame_count := int(numeric_value)
	if frame_count <= 0:
		return null
	return frame_count

func append_runtime_error(entry: Dictionary) -> void:
	var normalized := {
		"message": str(entry.get("message", "")),
		"source": str(entry.get("source", "bridge")),
	}
	for key in entry.keys():
		if not key is String:
			continue
		var key_name := str(key)
		if key_name in ["message", "source"]:
			continue
		normalized[key_name] = _json_safe_value(entry.get(key))
	push_error("[godot-qa] %s" % str(normalized.get("message", "")))
	_runtime_errors.append(normalized)
	_record_log("error", "runtime_error", str(normalized.get("message", "")), normalized)


func record_runtime_error(message: String, source := "bridge", extra := {}) -> void:
	var entry := {
		"message": message,
		"source": source,
	}
	if extra is Dictionary:
		for key in extra.keys():
			if key is String:
				entry[str(key)] = extra.get(key)
	append_runtime_error(entry)


func _record_runtime_error(message: String, source := "bridge") -> void:
	record_runtime_error(message, source)


func _json_safe_value(value: Variant) -> Variant:
	if value == null:
		return null
	if value is bool or value is int or value is float or value is String:
		return value
	if value is Array:
		var normalized_array: Array = []
		for item in value:
			normalized_array.append(_json_safe_value(item))
		return normalized_array
	if value is Dictionary:
		var normalized_dict := {}
		for key in value.keys():
			if key is String:
				normalized_dict[str(key)] = _json_safe_value(value.get(key))
		return normalized_dict
	return str(value)

func _record_log(level: String, event_name: String, message: String, data := {}) -> void:
	var entry := {
		"cursor": str(_session_logs.size() + 1),
		"level": level,
		"event": event_name,
		"message": message,
		"data": data if data is Dictionary else {},
	}
	_session_logs.append(entry)

func _read_logs(since: String) -> Dictionary:
	var start_index := 0
	if since != "":
		start_index = maxi(int(since), 0)
	var entries: Array[Dictionary] = []
	for index in range(start_index, _session_logs.size()):
		entries.append((_session_logs[index] as Dictionary).duplicate(true))
	return {
		"entries": entries,
		"next_cursor": str(_session_logs.size()),
	}


func _live_edit_protocol_response(command_name: String, result: Dictionary, request_id: String) -> Dictionary:
	if not bool(result.get("ok", false)):
		var error_payload := (result.get("error", {}) as Dictionary).duplicate(true)
		_record_log(
			"error",
			"runtime_error",
			str(error_payload.get("message", "Live edit command failed")),
			(error_payload.get("data", {}) as Dictionary).duplicate(true),
		)
		return QaProtocol.error(
			str(error_payload.get("type", "runtime_error")),
			str(error_payload.get("message", "Live edit command failed")),
			error_payload.get("data", {}),
			request_id,
		)
	_record_log("info", "live_edit_command", "live edit command completed", {"command": command_name})
	return QaProtocol.ok((result.get("data", {}) as Dictionary).duplicate(true), request_id)
