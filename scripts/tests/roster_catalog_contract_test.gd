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
	_assert(roster.size() == 6, "El roster visible de shell deberia incluir exactamente seis fichas competitivas.")

	var expected_labels := ["Ariete", "Grua", "Cizalla", "Patin", "Aguja", "Ancla"]
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
			"primary_skill",
			"button_reference",
			"visual_differentiation_scope",
			"body_read",
			"easy",
			"hard",
			"archetype_family",
			"config_path",
		]:
			_assert(
				String(entry.get(field_name, "")).strip_edges() != "",
				"La ficha %s no deberia dejar vacio `%s`." % [label, field_name]
			)
		_assert(
			String(entry.get("visual_differentiation_scope", "")) == "moderada",
			"La ficha %s deberia declarar diferenciacion visual moderada." % label
		)
		_assert(
			String(entry.get("button_reference", "")).contains("Skill/carga"),
			"La ficha %s deberia exponer referencia de boton de skill/carga." % label
		)
		var mode_notes: Dictionary = entry.get("mode_notes", {})
		_assert(String(mode_notes.get("ffa", "")).strip_edges() != "", "La ficha %s deberia tener nota FFA." % label)
		_assert(String(mode_notes.get("teams", "")).strip_edges() != "", "La ficha %s deberia tener nota Teams." % label)

	_assert(actual_labels == expected_labels, "Characters deberia conservar el orden competitivo de seis arquetipos.")
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
