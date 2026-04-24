extends SceneTree

const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")

const EXPECTED_MODULE_IDS := [
	"movimiento",
	"impacto",
	"energia",
	"partes",
	"recuperacion",
	"sandbox",
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var practice_catalog := PracticeCatalog.new()
	_assert(
		practice_catalog.has_method("get_modules"),
		"PracticeCatalog deberia exponer el listado ordenado de modulos."
	)
	_assert(
		practice_catalog.has_method("get_module"),
		"PracticeCatalog deberia poder resolver un modulo por id."
	)
	if not (practice_catalog.has_method("get_modules") and practice_catalog.has_method("get_module")):
		_finish()
		return

	var modules: Array = PracticeCatalog.get_modules()
	_assert(
		modules.size() == EXPECTED_MODULE_IDS.size(),
		"PracticeCatalog deberia congelar exactamente seis modulos iniciales."
	)
	for index in range(EXPECTED_MODULE_IDS.size()):
		var expected_module_id: String = EXPECTED_MODULE_IDS[index]
		var module_spec: Dictionary = modules[index] if index < modules.size() else {}
		_assert(
			String(module_spec.get("id", "")) == expected_module_id,
			"PracticeCatalog deberia mantener el orden de modulos acordado."
		)
		_assert(
			not String(module_spec.get("label", "")).is_empty(),
			"Cada modulo de practica deberia tener label visible."
		)
		_assert(
			not String(module_spec.get("summary", "")).is_empty(),
			"Cada modulo de practica deberia tener resumen corto."
		)
		_assert(
			not String(module_spec.get("recommended_roster_entry_id", "")).is_empty(),
			"Cada modulo de practica deberia recomendar un entry id del roster."
		)
		if expected_module_id == "impacto":
			_assert(
				String(module_spec.get("recommended_roster_entry_id", "")) == "ariete",
				"El modulo impacto deberia recomendar Ariete."
			)
		elif expected_module_id == "energia":
			_assert(
				String(module_spec.get("recommended_roster_entry_id", "")) == "aguja",
				"El modulo energia deberia recomendar Aguja para practicar cargas y decision de skill."
			)
		elif expected_module_id == "partes":
			_assert(
				String(module_spec.get("recommended_roster_entry_id", "")) == "cizalla",
				"El modulo partes deberia recomendar Cizalla."
			)
		elif expected_module_id == "recuperacion":
			_assert(
				String(module_spec.get("recommended_roster_entry_id", "")) == "grua",
				"El modulo recuperacion deberia recomendar Grua."
			)
		elif expected_module_id == "sandbox":
			_assert(
				String(module_spec.get("recommended_roster_entry_id", "")) == "patin",
				"Sandbox deberia mantener Patin como default si no hay ultimo robot elegido."
			)
			_assert(
				(module_spec.get("alternate_roster_entry_ids", []) as Array).has("ancla"),
				"Sandbox deberia dejar Ancla como alternativa recomendada de zona."
			)
		_assert(
			module_spec.get("onboarding_topic_ids", []) is Array and not (module_spec.get("onboarding_topic_ids", []) as Array).is_empty(),
			"Cada modulo de practica deberia enlazar al menos un tema de onboarding."
		)
		_assert(
			not String(module_spec.get("lane_scene_path", "")).is_empty(),
			"Cada modulo de practica deberia apuntar a una escena dedicada."
		)
		_assert(
			module_spec.has("supports_two_players"),
			"Cada modulo de practica deberia declarar si soporta dos jugadores."
		)
		var context_card: Dictionary = module_spec.get("context_card", {})
		_assert(
			not context_card.is_empty(),
			"Cada modulo de practica deberia declarar una tarjeta contextual."
		)
		_assert(
			String(context_card.get("title", "")).strip_edges() != "",
			"Cada tarjeta contextual deberia tener titulo."
		)
		_assert(
			context_card.get("lines", []) is Array and not (context_card.get("lines", []) as Array).is_empty(),
			"Cada tarjeta contextual deberia tener lineas cortas."
		)
		_assert(
			bool(module_spec.get("supports_two_players", false)),
			"El primer alcance M5 deberia soportar P1/P2 en todos los modulos."
		)
		_assert(
			bool(module_spec.get("explicit_hud_default", false)),
			"Practica deberia declarar ayuda visible por defecto por modulo."
		)

		var resolved_module: Dictionary = PracticeCatalog.get_module(expected_module_id)
		_assert(
			String(resolved_module.get("id", "")) == expected_module_id,
			"PracticeCatalog.get_module() deberia devolver el modulo correcto por id."
		)

	var first_pass_ids := PracticeCatalog.get_first_pass_module_ids()
	_assert(
		first_pass_ids == ["movimiento", "impacto", "partes", "sandbox"],
		"El primer pase M8 debe priorizar movimiento, choque, skill/partes danadas y sandbox."
	)
	for module_spec in modules:
		var module_id := String(module_spec.get("id", ""))
		_assert(
			String(module_spec.get("player_scope", "")) == "1-2 jugadores locales",
			"%s debe declarar alcance de producto 1-2P." % module_id
		)
		_assert(
			String(module_spec.get("hud_default", "")) == "explicito",
			"%s debe declarar ayuda visible por defecto." % module_id
		)
		_assert(
			module_spec.get("teaching_tags", []) is Array and not (module_spec.get("teaching_tags", []) as Array).is_empty(),
			"%s debe declarar tags pedagogicos verificables." % module_id
		)
	_assert(
		(PracticeCatalog.get_module("partes").get("teaching_tags", []) as Array).has("skill"),
		"`partes` debe absorber la practica aplicada de skill sin crear un modulo nuevo."
	)
	_assert(
		(PracticeCatalog.get_module("partes").get("teaching_tags", []) as Array).has("dano_modular"),
		"`partes` debe cubrir partes danadas como prioridad M8."
	)

	_assert(
		PracticeCatalog.get_module("desconocido").is_empty(),
		"Un modulo desconocido deberia devolver un diccionario vacio."
	)
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
