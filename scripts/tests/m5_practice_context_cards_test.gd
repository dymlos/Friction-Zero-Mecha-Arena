extends SceneTree

const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const PracticeDirector = preload("res://scripts/practice/practice_director.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for module in PracticeCatalog.get_modules():
		var module_id := String(module.get("id", ""))
		var card: Dictionary = module.get("context_card", {})
		_assert(not card.is_empty(), "%s debe declarar context_card." % module_id)
		_assert(String(card.get("title", "")).strip_edges() != "", "%s debe tener titulo de tarjeta." % module_id)
		_assert(card.get("lines", []) is Array, "%s debe tener lineas de tarjeta." % module_id)
		var lines: Array = card.get("lines", [])
		_assert(lines.size() >= 1 and lines.size() <= 3, "%s debe tener entre una y tres lineas de tarjeta." % module_id)
		for line in lines:
			_assert(String(line).length() <= 96, "%s tiene una linea demasiado larga." % module_id)
		_assert(bool(module.get("supports_two_players", false)), "%s debe soportar 1-2 jugadores en M5." % module_id)
		_assert(bool(module.get("explicit_hud_default", false)), "%s debe declarar ayuda visible por defecto." % module_id)

	var director := PracticeDirector.new()
	_assert(director.has_method("get_context_card_lines"), "PracticeDirector debe exponer tarjeta contextual.")
	_assert(director.has_method("get_context_card_title"), "PracticeDirector debe exponer titulo de tarjeta.")
	director.queue_free()

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
