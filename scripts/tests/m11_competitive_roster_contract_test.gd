extends SceneTree

const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var roster: Array = RosterCatalog.get_competitive_roster()
	_assert(roster.size() == 6, "El roster competitivo M11 deberia tener seis arquetipos.")

	var expected_ids := ["ariete", "grua", "cizalla", "patin", "aguja", "ancla"]
	var actual_ids: Array[String] = []
	for entry in roster:
		var entry_id := String(entry.get("id", ""))
		actual_ids.append(entry_id)
		var config_path := String(entry.get("config_path", ""))
		_assert(load(config_path) is RobotArchetypeConfig, "`%s` deberia cargar un RobotArchetypeConfig." % config_path)
		var mode_notes: Dictionary = entry.get("mode_notes", {})
		_assert(String(mode_notes.get("ffa", "")).strip_edges() != "", "La ficha `%s` deberia tener nota FFA." % entry_id)
		_assert(String(mode_notes.get("teams", "")).strip_edges() != "", "La ficha `%s` deberia tener nota Teams." % entry_id)

	_assert(actual_ids == expected_ids, "El orden competitivo deberia ser Ariete, Grua, Cizalla, Patin, Aguja, Ancla.")
	_assert(RosterCatalog.get_competitive_entry_ids() == expected_ids, "Los ids competitivos deberian conservar el mismo orden estable.")
	_assert(RosterCatalog.get_default_entry_id_for_slot(5) == "aguja", "P5 deberia preseleccionar Aguja.")
	_assert(RosterCatalog.get_default_entry_id_for_slot(6) == "ancla", "P6 deberia preseleccionar Ancla.")

	var aguja_path := "res://data/config/robots/aguja_archetype.tres"
	var ancla_path := "res://data/config/robots/ancla_archetype.tres"
	_assert(RosterCatalog.get_entry_id_for_archetype_path(aguja_path) == "aguja", "Aguja deberia resolverse desde su config_path.")
	_assert(RosterCatalog.get_entry_id_for_archetype_path(ancla_path) == "ancla", "Ancla deberia resolverse desde su config_path.")
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
