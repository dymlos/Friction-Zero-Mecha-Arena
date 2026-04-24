extends Node
class_name MatchController

const MatchConfig = preload("res://scripts/systems/match_config.gd")
const PostMatchEvent = preload("res://scripts/systems/post_match_event.gd")
const PostMatchReview = preload("res://scripts/systems/post_match_review.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")

signal round_started(round_number: int)

enum MatchMode { FFA, TEAMS }
enum EliminationCause { VOID, EXPLOSION, UNSTABLE_EXPLOSION }

const SUPPORT_PAYLOAD_LABELS := {
	"stabilizer": "estabilizador",
	"surge": "energia",
	"mobility": "movilidad",
	"interference": "interferencia",
}
const MAX_POST_MATCH_STORY_LINES := 2
const MAX_POST_MATCH_LOSER_LINES := 1
const MAX_POST_MATCH_SNIPPET_LINES := 3
const MAX_BASE_MATCH_RESULT_LINES := 22
const OPTIONAL_RESULT_LINE_PREFIXES := [
	"Cierre ronda |",
	"Causa bajas |",
	"Resumen |",
	"Momento inicial |",
	"Momento final |",
	"Cierre |",
]
const REQUIRED_RESULT_LINE_PREFIXES := [
	"Lectura |",
	"Replay |",
	"Stats |",
]

@export var match_mode: MatchMode = MatchMode.FFA
@export var mode_variant_id := MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE
@export var match_config: MatchConfig
@export_range(0.2, 6.0, 0.1) var round_reset_delay := 1.8
@export_range(0.5, 8.0, 0.1) var match_restart_delay := 2.6
# Nodo-level override used as fallback when this scene/binder does not provide MatchConfig.
# Scenes that inherit this script can tune round intro directly en este campo.
@export_range(0.0, 3.0, 0.05) var round_intro_duration := 0.0
@export_range(0.0, 0.95, 0.05) var space_reduction_start_ratio := 0.55
@export_range(0.0, 8.0, 0.1) var space_reduction_warning_seconds := 3.5
@export_range(0.35, 1.0, 0.05) var space_reduction_min_scale := 0.55

var registered_robots: Array[RobotBase] = []

var _round_number := 1
var _round_active := false
var _round_reset_pending := false
var _match_over := false
var _round_eliminated_robot_ids: Dictionary = {}
var _round_elimination_source_robot_ids: Dictionary = {}
var _round_elimination_order_by_robot_id: Dictionary = {}
var _round_elimination_cause_counts: Dictionary = {}
var _round_elimination_recap_entries: Array[String] = []
var _round_elimination_highlight_entries: Array[String] = []
var _match_closing_cause_counts: Dictionary = {}
var _competitor_scores: Dictionary = {}
var _competitor_labels: Dictionary = {}
var _competitor_archetype_labels: Dictionary = {}
var _competitor_match_stats: Dictionary = {}
var _competitor_order: Array[String] = []
var _robot_support_state: Dictionary = {}
var _round_support_usage_by_competitor: Dictionary = {}
var _round_support_highlight_by_competitor: Dictionary = {}
var _last_elimination_summary := ""
var _round_status_line := ""
var _round_elapsed_seconds := 0.0
var _round_intro_remaining := 0.0
var _hud_detail_mode_override := -1
var _round_lifecycle_token := 0
var _match_restart_deadline_msec := 0
var _match_decided_rounds := 0
var _match_decided_rounds_with_support := 0
var _paused_by_owner := false
var _pause_owner_slot := 0
var _transition_timer: Timer = null
var _pending_transition := ""
var _last_round_closing_cause := -1
var _last_round_was_draw := false
var _runtime_match_restart_enabled := true
var _post_match_review := PostMatchReview.new()
var _post_match_event_sequence := 0
var _last_match_close_event: Dictionary = {}
var _ffa_aftermath_context_line := ""


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

	if _round_intro_remaining > 0.0:
		_round_intro_remaining = maxf(_round_intro_remaining - delta, 0.0)
		if _round_intro_remaining > 0.0:
			_round_status_line = _build_round_intro_status_line()
		else:
			_round_status_line = "Ronda %s en juego" % _round_number
		return

	_round_elapsed_seconds += delta


func start_match() -> void:
	mode_variant_id = MatchModeVariantCatalog.sanitize_variant_id(match_mode, mode_variant_id)
	_round_lifecycle_token += 1
	_cancel_pending_transition()
	_round_number = 1
	_round_active = true
	_round_reset_pending = false
	_match_over = false
	_round_eliminated_robot_ids.clear()
	_round_elimination_source_robot_ids.clear()
	_round_elimination_order_by_robot_id.clear()
	_round_elimination_cause_counts.clear()
	_round_elimination_recap_entries.clear()
	_round_elimination_highlight_entries.clear()
	_match_closing_cause_counts.clear()
	_last_elimination_summary = ""
	_round_support_usage_by_competitor.clear()
	_round_support_highlight_by_competitor.clear()
	_competitor_scores.clear()
	_competitor_labels.clear()
	_competitor_archetype_labels.clear()
	_competitor_match_stats.clear()
	_match_decided_rounds = 0
	_match_decided_rounds_with_support = 0
	_paused_by_owner = false
	_pause_owner_slot = 0
	_competitor_order.clear()
	_robot_support_state.clear()
	_last_round_closing_cause = -1
	_last_round_was_draw = false
	_post_match_review.reset()
	_post_match_event_sequence = 0
	_last_match_close_event.clear()
	_ffa_aftermath_context_line = ""

	for robot in registered_robots:
		if is_instance_valid(robot):
			_register_competitor(robot)

	_round_elapsed_seconds = 0.0
	_round_intro_remaining = _resolve_round_intro_duration()
	_match_restart_deadline_msec = 0
	_round_status_line = _build_round_intro_status_line() if is_round_intro_active() else "Ronda %s en juego" % _round_number
	round_started.emit(_round_number)


func is_match_over() -> bool:
	return _match_over


func is_round_active() -> bool:
	return _round_active


func is_round_reset_pending() -> bool:
	return _round_reset_pending


func is_round_intro_active() -> bool:
	return _round_active and not _round_reset_pending and _round_intro_remaining > 0.0


func get_round_number() -> int:
	return _round_number


func get_round_intro_time_left() -> float:
	return maxf(_round_intro_remaining, 0.0)


func get_round_status_line() -> String:
	return _round_status_line


func get_last_elimination_summary() -> String:
	return _last_elimination_summary


func get_hud_detail_mode() -> MatchConfig.HudDetailMode:
	if _hud_detail_mode_override >= 0:
		return _hud_detail_mode_override
	if match_config == null:
		return MatchConfig.HudDetailMode.EXPLICIT

	return match_config.get_default_hud_detail_mode(match_mode == MatchMode.FFA)


func get_hud_detail_mode_label() -> String:
	return "Ayuda limpia" if is_contextual_hud_enabled() else "Ayuda completa"


func cycle_hud_detail_mode() -> MatchConfig.HudDetailMode:
	var next_mode := MatchConfig.HudDetailMode.CONTEXTUAL
	if is_contextual_hud_enabled():
		next_mode = MatchConfig.HudDetailMode.EXPLICIT

	_hud_detail_mode_override = next_mode
	return next_mode


func apply_runtime_hud_detail_mode(next_mode: int) -> void:
	if next_mode < 0:
		_hud_detail_mode_override = -1
		return

	_hud_detail_mode_override = next_mode


func get_runtime_hud_detail_mode() -> int:
	return int(get_hud_detail_mode())


func set_runtime_match_restart_enabled(is_enabled: bool) -> void:
	_runtime_match_restart_enabled = is_enabled


func is_match_restart_enabled() -> bool:
	return _runtime_match_restart_enabled


func is_contextual_hud_enabled() -> bool:
	return get_hud_detail_mode() == MatchConfig.HudDetailMode.CONTEXTUAL


func get_team_score(team_id: int) -> int:
	return int(_competitor_scores.get(_get_team_competitor_key(team_id), 0))


