extends Node
class_name MatchController

const MatchConfig = preload("res://scripts/systems/match_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

enum MatchMode { FFA, TEAMS }
enum EliminationCause { VOID, EXPLOSION }

@export var match_mode: MatchMode = MatchMode.FFA
@export var match_config: MatchConfig
@export_range(0.2, 6.0, 0.1) var round_reset_delay := 1.8

var registered_robots: Array[RobotBase] = []

var _round_number := 1
var _round_active := false
var _round_reset_pending := false
var _round_eliminated_robot_ids: Dictionary = {}
var _competitor_scores: Dictionary = {}
var _competitor_labels: Dictionary = {}
var _competitor_order: Array[String] = []
var _last_elimination_summary := ""
var _round_status_line := ""


func register_robot(robot: RobotBase) -> void:
	if registered_robots.has(robot):
		return

	registered_robots.append(robot)
	_register_competitor(robot)


func unregister_robot(robot: RobotBase) -> void:
	registered_robots.erase(robot)


func get_local_player_count() -> int:
	if match_config == null:
		return 1

	return clampi(match_config.local_player_count, 1, match_config.max_players)


func start_match() -> void:
	_round_number = 1
	_round_reset_pending = false
	_round_eliminated_robot_ids.clear()
	_last_elimination_summary = ""
	_competitor_scores.clear()
	_competitor_labels.clear()
	_competitor_order.clear()

	for robot in registered_robots:
		if is_instance_valid(robot):
			_register_competitor(robot)

	_round_active = true
	_round_status_line = "Ronda %s en juego" % _round_number


func is_round_active() -> bool:
	return _round_active


func is_round_reset_pending() -> bool:
	return _round_reset_pending


func get_round_status_line() -> String:
	return _round_status_line


func get_last_elimination_summary() -> String:
	return _last_elimination_summary


func get_team_score(team_id: int) -> int:
	return int(_competitor_scores.get(_get_team_competitor_key(team_id), 0))


func get_round_state_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append(get_round_status_line())
	var score_line := _build_score_summary_line()
	if score_line != "":
		lines.append(score_line)
	return lines


func get_alive_robots() -> Array[RobotBase]:
	var alive: Array[RobotBase] = []
	for robot in registered_robots:
		if is_instance_valid(robot) and not robot.is_fully_disabled() and not is_robot_eliminated(robot):
			alive.append(robot)

	return alive


func get_robot_status_lines() -> Array[String]:
	var lines: Array[String] = []
	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue

		lines.append(_build_robot_status_line(robot))

	return lines


func is_robot_eliminated(robot: RobotBase) -> bool:
	if robot == null:
		return false

	return _round_eliminated_robot_ids.has(robot.get_instance_id())


func record_robot_elimination(robot: RobotBase, cause: EliminationCause) -> String:
	if robot == null:
		return ""
	if not _round_active or _round_reset_pending:
		return ""

	var robot_id := robot.get_instance_id()
	if _round_eliminated_robot_ids.has(robot_id):
		return ""

	_round_eliminated_robot_ids[robot_id] = cause
	_last_elimination_summary = _build_elimination_summary(robot, cause)
	robot.hold_for_round_reset()

	var winner_key := _find_last_competitor_standing()
	if winner_key == "":
		if _get_remaining_competitor_count() == 0:
			_finish_round_draw()
			return _round_status_line

		_round_status_line = "Ronda %s en juego" % _round_number
		return _last_elimination_summary

	_finish_round_with_winner(winner_key)
	return _round_status_line


func _build_robot_status_line(robot: RobotBase) -> String:
	var control_label := "P%s" % robot.player_index if robot.is_player_controlled else "CPU"
	var state_label := "Activo"
	if is_robot_eliminated(robot):
		state_label = "Fuera"
	elif robot.is_disabled_state():
		state_label = "Inutilizado"

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


func _register_competitor(robot: RobotBase) -> void:
	var competitor_key := _get_competitor_key(robot)
	if competitor_key == "":
		return

	if not _competitor_order.has(competitor_key):
		_competitor_order.append(competitor_key)

	if not _competitor_scores.has(competitor_key):
		_competitor_scores[competitor_key] = 0

	_competitor_labels[competitor_key] = _get_competitor_label(robot)


func _get_competitor_key(robot: RobotBase) -> String:
	if robot == null:
		return ""

	if match_mode == MatchMode.TEAMS:
		return _get_team_competitor_key(robot.get_team_identity())

	return "robot_%s" % robot.get_instance_id()


func _get_team_competitor_key(team_id: int) -> String:
	return "team_%s" % team_id


func _get_competitor_label(robot: RobotBase) -> String:
	if robot == null:
		return ""

	if match_mode == MatchMode.TEAMS:
		return "Equipo %s" % robot.get_team_identity()

	return robot.display_name


func _get_competitor_label_from_key(competitor_key: String) -> String:
	return str(_competitor_labels.get(competitor_key, competitor_key))


func _build_elimination_summary(robot: RobotBase, cause: EliminationCause) -> String:
	var cause_label := "cayo al vacio" if cause == EliminationCause.VOID else "explosiono tras quedar inutilizado"
	return "%s %s" % [robot.display_name, cause_label]


func _find_last_competitor_standing() -> String:
	var remaining_competitors: Array[String] = []
	for competitor_key in _get_remaining_competitor_keys():
		remaining_competitors.append(competitor_key)

	if remaining_competitors.size() != 1:
		return ""

	return remaining_competitors[0]


func _get_remaining_competitor_count() -> int:
	return _get_remaining_competitor_keys().size()


func _get_remaining_competitor_keys() -> Array[String]:
	var remaining_lookup := {}
	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue
		if is_robot_eliminated(robot):
			continue

		remaining_lookup[_get_competitor_key(robot)] = true

	var remaining: Array[String] = []
	for competitor_key in _competitor_order:
		if remaining_lookup.has(competitor_key):
			remaining.append(competitor_key)

	return remaining


func _finish_round_with_winner(winner_key: String) -> void:
	_round_active = false
	_round_reset_pending = true
	_competitor_scores[winner_key] = int(_competitor_scores.get(winner_key, 0)) + 1
	_round_status_line = "%s gana la ronda %s" % [_get_competitor_label_from_key(winner_key), _round_number]
	_schedule_round_reset()


func _finish_round_draw() -> void:
	_round_active = false
	_round_reset_pending = true
	_round_status_line = "Ronda %s sin ganador" % _round_number
	_schedule_round_reset()


func _schedule_round_reset() -> void:
	await get_tree().create_timer(round_reset_delay).timeout
	if not is_inside_tree():
		return

	_reset_round()


func _reset_round() -> void:
	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue

		robot.reset_to_spawn()

	_round_eliminated_robot_ids.clear()
	_last_elimination_summary = ""
	_round_number += 1
	_round_active = true
	_round_reset_pending = false
	_round_status_line = "Ronda %s en juego" % _round_number


func _build_score_summary_line() -> String:
	var score_parts: Array[String] = []
	for competitor_key in _competitor_order:
		score_parts.append("%s %s" % [
			_get_competitor_label_from_key(competitor_key),
			int(_competitor_scores.get(competitor_key, 0)),
		])

	return "Marcador | %s" % " | ".join(score_parts)
