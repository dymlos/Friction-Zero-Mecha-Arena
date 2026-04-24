extends Node
class_name PracticeDirector

const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const PracticeLaneBase = preload("res://scripts/practice/practice_lane_base.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

signal lane_completed
signal lane_status_changed

var _active_module_id := ""
var _active_module_spec: Dictionary = {}
var _active_lane: PracticeLaneBase = null
var _active_lane_completed_callable: Callable = Callable()
var _active_lane_status_callable: Callable = Callable()


func setup(module_id: String, fixture_root: Node3D, player_robots: Array[RobotBase]) -> void:
	_active_module_spec = PracticeCatalog.get_module(module_id)
	if _active_module_spec.is_empty():
		var modules := PracticeCatalog.get_modules()
		if not modules.is_empty():
			_active_module_spec = modules[0]

	_active_module_id = String(_active_module_spec.get("id", ""))
	_mount_lane(fixture_root, player_robots)


func get_active_module_id() -> String:
	return _active_module_id


func get_active_module_spec() -> Dictionary:
	return _active_module_spec.duplicate(true)


func get_active_lane() -> PracticeLaneBase:
	return _active_lane


func get_objective_lines() -> Array[String]:
	if _active_lane != null:
		return _active_lane.get_objective_lines()

	var summary := String(_active_module_spec.get("summary", ""))
	if summary.is_empty():
		return []

	return [summary]


func get_progress_lines() -> Array[String]:
	if _active_lane != null:
		return _active_lane.get_progress_lines()

	return []


func get_callout_lines() -> Array[String]:
	if _active_lane != null:
		return _active_lane.get_callout_lines()

	return []


func get_context_card_title() -> String:
	if _active_lane != null:
		return _active_lane.get_context_card_title()

	var context_card: Dictionary = _active_module_spec.get("context_card", {})
	return String(context_card.get("title", "Que probar"))


func get_context_card_lines() -> Array[String]:
	if _active_lane != null:
		return _active_lane.get_context_card_lines()

	var context_card: Dictionary = _active_module_spec.get("context_card", {})
	var lines: Array[String] = []
	for line in context_card.get("lines", []):
		var normalized := String(line).strip_edges()
		if not normalized.is_empty():
			lines.append(normalized)
	return lines


func restart_lane(fixture_root: Node3D, player_robots: Array[RobotBase]) -> void:
	_mount_lane(fixture_root, player_robots)


func _mount_lane(fixture_root: Node3D, player_robots: Array[RobotBase]) -> void:
	if fixture_root == null:
		return

	if is_instance_valid(_active_lane):
		_disconnect_active_lane_signals()
		fixture_root.remove_child(_active_lane)
		_active_lane.queue_free()
		_active_lane = null

	var lane_scene_path := String(_active_module_spec.get("lane_scene_path", ""))
	if lane_scene_path.is_empty():
		return

	var packed_scene := load(lane_scene_path)
	if not (packed_scene is PackedScene):
		return

	var lane_instance := (packed_scene as PackedScene).instantiate()
	if not (lane_instance is PracticeLaneBase):
		lane_instance.queue_free()
		return

	_active_lane = lane_instance as PracticeLaneBase
	fixture_root.add_child(_active_lane)
	_active_lane.configure_lane(_active_module_spec, player_robots)
	_connect_active_lane_signals()
	lane_status_changed.emit()


func _connect_active_lane_signals() -> void:
	if _active_lane == null:
		return

	_active_lane_completed_callable = Callable(self, "_on_active_lane_completed")
	_active_lane_status_callable = Callable(self, "_on_active_lane_status_changed")
	if _active_lane.has_signal("lane_completed"):
		_active_lane.lane_completed.connect(_active_lane_completed_callable)
	if _active_lane.has_signal("lane_status_changed"):
		_active_lane.lane_status_changed.connect(_active_lane_status_callable)


func _disconnect_active_lane_signals() -> void:
	if _active_lane == null:
		return

	if _active_lane_completed_callable.is_valid() and _active_lane.has_signal("lane_completed") and _active_lane.lane_completed.is_connected(_active_lane_completed_callable):
		_active_lane.lane_completed.disconnect(_active_lane_completed_callable)
	if _active_lane_status_callable.is_valid() and _active_lane.has_signal("lane_status_changed") and _active_lane.lane_status_changed.is_connected(_active_lane_status_callable):
		_active_lane.lane_status_changed.disconnect(_active_lane_status_callable)

	_active_lane_completed_callable = Callable()
	_active_lane_status_callable = Callable()


func _on_active_lane_completed() -> void:
	lane_completed.emit()
	lane_status_changed.emit()


func _on_active_lane_status_changed() -> void:
	lane_status_changed.emit()
