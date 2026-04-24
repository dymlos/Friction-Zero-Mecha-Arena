extends SceneTree

const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const ControlReferenceCatalog = preload("res://scripts/systems/control_reference_catalog.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(
		RosterCatalog.get_teaching_focus_entry_ids() == ["ariete", "patin", "cizalla"],
		"El foco inicial M4 debe ser Ariete, Patin y Cizalla en ese orden ensenable."
	)

	var focus_labels := []
	for entry in RosterCatalog.get_teaching_focus_roster():
		focus_labels.append(String(entry.get("label", "")))
	_assert(focus_labels == ["Ariete", "Patin", "Cizalla"], "El foco inicial debe leer Pusher/Tank, Mobility y Dismantler.")

	var universal_actions := RosterCatalog.get_universal_action_labels()
	_assert(universal_actions.has("Choque / ataque"), "Las acciones universales deben incluir choque/ataque.")
	_assert(universal_actions.has("Energia"), "Las acciones universales deben incluir redistribucion de energia.")
	_assert(universal_actions.has("Overdrive"), "Las acciones universales deben incluir Overdrive.")
	_assert(universal_actions.has("Partes / item"), "Las acciones universales deben incluir parte o item cargado.")

	var button_reference := ControlReferenceCatalog.get_default_button_reference()
	_assert(button_reference.contains("Skill/carga"), "La referencia de botones debe explicar el boton de skill/carga.")
	_assert(button_reference.contains("Choque"), "La referencia de botones debe explicar choque/ataque.")
	_assert(button_reference.contains("Energia"), "La referencia de botones debe explicar energia.")
	_assert(button_reference.contains("Overdrive"), "La referencia de botones debe explicar Overdrive.")

	for entry in RosterCatalog.get_shell_roster():
		var entry_id := String(entry.get("id", ""))
		var label := String(entry.get("label", ""))
		_assert(String(entry.get("role", "")).strip_edges() != "", "%s debe mostrar rol." % label)
		_assert(String(entry.get("primary_skill", "")).strip_edges() != "", "%s debe mostrar skill principal." % label)
		_assert(String(entry.get("button_reference", "")).strip_edges() != "", "%s debe mostrar botones." % label)
		_assert(String(entry.get("visual_differentiation_scope", "")) == "moderada", "%s debe declarar diferenciacion visual moderada." % label)
		_assert(String(entry.get("body_read", "")).strip_edges() != "", "%s debe leer desde el cuerpo." % label)
		_assert(not String(entry.get("extra_skill_labels", "")).contains(","), "%s no debe declarar multiples skills player-facing." % label)
		if RosterCatalog.get_teaching_focus_entry_ids().has(entry_id):
			_assert(bool(entry.get("teaching_focus", false)), "%s debe quedar marcado como foco inicial." % label)
		else:
			_assert(not bool(entry.get("teaching_focus", false)), "%s no debe presentarse como foco inicial M4." % label)

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
