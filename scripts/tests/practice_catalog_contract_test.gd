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

		var resolved_module: Dictionary = PracticeCatalog.get_module(expected_module_id)
		_assert(
			String(resolved_module.get("id", "")) == expected_module_id,
			"PracticeCatalog.get_module() deberia devolver el modulo correcto por id."
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
