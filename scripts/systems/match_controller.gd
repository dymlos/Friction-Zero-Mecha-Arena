extends Node
class_name MatchController

const MatchConfig = preload("res://scripts/systems/match_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

enum MatchMode { FFA, TEAMS }

@export var match_mode: MatchMode = MatchMode.FFA
@export var match_config: MatchConfig

var registered_robots: Array[RobotBase] = []


func register_robot(robot: RobotBase) -> void:
	if registered_robots.has(robot):
		return

	registered_robots.append(robot)


func unregister_robot(robot: RobotBase) -> void:
	registered_robots.erase(robot)


func get_alive_robots() -> Array[RobotBase]:
	var alive: Array[RobotBase] = []
	for robot in registered_robots:
		if is_instance_valid(robot) and not robot.is_fully_disabled():
			alive.append(robot)

	return alive