func get_round_state_lines() -> Array[String]:
	var lines: Array[String] = []
	var contextual_hud := is_contextual_hud_enabled()
	lines.append(get_round_status_line())
	var pause_prompt_line := get_pause_prompt_line()
	if pause_prompt_line != "":
		lines.append(pause_prompt_line)
	if not contextual_hud:
		lines.append("Modo | %s" % get_match_mode_label())
		var target_score_line := _build_target_score_line()
		if target_score_line != "":
			lines.append(target_score_line)
	var score_line := _build_score_summary_line()
	if score_line != "":
		lines.append(score_line)
	var standings_line := _build_ffa_standings_line()
	if standings_line != "":
		lines.append(standings_line)
	var tiebreaker_line := _build_ffa_tiebreaker_line()
	if tiebreaker_line != "":
		lines.append(tiebreaker_line)
	if _ffa_aftermath_context_line != "" and match_mode == MatchMode.FFA and _round_active and not _round_reset_pending:
		lines.append(_ffa_aftermath_context_line)
	if contextual_hud:
		return lines

	var restart_prompt_line := get_match_restart_prompt_line()
	if restart_prompt_line != "":
		lines.append(restart_prompt_line)
	var recap_line := get_round_recap_line()
	if recap_line != "":
		lines.append(recap_line)
	if _last_elimination_summary != "":
		lines.append("Ultima baja | %s" % _last_elimination_summary)
	var elimination_cause_line := _build_round_elimination_cause_summary_line()
	if elimination_cause_line != "":
		lines.append(elimination_cause_line)
	var space_reduction_warning_line := _build_space_reduction_warning_line()
	if space_reduction_warning_line != "":
		lines.append(space_reduction_warning_line)
	elif is_space_reduction_active():
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
	if match_mode == MatchMode.FFA and is_last_alive_variant():
		return "FFA | Ultimo vivo"
	return "FFA" if match_mode == MatchMode.FFA else "Equipos"


func set_mode_variant_id(next_variant_id: String) -> void:
	mode_variant_id = MatchModeVariantCatalog.sanitize_variant_id(match_mode, next_variant_id)


func get_mode_variant_id() -> String:
	return MatchModeVariantCatalog.sanitize_variant_id(match_mode, mode_variant_id)


func is_last_alive_variant() -> bool:
	return match_mode == MatchMode.FFA and MatchModeVariantCatalog.is_last_alive(get_mode_variant_id())


func get_mode_variant_label() -> String:
	return MatchModeVariantCatalog.get_variant_label(match_mode, get_mode_variant_id())


func get_current_play_area_scale() -> float:
	if not _round_active or _round_reset_pending:
		return 1.0
	if is_round_intro_active():
		return 1.0
	if not is_progressive_space_reduction_enabled():
		return 1.0

	var round_duration := maxf(float(match_config.round_time_seconds), 0.01)
	var round_progress := clampf(_round_elapsed_seconds / round_duration, 0.0, 1.0)
	var start_ratio := _get_space_reduction_start_ratio()
	if round_progress <= start_ratio:
		return 1.0

	var shrink_window := maxf(1.0 - start_ratio, 0.01)
	var shrink_progress := clampf((round_progress - start_ratio) / shrink_window, 0.0, 1.0)
	return lerpf(1.0, _get_space_reduction_min_scale(), shrink_progress)


func is_space_reduction_active() -> bool:
	return get_current_play_area_scale() < 0.999


func get_space_reduction_warning_strength() -> float:
	if not _round_active or _round_reset_pending:
		return 0.0
	if is_round_intro_active():
		return 0.0
	if is_space_reduction_active():
		return 0.0
	if not is_progressive_space_reduction_enabled():
		return 0.0

	var time_until_reduction := get_time_until_space_reduction()
	if time_until_reduction <= 0.0:
		return 0.0

	var warning_window := _get_space_reduction_warning_window()
	if warning_window <= 0.0 or time_until_reduction > warning_window:
		return 0.0

	return clampf(1.0 - (time_until_reduction / warning_window), 0.0, 1.0)


func get_time_until_space_reduction() -> float:
	if not _round_active or _round_reset_pending:
		return 0.0
	if is_round_intro_active():
		return 0.0
	if not is_progressive_space_reduction_enabled():
		return 0.0

	var round_duration := maxf(float(match_config.round_time_seconds), 0.01)
	var reduction_start_time := round_duration * _get_space_reduction_start_ratio()
	return maxf(reduction_start_time - _round_elapsed_seconds, 0.0)


func _get_space_reduction_warning_window() -> float:
	var time_until_reduction := maxf(float(match_config.round_time_seconds) * _get_space_reduction_start_ratio(), 0.0)
	return minf(space_reduction_warning_seconds, time_until_reduction)


func _get_space_reduction_start_ratio() -> float:
	if match_config != null:
		return clampf(match_config.space_reduction_start_ratio, 0.0, 0.95)

	return clampf(space_reduction_start_ratio, 0.0, 0.95)


func _get_space_reduction_min_scale() -> float:
	if match_config != null:
		return clampf(match_config.space_reduction_min_scale, 0.35, 1.0)

	return clampf(space_reduction_min_scale, 0.35, 1.0)


func get_alive_robots() -> Array[RobotBase]:
	var alive: Array[RobotBase] = []
	for robot in registered_robots:
		if is_instance_valid(robot) and not robot.is_fully_disabled() and not is_robot_eliminated(robot):
			alive.append(robot)

	return alive


func get_robot_status_lines() -> Array[String]:
	var lines: Array[String] = []
	var contextual_hud := is_contextual_hud_enabled()
	for robot in _get_live_roster_ordered_robots():
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
	var target_score_line := _build_target_score_line()
	if target_score_line != "":
		lines.append(target_score_line)

	var score_line := _build_score_summary_line()
	if score_line != "":
		lines.append(score_line)
	if _match_over:
		_append_post_match_review_lines(lines, true, 1)
	var round_closing_line := _build_round_closing_line()
	if round_closing_line != "":
		lines.append(round_closing_line)
	var match_closing_cause_line := _build_match_closing_cause_summary_line()
	if match_closing_cause_line != "":
		lines.append(match_closing_cause_line)
	var closing_points_line := _build_closing_points_profile_line()
	if closing_points_line != "":
		lines.append(closing_points_line)
	var decisive_closing_line := _build_decisive_closing_line()
	if decisive_closing_line != "":
		lines.append(decisive_closing_line)
	var elimination_cause_line := _build_round_elimination_cause_summary_line()
	if elimination_cause_line != "":
		lines.append(elimination_cause_line)
	var standings_line := _build_ffa_standings_line()
	if standings_line != "":
		lines.append(standings_line)
	var tiebreaker_line := _build_ffa_tiebreaker_line()
	if tiebreaker_line != "":
		lines.append(tiebreaker_line)
	var recap_line := get_round_recap_line()
	if recap_line != "":
		lines.append(recap_line)
	if _match_over:
		_append_post_match_snippet_lines(lines)
	if _match_over:
		lines.append_array(_build_match_stats_lines())
	lines.append_array(_build_round_highlight_lines())

	for robot in _get_recap_ordered_robots():
		if not is_instance_valid(robot):
			continue

		lines.append(_build_robot_recap_panel_line(robot))

	var closing_elimination_line := _build_closing_elimination_line()
	if closing_elimination_line != "":
		lines.append(closing_elimination_line)

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
	var target_score_line := _build_target_score_line()
	if target_score_line != "":
		lines.append(target_score_line)

	var score_line := _build_score_summary_line()
	if score_line != "":
		lines.append(score_line)
	_append_post_match_review_lines(lines, true, MAX_POST_MATCH_STORY_LINES)
	var match_closing_cause_line := _build_match_closing_cause_summary_line()
	if match_closing_cause_line != "":
		lines.append(match_closing_cause_line)
	var closing_points_line := _build_closing_points_profile_line()
	if closing_points_line != "":
		lines.append(closing_points_line)
	var decisive_closing_line := _build_decisive_closing_line()
	if decisive_closing_line != "":
		lines.append(decisive_closing_line)
	var elimination_cause_line := _build_round_elimination_cause_summary_line()
	if elimination_cause_line != "":
		lines.append(elimination_cause_line)
	var standings_line := _build_ffa_standings_line()
	if standings_line != "":
		lines.append(standings_line)
	var tiebreaker_line := _build_ffa_tiebreaker_line()
	if tiebreaker_line != "":
		lines.append(tiebreaker_line)
	var recap_line := get_round_recap_line()
	if recap_line != "":
		lines.append(recap_line)
	_append_post_match_snippet_lines(lines)
	lines.append_array(_build_match_stats_lines())
	lines.append_array(_build_round_highlight_lines())
	for robot in _get_recap_ordered_robots():
		if not is_instance_valid(robot):
			continue

		lines.append(_build_robot_recap_panel_line(robot))

	var closing_elimination_line := _build_closing_elimination_line()
	if closing_elimination_line != "":
		lines.append(closing_elimination_line)

	var restart_prompt_line := get_match_restart_prompt_line()
	if restart_prompt_line != "":
		lines.append(restart_prompt_line)

	return _apply_match_result_line_budget(lines)


