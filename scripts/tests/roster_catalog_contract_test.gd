extends SceneTree

const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(RosterCatalog != null, "El catalogo del roster deberia vivir en scripts/systems/roster_catalog.gd.")
	if RosterCatalog == null:
		_finish()
		return

	var roster: Array = RosterCatalog.get_shell_roster()
	_assert(roster.size() == 4, "El roster visible de shell deberia incluir exactamente cuatro fichas base.")

	var expected_labels := ["Ariete", "Grua", "Cizalla", "Patin"]
	var actual_labels: Array[String] = []
	for entry in roster:
		var label := String(entry.get("label", ""))
		actual_labels.append(label)
		var config: Variant = entry.get("config", null)
		_assert(config is RobotArchetypeConfig, "Cada ficha de Characters deberia exponer un RobotArchetypeConfig real.")
		for field_name in [
			"id",
			"label",
			"role",
			"fantasy",
			"strength",
			"risk",
			"signature",
			"body_read",
			"easy",
			"hard",
		]:
			_assert(
				String(entry.get(field_name, "")).strip_edges() != "",
				"La ficha %s no deberia dejar vacio `%s`." % [label, field_name]
			)

	_assert(actual_labels == expected_labels, "Characters deberia conservar el orden Ariete, Grua, Cizalla y Patin.")
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
