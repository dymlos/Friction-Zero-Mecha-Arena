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


func get_local_player_count() -> int:
	if match_config == null:
		return 1

	return clampi(match_config.local_player_count, 1, match_config.max_players)


func get_alive_robots() -> Array[RobotBase]:
	var alive: Array[RobotBase] = []
	for robot in registered_robots:
		if is_instance_valid(robot) and not robot.is_fully_disabled():
			alive.append(robot)

	return alive


func get_robot_status_lines() -> Array[String]:
	var lines: Array[String] = []
	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue

		lines.append(_build_robot_status_line(robot))

	return lines


func _build_robot_status_line(robot: RobotBase) -> String:
	var control_label := "P%s" % robot.player_index if robot.is_player_controlled else "CPU"
	var state_label := "Inutilizado" if robot.is_disabled_state() else "Activo"
	var line := "%s %s | %s | %s/4 partes" % [
		control_label,
		robot.display_name,
		state_label,
		robot.get_active_part_count(),
	]
	line += " | %s" % robot.get_energy_state_summary()
	if robot.is_carrying_part():
		line += " | carga %s" % RobotBase.get_part_display_name(robot.get_carried_part_name())

	return line
