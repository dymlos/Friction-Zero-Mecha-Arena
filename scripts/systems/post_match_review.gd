extends RefCounted
class_name PostMatchReview

const PostMatchEvent = preload("res://scripts/systems/post_match_event.gd")

const MAX_EVENTS := 64
const MAX_SNIPPETS := 3

var _events: Array[Dictionary] = []
var _story_lines: Array[String] = []
var _snippet_lines: Array[String] = []
var _loser_reading_lines: Array[String] = []


func reset() -> void:
	_events.clear()
	_story_lines.clear()
	_snippet_lines.clear()
	_loser_reading_lines.clear()


func record_event(event: Dictionary) -> void:
	var headline := str(event.get("headline", "")).strip_edges()
	if headline.is_empty():
		return
	if _events.size() >= MAX_EVENTS:
		return

	var stored := event.duplicate(true)
	stored["headline"] = headline
	stored["priority"] = clampi(int(stored.get("priority", 0)), 0, 100)
	stored["sequence"] = maxi(int(stored.get("sequence", _events.size() + 1)), 0)
	_events.append(stored)
	_events.sort_custom(_compare_events_by_sequence)


func build_review(match_context: Dictionary) -> Dictionary:
	_story_lines = _build_story_lines(match_context)
	_snippet_lines = _build_snippet_lines()
	_loser_reading_lines = _build_loser_reading_lines(match_context)
	return {
		"story": _story_lines.duplicate(),
		"snippets": _snippet_lines.duplicate(),
		"loser_reading": _loser_reading_lines.duplicate(),
	}


func get_story_lines() -> Array[String]:
	return _story_lines.duplicate()


func get_snippet_lines() -> Array[String]:
	return _snippet_lines.duplicate()


func get_loser_reading_lines() -> Array[String]:
	return _loser_reading_lines.duplicate()


