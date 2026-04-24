extends SceneTree

const OnboardingCatalog = preload("res://scripts/systems/onboarding_catalog.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(
		OnboardingCatalog != null,
		"El catalogo de onboarding deberia vivir en scripts/systems/onboarding_catalog.gd."
	)
	if OnboardingCatalog == null:
		_finish()
		return

	var sections: Array = OnboardingCatalog.get_sections()
	var expected_ids := [
		"controls",
		"victory",
		"combat",
		"parts",
		"energy",
		"recovery",
	]
	var actual_ids: Array[String] = []
	for entry in sections:
		var section_id := String(entry.get("id", ""))
		actual_ids.append(section_id)
		for field_name in ["id", "label", "summary", "callout"]:
			_assert(
				String(entry.get(field_name, "")).strip_edges() != "",
				"La seccion %s no deberia dejar vacio `%s`." % [section_id, field_name]
			)
		var bullets_variant: Variant = entry.get("bullets", [])
		_assert(
			bullets_variant is Array and not (bullets_variant as Array).is_empty(),
			"La seccion %s deberia incluir bullets accionables." % section_id
		)
		if bullets_variant is Array:
			for bullet in bullets_variant:
				_assert(
					String(bullet).strip_edges() != "",
					"La seccion %s no deberia incluir bullets vacios." % section_id
				)

	_assert(
		actual_ids == expected_ids,
		"How to Play deberia conservar el orden movimiento/control, victoria, combate, partes, energia y recuperacion."
	)
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