func get_post_match_review_summary() -> Dictionary:
	return _post_match_review.build_review(_build_post_match_context())


func get_post_match_review_lines() -> Array[String]:
	get_post_match_review_summary()
	return _post_match_review.get_story_lines()


func get_post_match_snippet_lines() -> Array[String]:
	get_post_match_review_summary()
	return _post_match_review.get_snippet_lines()


func get_post_match_loser_reading_lines() -> Array[String]:
	get_post_match_review_summary()
	return _post_match_review.get_loser_reading_lines()


func _append_unique_lines(target: Array[String], source: Array[String], max_count: int = -1) -> void:
	var appended := 0
	for line in source:
		if max_count >= 0 and appended >= max_count:
			return
		if line == "":
			continue
		if target.has(line):
			continue

		target.append(line)
		appended += 1


func _append_post_match_review_lines(
	lines: Array[String],
	include_loser_reading: bool,
	story_line_limit: int = MAX_POST_MATCH_STORY_LINES
) -> void:
	_append_unique_lines(lines, get_post_match_review_lines(), story_line_limit)
	if include_loser_reading:
		_append_unique_lines(lines, get_post_match_loser_reading_lines(), MAX_POST_MATCH_LOSER_LINES)


func _append_post_match_snippet_lines(lines: Array[String]) -> void:
	_append_unique_lines(lines, get_post_match_snippet_lines(), MAX_POST_MATCH_SNIPPET_LINES)


func _apply_match_result_line_budget(lines: Array[String]) -> Array[String]:
	if lines.size() <= MAX_BASE_MATCH_RESULT_LINES:
		return lines

	var trimmed := lines.duplicate()
	for prefix in OPTIONAL_RESULT_LINE_PREFIXES:
		if trimmed.size() <= MAX_BASE_MATCH_RESULT_LINES:
			break
		_remove_first_line_with_prefix(trimmed, prefix)

	return trimmed


func _remove_first_line_with_prefix(lines: Array[String], prefix: String) -> void:
	for index in range(lines.size()):
		if lines[index].begins_with(prefix):
			lines.remove_at(index)
			return


func get_match_restart_time_left() -> float:
	if not _match_over or not is_match_restart_enabled():
		return 0.0
	if _match_restart_deadline_msec <= 0:
		return 0.0

	var remaining_msec: int = maxi(_match_restart_deadline_msec - Time.get_ticks_msec(), 0)
	return float(remaining_msec) / 1000.0


func get_match_restart_prompt_line() -> String:
	if not _match_over or not is_match_restart_enabled():
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


func request_pause_restart() -> void:
	_round_lifecycle_token += 1
	_cancel_pending_transition()
	_restart_match()


func set_pause_state(is_paused: bool, owner_slot: int = 0) -> void:
	_paused_by_owner = is_paused
	_pause_owner_slot = owner_slot if is_paused else 0


func is_paused_by_owner() -> bool:
	return _paused_by_owner


func get_pause_owner_slot() -> int:
	return _pause_owner_slot


func get_pause_prompt_line() -> String:
	if not _paused_by_owner or _pause_owner_slot <= 0:
		return ""

	return "Pausa | P%s reanuda | F5 reinicia" % _pause_owner_slot


func record_part_restoration(restored_robot: RobotBase, restored_by: RobotBase) -> void:
	if restored_robot == null or restored_by == null:
		return
	if not _round_active or _round_reset_pending:
		return
	if restored_by == restored_robot:
		return

	_increment_robot_match_stat(restored_by, "rescues")


func record_part_denial(original_robot: RobotBase, denied_by: RobotBase) -> void:
	if original_robot == null or denied_by == null:
		return
	if not _round_active or _round_reset_pending:
		return
	if denied_by == original_robot:
		return
	if denied_by.is_ally_of(original_robot):
		return

	_increment_robot_match_stat(denied_by, "denials")


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


func set_ffa_aftermath_context_line(line: String) -> void:
	_ffa_aftermath_context_line = line


func record_ffa_aftermath_collection(robot: RobotBase, payload_id: String, source_eliminated_label: String, arena_zone: String) -> void:
	if match_mode != MatchMode.FFA:
		return
	if robot == null:
		return
	if not _round_active or _round_reset_pending:
		return

	_increment_robot_match_stat(robot, "ffa_aftermath_collected")
	var competitor_key := _get_competitor_key(robot)
	_record_post_match_event(PostMatchEvent.TYPE_FFA_AFTERMATH, 65, "%s tomo botin" % robot.get_roster_display_name(), "", {
		"competitor_key": competitor_key,
		"competitor_label": _get_competitor_label_from_key(competitor_key),
		"robot_name": robot.display_name,
		"payload_id": payload_id,
		"cause_label": "botin",
		"source_eliminated_label": source_eliminated_label,
		"arena_zone": arena_zone,
	})
	match payload_id:
		"chatarra":
			_increment_robot_match_stat(robot, "ffa_aftermath_scrap")
		"carga":
			_increment_robot_match_stat(robot, "ffa_aftermath_charge")
		"impulso":
			_increment_robot_match_stat(robot, "ffa_aftermath_surge")


func record_support_pickup_collection(robot: RobotBase, payload_name: String = "") -> void:
	if match_mode != MatchMode.TEAMS:
		return
	if robot == null:
		return
	if not _round_active or _round_reset_pending:
		return

	_increment_robot_match_stat(robot, "support_pickups")
	_increment_support_payload_stat(robot, payload_name, "support_pickup")


func record_support_payload_use(robot: RobotBase, payload_name: String = "", target_robot: RobotBase = null) -> void:
	if match_mode != MatchMode.TEAMS:
		return
	if robot == null:
		return
	if not _round_active or _round_reset_pending:
		return

	_increment_robot_match_stat(robot, "support_uses")
	_increment_support_payload_stat(robot, payload_name, "support_use")
	var competitor_key := _get_competitor_key(robot)
	if competitor_key != "":
		_round_support_usage_by_competitor[competitor_key] = true
		var support_highlight := _build_support_highlight_line(robot, payload_name, target_robot)
		if support_highlight != "":
			_round_support_highlight_by_competitor[competitor_key] = support_highlight
			_record_post_match_event(PostMatchEvent.TYPE_SUPPORT, 40, support_highlight.replace("Apoyo decisivo | ", ""), "", {
				"competitor_key": competitor_key,
				"competitor_label": _get_competitor_label_from_key(competitor_key),
				"robot_name": robot.display_name,
				"target_robot_name": target_robot.display_name if is_instance_valid(target_robot) else "",
				"payload_name": payload_name,
				"decisive": false,
				"arena_zone": _get_robot_arena_zone(robot),
			})


func record_robot_elimination(
	robot: RobotBase,
	cause: EliminationCause,
	source_robot: RobotBase = null
) -> String:
	if robot == null:
		return ""
	if not _round_active or _round_reset_pending:
		return ""

	var robot_id := robot.get_instance_id()
	if _round_eliminated_robot_ids.has(robot_id):
		return ""

	_round_eliminated_robot_ids[robot_id] = cause
	if is_instance_valid(source_robot) and source_robot != robot:
		_round_elimination_source_robot_ids[robot_id] = source_robot.get_instance_id()
	_round_elimination_order_by_robot_id[robot_id] = _round_elimination_order_by_robot_id.size() + 1
	var cause_key := int(cause)
	_round_elimination_cause_counts[cause_key] = int(_round_elimination_cause_counts.get(cause_key, 0)) + 1
	_round_elimination_recap_entries.append(_build_compact_elimination_summary(robot, cause, source_robot))
	_last_elimination_summary = _build_elimination_summary(robot, cause, source_robot)
	_round_elimination_highlight_entries.append(_last_elimination_summary)
	_record_elimination_stats(robot, cause)
	robot.hold_for_round_reset()

	var winner_key := _find_last_competitor_standing()
	_record_post_match_elimination_event(robot, cause, source_robot, winner_key)
	if winner_key == "":
		if _get_remaining_competitor_count() == 0:
			_finish_round_draw()
			return _round_status_line

		_round_status_line = "Ronda %s en juego" % _round_number
		return _last_elimination_summary

	_finish_round_with_winner(winner_key, cause)
	return _round_status_line


