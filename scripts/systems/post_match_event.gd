extends RefCounted
class_name PostMatchEvent

const TYPE_ELIMINATION := "elimination"
const TYPE_SUPPORT := "support"
const TYPE_PART_LOSS := "part_loss"
const TYPE_PART_RETURN := "part_return"
const TYPE_PART_DENIAL := "part_denial"
const TYPE_EDGE_PICKUP := "edge_pickup"
const TYPE_MATCH_CLOSE := "match_close"


static func make_event(
	sequence: int,
	round_number: int,
	time_seconds: float,
	event_type: String,
	priority: int,
	headline: String,
	detail: String = "",
	metadata: Dictionary = {}
) -> Dictionary:
	var event := metadata.duplicate(true)
	event["sequence"] = maxi(sequence, 0)
	event["round_number"] = maxi(round_number, 1)
	event["time_seconds"] = maxf(time_seconds, 0.0)
	event["event_type"] = event_type
	event["priority"] = priority
	event["headline"] = headline.strip_edges()
	event["detail"] = detail.strip_edges()
	return event


static func format_timestamp(time_seconds: float) -> String:
	var total_seconds := maxi(int(floor(maxf(time_seconds, 0.0))), 0)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


static func format_replay_line(event: Dictionary) -> String:
	var timestamp := format_timestamp(float(event.get("time_seconds", 0.0)))
	var round_number := maxi(int(event.get("round_number", 1)), 1)
	var arena_zone := str(event.get("arena_zone", "centro")).strip_edges()
	if arena_zone.is_empty():
		arena_zone = "centro"
	var cause_label := str(event.get("cause_label", event.get("event_type", ""))).strip_edges()
	if cause_label.is_empty():
		cause_label = "evento"
	var competitor_label := str(event.get("competitor_label", event.get("robot_name", ""))).strip_edges()
	if competitor_label.is_empty():
		competitor_label = str(event.get("headline", "")).strip_edges()
	return "Replay | %s R%s | %s | %s | %s" % [timestamp, round_number, arena_zone, cause_label, competitor_label]


static func format_moment_line(label: String, event: Dictionary) -> String:
	var clean_label := label.strip_edges()
	if clean_label.is_empty():
		clean_label = "Momento decisivo"
	var headline := str(event.get("headline", "")).strip_edges()
	if headline.is_empty():
		headline = str(event.get("detail", "")).strip_edges()
	return "%s | %s" % [clean_label, headline]
