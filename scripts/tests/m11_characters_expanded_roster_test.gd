extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(game_shell)
	current_scene = game_shell

	await process_frame
	await process_frame

	game_shell.call("open_characters", "local_match_setup")
	await process_frame
	await process_frame

	var characters_screen: Variant = game_shell.call("get_active_screen")
	_assert(characters_screen != null, "Characters deberia abrirse desde la shell.")
	if characters_screen == null:
		await _cleanup_current_scene()
		_finish()
		return

	_assert(
		characters_screen.has_method("get_visible_character_labels"),
		"Characters deberia exponer la lista visible para validar filtros."
	)
	_assert(
		characters_screen.has_method("select_character_by_id"),
		"Characters deberia permitir seleccionar una ficha por id estable."
	)
	_assert(
		characters_screen.has_method("set_filter"),
		"Characters deberia permitir cambiar filtro desde tests y botones."
	)
	_assert(
		characters_screen.has_method("get_detail_text"),
		"Characters deberia exponer el detalle visible como contrato de comunicacion."
	)
	if not (
		characters_screen.has_method("get_visible_character_labels")
		and characters_screen.has_method("select_character_by_id")
		and characters_screen.has_method("set_filter")
		and characters_screen.has_method("get_detail_text")
	):
		await _cleanup_current_scene()
		_finish()
		return

	var labels: Array = characters_screen.call("get_visible_character_labels")
	_assert(labels == ["Ariete", "Grua", "Cizalla", "Patin", "Aguja", "Ancla"], "Characters deberia listar seis nombres competitivos.")

	characters_screen.call("select_character_by_id", "aguja")
	await process_frame
	var aguja_detail := String(characters_screen.call("get_detail_text"))
	_assert(aguja_detail.contains("Pulso"), "Seleccionar Aguja deberia mostrar Pulso.")
	_assert(aguja_detail.contains("FFA |"), "Cada ficha deberia mostrar una linea de modo FFA.")
	_assert(aguja_detail.contains("Teams |"), "Cada ficha deberia mostrar una linea de modo Teams.")

	characters_screen.call("select_character_by_id", "ancla")
	await process_frame
	var ancla_detail := String(characters_screen.call("get_detail_text"))
	_assert(ancla_detail.contains("Baliza"), "Seleccionar Ancla deberia mostrar Baliza.")

	characters_screen.call("set_filter", "range_zone")
	await process_frame
	var range_labels: Array = characters_screen.call("get_visible_character_labels")
	_assert(range_labels.has("Ancla"), "El filtro Rango / zona no deberia ocultar Ancla.")
	_assert(range_labels.has("Aguja"), "El filtro Rango / zona deberia incluir Aguja.")
	_assert(range_labels.has("Grua"), "El filtro Rango / zona deberia incluir Grua por comunicacion tactica.")
	_assert(not range_labels.has("Ariete"), "El filtro Rango / zona deberia ocultar Ariete.")

	characters_screen.call("set_filter", "teaching_focus")
	await process_frame
	var focus_labels: Array = characters_screen.call("get_visible_character_labels")
	_assert(
		focus_labels == ["Ariete", "Patin", "Cizalla"],
		"El filtro Foco inicial deberia mostrar Ariete, Patin y Cizalla en orden ensenable."
	)
	characters_screen.call("select_character_by_id", "cizalla")
	await process_frame
	var cizalla_detail := String(characters_screen.call("get_detail_text"))
	_assert(cizalla_detail.contains("Corte"), "Seleccionar Cizalla deberia mostrar Corte como skill principal.")
	_assert(cizalla_detail.contains("Skill/carga"), "Characters deberia mostrar el boton de skill/carga.")
	_assert(cizalla_detail.contains("Choque"), "Characters deberia mostrar el boton de choque/ataque.")
	_assert(cizalla_detail.contains("Energia"), "Characters deberia mostrar los botones de energia.")
	_assert(cizalla_detail.contains("Overdrive"), "Characters deberia mostrar el boton de Overdrive.")

	characters_screen.call("focus_back_button")
	await process_frame
	characters_screen.call("go_back")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "local_match_setup",
		"Volver desde Characters deberia conservar el owner local_match_setup."
	)
	var focus_owner := root.get_viewport().gui_get_focus_owner()
	_assert(
		focus_owner != null and String(focus_owner.name) == "CharactersButton",
		"Volver desde Characters deberia restaurar foco owner-aware."
	)

	await _cleanup_current_scene()
	_finish()


func _cleanup_current_scene() -> void:
	if current_scene == null or not is_instance_valid(current_scene):
		return

	var scene := current_scene
	var parent := scene.get_parent()
	if parent != null:
		parent.remove_child(scene)
	scene.free()
	current_scene = null
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