func _build_robot_status_line(robot: RobotBase, contextual_hud: bool) -> String:
	if registered_robots.size() > 4:
		return _build_compact_robot_status_line(robot, contextual_hud)

	var control_label := "P%s" % robot.player_index if robot.is_player_controlled else "CPU"
	var support_state := get_robot_support_state(robot)
	var has_active_support := match_mode == MatchMode.TEAMS and support_state != ""
	var is_eliminated := is_robot_eliminated(robot)
	var state_label := "Activo"
	var state_detail := ""
	if is_eliminated:
		state_label = "Apoyo activo" if has_active_support else "Fuera"
		if not (contextual_hud and has_active_support):
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
	if has_active_support:
		segments = [state_label]
		if support_state != "":
			segments.append(support_state)
		if state_detail != "" and not contextual_hud:
			segments.append("baja %s" % state_detail)
	var can_show_robot_combat_state := not is_eliminated and not robot.is_disabled_state()
	if contextual_hud:
		if can_show_robot_combat_state:
			if robot.control_mode == RobotBase.ControlMode.HARD:
				segments.append("Avanzado")
			if robot.get_active_part_count() < RobotBase.BODY_PARTS.size():
				segments.append("%s/%s partes" % [robot.get_active_part_count(), RobotBase.BODY_PARTS.size()])
			if not robot.is_energy_balanced():
				segments.append(robot.get_energy_state_summary())
		elif robot.is_disabled_state():
			segments.append("%s/%s partes" % [robot.get_active_part_count(), RobotBase.BODY_PARTS.size()])
	else:
		if can_show_robot_combat_state:
			var mode_label := "Avanzado" if robot.control_mode == RobotBase.ControlMode.HARD else "Simple"
			segments = [mode_label, state_segment, "%s/%s partes" % [robot.get_active_part_count(), RobotBase.BODY_PARTS.size()]]
			if robot.is_player_controlled and not has_active_support:
				segments.append(robot.get_input_hint())
			segments.append(robot.get_energy_state_summary())
		elif robot.is_disabled_state():
			segments.append("%s/%s partes" % [robot.get_active_part_count(), RobotBase.BODY_PARTS.size()])
	if can_show_robot_combat_state:
		var core_skill_summary := robot.get_core_skill_status_summary()
		if core_skill_summary != "" and _should_show_core_skill_summary(robot, contextual_hud):
			segments.append(core_skill_summary)
		var passive_summary := robot.get_passive_status_summary()
		if passive_summary != "":
			segments.append(passive_summary)
		if robot.is_energy_surge_active():
			segments.append("energia")
		if robot.is_mobility_boost_active():
			segments.append("impulso")
		if robot.has_method("is_mobility_skill_active") and robot.is_mobility_skill_active():
			segments.append("derrape")
		if robot.is_stability_boost_active():
			segments.append("estabilidad")
		if robot.is_ram_skill_active():
			segments.append("embestida")
		if robot.is_control_zone_suppressed():
			segments.append("zona")
		if robot.has_carried_item():
			segments.append("item %s" % robot.get_carried_item_display_name())
		if robot.is_carrying_part():
			segments.append("carga %s" % RobotBase.get_part_display_name(robot.get_carried_part_name()))
	if support_state != "" and not has_active_support:
		segments.append(support_state)

	return "%s %s | %s" % [control_label, robot.get_roster_display_name(), " | ".join(segments)]


func _build_compact_robot_status_line(robot: RobotBase, contextual_hud: bool) -> String:
	var control_label := "P%s" % robot.player_index if robot.is_player_controlled else "CPU"
	var roster_label := robot.get_archetype_label()
	if roster_label.is_empty():
		roster_label = robot.display_name

	var support_state := get_robot_support_state(robot)
	var has_active_support := match_mode == MatchMode.TEAMS and support_state != ""
	var is_eliminated := is_robot_eliminated(robot)
	var segments: Array[String] = []
	if is_eliminated:
		segments.append("apoyo" if has_active_support else "fuera")
		if has_active_support and support_state != "":
			segments.append(_compact_status_text(support_state))
		else:
			var cause_label := _get_elimination_cause_label(_get_robot_elimination_cause(robot))
			if cause_label != "":
				segments.append(cause_label)
	elif robot.is_disabled_state():
		segments.append("inutilizado")
		var explosion_time_left := robot.get_disabled_explosion_time_left()
		if explosion_time_left > 0.0:
			segments.append("%.1fs" % snappedf(explosion_time_left, 0.1))
	else:
		segments.append("vivo")
		var core_skill_summary := robot.get_core_skill_status_summary()
		if core_skill_summary != "" and _should_show_core_skill_summary(robot, contextual_hud):
			segments.append(_compact_core_skill_summary(core_skill_summary))
		if robot.get_active_part_count() < RobotBase.BODY_PARTS.size():
			segments.append("%s/4 partes" % robot.get_active_part_count())
		if robot.is_energy_surge_active():
			segments.append("energia")
		if robot.is_mobility_boost_active():
			segments.append("impulso")
		if robot.has_method("is_mobility_skill_active") and robot.is_mobility_skill_active():
			segments.append("derrape")
		if robot.is_ram_skill_active():
			segments.append("embestida")
		if robot.is_control_zone_suppressed():
			segments.append("zona")

	return "%s %s | %s" % [control_label, roster_label, " | ".join(segments)]


func _should_show_core_skill_summary(robot: RobotBase, contextual_hud: bool) -> bool:
	if not contextual_hud:
		return true
	if _ffa_aftermath_context_line != "":
		return true
	if robot != null and robot.get_active_part_count() < RobotBase.BODY_PARTS.size():
		return true
	return not _round_active or _round_reset_pending or _match_over


func _compact_core_skill_summary(summary: String) -> String:
	var clean_summary := summary.strip_edges()
	if clean_summary.begins_with("habilidad "):
		clean_summary = clean_summary.substr(10).strip_edges()
	elif clean_summary.begins_with("skill "):
		clean_summary = clean_summary.substr(6).strip_edges()
	var parts := clean_summary.split(" ", false)
	if parts.size() >= 2:
		var charge_segment := str(parts[parts.size() - 1])
		if charge_segment.contains("/"):
			var values := charge_segment.split("/", false)
			if values.size() == 2 and values[0] == values[1]:
				return "%s lista" % str(parts[0]).to_lower()
	return clean_summary.to_lower()


func _compact_status_text(summary: String) -> String:
	var clean_summary := summary.strip_edges()
	if clean_summary.length() <= 28:
		return clean_summary
	return clean_summary.substr(0, 27).strip_edges() + "..."


func _build_space_reduction_warning_line() -> String:
	if get_space_reduction_warning_strength() <= 0.0:
		return ""

	return "Arena se cierra en %.1fs" % snappedf(get_time_until_space_reduction(), 0.1)


func _build_robot_recap_panel_line(robot: RobotBase) -> String:
	if robot == null:
		return ""

	var robot_label := robot.get_roster_display_name()
	var robot_id := robot.get_instance_id()
	if _round_eliminated_robot_ids.has(robot_id):
		var cause_label := _get_elimination_cause_label(_get_robot_elimination_cause(robot))
		var elimination_order := int(_round_elimination_order_by_robot_id.get(robot_id, 0))
		var source_suffix := _get_elimination_source_suffix(robot)
		if source_suffix != "":
			cause_label += source_suffix
		return "%s | baja %s | %s | %s" % [
			robot_label,
			elimination_order,
			cause_label,
			_build_robot_part_state_summary(robot),
		]

	if robot.is_disabled_state():
		var detail := "inutilizado"
		if robot.is_disabled_explosion_unstable():
			detail = "inutilizado | inestable"
		return "%s | %s | %s" % [robot_label, detail, _build_robot_part_state_summary(robot)]

	return "%s | sigue en pie | %s" % [robot_label, _build_robot_part_state_summary(robot)]


