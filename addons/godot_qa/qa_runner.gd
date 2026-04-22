extends SceneTree

const QaArgs = preload("res://addons/godot_qa/qa_args.gd")
const QaProtocol = preload("res://addons/godot_qa/qa_protocol.gd")
const QaRuntime = preload("res://addons/godot_qa/qa_runtime.gd")
const QaSnapshot = preload("res://addons/godot_qa/qa_snapshot.gd")
const SUPPORTED_STEP_TYPES: Array[String] = [
	"wait_frames",
	"snapshot",
	"tap_action",
	"hold_action",
	"release_action",
	"click",
]
const SUPPORTED_ASSERTION_TYPES: Array[String] = ["exists", "visible", "hidden", "focused", "no_errors"]
const EXPANDED_ASSERTION_TYPES: Array[String] = [
	"exists",
	"not_exists",
	"visible",
	"hidden",
	"enabled",
	"disabled",
	"focused",
	"text_equals",
	"text_contains",
	"inside_viewport",
	"no_overlap",
	"no_errors",
]

var _scenario: Dictionary = {}
var _artifacts: Dictionary = {}
var _failures: Array[Dictionary] = []
var _runtime_errors: Array[Dictionary] = []
var _snapshots: Array[String] = []
var _snapshot_artifacts: Dictionary = {}
var _scene_instance: Node = null
var _runtime: RefCounted = null
var _held_actions := {}
var _last_snapshot_name := ""
var _last_snapshot_artifacts: Dictionary = {}
var _started_at_msec := 0


func _initialize() -> void:
	var parsed_args := QaArgs.parse_user_args(OS.get_cmdline_user_args())
	var request_path = str(parsed_args.get("options", {}).get("run_request", ""))
	if request_path == "":
		print(JSON.stringify(QaProtocol.error(
			"missing_run_request",
			"qa_runner requires --qa-run-request=<abs-path>",
			{"qa_args": parsed_args},
		)))
		quit(1)
		return

	_started_at_msec = Time.get_ticks_msec()
	await _run(request_path)


func _run(request_path: String) -> void:
	var request = _read_json_file(request_path)
	if request == null:
		print(JSON.stringify(QaProtocol.error(
			"request_read_failed",
			"qa_runner could not load request.json",
			{"request_path": request_path},
		)))
		quit(1)
		return

	_scenario = request.get("scenario", {})
	_artifacts = request.get("artifacts", {})
	if not _scenario is Dictionary or not _artifacts is Dictionary:
		print(JSON.stringify(QaProtocol.error(
			"request_invalid",
			"request.json must contain scenario and artifacts objects",
			{"request_path": request_path},
		)))
		quit(1)
		return

	var scene_path := str(_scenario.get("scene", ""))
	var packed_scene := load(scene_path)
	if packed_scene == null or not packed_scene is PackedScene:
		_record_runtime_error("Unable to load scene %s" % scene_path)
		_failures.append(_failure(
			"scene_load_failed",
			"scene could not be loaded",
			{
				"target": scene_path,
				"expected": "loadable PackedScene",
				"actual": "missing_or_invalid",
			},
		))
		await _finalize_and_quit()
		return

	_scene_instance = packed_scene.instantiate()
	if _scene_instance == null:
		_record_runtime_error("PackedScene.instantiate() returned null for %s" % scene_path)
		_failures.append(_failure(
			"scene_instantiate_failed",
			"scene could not be instantiated",
			{
				"target": scene_path,
				"expected": "instantiated scene tree",
				"actual": "null",
			},
		))
		await _finalize_and_quit()
		return

	get_root().add_child(_scene_instance)
	await _apply_requested_viewport()
	await process_frame
	_runtime = QaRuntime.new(_scene_instance, get_root(), _runtime_errors, _held_actions)

	for step in _scenario.get("steps", []):
		await _run_step(step)

	for assertion in _scenario.get("assert", []):
		await _run_assertion(assertion)

	await _finalize_and_quit()


func _apply_requested_viewport() -> void:
	var viewport_request = _scenario.get("viewport", {})
	if not viewport_request is Dictionary:
		return

	var width := int(viewport_request.get("width", 0))
	var height := int(viewport_request.get("height", 0))
	if width <= 0 or height <= 0:
		return

	var root_window := get_root()
	if root_window.has_method("set_size_2d_override"):
		root_window.call("set_size_2d_override", Vector2i(width, height))
	if root_window.has_method("set_size_2d_override_stretch"):
		root_window.call("set_size_2d_override_stretch", true)
	root_window.min_size = Vector2i(width, height)
	root_window.size = Vector2i(width, height)
	root_window.content_scale_size = Vector2i(width, height)
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame


