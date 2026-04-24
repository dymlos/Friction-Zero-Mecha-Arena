extends SceneTree

const SETTINGS_SCREEN := preload("res://scenes/shell/settings_screen.tscn")
const HOW_TO_PLAY_SCREEN := preload("res://scenes/shell/how_to_play_screen.tscn")
const CHARACTERS_SCREEN := preload("res://scenes/shell/characters_screen.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_settings_pause_scope()
	await _validate_how_to_play_pause_scope()
	await _validate_characters_pause_scope()
	_finish()


func _validate_settings_pause_scope() -> void:
	var settings = SETTINGS_SCREEN.instantiate()
	_assert(settings.has_method("set_surface_scope"), "SettingsScreen deberia aceptar scope de superficie.")
	if settings.has_method("set_surface_scope"):
		settings.call("set_surface_scope", "pause")
	root.add_child(settings)
	await process_frame
	await process_frame

	_assert(
		settings.call("get_section_ids") == ["audio", "hud"],
		"Settings en pausa deberia exponer solo audio/HUD."
	)
	var video_button := settings.find_child("VideoButton", true, false) as Button
	var controls_button := settings.find_child("ControlsButton", true, false) as Button
	_assert(
		video_button != null and (not video_button.visible or video_button.disabled),
		"Settings en pausa deberia ocultar o deshabilitar Video."
	)
	_assert(
		controls_button != null and (not controls_button.visible or controls_button.disabled),
		"Settings en pausa deberia ocultar o deshabilitar Controles."
	)
	var before_snapshot := settings.call("get_settings_snapshot") as Dictionary
	var window_result: Variant = settings.call("set_window_mode", "fullscreen")
	var vsync_result: Variant = settings.call("set_vsync_enabled", false)
	var after_snapshot := settings.call("get_settings_snapshot") as Dictionary
	_assert(
		window_result == false or String(after_snapshot.get("window_mode", "")) == String(before_snapshot.get("window_mode", "")),
		"Settings en pausa no deberia persistir window mode."
	)
	_assert(
		vsync_result == false or bool(after_snapshot.get("vsync_enabled", true)) == bool(before_snapshot.get("vsync_enabled", true)),
		"Settings en pausa no deberia persistir vsync."
	)
	_assert(settings.call("set_master_volume", 0.72) != false, "Settings en pausa deberia permitir audio.")
	_assert(settings.call("set_hud_detail_mode", 1) != false, "Settings en pausa deberia permitir HUD.")

	settings.queue_free()
	await process_frame


func _validate_how_to_play_pause_scope() -> void:
	var how_to_play = HOW_TO_PLAY_SCREEN.instantiate()
	_assert(how_to_play.has_method("set_surface_scope"), "HowToPlayScreen deberia aceptar scope de superficie.")
	if how_to_play.has_method("set_surface_scope"):
		how_to_play.call("set_surface_scope", "pause")
	root.add_child(how_to_play)
	await process_frame
	await process_frame

	var practice_button := how_to_play.find_child("PracticeButton", true, false) as Button
	_assert(
		practice_button != null and (not practice_button.visible or practice_button.disabled),
		"How to Play en pausa no deberia mostrar CTA usable hacia Practica."
	)
	var practice_emitted := false
	how_to_play.practice_requested.connect(func(_module_id: String) -> void:
		practice_emitted = true
	)
	how_to_play.call("open_selected_topic_practice")
	await process_frame
	_assert(not practice_emitted, "How to Play en pausa no deberia emitir practice_requested.")

	var back_state := {"emitted": false}
	how_to_play.back_requested.connect(func() -> void:
		back_state["emitted"] = true
	)
	how_to_play.call("go_back")
	await process_frame
	_assert(bool(back_state.get("emitted", false)), "How to Play en pausa deberia conservar Volver.")

	how_to_play.queue_free()
	await process_frame


func _validate_characters_pause_scope() -> void:
	var characters = CHARACTERS_SCREEN.instantiate()
	_assert(characters.has_method("set_surface_scope"), "CharactersScreen deberia aceptar scope de superficie.")
	if characters.has_method("set_surface_scope"):
		characters.call("set_surface_scope", "pause")
	root.add_child(characters)
	await process_frame
	await process_frame

	_assert(characters.has_method("set_filter"), "Characters en pausa deberia conservar filtros.")
	characters.call("set_filter", "range_zone")
	var visible_labels: Array = characters.call("get_visible_character_labels")
	_assert(
		visible_labels.has("Aguja") and visible_labels.has("Ancla"),
		"Characters en pausa deberia mantener filtros de identidad."
	)
	_assert(
		not characters.has_method("build_launch_config") and not characters.has_method("set_slot_active"),
		"Characters en pausa no deberia exponer APIs de seleccion de slots."
	)

	var back_state := {"emitted": false}
	characters.back_requested.connect(func() -> void:
		back_state["emitted"] = true
	)
	characters.call("go_back")
	await process_frame
	_assert(bool(back_state.get("emitted", false)), "Characters en pausa deberia conservar Volver.")

	characters.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
