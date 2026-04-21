extends Node
class_name MatchController

const MatchConfig = preload("res://scripts/systems/match_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

signal round_started(round_number: int)

enum MatchMode { FFA, TEAMS }
enum EliminationCause { VOID, EXPLOSION, UNSTABLE_EXPLOSION }

@export var match_mode: MatchMode = MatchMode.FFA
@export var match_config: MatchConfig
@export_range(0.2, 6.0, 0.1) var round_reset_delay := 1.8
@export_range(0.5, 8.0, 0.1) var match_restart_delay := 2.6
@export_range(0.0, 0.95, 0.05) var space_reduction_start_ratio := 0.55
@export_range(0.35, 1.0, 0.05) var space_reduction_min_scale := 0.55

var registered_robots: Array[RobotBase] = []

var _round_number := 1
var _round_active := false
var _round_reset_pending := false
var _match_over := false
var _round_eliminated_robot_ids: Dictionary = {}
var _round_elimination_order_by_robot_id: Dictionary = {}
var _round_elimination_recap_entries: Array[String] = []
var _competitor_scores: Dictionary = {}
var _competitor_labels: Dictionary = {}
var _competitor_archetype_labels: Dictionary = {}
var _competitor_match_stats: Dictionary = {}
var _competitor_order: Array[String] = []
var _robot_support_state: Dictionary = {}
var _last_elimination_summary := ""
var _round_status_line := ""
var _round_elapsed_seconds := 0.0
var _hud_detail_mode_override := -1
var _round_lifecycle_token := 0
var _match_restart_deadline_msec := 0
var _transition_timer: Timer = null
var _pending_transition := ""


func _ready() -> void:
	_ensure_transition_timer()


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


func _process(delta: float) -> void:
	if not _round_active or _round_reset_pending:
		return

	_round_elapsed_seconds += delta


func start_match() -> void:
	_round_lifecycle_token += 1
	_cancel_pending_transition()
	_round_number = 1
	_round_active = true
	_round_reset_pending = false
	_match_over = false
	_round_eliminated_robot_ids.clear()
	_round_elimination_order_by_robot_id.clear()
	_round_elimination_recap_entries.clear()
	_last_elimination_summary = ""
	_competitor_scores.clear()
	_competitor_labels.clear()
	_competitor_archetype_labels.clear()
	_competitor_match_stats.clear()
	_competitor_order.clear()
	_robot_support_state.clear()

	for robot in registered_robots:
		if is_instance_valid(robot):
			_register_competitor(robot)

	_round_elapsed_seconds = 0.0
	_match_restart_deadline_msec = 0
	_round_status_line = "Ronda %s en juego" % _round_number
	round_started.emit(_round_number)


func is_match_over() -> bool:
	return _match_over


func is_round_active() -> bool:
	return _round_active


func is_round_reset_pending() -> bool:
	return _round_reset_pending


func get_round_status_line() -> String:
	return _round_status_line


func get_last_elimination_summary() -> String:
	return _last_elimination_summary


func get_hud_detail_mode() -> MatchConfig.HudDetailMode:
	if _hud_detail_mode_override >= 0:
		return _hud_detail_mode_override
	if match_config == null:
		return MatchConfig.HudDetailMode.EXPLICIT

	return match_config.hud_detail_mode


func get_hud_detail_mode_label() -> String:
	return "HUD contextual" if is_contextual_hud_enabled() else "HUD explicito"


func cycle_hud_detail_mode() -> MatchConfig.HudDetailMode:
	var next_mode := MatchConfig.HudDetailMode.CONTEXTUAL
	if is_contextual_hud_enabled():
		next_mode = MatchConfig.HudDetailMode.EXPLICIT

	_hud_detail_mode_override = next_mode
	return next_mode


func is_contextual_hud_enabled() -> bool:
	return get_hud_detail_mode() == MatchConfig.HudDetailMode.CONTEXTUAL


func get_team_score(team_id: int) -> int:
	return int(_competitor_scores.get(_get_team_competitor_key(team_id), 0))


func get_round_state_lines() -> Array[String]:
	var lines: Array[String] = []
	var contextual_hud := is_contextual_hud_enabled()
	lines.append(get_round_status_line())
	if not contextual_hud:
		lines.append("Modo | %s" % get_match_mode_label())
		lines.append("Objetivo | Primero a %s" % get_rounds_to_win())
	var score_line := _build_score_summary_line()
	if score_line != "":
		lines.append(score_line)
	var restart_prompt_line := get_match_restart_prompt_line()
	if restart_prompt_line != "":
		lines.append(restart_prompt_line)
	var recap_line := get_round_recap_line()
	if recap_line != "":
		lines.append(recap_line)
	if _last_elimination_summary != "":
		lines.append("Ultima baja | %s" % _last_elimination_summary)
	if is_space_reduction_active():
		lines.append("Arena cerrandose | %s%%" % int(round(get_current_play_area_scale() * 100.0)))
	return lines


func is_progressive_space_reduction_enabled() -> bool:
	if match_config == null:
		return false

	return match_config.progressive_space_reduction and float(match_config.round_time_seconds) > 0.0


func get_rounds_to_win() -> int:
	if match_config == null:
		return 1

	return max(1, match_config.rounds_to_win)


func get_match_mode_label() -> String:
	return "FFA" if match_mode == MatchMode.FFA else "Equipos"


func get_current_play_area_scale() -> float:
	if not _round_active or _round_reset_pending:
		return 1.0
	if not is_progressive_space_reduction_enabled():
		return 1.0

	var round_duration := maxf(float(match_config.round_time_seconds), 0.01)
	var round_progress := clampf(_round_elapsed_seconds / round_duration, 0.0, 1.0)
	if round_progress <= space_reduction_start_ratio:
		return 1.0

	var shrink_window := maxf(1.0 - space_reduction_start_ratio, 0.01)
	var shrink_progress := clampf((round_progress - space_reduction_start_ratio) / shrink_window, 0.0, 1.0)
	return lerpf(1.0, space_reduction_min_scale, shrink_progress)


func is_space_reduction_active() -> bool:
	return get_current_play_area_scale() < 0.999


func get_alive_robots() -> Array[RobotBase]:
	var alive: Array[RobotBase] = []
	for robot in registered_robots:
		if is_instance_valid(robot) and not robot.is_fully_disabled() and not is_robot_eliminated(robot):
			alive.append(robot)

	return alive


func get_robot_status_lines() -> Array[String]:
	var lines: Array[String] = []
	var contextual_hud := is_contextual_hud_enabled()
	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue

		lines.append(_build_robot_status_line(robot, contextual_hud))

	return lines


func is_robot_eliminated(robot: RobotBase) -> bool:
	if robot == null:
		return false

	return _round_eliminated_robot_ids.has(robot.get_instance_id())


func get_round_recap_line() -> String:
	if _round_active:
		return ""
	if _round_elimination_recap_entries.is_empty():
		return ""

	return "Resumen | %s" % " -> ".join(_round_elimination_recap_entries)


func get_round_recap_panel_title() -> String:
	if _round_active:
		return ""

	return "Resultado de partida" if _match_over else "Cierre de ronda"


func get_round_recap_panel_lines() -> Array[String]:
	if _round_active:
		return []

	var lines: Array[String] = []
	if _round_status_line != "":
		lines.append("Decision | %s" % _round_status_line)

	var score_line := _build_score_summary_line()
	if score_line != "":
		lines.append(score_line)
	if _match_over:
		lines.append_array(_build_match_stats_lines())

	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue

		lines.append(_build_robot_recap_panel_line(robot))

	var restart_prompt_line := get_match_restart_prompt_line()
	if restart_prompt_line != "":
		lines.append(restart_prompt_line)

	return lines


func get_match_result_title() -> String:
	if not _match_over:
		return ""

	return "Partida cerrada"


func get_match_result_lines() -> Array[String]:
	if not _match_over:
		return []

	var lines: Array[String] = []
	if _round_status_line != "":
		lines.append(_round_status_line)

	var score_line := _build_score_summary_line()
	if score_line != "":
		lines.append(score_line)
	lines.append_array(_build_match_stats_lines())

	if _last_elimination_summary != "":
		lines.append("Cierre | %s" % _last_elimination_summary)

	var restart_prompt_line := get_match_restart_prompt_line()
	if restart_prompt_line != "":
		lines.append(restart_prompt_line)

	return lines


func get_match_restart_time_left() -> float:
	if not _match_over:
		return 0.0
	if _match_restart_deadline_msec <= 0:
		return 0.0

	var remaining_msec: int = maxi(_match_restart_deadline_msec - Time.get_ticks_msec(), 0)
	return float(remaining_msec) / 1000.0


func get_match_restart_prompt_line() -> String:
	if not _match_over:
		return ""

	return "Reinicio | F5 ahora o %.1fs" % snappedf(get_match_restart_time_left(), 0.1)


func set_robot_support_state(robot: RobotBase, state_label: String) -> void:
	if robot == null:
		return

	var robot_id := robot.get_instance_id()
	if state_label == "":
		_robot_support_state.erase(robot_id)
		return

	_robot_support_state[robot_id] = state_label


func clear_robot_support_state(robot: RobotBase) -> void:
	set_robot_support_state(robot, "")


func get_robot_support_state(robot: RobotBase) -> String:
	if robot == null:
		return ""

	return str(_robot_support_state.get(robot.get_instance_id(), ""))


func request_match_restart() -> bool:
	if not _match_over:
		return false

	_round_lifecycle_token += 1
	_cancel_pending_transition()
	_restart_match()
	return true


func record_part_restoration(restored_robot: RobotBase, restored_by: RobotBase) -> void:
	if restored_robot == null or restored_by == null:
		return
	if not _round_active or _round_reset_pending:
		return
	if restored_by == restored_robot:
		return

	_increment_robot_match_stat(restored_by, "rescues")


func record_part_loss(robot: RobotBase, part_name: String) -> void:
	if robot == null:
		return
	if not _round_active or _round_reset_pending:
		return
	if not RobotBase.BODY_PARTS.has(part_name):
		return

	_increment_robot_match_stat(robot, "parts_lost")
	if part_name.contains("arm"):
		_increment_robot_match_stat(robot, "arms_lost")
		return
	if part_name.contains("leg"):
		_increment_robot_match_stat(robot, "legs_lost")


func record_edge_pickup_collection(robot: RobotBase) -> void:
	if robot == null:
		return
	if not _round_active or _round_reset_pending:
		return

	_increment_robot_match_stat(robot, "edge_pickups")


func record_robot_elimination(robot: RobotBase, cause: EliminationCause) -> String:
	if robot == null:
		return ""
	if not _round_active or _round_reset_pending:
		return ""

	var robot_id := robot.get_instance_id()
	if _round_eliminated_robot_ids.has(robot_id):
		return ""

	_round_eliminated_robot_ids[robot_id] = cause
	_round_elimination_order_by_robot_id[robot_id] = _round_elimination_order_by_robot_id.size() + 1
	_round_elimination_recap_entries.append(_build_compact_elimination_summary(robot, cause))
	_last_elimination_summary = _build_elimination_summary(robot, cause)
	_record_elimination_stats(robot, cause)
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


func _build_robot_status_line(robot: RobotBase, contextual_hud: bool) -> String:
	var control_label := "P%s" % robot.player_index if robot.is_player_controlled else "CPU"
	var state_label := "Activo"
	var state_detail := ""
	if is_robot_eliminated(robot):
		state_label = "Fuera"
		state_detail = _get_elimination_cause_label(_get_robot_elimination_cause(robot))
	elif robot.is_disabled_state():
		state_label = "Inutilizado"
		var explosion_time_left := robot.get_disabled_explosion_time_left()
		if explosion_time_left > 0.0:
			state_detail = "explota %.1fs" % snappedf(explosion_time_left, 0.1)
			if robot.is_disabled_explosion_unstable():
				state_detail = "inestable | %s" % state_detail

	var state_segment := state_label
	if state_detail != "":
		state_segment += " | %s" % state_detail

	var segments: Array[String] = [state_segment]
	if contextual_hud:
		if robot.control_mode == RobotBase.ControlMode.HARD:
			segments.append("Hard")
		if robot.get_active_part_count() < RobotBase.BODY_PARTS.size():
			segments.append("%s/%s partes" % [robot.get_active_part_count(), RobotBase.BODY_PARTS.size()])
		if not robot.is_energy_balanced():
			segments.append(robot.get_energy_state_summary())
	else:
		var mode_label := "Hard" if robot.control_mode == RobotBase.ControlMode.HARD else "Easy"
		segments = [mode_label, state_segment, "%s/%s partes" % [robot.get_active_part_count(), RobotBase.BODY_PARTS.size()]]
		if robot.is_player_controlled:
			segments.append(robot.get_input_hint())
		segments.append(robot.get_energy_state_summary())
	var core_skill_summary := robot.get_core_skill_status_summary()
	if core_skill_summary != "":
		segments.append(core_skill_summary)
	if robot.is_energy_surge_active():
		segments.append("energia")
	if robot.is_mobility_boost_active():
		segments.append("impulso")
	if robot.is_control_zone_suppressed():
		segments.append("zona")
	if robot.has_carried_item():
		segments.append("item %s" % robot.get_carried_item_display_name())
	if robot.is_carrying_part():
		segments.append("carga %s" % RobotBase.get_part_display_name(robot.get_carried_part_name()))
	var support_state := get_robot_support_state(robot)
	if support_state != "":
		segments.append(support_state)

	return "%s %s | %s" % [control_label, robot.get_roster_display_name(), " | ".join(segments)]


func _build_robot_recap_panel_line(robot: RobotBase) -> String:
	if robot == null:
		return ""

	var robot_id := robot.get_instance_id()
	if _round_eliminated_robot_ids.has(robot_id):
		var cause_label := _get_elimination_cause_label(_get_robot_elimination_cause(robot))
		var elimination_order := int(_round_elimination_order_by_robot_id.get(robot_id, 0))
		return "%s | baja %s | %s" % [robot.display_name, elimination_order, cause_label]

	if robot.is_disabled_state():
		var detail := "inutilizado"
		if robot.is_disabled_explosion_unstable():
			detail = "inutilizado | inestable"
		return "%s | %s" % [robot.display_name, detail]

	return "%s | sigue en pie" % robot.display_name


func _register_competitor(robot: RobotBase) -> void:
	var competitor_key := _get_competitor_key(robot)
	if competitor_key == "":
		return

	if not _competitor_order.has(competitor_key):
		_competitor_order.append(competitor_key)

	if not _competitor_scores.has(competitor_key):
		_competitor_scores[competitor_key] = 0

	_competitor_labels[competitor_key] = _get_competitor_label(robot)
	_competitor_archetype_labels[competitor_key] = robot.get_archetype_label()
	_ensure_competitor_match_stats(competitor_key)


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
	var cause_label := "cayo al vacio"
	if cause == EliminationCause.EXPLOSION:
		cause_label = "explosiono tras quedar inutilizado"
	elif cause == EliminationCause.UNSTABLE_EXPLOSION:
		cause_label = "exploto en sobrecarga"
	return "%s %s" % [robot.display_name, cause_label]


func _build_match_stats_lines() -> Array[String]:
	if not _match_over:
		return []

	var lines: Array[String] = []
	for competitor_key in _competitor_order:
		var stats_line := _build_competitor_match_stats_line(competitor_key)
		if stats_line == "":
			continue

		lines.append(stats_line)

	return lines


func _build_competitor_match_stats_line(competitor_key: String) -> String:
	var stats := _get_competitor_match_stats(competitor_key)
	if stats.is_empty():
		return ""

	var segments: Array[String] = []
	var rescues := int(stats.get("rescues", 0))
	if rescues > 0:
		segments.append("rescates %s" % rescues)
	var edge_pickups := int(stats.get("edge_pickups", 0))
	if edge_pickups > 0:
		segments.append("borde %s" % edge_pickups)
	var part_loss_segment := _build_part_loss_stats_segment(stats)
	if part_loss_segment != "":
		segments.append(part_loss_segment)
	segments.append(_build_elimination_stats_segment(stats))
	return "Stats | %s | %s" % [_get_competitor_label_from_key(competitor_key), " | ".join(segments)]


func _build_part_loss_stats_segment(stats: Dictionary) -> String:
	var total_parts_lost := int(stats.get("parts_lost", 0))
	if total_parts_lost <= 0:
		return ""

	var breakdown: Array[String] = []
	var arms_lost := int(stats.get("arms_lost", 0))
	if arms_lost > 0:
		breakdown.append(_build_plural_segment(arms_lost, "brazo", "brazos"))
	var legs_lost := int(stats.get("legs_lost", 0))
	if legs_lost > 0:
		breakdown.append(_build_plural_segment(legs_lost, "pierna", "piernas"))

	if breakdown.is_empty():
		return "partes perdidas %s" % total_parts_lost

	return "partes perdidas %s (%s)" % [total_parts_lost, ", ".join(breakdown)]


func _build_elimination_stats_segment(stats: Dictionary) -> String:
	var total_eliminations := int(stats.get("eliminations", 0))
	if total_eliminations <= 0:
		return "bajas 0"

	var breakdown: Array[String] = []
	var void_eliminations := int(stats.get("void_eliminations", 0))
	if void_eliminations > 0:
		breakdown.append("%s vacio" % void_eliminations)
	var explosion_eliminations := int(stats.get("explosion_eliminations", 0))
	if explosion_eliminations > 0:
		breakdown.append("%s explosion" % explosion_eliminations)
	var unstable_eliminations := int(stats.get("unstable_explosion_eliminations", 0))
	if unstable_eliminations > 0:
		breakdown.append("%s explosion inestable" % unstable_eliminations)

	if breakdown.is_empty():
		return "bajas %s" % total_eliminations

	return "bajas %s (%s)" % [total_eliminations, ", ".join(breakdown)]


func _build_plural_segment(amount: int, singular_label: String, plural_label: String) -> String:
	if amount == 1:
		return "1 %s" % singular_label

	return "%s %s" % [amount, plural_label]


func _build_compact_elimination_summary(robot: RobotBase, cause: EliminationCause) -> String:
	return "%s %s" % [robot.display_name, _get_elimination_cause_label(cause)]


func _get_robot_elimination_cause(robot: RobotBase) -> int:
	if robot == null:
		return -1
	if not _round_eliminated_robot_ids.has(robot.get_instance_id()):
		return -1

	return int(_round_eliminated_robot_ids[robot.get_instance_id()])


func _get_elimination_cause_label(cause: int) -> String:
	if cause == EliminationCause.VOID:
		return "vacio"
	if cause == EliminationCause.EXPLOSION:
		return "explosion"
	if cause == EliminationCause.UNSTABLE_EXPLOSION:
		return "explosion inestable"

	return ""


func _ensure_competitor_match_stats(competitor_key: String) -> void:
	if competitor_key == "":
		return
	if _competitor_match_stats.has(competitor_key):
		return

	_competitor_match_stats[competitor_key] = {
		"rescues": 0,
		"edge_pickups": 0,
		"parts_lost": 0,
		"arms_lost": 0,
		"legs_lost": 0,
		"eliminations": 0,
		"void_eliminations": 0,
		"explosion_eliminations": 0,
		"unstable_explosion_eliminations": 0,
	}


func _get_competitor_match_stats(competitor_key: String) -> Dictionary:
	_ensure_competitor_match_stats(competitor_key)
	return _competitor_match_stats.get(competitor_key, {})


func _increment_robot_match_stat(robot: RobotBase, stat_name: String, amount: int = 1) -> void:
	if robot == null or amount <= 0:
		return

	var competitor_key := _get_competitor_key(robot)
	if competitor_key == "":
		return

	_increment_competitor_match_stat(competitor_key, stat_name, amount)


func _increment_competitor_match_stat(competitor_key: String, stat_name: String, amount: int = 1) -> void:
	if competitor_key == "" or amount <= 0:
		return

	_ensure_competitor_match_stats(competitor_key)
	var stats := _get_competitor_match_stats(competitor_key)
	stats[stat_name] = int(stats.get(stat_name, 0)) + amount
	_competitor_match_stats[competitor_key] = stats


func _record_elimination_stats(robot: RobotBase, cause: EliminationCause) -> void:
	if robot == null:
		return

	_increment_robot_match_stat(robot, "eliminations")
	match cause:
		EliminationCause.VOID:
			_increment_robot_match_stat(robot, "void_eliminations")
		EliminationCause.EXPLOSION:
			_increment_robot_match_stat(robot, "explosion_eliminations")
		EliminationCause.UNSTABLE_EXPLOSION:
			_increment_robot_match_stat(robot, "unstable_explosion_eliminations")


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
	var winner_score := int(_competitor_scores.get(winner_key, 0)) + 1
	_competitor_scores[winner_key] = winner_score
	if winner_score >= get_rounds_to_win():
		_finish_match_with_winner(winner_key, winner_score)
		return

	_round_status_line = "%s gana la ronda %s" % [_get_competitor_label_from_key(winner_key), _round_number]
	_schedule_round_reset()


func _finish_round_draw() -> void:
	_round_active = false
	_round_reset_pending = true
	_round_status_line = "Ronda %s sin ganador" % _round_number
	_schedule_round_reset()


func _finish_match_with_winner(winner_key: String, winner_score: int) -> void:
	_match_over = true
	_match_restart_deadline_msec = Time.get_ticks_msec() + int(round(match_restart_delay * 1000.0))
	_round_status_line = "%s gana la partida %s-%s" % [
		_get_competitor_label_from_key(winner_key),
		winner_score,
		_get_highest_losing_score(winner_key),
	]
	_schedule_match_restart()


func _schedule_round_reset() -> void:
	_ensure_transition_timer()
	_pending_transition = "round_reset"
	_transition_timer.start(round_reset_delay)


func _schedule_match_restart() -> void:
	_ensure_transition_timer()
	_pending_transition = "match_restart"
	_transition_timer.start(match_restart_delay)


func _reset_round() -> void:
	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue

		robot.reset_to_spawn()

	_round_eliminated_robot_ids.clear()
	_round_elimination_order_by_robot_id.clear()
	_round_elimination_recap_entries.clear()
	_last_elimination_summary = ""
	_robot_support_state.clear()
	_round_number += 1
	_round_active = true
	_round_reset_pending = false
	_round_elapsed_seconds = 0.0
	_match_restart_deadline_msec = 0
	_round_status_line = "Ronda %s en juego" % _round_number
	round_started.emit(_round_number)


func _restart_match() -> void:
	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue

		robot.reset_to_spawn()

	_match_restart_deadline_msec = 0
	start_match()


func _ensure_transition_timer() -> void:
	if is_instance_valid(_transition_timer):
		return

	_transition_timer = Timer.new()
	_transition_timer.name = "TransitionTimer"
	_transition_timer.one_shot = true
	add_child(_transition_timer)
	_transition_timer.timeout.connect(_on_transition_timer_timeout)


func _cancel_pending_transition() -> void:
	_pending_transition = ""
	if is_instance_valid(_transition_timer):
		_transition_timer.stop()


func _on_transition_timer_timeout() -> void:
	var pending_transition := _pending_transition
	_pending_transition = ""
	if pending_transition == "round_reset":
		_reset_round()
	elif pending_transition == "match_restart":
		_restart_match()


func _build_score_summary_line() -> String:
	var score_parts: Array[String] = []
	for competitor_key in _competitor_order:
		var competitor_label := _get_competitor_label_from_key(competitor_key)
		var competitor_score := int(_competitor_scores.get(competitor_key, 0))
		var archetype_label := str(_competitor_archetype_labels.get(competitor_key, ""))
		if match_mode == MatchMode.FFA and archetype_label != "":
			score_parts.append("%s %s [%s]" % [competitor_label, competitor_score, archetype_label])
			continue

		score_parts.append("%s %s" % [competitor_label, competitor_score])

	return "Marcador | %s" % " | ".join(score_parts)


func _get_highest_losing_score(winner_key: String) -> int:
	var highest_score := 0
	for competitor_key in _competitor_order:
		if competitor_key == winner_key:
			continue

		highest_score = max(highest_score, int(_competitor_scores.get(competitor_key, 0)))

	return highest_score