func _build_robot_part_state_summary(robot: RobotBase) -> String:
	if robot == null:
		return ""

	var segments: Array[String] = ["%s/%s partes" % [robot.get_active_part_count(), RobotBase.BODY_PARTS.size()]]
	var missing_parts: Array[String] = []
	for part_name in RobotBase.BODY_PARTS:
		if robot.get_part_health(part_name) > 0.0:
			continue

		missing_parts.append(RobotBase.get_part_display_name(part_name))

	if not missing_parts.is_empty():
		segments.append("sin %s" % ", ".join(missing_parts))

	return " | ".join(segments)


func _next_post_match_event_sequence() -> int:
	_post_match_event_sequence += 1
	return _post_match_event_sequence


func _record_post_match_event(
	event_type: String,
	priority: int,
	headline: String,
	detail: String = "",
	metadata: Dictionary = {}
) -> Dictionary:
	var event := PostMatchEvent.make_event(
		_next_post_match_event_sequence(),
		_round_number,
		_round_elapsed_seconds,
		event_type,
		priority,
		headline,
		detail,
		metadata
	)
	_post_match_review.record_event(event)
	return event


func _record_post_match_elimination_event(
	robot: RobotBase,
	cause: EliminationCause,
	source_robot: RobotBase,
	winner_key: String
) -> void:
	if robot == null:
		return

	var priority := 45
	var is_round_closing_candidate := winner_key != ""
	if is_round_closing_candidate:
		var winner_score_after_round := int(_competitor_scores.get(winner_key, 0)) + _get_round_score_value(cause)
		priority = 90 if winner_score_after_round >= get_rounds_to_win() else 75
	elif _round_elimination_order_by_robot_id.size() == 1:
		priority = 55

	var competitor_key := _get_competitor_key(robot)
	_record_post_match_event(PostMatchEvent.TYPE_ELIMINATION, priority, _last_elimination_summary, "", {
		"robot_name": robot.display_name,
		"source_robot_name": source_robot.display_name if is_instance_valid(source_robot) else "",
		"competitor_key": competitor_key,
		"competitor_label": _get_competitor_label_from_key(competitor_key),
		"team_id": robot.get_team_identity(),
		"cause": int(cause),
		"cause_label": _get_match_closing_cause_label(int(cause)),
		"arena_zone": _get_robot_arena_zone(robot),
		"part_state_summary": _build_robot_part_state_summary(robot),
		"is_round_closing_candidate": is_round_closing_candidate,
	})


func _get_robot_arena_zone(robot: RobotBase) -> String:
	if not is_instance_valid(robot):
		return "centro"

	var position := robot.global_position
	if absf(position.x) < 4.0 and absf(position.z) < 4.0:
		return "centro"
	if absf(position.x) >= absf(position.z):
		return "borde este" if position.x >= 0.0 else "borde oeste"
	return "borde sur" if position.z >= 0.0 else "borde norte"


func _get_recap_ordered_robots() -> Array[RobotBase]:
	return _get_ordered_robots_for_competitive_readability()


func _get_live_roster_ordered_robots() -> Array[RobotBase]:
	return _get_ordered_robots_for_competitive_readability()


func _get_ordered_robots_for_competitive_readability() -> Array[RobotBase]:
	var ordered_robots: Array[RobotBase] = []
	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue

		ordered_robots.append(robot)

	if match_mode == MatchMode.TEAMS:
		ordered_robots.sort_custom(_compare_team_robots_for_recap)
		return ordered_robots

	ordered_robots.sort_custom(_compare_ffa_robots_for_recap)
	return ordered_robots


func _compare_team_robots_for_recap(a: RobotBase, b: RobotBase) -> bool:
	if a == null or b == null:
		return is_instance_valid(a)

	var team_a := _get_competitor_key(a)
	var team_b := _get_competitor_key(b)
	if team_a != team_b:
		return _compare_team_competitors_for_recap(team_a, team_b)

	var state_rank_a := _get_team_robot_recap_state_rank(a)
	var state_rank_b := _get_team_robot_recap_state_rank(b)
	if state_rank_a != state_rank_b:
		return state_rank_a < state_rank_b

	if state_rank_a == 2:
		var elimination_order_a := int(_round_elimination_order_by_robot_id.get(a.get_instance_id(), 0))
		var elimination_order_b := int(_round_elimination_order_by_robot_id.get(b.get_instance_id(), 0))
		if elimination_order_a != elimination_order_b:
			return elimination_order_a < elimination_order_b

	return registered_robots.find(a) < registered_robots.find(b)


func _compare_team_competitors_for_recap(a: String, b: String) -> bool:
	var finish_rank_a := _get_team_recap_finish_rank(a)
	var finish_rank_b := _get_team_recap_finish_rank(b)
	if finish_rank_a != finish_rank_b:
		return finish_rank_a < finish_rank_b

	var score_a := int(_competitor_scores.get(a, 0))
	var score_b := int(_competitor_scores.get(b, 0))
	if score_a != score_b:
		return score_a > score_b

	return _competitor_order.find(a) < _competitor_order.find(b)


func _get_team_recap_finish_rank(team_key: String) -> int:
	if match_mode != MatchMode.TEAMS:
		return 999

	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue
		if _get_competitor_key(robot) != team_key:
			continue
		if not is_robot_eliminated(robot):
			return 0

	return 1


func _get_team_robot_recap_state_rank(robot: RobotBase) -> int:
	if robot == null:
		return 999
	if not is_robot_eliminated(robot):
		if robot.is_disabled_state():
			return 1
		return 0

	return 2


func _compare_ffa_robots_for_recap(a: RobotBase, b: RobotBase) -> bool:
	if a == null or b == null:
		return is_instance_valid(a)

	var competitor_a := _get_competitor_key(a)
	var competitor_b := _get_competitor_key(b)
	if competitor_a == competitor_b:
		return registered_robots.find(a) < registered_robots.find(b)

	return _compare_ffa_competitors_for_standings(competitor_a, competitor_b)


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


func _build_elimination_summary(
	robot: RobotBase,
	cause: EliminationCause,
	source_robot: RobotBase = null
) -> String:
	var cause_label := "cayo al vacio"
	if cause == EliminationCause.EXPLOSION:
		cause_label = "explosiono tras quedar inutilizado"
	elif cause == EliminationCause.UNSTABLE_EXPLOSION:
		cause_label = "exploto en sobrecarga"
	return "%s %s%s" % [
		robot.display_name,
		cause_label,
		_get_elimination_source_suffix_for_robot(source_robot),
	]


func _build_round_elimination_cause_summary_line() -> String:
	var void_count := int(_round_elimination_cause_counts.get(EliminationCause.VOID, 0))
	var explosion_count := int(_round_elimination_cause_counts.get(EliminationCause.EXPLOSION, 0))
	var unstable_count := int(_round_elimination_cause_counts.get(EliminationCause.UNSTABLE_EXPLOSION, 0))
	var segments: Array[String] = []

	if void_count > 0:
		segments.append("ring-out %s" % void_count)
	if explosion_count > 0:
		segments.append("destruccion total %s" % explosion_count)
	if unstable_count > 0:
		segments.append("explosion inestable %s" % unstable_count)

	if segments.is_empty():
		return ""

	return "Causa bajas | %s" % " | ".join(segments)


func _build_match_closing_cause_summary_line() -> String:
	if not _match_over:
		return ""

	var void_count := int(_match_closing_cause_counts.get(EliminationCause.VOID, 0))
	var explosion_count := int(_match_closing_cause_counts.get(EliminationCause.EXPLOSION, 0))
	var unstable_count := int(_match_closing_cause_counts.get(EliminationCause.UNSTABLE_EXPLOSION, 0))
	var segments: Array[String] = []

	if void_count > 0:
		segments.append("ring-out %s" % void_count)
	if explosion_count > 0:
		segments.append("destruccion total %s" % explosion_count)
	if unstable_count > 0:
		segments.append("explosion inestable %s" % unstable_count)

	if segments.is_empty():
		return ""

	return "Cierres | %s" % " | ".join(segments)


func _build_closing_points_profile_line() -> String:
	if _round_active:
		return ""
	if match_config == null:
		return ""
	if is_last_alive_variant():
		return ""

	return "Puntos cierre | ring-out %s | destruccion total %s | explosion inestable %s" % [
		match_config.void_elimination_round_points,
		match_config.destruction_elimination_round_points,
		match_config.unstable_elimination_round_points,
	]


