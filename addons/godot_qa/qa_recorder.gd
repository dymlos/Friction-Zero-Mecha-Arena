extends Node

var _scene_root: Node = null
var _root_window: Window = null
var _runtime: RefCounted = null
var _events: Array[Dictionary] = []
var _unconverted_events: Array[Dictionary] = []
var _frame_index := 0
var _sequence := 0
var _action_start_frames := {}
var _last_focus_target := ""
var _suppress_mouse_release_frame := -1


func _init(scene_root: Node, root_window: Window, runtime: RefCounted) -> void:
	_scene_root = scene_root
	_root_window = root_window
	_runtime = runtime


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_input(true)


func _process(_delta: float) -> void:
	_frame_index += 1
	var focus_owner := _root_window.gui_get_focus_owner() if _root_window != null else null
	var focus_target := _stable_locator(focus_owner)
	if focus_target != _last_focus_target:
		_last_focus_target = focus_target
		_append_event(
			{
				"type": "focus_changed",
				"target": focus_target,
			}
		)


func _input(event: InputEvent) -> void:
	if event is InputEventAction:
		var action_event := event as InputEventAction
		var action_name := str(action_event.action)
		if action_name == "":
			return
		if action_event.pressed:
			_action_start_frames[action_name] = _frame_index
			return
		if not _action_start_frames.has(action_name):
			return
		var start_frame := int(_action_start_frames[action_name])
		_action_start_frames.erase(action_name)
		var frame_span := maxi(_frame_index - start_frame, 0)
		if frame_span <= 1:
			_append_event(
				{
					"type": "tap_action",
					"action": action_name,
				}
			)
			return
		_append_event(
			{
				"type": "hold_action",
				"action": action_name,
				"frames": frame_span,
			}
		)
		_append_event(
			{
				"type": "release_action",
				"action": action_name,
			}
		)
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or mouse_event.pressed:
			return
		if _suppress_mouse_release_frame == _frame_index:
			return
		var hovered := _hovered_control()
		var locator := _stable_locator(hovered)
		if locator == "":
			_append_unconverted_event(
				{
					"type": "click",
					"reason": "no stable locator",
					"position": [float(mouse_event.position.x), float(mouse_event.position.y)],
				}
			)
			return
		_append_event(
			{
				"type": "click",
				"target": locator,
				"resolved": locator,
			}
		)


func note_wait_frames(frames: int) -> void:
	if frames <= 0:
		return
	_append_event(
		{
			"type": "wait_frames",
			"frames": frames,
		}
	)


func note_snapshot(name: String) -> void:
	if name == "":
		return
	_append_event(
		{
			"type": "snapshot",
			"name": name,
		}
	)


func note_click_target(target: String, resolved: String) -> void:
	var locator := target if target != "" else resolved
	if locator == "":
		_append_unconverted_event(
			{
				"type": "click",
				"reason": "no stable locator",
			}
		)
		return
	_suppress_mouse_release_frame = _frame_index
	_append_event(
		{
			"type": "click",
			"target": locator,
			"resolved": resolved if resolved != "" else locator,
		}
	)


func export() -> Dictionary:
	return {
		"events": _duplicate_entries(_events),
		"unconverted_events": _duplicate_entries(_unconverted_events),
		"frame_index": _frame_index,
	}


func _append_event(payload: Dictionary) -> void:
	_sequence += 1
	var event := payload.duplicate(true)
	event["seq"] = _sequence
	event["frame"] = _frame_index
	_events.append(event)


func _append_unconverted_event(payload: Dictionary) -> void:
	_sequence += 1
	var event := payload.duplicate(true)
	event["seq"] = _sequence
	event["frame"] = _frame_index
	_unconverted_events.append(event)


func _hovered_control() -> Control:
	if _root_window == null:
		return null
	if _root_window.has_method("gui_get_hovered_control"):
		return _root_window.call("gui_get_hovered_control") as Control
	return null


func _stable_locator(node: Variant) -> String:
	if node == null or _runtime == null or not _runtime.has_method("stable_locator_for_node"):
		return ""
	return str(_runtime.call("stable_locator_for_node", node))


func _duplicate_entries(entries: Array[Dictionary]) -> Array[Dictionary]:
	var duplicated: Array[Dictionary] = []
	for entry in entries:
		duplicated.append(entry.duplicate(true))
	return duplicated
