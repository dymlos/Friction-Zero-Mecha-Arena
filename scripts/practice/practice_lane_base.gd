extends Node3D
class_name PracticeLaneBase

const RobotBase = preload("res://scripts/robots/robot_base.gd")

signal lane_completed
signal lane_status_changed

var _module_spec: Dictionary = {}
var _player_robots: Array[RobotBase] = []
var _objective_lines: Array[String] = []
var _progress_lines: Array[String] = []
var _callout_lines: Array[String] = []
var _lane_completed := false


func configure_lane(module_spec: Dictionary, player_robots: Array) -> void:
	_module_spec = module_spec.duplicate(true)
	_player_robots.clear()
	for robot_variant in player_robots:
		if robot_variant is RobotBase:
			_player_robots.append(robot_variant as RobotBase)
	_lane_completed = false
	_objective_lines = _sanitize_lines(get_objective_lines())
	_progress_lines.clear()
	_callout_lines.clear()
	if _objective_lines.is_empty():
		_objective_lines = [String(_module_spec.get("summary", ""))]
	lane_status_changed.emit()


func get_objective_lines() -> Array[String]:
	return _objective_lines.duplicate()


func get_progress_lines() -> Array[String]:
	return _progress_lines.duplicate()


func get_callout_lines() -> Array[String]:
	return _callout_lines.duplicate()


func get_module_spec() -> Dictionary:
	return _module_spec.duplicate(true)


func get_player_robots() -> Array[RobotBase]:
	return _player_robots.duplicate()


func is_lane_completed() -> bool:
	return _lane_completed


func set_objective_lines(lines: Array[String]) -> void:
	_objective_lines = _sanitize_lines(lines)
	lane_status_changed.emit()


func set_progress_lines(lines: Array[String]) -> void:
	_progress_lines = _sanitize_lines(lines)
	lane_status_changed.emit()


func set_callout_lines(lines: Array[String]) -> void:
	_callout_lines = _sanitize_lines(lines)
	lane_status_changed.emit()


func complete_lane() -> void:
	if _lane_completed:
		return

	_lane_completed = true
	lane_completed.emit()
	lane_status_changed.emit()


func _sanitize_lines(lines: Array[String]) -> Array[String]:
	var sanitized: Array[String] = []
	for line in lines:
		var normalized := String(line).strip_edges()
		if normalized.is_empty():
			continue
		sanitized.append(normalized)

	return sanitized
