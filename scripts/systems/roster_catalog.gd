extends RefCounted
class_name RosterCatalog

const ARIETE_CONFIG := preload("res://data/config/robots/ariete_archetype.tres")
const GRUA_CONFIG := preload("res://data/config/robots/grua_archetype.tres")
const CIZALLA_CONFIG := preload("res://data/config/robots/cizalla_archetype.tres")
const PATIN_CONFIG := preload("res://data/config/robots/patin_archetype.tres")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")


static func get_shell_roster() -> Array:
	return [
		_build_entry("ariete", ARIETE_CONFIG),
		_build_entry("grua", GRUA_CONFIG),
		_build_entry("cizalla", CIZALLA_CONFIG),
		_build_entry("patin", PATIN_CONFIG),
	]


static func get_shell_roster_entry(entry_id: String) -> Dictionary:
	for entry in get_shell_roster():
		if String(entry.get("id", "")) == entry_id:
			return entry

	return {}


static func get_shell_roster_entry_label(entry_id: String) -> String:
	return String(get_shell_roster_entry(entry_id).get("label", ""))


static func _build_entry(entry_id: String, config: RobotArchetypeConfig) -> Dictionary:
	return {
		"id": entry_id,
		"label": config.archetype_label,
		"role": config.role_label,
		"fantasy": config.fantasy_line,
		"strength": config.strength_line,
		"risk": config.risk_line,
		"signature": config.signature_line,
		"body_read": config.body_read_line,
		"easy": config.easy_line,
		"hard": config.hard_line,
		"accent_color": config.accent_color,
		"core_skill_label": config.core_skill_label,
		"config": config,
	}