func _run_step(step: Variant) -> void:
	if not step is Dictionary or step.size() != 1:
		_failures.append(_failure(
			"unsupported_step",
			"step must be an object with exactly one operation",
			{
				"target": "step",
				"expected": "object with exactly one supported operation",
				"actual": step,
			},
		))
		return

	if step.has("wait_frames"):
		var frame_count := int(step.get("wait_frames", 0))
		for _i in range(max(frame_count, 0)):
			await process_frame
		return

	if step.has("snapshot"):
		var snapshot_name := str(step.get("snapshot", ""))
		if snapshot_name == "":
			_failures.append(_failure(
				"unsupported_step",
				"snapshot step requires a non-empty name",
				{
					"target": "snapshot",
					"expected": "non-empty snapshot name",
					"actual": step,
				},
			))
			return
		await _capture_snapshot(snapshot_name)
		return

	var runtime_command := _runtime_command_for_step(step)
	if not runtime_command.is_empty():
		var runtime_result: Dictionary = await _runtime.execute(
			str(runtime_command.get("command", "")),
			runtime_command.get("params", {}),
		)
		if not bool(runtime_result.get("ok", false)):
			_failures.append(_runtime_error_to_failure(runtime_result.get("error", {})))
		return

	_failures.append(_failure(
		"unsupported_step",
		"M03 runner does not support this step yet",
		{
			"target": _operation_name(step, "step"),
			"expected": SUPPORTED_STEP_TYPES,
			"actual": step,
		},
	))


func _run_assertion(assertion: Variant) -> void:
	if not assertion is Dictionary or assertion.size() != 1:
		_failures.append(_failure(
			"unsupported_assertion",
			"assertion must be an object with exactly one operation",
			{
				"target": "assertion",
				"expected": "object with exactly one supported operation",
				"actual": assertion,
			},
		))
		return

	var runtime_command := _runtime_command_for_assertion(assertion)
	if not runtime_command.is_empty():
		var runtime_result: Dictionary = _runtime.execute(
			str(runtime_command.get("command", "")),
			runtime_command.get("params", {}),
		)
		if not bool(runtime_result.get("ok", false)):
			_failures.append(_runtime_error_to_failure(runtime_result.get("error", {})))
		return

	_failures.append(_failure(
		"unsupported_assertion",
		"M03 runner does not support this assertion yet",
		{
			"target": _operation_name(assertion, "assertion"),
			"expected": EXPANDED_ASSERTION_TYPES,
			"actual": assertion,
		},
	))


func _runtime_command_for_step(step: Dictionary) -> Dictionary:
	if step.has("tap_action"):
		return {
			"command": "input.tap_action",
			"params": {
				"action": str(step.get("tap_action", "")),
			},
		}
	if step.has("hold_action"):
		var hold_action: Dictionary = step.get("hold_action", {})
		return {
			"command": "input.hold_action",
			"params": {
				"action": str(hold_action.get("action", "")),
				"frames": hold_action.get("frames", 0),
			},
		}
	if step.has("release_action"):
		return {
			"command": "input.release_action",
			"params": {
				"action": str(step.get("release_action", "")),
			},
		}
	if step.has("click"):
		return {
			"command": "input.click_target",
			"params": {
				"target": str(step.get("click", "")),
			},
		}
	return {}


func _runtime_command_for_assertion(assertion: Dictionary) -> Dictionary:
	if assertion.has("exists"):
		return {"command": "assert.exists", "params": {"target": str(assertion.get("exists", ""))}}
	if assertion.has("not_exists"):
		return {"command": "assert.not_exists", "params": {"target": str(assertion.get("not_exists", ""))}}
	if assertion.has("visible"):
		return {"command": "assert.visible", "params": {"target": str(assertion.get("visible", ""))}}
	if assertion.has("hidden"):
		return {"command": "assert.hidden", "params": {"target": str(assertion.get("hidden", ""))}}
	if assertion.has("enabled"):
		return {"command": "assert.enabled", "params": {"target": str(assertion.get("enabled", ""))}}
	if assertion.has("disabled"):
		return {"command": "assert.disabled", "params": {"target": str(assertion.get("disabled", ""))}}
	if assertion.has("focused"):
		return {"command": "assert.focused", "params": {"target": str(assertion.get("focused", ""))}}
	if assertion.has("text_equals"):
		var text_equals: Dictionary = assertion.get("text_equals", {})
		return {
			"command": "assert.text_equals",
			"params": {
				"target": str(text_equals.get("target", "")),
				"expected": str(text_equals.get("expected", "")),
			},
		}
	if assertion.has("text_contains"):
		var text_contains: Dictionary = assertion.get("text_contains", {})
		return {
			"command": "assert.text_contains",
			"params": {
				"target": str(text_contains.get("target", "")),
				"expected": str(text_contains.get("expected", "")),
			},
		}
	if assertion.has("inside_viewport"):
		return {
			"command": "assert.inside_viewport",
			"params": {"target": str(assertion.get("inside_viewport", ""))},
		}
	if assertion.has("no_overlap"):
		var no_overlap: Dictionary = assertion.get("no_overlap", {})
		return {
			"command": "assert.no_overlap",
			"params": {
				"a": str(no_overlap.get("a", "")),
				"b": str(no_overlap.get("b", "")),
			},
		}
	if assertion.has("no_errors"):
		return {"command": "assert.no_errors", "params": {}}
	return {}