func _build_decisive_closing_line() -> String:
	if not _match_over:
		return ""
	if _last_round_closing_cause < 0:
		return ""
	if is_last_alive_variant():
		return "Cierre decisivo | ultimo vivo (+1 ronda)"

	return "Cierre decisivo | %s (+%s)" % [
		_get_match_closing_cause_label(_last_round_closing_cause),
		_get_round_score_value(_last_round_closing_cause),
	]


func _build_round_closing_line() -> String:
	if _round_active:
		return ""
	if _match_over:
		return ""
	if _last_round_was_draw:
		return "Cierre ronda | sin ganador (+0)"
	if _last_round_closing_cause < 0:
		return ""
	if is_last_alive_variant():
		return "Cierre ronda | ultimo vivo (+1 ronda)"

	return "Cierre ronda | %s (+%s)" % [
		_get_match_closing_cause_label(_last_round_closing_cause),
		_get_round_score_value(_last_round_closing_cause),
	]


func _build_post_match_context() -> Dictionary:
	var winner_key := _get_match_winner_competitor_key()
	if winner_key == "":
		winner_key = _get_round_winner_competitor_key()

	return {
		"match_mode": get_match_mode_label(),
		"winner_label": _get_competitor_label_from_key(winner_key),
		"winner_key": winner_key,
		"is_draw": _last_round_was_draw,
		"score_line": _build_score_summary_line(),
		"standings_line": _build_ffa_standings_line(),
		"tiebreaker_line": _build_ffa_tiebreaker_line(),
		"closing_cause_label": _get_match_closing_cause_label(_last_round_closing_cause),
		"closing_summary_line": _build_match_closing_cause_summary_line(),
		"part_loss_lines": _build_post_match_part_loss_lines(),
		"support_summary_line": _build_match_support_summary_line(),
		"last_elimination_line": _build_closing_elimination_line(),
		"match_time_seconds": _round_elapsed_seconds,
	}


func _build_post_match_part_loss_lines() -> Array[String]:
	var lines: Array[String] = []
	for competitor_key in _get_match_stats_ordered_competitors():
		var stats_line := _build_competitor_match_stats_line(competitor_key)
		if stats_line.contains("partes perdidas"):
			lines.append(stats_line)
	return lines


func _build_closing_elimination_line() -> String:
	if not _match_over:
		return ""
	if _last_elimination_summary == "":
		return ""

	return "Cierre | %s" % _last_elimination_summary


func _get_elimination_source_suffix(robot: RobotBase) -> String:
	if robot == null:
		return ""

	var source_id := int(_round_elimination_source_robot_ids.get(robot.get_instance_id(), 0))
	if source_id == 0:
		return ""

	var source_node := instance_from_id(source_id)
	if not (source_node is RobotBase):
		return ""

	return _get_elimination_source_suffix_for_robot(source_node as RobotBase)


func _get_elimination_source_suffix_for_robot(source_robot: RobotBase) -> String:
	if not is_instance_valid(source_robot):
		return ""

	return " por %s" % source_robot.display_name


func _build_match_stats_lines() -> Array[String]:
	if not _match_over:
		return []

	var lines: Array[String] = []
	var support_summary := _build_match_support_summary_line()
	if support_summary != "":
		lines.append(support_summary)
	for competitor_key in _get_match_stats_ordered_competitors():
		var stats_line := _build_competitor_match_stats_line(competitor_key)
		if stats_line == "":
			continue

		lines.append(stats_line)

	return lines


func _build_match_support_summary_line() -> String:
	if match_mode != MatchMode.TEAMS:
		return ""

	if _match_decided_rounds <= 0:
		return ""
	if _match_decided_rounds_with_support <= 0:
		return ""

	var support_decider_percent := int(round((float(_match_decided_rounds_with_support) / float(_match_decided_rounds)) * 100.0))
	return "Aporte de apoyo | %s rondas (%s%%) decisivas con apoyo" % [
		"%s/%s" % [_match_decided_rounds_with_support, _match_decided_rounds],
		support_decider_percent,
	]


func _build_competitor_match_stats_line(competitor_key: String) -> String:
	var stats := _get_competitor_match_stats(competitor_key)
	if stats.is_empty():
		return ""

	var segments: Array[String] = []
	var rescues := int(stats.get("rescues", 0))
	if rescues > 0:
		segments.append("rescates %s" % rescues)
	var denial_segment := _build_part_denial_stats_segment(stats)
	if denial_segment != "":
		segments.append(denial_segment)
	var edge_pickups := int(stats.get("edge_pickups", 0))
	if edge_pickups > 0:
		segments.append("borde %s" % edge_pickups)
	var support_segment := _build_support_stats_segment(stats)
	if support_segment != "":
		segments.append(support_segment)
	var part_loss_segment := _build_part_loss_stats_segment(stats)
	if part_loss_segment != "":
		segments.append(part_loss_segment)
	segments.append(_build_elimination_stats_segment(stats))
	return "Stats | %s | %s" % [_get_competitor_label_from_key(competitor_key), " | ".join(segments)]


func _build_support_stats_segment(stats: Dictionary) -> String:
	var support_pickups := int(stats.get("support_pickups", 0))
	var support_uses := int(stats.get("support_uses", 0))
	var support_rounds_decided := int(stats.get("support_rounds_decided", 0))
	if support_pickups <= 0 and support_uses <= 0:
		return ""
	if support_uses <= 0:
		var round_support_segment := _build_support_round_segment(support_rounds_decided)
		return "apoyo %s" % support_pickups if round_support_segment == "" else "apoyo %s | %s" % [support_pickups, round_support_segment]
	var usage_label := _build_plural_segment(support_uses, "uso", "usos")
	var payload_breakdown := _build_support_payload_breakdown(stats, "support_use")
	var segments: Array[String] = []
	if payload_breakdown.is_empty():
		segments.append("apoyo %s (%s)" % [support_pickups, usage_label])
	else:
		segments.append("apoyo %s (%s: %s)" % [support_pickups, usage_label, ", ".join(payload_breakdown)])

	var round_segment := _build_support_round_segment(support_rounds_decided)
	if round_segment != "":
		segments.append(round_segment)

	return " | ".join(segments)


func _build_support_round_segment(support_rounds_decided: int) -> String:
	if _match_decided_rounds <= 0 or support_rounds_decided <= 0:
		return ""
	var support_rounds_percent := int(round((float(support_rounds_decided) / float(_match_decided_rounds)) * 100.0))
	return "rondas decisivas por apoyo %s/%s (%s%%)" % [support_rounds_decided, _match_decided_rounds, support_rounds_percent]


func _build_support_payload_breakdown(stats: Dictionary, stat_prefix: String) -> Array[String]:
	var segments: Array[String] = []
	for payload_name in SUPPORT_PAYLOAD_LABELS.keys():
		var stat_name := "%s_%s" % [stat_prefix, payload_name]
		var amount := int(stats.get(stat_name, 0))
		if amount <= 0:
			continue

		segments.append("%s %s" % [SUPPORT_PAYLOAD_LABELS[payload_name], amount])

	return segments


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


func _build_part_denial_stats_segment(stats: Dictionary) -> String:
	var total_denials := int(stats.get("denials", 0))
	if total_denials <= 0:
		return ""

	return "negaciones %s" % total_denials


func _build_elimination_stats_segment(stats: Dictionary) -> String:
	var total_eliminations := int(stats.get("eliminations", 0))
	if total_eliminations <= 0:
		return "bajas sufridas 0"

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
		return "bajas sufridas %s" % total_eliminations

	return "bajas sufridas %s (%s)" % [total_eliminations, ", ".join(breakdown)]


func _get_match_stats_ordered_competitors() -> Array[String]:
	var ordered_competitors := _competitor_order.duplicate()
	if ordered_competitors.size() <= 1:
		return ordered_competitors

	if match_mode == MatchMode.TEAMS:
		ordered_competitors.sort_custom(_compare_team_competitors_for_recap)
		return ordered_competitors

	ordered_competitors.sort_custom(_compare_ffa_competitors_for_standings)
	return ordered_competitors


func _build_plural_segment(amount: int, singular_label: String, plural_label: String) -> String:
	if amount == 1:
		return "1 %s" % singular_label

	return "%s %s" % [amount, plural_label]


func _build_compact_elimination_summary(
	robot: RobotBase,
	cause: EliminationCause,
	source_robot: RobotBase = null
) -> String:
	return _build_elimination_summary(robot, cause, source_robot)


