extends Node
class_name PracticeDirector

const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const PracticeLaneBase = preload("res://scripts/practice/practice_lane_base.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _active_module_id := ""
var _active_module_spec: Dictionary = {}
var _active_lane: PracticeLaneBase = null


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


func get_objective_lines() -> Array[String]:
	if _active_lane != null:
		return _active_lane.get_objective_lines()

	var summary := String(_active_module_spec.get("summary", ""))
	if summary.is_empty():
		return []

	return [summary]


func restart_lane(fixture_root: Node3D, player_robots: Array[RobotBase]) -> void:
	_mount_lane(fixture_root, player_robots)


func _mount_lane(fixture_root: Node3D, player_robots: Array[RobotBase]) -> void:
	if fixture_root == null:
		return

	if is_instance_valid(_active_lane):
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