func _build_story_lines(match_context: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if bool(match_context.get("is_draw", false)):
		lines.append("Lectura | Nadie cerro la ronda: el desempate quedo sin ganador.")
		return lines

	var mode := _normalized_mode(match_context.get("match_mode", ""))
	if mode == "ffa":
		lines.append(_build_ffa_story_line(match_context))
	else:
		lines.append(_build_teams_story_line(match_context))
	return lines


func _build_teams_story_line(match_context: Dictionary) -> String:
	var winner_label := _context_text(match_context, "winner_label", "Equipo ganador")
	var cause_label := _context_text(match_context, "closing_cause_label", "cierre")
	var support_summary := _context_text(match_context, "support_summary_line")
	var part_loss_lines := _context_array(match_context, "part_loss_lines")
	if cause_label == "explosion inestable":
		return "Lectura | %s gano por %s tras forzar sobrecarga." % [winner_label, cause_label]
	if _has_real_support_summary(support_summary):
		return "Lectura | %s gano por %s con apoyo decisivo." % [winner_label, cause_label]
	if cause_label == "destruccion total" or not part_loss_lines.is_empty():
		return "Lectura | %s gano por %s tras desgaste modular." % [winner_label, cause_label]
	var closing_summary := _context_text(match_context, "closing_summary_line")
	if not closing_summary.is_empty():
		return "Lectura | %s gano por %s: %s." % [winner_label, cause_label, _strip_prefix(closing_summary)]
	return "Lectura | %s gano por %s." % [winner_label, cause_label]


func _build_ffa_story_line(match_context: Dictionary) -> String:
	var winner_label := _context_text(match_context, "winner_label", "ganador")
	var standings_line := _context_text(match_context, "standings_line")
	var tiebreaker_line := _context_text(match_context, "tiebreaker_line")
	if not tiebreaker_line.is_empty():
		return "Lectura | FFA premio supervivencia: %s quedo primero y %s." % [winner_label, _strip_prefix(tiebreaker_line)]
	if not standings_line.is_empty():
		return "Lectura | FFA premio supervivencia: %s quedo primero en %s." % [winner_label, _strip_prefix(standings_line)]
	return "Lectura | FFA premio supervivencia: %s quedo ultimo en pie." % winner_label


func _build_loser_reading_lines(match_context: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if bool(match_context.get("is_draw", false)):
		return lines

	var mode := _normalized_mode(match_context.get("match_mode", ""))
	if mode == "ffa":
		var standings_line := _context_text(match_context, "standings_line")
		var tiebreaker_line := _context_text(match_context, "tiebreaker_line")
		if not tiebreaker_line.is_empty():
			lines.append("Como perdiste | El orden final se resolvio por %s." % _strip_prefix(tiebreaker_line))
		elif not standings_line.is_empty():
			lines.append("Como perdiste | El cierre dejo %s." % _strip_prefix(standings_line))
		return lines

	var part_loss_lines := _context_array(match_context, "part_loss_lines")
	if not part_loss_lines.is_empty():
		lines.append("Como perdiste | %s." % _strip_prefix(str(part_loss_lines[0])))
		return lines

	var last_elimination_line := _context_text(match_context, "last_elimination_line")
	if not last_elimination_line.is_empty():
		lines.append("Como perdiste | %s." % _strip_prefix(last_elimination_line))
	return lines


func _build_snippet_lines() -> Array[String]:
	var selected := _select_snippet_events()
	var lines: Array[String] = []
	for event in selected:
		lines.append(PostMatchEvent.format_replay_line(event))
	return lines


func _select_snippet_events() -> Array[Dictionary]:
	var unique_events: Array[Dictionary] = []
	var seen := {}
	for event in _events:
		var key := "%s|%s" % [str(event.get("event_type", "")), str(event.get("headline", ""))]
		if seen.has(key):
			continue
		seen[key] = true
		unique_events.append(event)

	var close_events: Array[Dictionary] = []
	var decisive_support_events: Array[Dictionary] = []
	var other_events: Array[Dictionary] = []
	for event in unique_events:
		var event_type := str(event.get("event_type", ""))
		if event_type == PostMatchEvent.TYPE_MATCH_CLOSE:
			close_events.append(event)
		elif event_type == PostMatchEvent.TYPE_SUPPORT and bool(event.get("decisive", false)):
			decisive_support_events.append(event)
		else:
			other_events.append(event)

	close_events.sort_custom(_compare_events_by_priority)
	decisive_support_events.sort_custom(_compare_events_by_priority)
	other_events.sort_custom(_compare_events_by_priority)

	var selected: Array[Dictionary] = []
	_append_selected_events(selected, close_events)
	_append_selected_events(selected, decisive_support_events)
	_append_selected_events(selected, other_events)
	return selected


func _append_selected_events(target: Array[Dictionary], source: Array[Dictionary]) -> void:
	for event in source:
		if target.size() >= MAX_SNIPPETS:
			return
		target.append(event)


func _context_text(match_context: Dictionary, key: String, fallback: String = "") -> String:
	return str(match_context.get(key, fallback)).strip_edges()


func _context_array(match_context: Dictionary, key: String) -> Array:
	var value = match_context.get(key, [])
	if value is Array:
		return value as Array
	return []


func _normalized_mode(value) -> String:
	return str(value).strip_edges().to_lower()


func _strip_prefix(line: String) -> String:
	var clean_line := line.strip_edges()
	var separator_index := clean_line.find("|")
	if separator_index == -1:
		return clean_line
	return clean_line.substr(separator_index + 1).strip_edges()


func _has_real_support_summary(support_summary: String) -> bool:
	var clean_summary := support_summary.strip_edges()
	if clean_summary.is_empty():
		return false
	return not clean_summary.contains("0/")


static func _compare_events_by_sequence(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("sequence", 0)) < int(b.get("sequence", 0))


static func _compare_events_by_priority(a: Dictionary, b: Dictionary) -> bool:
	var priority_a := int(a.get("priority", 0))
	var priority_b := int(b.get("priority", 0))
	if priority_a == priority_b:
		return int(a.get("sequence", 0)) > int(b.get("sequence", 0))
	return priority_a > priority_b