func _build_round_highlight_lines() -> Array[String]:
	if _round_active:
		return []

	var lines: Array[String] = []
	var support_highlight := _get_decisive_support_highlight_line()
	if support_highlight != "":
		lines.append(support_highlight)
	if _round_elimination_highlight_entries.is_empty():
		return lines

	var first_highlight := str(_round_elimination_highlight_entries.front())
	var last_highlight := str(_round_elimination_highlight_entries.back())
	if first_highlight == last_highlight:
		lines.append("Momento clave | %s" % first_highlight)
		return lines

	lines.append("Momento inicial | %s" % first_highlight)
	lines.append("Momento final | %s" % last_highlight)
	return lines


func _get_decisive_support_highlight_line() -> String:
	if match_mode != MatchMode.TEAMS:
		return ""
	if _round_active:
		return ""

	var winner_key := _get_round_winner_competitor_key()
	if winner_key == "":
		return ""

	return str(_round_support_highlight_by_competitor.get(winner_key, ""))


func _get_round_winner_competitor_key() -> String:
	if _match_over:
		for competitor_key in _competitor_order:
			if int(_competitor_scores.get(competitor_key, 0)) >= get_rounds_to_win():
				return competitor_key
		return ""

	return _find_last_competitor_standing()


func _get_match_winner_competitor_key() -> String:
	if not _match_over:
		return ""
	for competitor_key in _competitor_order:
		if int(_competitor_scores.get(competitor_key, 0)) >= get_rounds_to_win():
			return competitor_key
	return ""


func _build_ffa_standings_line() -> String:
	if match_mode != MatchMode.FFA:
		return ""
	if _competitor_order.is_empty():
		return ""
	if not _should_show_live_ffa_standings():
		return ""

	var ordered_competitors := _competitor_order.duplicate()
	ordered_competitors.sort_custom(_compare_ffa_competitors_for_standings)
	if ordered_competitors.size() > 4:
		return _build_compact_ffa_standings_line(ordered_competitors)
	var segments: Array[String] = []
	for index in range(ordered_competitors.size()):
		var competitor_key := str(ordered_competitors[index])
		segments.append("%s. %s (%s)" % [
			index + 1,
			_get_competitor_label_from_key(competitor_key),
			_format_ffa_standing_score(int(_competitor_scores.get(competitor_key, 0))),
		])

	return "Posiciones | %s" % " | ".join(segments)


func _build_compact_ffa_standings_line(ordered_competitors: Array) -> String:
	var visible_keys: Array[String] = []
	if not ordered_competitors.is_empty():
		visible_keys.append(str(ordered_competitors[0]))
	if ordered_competitors.size() > 1:
		visible_keys.append(str(ordered_competitors[1]))

	var last_standing_key := _find_last_competitor_standing()
	if last_standing_key != "" and not visible_keys.has(last_standing_key):
		visible_keys.append(last_standing_key)

	var hidden_count := maxi(ordered_competitors.size() - visible_keys.size(), 0)
	var segments: Array[String] = []
	for competitor_key in visible_keys:
		var index := ordered_competitors.find(competitor_key)
		if index < 0:
			continue
		segments.append("%s. %s (%s)" % [
			index + 1,
			_get_competitor_label_from_key(competitor_key),
			_format_ffa_standing_score(int(_competitor_scores.get(competitor_key, 0))),
		])
	if hidden_count > 0:
		segments.append("+%s" % hidden_count)

	return "Posiciones | %s" % " | ".join(segments)


func _build_ffa_tiebreaker_line() -> String:
	if match_mode != MatchMode.FFA:
		return ""
	if not _should_show_live_ffa_standings():
		return ""
	var tie_segments := _build_ffa_tiebreak_segments()
	if tie_segments.is_empty():
		return ""

	return "Desempate | %s" % " ; ".join(tie_segments)


func _should_show_live_ffa_standings() -> bool:
	if not _round_active:
		return true
	if not _round_elimination_order_by_robot_id.is_empty():
		return true

	return _ffa_scores_have_difference()


func _ffa_standings_have_score_tie() -> bool:
	if _competitor_order.size() < 2:
		return false

	var seen_scores := {}
	for competitor_key in _competitor_order:
		var score := int(_competitor_scores.get(competitor_key, 0))
		if seen_scores.has(score):
			return true
		seen_scores[score] = true

	return false


func _build_ffa_tiebreak_segments() -> Array[String]:
	if not _ffa_standings_have_score_tie():
		return []

	var ordered_competitors := _competitor_order.duplicate()
	ordered_competitors.sort_custom(_compare_ffa_competitors_for_standings)
	var tie_segments: Array[String] = []
	var current_group: Array[String] = []
	var current_score := 0
	var has_current_group := false

	for competitor_key in ordered_competitors:
		var score := int(_competitor_scores.get(competitor_key, 0))
		if not has_current_group or score == current_score:
			current_group.append(str(competitor_key))
			current_score = score
			has_current_group = true
			continue

		if current_group.size() > 1:
			tie_segments.append(_build_ffa_tiebreak_segment(current_score, current_group))

		current_group = [str(competitor_key)]
		current_score = score

	if current_group.size() > 1:
		tie_segments.append(_build_ffa_tiebreak_segment(current_score, current_group))

	return tie_segments


func _build_ffa_tiebreak_segment(score: int, competitor_keys: Array[String]) -> String:
	var labels: Array[String] = []
	for competitor_key in competitor_keys:
		labels.append(_get_competitor_label_from_key(competitor_key))

	var score_label := "%sR" % score if is_last_alive_variant() else "%s pts" % score
	return "%s: %s" % [score_label, " > ".join(labels)]


func _format_ffa_standing_score(score: int) -> String:
	if is_last_alive_variant():
		return "%sR" % score
	return str(score)


func _ffa_scores_have_difference() -> bool:
	if _competitor_order.size() < 2:
		return false

	var baseline_score := int(_competitor_scores.get(_competitor_order[0], 0))
	for competitor_key in _competitor_order:
		if int(_competitor_scores.get(competitor_key, 0)) != baseline_score:
			return true

	return false


func _compare_ffa_competitors_for_standings(a: String, b: String) -> bool:
	var score_a := int(_competitor_scores.get(a, 0))
	var score_b := int(_competitor_scores.get(b, 0))
	if score_a != score_b:
		return score_a > score_b

	var finish_rank_a := _get_ffa_round_finish_rank(a)
	var finish_rank_b := _get_ffa_round_finish_rank(b)
	if finish_rank_a != finish_rank_b:
		return finish_rank_a < finish_rank_b

	return _competitor_order.find(a) < _competitor_order.find(b)


func _get_ffa_round_finish_rank(competitor_key: String) -> int:
	if match_mode != MatchMode.FFA:
		return 999
	if competitor_key == "":
		return 999

	for robot in registered_robots:
		if not is_instance_valid(robot):
			continue
		if _get_competitor_key(robot) != competitor_key:
			continue
		if not is_robot_eliminated(robot):
			return 1

		var elimination_order := int(_round_elimination_order_by_robot_id.get(robot.get_instance_id(), 0))
		if elimination_order > 0:
			return _competitor_order.size() - elimination_order + 1
		break

	return _competitor_order.size() + 1


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


func _build_support_highlight_line(robot: RobotBase, payload_name: String, target_robot: RobotBase) -> String:
	var payload_label := str(SUPPORT_PAYLOAD_LABELS.get(payload_name, ""))
	if payload_label == "":
		return ""

	var support_robot_label := robot.get_roster_display_name()
	if is_instance_valid(target_robot):
		return "Apoyo decisivo | %s %s > %s" % [
			support_robot_label,
			payload_label,
			target_robot.get_roster_display_name(),
		]

	return "Apoyo decisivo | %s %s" % [support_robot_label, payload_label]


