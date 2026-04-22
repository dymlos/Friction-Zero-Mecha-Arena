extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

const EXPECTED_SCENE_ORDER := [
	{
		"path": "res://scenes/main/main.tscn",
		"label": "Equipos base",
	},
	{
		"path": "res://scenes/main/main_teams_validation.tscn",
		"label": "Equipos rapido",
	},
	{
		"path": "res://scenes/main/main_ffa.tscn",
		"label": "FFA base",
	},
	{
		"path": "res://scenes/main/main_ffa_validation.tscn",
		"label": "FFA rapido",
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_lab_scene_selector_cycles_between_variants()
	_finish()


func _validate_lab_scene_selector_cycles_between_variants() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	current_scene = main

	await process_frame
	await process_frame

	_assert(main.has_method("cycle_lab_scene_variant"), "Main deberia poder ciclar escenas/laboratorios runtime.")
	_assert(main.has_method("get_lab_scene_variant_summary_line"), "Main deberia exponer un resumen legible de la escena activa.")
	if not main.has_method("cycle_lab_scene_variant") or not main.has_method("get_lab_scene_variant_summary_line"):
		await _cleanup_current_scene()
		return

	_assert(
		String(main.call("get_lab_scene_variant_summary_line")).contains("Equipos base"),
		"El resumen runtime deberia arrancar identificando la escena base de Equipos."
	)

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel") as Label
	_assert(round_label != null, "El HUD deberia seguir exponiendo RoundLabel.")
	if round_label != null:
		_assert(
			round_label.text.contains("Escena | Equipos base"),
			"El HUD deberia dejar visible la escena activa para el loop de laboratorio."
		)

	for index in range(1, EXPECTED_SCENE_ORDER.size()):
		var expected: Dictionary = EXPECTED_SCENE_ORDER[index]
		current_scene.call("cycle_lab_scene_variant")
		await process_frame
		await process_frame
		await process_frame

		var active_scene := current_scene
		_assert(active_scene != null, "El ciclo runtime deberia dejar una escena activa tras cambiar de laboratorio.")
		if active_scene == null:
			return

		_assert(
			String(active_scene.scene_file_path) == String(expected.path),
			"El selector runtime deberia avanzar al siguiente laboratorio esperado."
		)
		_assert(
			active_scene.has_method("get_lab_scene_variant_summary_line"),
			"La escena recargada deberia conservar el resumen del selector runtime."
		)
		if active_scene.has_method("get_lab_scene_variant_summary_line"):
			_assert(
				String(active_scene.call("get_lab_scene_variant_summary_line")).contains(String(expected.label)),
				"Cada laboratorio deberia anunciar su variante activa al cargarse."
			)

		round_label = active_scene.get_node_or_null("UI/MatchHud/Root/RoundLabel") as Label
		_assert(round_label != null, "Cada laboratorio deberia seguir exponiendo RoundLabel.")
		if round_label != null:
			_assert(
				round_label.text.contains("Escena | %s" % expected.label),
				"El HUD del laboratorio recargado deberia reflejar la escena activa."
			)

	current_scene.call("cycle_lab_scene_variant")
	await process_frame
	await process_frame
	await process_frame

	var wrapped_scene := current_scene
	_assert(wrapped_scene != null, "El ciclo runtime deberia poder volver a una escena valida.")
	if wrapped_scene != null:
		_assert(
			String(wrapped_scene.scene_file_path) == String(EXPECTED_SCENE_ORDER[0].path),
			"El selector runtime deberia wrapear de nuevo al laboratorio base inicial."
		)

	await _cleanup_current_scene()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_current_scene() -> void:
	var active_scene := current_scene
	if not is_instance_valid(active_scene):
		return

	var parent := active_scene.get_parent()
	if parent != null:
		parent.remove_child(active_scene)
	active_scene.free()
	current_scene = null
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
