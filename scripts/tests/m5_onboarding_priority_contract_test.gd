extends SceneTree

const OnboardingCatalog = preload("res://scripts/systems/onboarding_catalog.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sections: Array = OnboardingCatalog.get_sections()
	var ids: Array[String] = []
	for section in sections:
		ids.append(String(section.get("id", "")))

	_assert(ids.size() >= 6, "How to Play debe cubrir al menos movimiento, victoria, combate, partes, energia y recuperacion.")
	_assert(ids.slice(0, 3) == ["controls", "victory", "combat"], "M5 debe priorizar movimiento/control, victoria y combate.")

	for required_id in ["controls", "victory", "combat", "parts", "energy", "recovery"]:
		var section := OnboardingCatalog.get_section(required_id)
		_assert(not section.is_empty(), "Falta seccion de onboarding: %s." % required_id)
		_assert(String(section.get("summary", "")).length() <= 160, "%s debe tener summary corto." % required_id)
		_assert(String(section.get("callout", "")).length() <= 150, "%s debe tener callout corto." % required_id)
		_assert(String(section.get("practice_module_id", "")).strip_edges() != "", "%s debe enlazar a practica." % required_id)

	var combat := OnboardingCatalog.get_section("combat")
	_assert(String(combat.get("practice_module_id", "")) == "impacto", "Combate debe abrir la estacion Impacto.")
	_assert(String(OnboardingCatalog.get_practice_module_id_for_section("controls")) == "movimiento", "Movimiento debe abrir la estacion Movimiento.")
	_assert(String(OnboardingCatalog.get_practice_module_id_for_section("victory")) == "impacto", "Victoria debe abrir Impacto por ring-out.")

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