func _ensure_competitor_match_stats(competitor_key: String) -> void:
	if competitor_key == "":
		return
	if _competitor_match_stats.has(competitor_key):
		return

	_competitor_match_stats[competitor_key] = {
		"rescues": 0,
		"denials": 0,
		"edge_pickups": 0,
		"support_pickups": 0,
		"support_pickup_stabilizer": 0,
		"support_pickup_surge": 0,
		"support_pickup_mobility": 0,
		"support_pickup_interference": 0,
		"support_uses": 0,
		"support_use_stabilizer": 0,
		"support_use_surge": 0,
		"support_use_mobility": 0,
		"support_use_interference": 0,
		"support_rounds_decided": 0,
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


func _increment_support_payload_stat(robot: RobotBase, payload_name: String, stat_prefix: String) -> void:
	if robot == null or payload_name == "":
		return
	if not SUPPORT_PAYLOAD_LABELS.has(payload_name):
		return

	_increment_robot_match_stat(robot, "%s_%s" % [stat_prefix, payload_name])


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


func _finish_round_with_winner(winner_key: String, finishing_cause: EliminationCause) -> void:
	_round_active = false
	_round_reset_pending = true
	_last_round_closing_cause = int(finishing_cause)
	_last_round_was_draw = false
	_match_closing_cause_counts[int(finishing_cause)] = int(_match_closing_cause_counts.get(int(finishing_cause), 0)) + 1
	_match_decided_rounds += 1
	if _round_support_usage_by_competitor.has(winner_key):
		_match_decided_rounds_with_support += 1
		_increment_competitor_match_stat(winner_key, "support_rounds_decided")
		_record_decisive_support_post_match_event(winner_key)
	var round_value := _get_round_score_value(finishing_cause)
	var winner_score := int(_competitor_scores.get(winner_key, 0)) + round_value
	_competitor_scores[winner_key] = winner_score
	_record_match_close_post_match_event(winner_key, finishing_cause, winner_score)
	if winner_score >= get_rounds_to_win():
		_finish_match_with_winner(winner_key, winner_score)
		return

	_round_status_line = "%s gana la ronda %s" % [_get_competitor_label_from_key(winner_key), _round_number]
	_schedule_round_reset()


func _record_match_close_post_match_event(
	winner_key: String,
	finishing_cause: EliminationCause,
	winner_score: int
) -> void:
	var is_match_close := winner_score >= get_rounds_to_win()
	var priority := 100 if is_match_close else 70
	var winner_label := _get_competitor_label_from_key(winner_key)
	var headline := "%s cerro la partida" % winner_label if is_match_close else "%s gano la ronda %s" % [winner_label, _round_number]
	_last_match_close_event = _record_post_match_event(PostMatchEvent.TYPE_MATCH_CLOSE, priority, headline, "", {
		"competitor_key": winner_key,
		"competitor_label": winner_label,
		"cause": int(finishing_cause),
		"cause_label": _get_match_closing_cause_label(int(finishing_cause)),
		"arena_zone": _get_last_eliminated_robot_arena_zone(),
		"match_over": is_match_close,
	})


func _record_decisive_support_post_match_event(winner_key: String) -> void:
	var highlight := str(_round_support_highlight_by_competitor.get(winner_key, ""))
	var winner_label := _get_competitor_label_from_key(winner_key)
	var headline := "Apoyo de %s preparo el cierre" % winner_label
	if highlight != "":
		headline = highlight.replace("Apoyo decisivo | ", "")
	_record_post_match_event(PostMatchEvent.TYPE_SUPPORT, 65, headline, "", {
		"competitor_key": winner_key,
		"competitor_label": winner_label,
		"cause_label": "apoyo",
		"arena_zone": "centro",
		"decisive": true,
	})


func _get_last_eliminated_robot_arena_zone() -> String:
	for index in range(_round_elimination_order_by_robot_id.size(), 0, -1):
		for robot in registered_robots:
			if not is_instance_valid(robot):
				continue
			if int(_round_elimination_order_by_robot_id.get(robot.get_instance_id(), 0)) == index:
				return _get_robot_arena_zone(robot)
	return "centro"


func _finish_round_draw() -> void:
	_round_active = false
	_round_reset_pending = true
	_round_status_line = "Ronda %s sin ganador" % _round_number
	_last_round_was_draw = true
	_schedule_round_reset()


func _get_round_victory_points_for_cause(cause: EliminationCause) -> int:
	if match_config == null:
		return 1

	return max(0, match_config.get_round_victory_points_for_cause(int(cause)))


func _get_round_score_value(cause: EliminationCause) -> int:
	if is_last_alive_variant():
		return 1
	return _get_round_victory_points_for_cause(cause)


func _finish_match_with_winner(winner_key: String, winner_score: int) -> void:
	_match_over = true
	_round_status_line = _build_match_victory_status_line(winner_key, winner_score)
	if is_match_restart_enabled():
		_match_restart_deadline_msec = Time.get_ticks_msec() + int(round(match_restart_delay * 1000.0))
		_schedule_match_restart()
	else:
		_match_restart_deadline_msec = 0


func _build_match_victory_status_line(winner_key: String, winner_score: int) -> String:
	if match_mode == MatchMode.FFA:
		if is_last_alive_variant():
			return "%s gana la partida con %s" % [
				_get_competitor_label_from_key(winner_key),
				_build_plural_segment(winner_score, "ronda", "rondas"),
			]
		return "%s gana la partida con %s" % [
			_get_competitor_label_from_key(winner_key),
			_build_plural_segment(winner_score, "punto", "puntos"),
		]

	return "%s gana la partida por %s-%s pts" % [
		_get_competitor_label_from_key(winner_key),
		winner_score,
		_get_highest_losing_score(winner_key),
	]


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
	_round_elimination_source_robot_ids.clear()
	_round_elimination_order_by_robot_id.clear()
	_round_elimination_cause_counts.clear()
	_round_elimination_recap_entries.clear()
	_round_elimination_highlight_entries.clear()
	_last_elimination_summary = ""
	_round_support_usage_by_competitor.clear()
	_round_support_highlight_by_competitor.clear()
	_robot_support_state.clear()
	_ffa_aftermath_context_line = ""
	_last_round_closing_cause = -1
	_last_round_was_draw = false
	_round_number += 1
	_round_active = true
	_round_reset_pending = false
	_round_elapsed_seconds = 0.0
	_round_intro_remaining = _resolve_round_intro_duration()
	_match_restart_deadline_msec = 0
	_round_status_line = _build_round_intro_status_line() if is_round_intro_active() else "Ronda %s en juego" % _round_number
	round_started.emit(_round_number)


func _resolve_round_intro_duration() -> float:
	if match_config == null:
		return maxf(round_intro_duration, 0.0)

	return maxf(match_config.get_round_intro_duration(match_mode == MatchMode.FFA), 0.0)


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
	if not _should_show_live_score_summary():
		return ""

	var score_parts: Array[String] = []
	var ordered_competitors := _competitor_order.duplicate()
	if match_mode == MatchMode.FFA:
		ordered_competitors.sort_custom(_compare_ffa_competitors_for_standings)
	for competitor_key in ordered_competitors:
		var competitor_label := _get_competitor_label_from_key(competitor_key)
		var competitor_score := int(_competitor_scores.get(competitor_key, 0))
		var archetype_label := str(_competitor_archetype_labels.get(competitor_key, ""))
		if match_mode == MatchMode.FFA and archetype_label != "":
			score_parts.append("%s %s [%s]" % [competitor_label, competitor_score, archetype_label])
			continue

		score_parts.append("%s %s" % [competitor_label, competitor_score])

	var label := "Rondas" if is_last_alive_variant() else "Marcador"
	return "%s | %s" % [label, " | ".join(score_parts)]


func _build_target_score_line() -> String:
	if is_last_alive_variant():
		return "Objetivo | Primero a %s rondas" % get_rounds_to_win()
	return "Objetivo | Primero a %s pts" % get_rounds_to_win()


func _should_show_live_score_summary() -> bool:
	if not _round_active:
		return true
	if match_mode == MatchMode.FFA:
		return _should_show_live_ffa_standings()

	return _match_decided_rounds > 0


func _build_round_intro_status_line() -> String:
	if match_mode == MatchMode.TEAMS:
		return "Ronda %s | carriles listos | arranca en %.1fs" % [_round_number, snappedf(get_round_intro_time_left(), 0.1)]
	return "Ronda %s | arranca en %.1fs" % [_round_number, snappedf(get_round_intro_time_left(), 0.1)]


func _get_highest_losing_score(winner_key: String) -> int:
	var highest_score := 0
	for competitor_key in _competitor_order:
		if competitor_key == winner_key:
			continue

		highest_score = max(highest_score, int(_competitor_scores.get(competitor_key, 0)))

	return highest_score


func _get_match_closing_cause_label(cause: int) -> String:
	if cause == EliminationCause.VOID:
		return "ring-out"
	if cause == EliminationCause.EXPLOSION:
		return "destruccion total"
	if cause == EliminationCause.UNSTABLE_EXPLOSION:
		return "explosion inestable"

	return ""
