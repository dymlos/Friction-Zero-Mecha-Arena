extends Node3D
class_name PracticeLaneBase

const RobotBase = preload("res://scripts/robots/robot_base.gd")

signal lane_completed
signal lane_status_changed

var _module_spec: Dictionary = {}
var _player_robots: Array[RobotBase] = []


func configure_lane(module_spec: Dictionary, player_robots: Array[RobotBase]) -> void:
	_module_spec = module_spec.duplicate(true)
	_player_robots = player_robots.duplicate()
	lane_status_changed.emit()


func get_objective_lines() -> Array[String]:
	var summary := String(_module_spec.get("summary", ""))
	if summary.is_empty():
		return []

	return [summary]