func _operation_name(entry: Dictionary, fallback: String) -> String:
	if entry.size() != 1:
		return fallback
	var keys := entry.keys()
	if keys.is_empty():
		return fallback
	return str(keys[0])


func _runtime_error_to_failure(error_data: Variant) -> Dictionary:
	if error_data is Dictionary:
		return _failure(
			str(error_data.get("type", "runtime_error")),
			str(error_data.get("message", "Runtime command failed")),
			error_data.get("data", {}),
		)
	return _failure(
		"runtime_error",
		"Runtime command failed",
		{
			"actual": error_data,
		},
	)


func _capture_snapshot(snapshot_name: String) -> void:
	if not _snapshots.has(snapshot_name):
		_snapshots.append(snapshot_name)
	_last_snapshot_name = snapshot_name

	var snapshot_dir := _snapshot_dir(snapshot_name)
	var snapshot_paths := QaSnapshot.snapshot_paths(snapshot_dir)
	_snapshot_artifacts[snapshot_name] = snapshot_paths.duplicate(true)
	_last_snapshot_artifacts = snapshot_paths.duplicate(true)
	var capture_result: Dictionary = await QaSnapshot.capture_snapshot_bundle(
		_scene_instance,
		get_root(),
		_runtime_errors,
		snapshot_dir,
	)
	if bool(capture_result.get("ok", false)):
		return
	for failure in capture_result.get("failures", []):
		if failure is Dictionary:
			var failure_dict: Dictionary = (failure as Dictionary).duplicate(true)
			_record_runtime_error("Unable to capture snapshot artifact %s" % str(failure_dict.get("target", snapshot_name)))
			_failures.append(_failure(
				str(failure_dict.get("type", "snapshot_write_failed")),
				str(failure_dict.get("message", "snapshot artifact failed")),
				{
					"target": failure_dict.get("target"),
					"expected": failure_dict.get("expected"),
					"actual": failure_dict.get("actual"),
				},
			))


func _snapshot_dir(snapshot_name: String) -> String:
	return "%s/%s" % [str(_artifacts.get("snapshots_dir", "")), snapshot_name]


func _failure(failure_type: String, message: String, extra := {}) -> Dictionary:
	var failure := {
		"type": failure_type,
		"message": message,
		"severity": "error",
	}
	if not _last_snapshot_artifacts.is_empty():
		failure["artifacts"] = _last_snapshot_artifacts.duplicate(true)
	elif _artifacts.has("root"):
		failure["artifacts"] = {"root": str(_artifacts.get("root", ""))}
	if extra is Dictionary:
		for key in extra.keys():
			failure[key] = extra[key]
	return failure


func _record_runtime_error(message: String, source := "runner") -> void:
	push_error("[godot-qa] %s" % message)
	_runtime_errors.append(
		{
			"message": message,
			"source": source,
		}
	)


func _result_payload() -> Dictionary:
	return {
		"ok": _failures.is_empty(),
		"scenario": str(_scenario.get("name", "")),
		"scene": str(_scenario.get("scene", "")),
		"duration_ms": Time.get_ticks_msec() - _started_at_msec,
		"snapshots": _snapshots.duplicate(),
		"snapshot_artifacts": _snapshot_artifacts.duplicate(true),
		"failures": _failures.duplicate(),
		"artifacts": _artifacts.duplicate(),
	}


func _finalize_and_quit() -> void:
	if _runtime != null:
		var release_failures: Array = await _runtime.release_held_actions()
		for release_failure in release_failures:
			_failures.append(_runtime_error_to_failure(release_failure))

	var result_path := str(_artifacts.get("result", ""))
	if result_path != "":
		var write_error := _write_json_file(result_path, _result_payload())
		if write_error != OK:
			print(JSON.stringify(QaProtocol.error(
				"result_write_failed",
				"qa_runner could not write result.json",
				{"result_path": result_path},
			)))
			quit(1)
			return

	print(JSON.stringify(_result_payload()))
	quit(0 if _failures.is_empty() else 1)


func _read_json_file(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		return null
	return parser.data


func _write_json_file(path: String, payload: Dictionary) -> int:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_string(JSON.stringify(payload))
	return OK
