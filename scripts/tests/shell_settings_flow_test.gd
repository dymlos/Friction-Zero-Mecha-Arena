extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")
const MatchConfig = preload("res://scripts/systems/match_config.gd")

const TEST_STORAGE_PATH := "user://test_shell_settings_flow.tres"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_storage()
	var store := root.get_node_or_null("/root/UserSettingsStore")
	_assert(store != null, "El proyecto deberia registrar UserSettingsStore como autoload.")
	if store == null:
		_finish()
		return

	_assert(store.has_method("set_storage_path_for_tests"), "UserSettingsStore deberia permitir aislar tests.")
	_assert(store.has_method("reset_to_defaults"), "UserSettingsStore deberia permitir restaurar defaults.")
	if not (store.has_method("set_storage_path_for_tests") and store.has_method("reset_to_defaults")):
		_finish()
		return

	store.call("set_storage_path_for_tests", TEST_STORAGE_PATH)
	store.call("reset_to_defaults")

	var game_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(game_shell)
	current_scene = game_shell
	await process_frame
	await process_frame

	_assert(game_shell.has_method("open_settings"), "GameShell deberia exponer la navegacion hacia Settings.")
	if not game_shell.has_method("open_settings"):
		await _cleanup_current_scene()
		_cleanup_store(store)
		_cleanup_storage()
		_finish()
		return

	game_shell.call("open_settings")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "settings",
		"La shell deberia poder abrir la pantalla Settings."
	)

	var settings_screen: Variant = game_shell.call("get_active_screen")
	_assert(settings_screen != null, "GameShell deberia devolver la pantalla Settings activa.")
	if settings_screen == null:
		await _cleanup_current_scene()
		_cleanup_store(store)
		_cleanup_storage()
		_finish()
		return

	_assert(settings_screen.has_method("get_section_ids"), "Settings deberia exponer sus secciones para tests.")
	_assert(settings_screen.has_method("set_surface_scope"), "Settings deberia exponer scope global/pausa.")
	_assert(settings_screen.has_method("get_settings_snapshot"), "Settings deberia exponer el snapshot activo.")
	_assert(settings_screen.has_method("set_master_volume"), "Settings deberia permitir editar master.")
	_assert(settings_screen.has_method("set_music_volume"), "Settings deberia permitir editar musica.")
	_assert(settings_screen.has_method("set_sfx_volume"), "Settings deberia permitir editar SFX.")
	_assert(settings_screen.has_method("set_window_mode"), "Settings deberia permitir editar window mode.")
	_assert(settings_screen.has_method("set_vsync_enabled"), "Settings deberia permitir editar vsync.")
	_assert(settings_screen.has_method("set_hud_detail_mode"), "Settings deberia permitir editar el default de HUD.")
	_assert(settings_screen.has_method("get_controls_summary_text"), "Settings deberia exponer el resumen de controles.")
	_assert(settings_screen.has_method("focus_back_button"), "Settings deberia poder mover foco a Volver.")
	_assert(settings_screen.has_method("go_back"), "Settings deberia exponer una salida explicita.")
	if _failed:
		await _cleanup_current_scene()
		_cleanup_store(store)
		_cleanup_storage()
		_finish()
		return

	var section_ids: Array = settings_screen.call("get_section_ids")
	_assert(
		section_ids == ["audio", "video", "hud", "controls"],
		"Settings deberia mantener el ordering Audio/Video/HUD/Controles."
	)
	settings_screen.call("set_surface_scope", "global")
	section_ids = settings_screen.call("get_section_ids")
	_assert(
		section_ids == ["audio", "video", "hud", "controls"],
		"Settings en scope global deberia conservar Audio/Video/HUD/Controles."
	)
	settings_screen.call("set_surface_scope", "pause")
	section_ids = settings_screen.call("get_section_ids")
	_assert(
		section_ids == ["audio", "hud"],
		"Settings en pausa debe limitarse a audio/HUD."
	)
	_assert(
		not bool(settings_screen.call("set_window_mode", "fullscreen")),
		"Pausa no debe aceptar cambios de video."
	)
	settings_screen.call("set_surface_scope", "global")
	var snapshot := settings_screen.call("get_settings_snapshot") as Dictionary
	_assert(
		int(snapshot.get("default_hud_detail_mode", -1)) == MatchConfig.HudDetailMode.CONTEXTUAL,
		"Settings deberia arrancar con el HUD default persistente."
	)
	_assert(
		String(snapshot.get("window_mode", "")) == "windowed",
		"Settings deberia arrancar mostrando windowed por default."
	)

	var controls_summary := String(settings_screen.call("get_controls_summary_text"))
	_assert(
		controls_summary.contains("Simple") and controls_summary.contains("Avanzado"),
		"Settings deberia explicar la referencia compacta Simple/Avanzado."
	)
	_assert(
		controls_summary.to_lower().contains("joypad"),
		"Settings deberia listar joypads conectados o su ausencia."
	)
	_assert(
		controls_summary.contains("Joypads | ninguno conectado") or controls_summary.contains("Joypad "),
		"Settings deberia listar joypads conectados con prompt o declarar ausencia."
	)

	settings_screen.call("set_master_volume", 0.35)
	settings_screen.call("set_music_volume", 0.45)
	settings_screen.call("set_sfx_volume", 0.55)
	settings_screen.call("set_window_mode", "borderless")
	settings_screen.call("set_vsync_enabled", false)
	settings_screen.call("set_hud_detail_mode", MatchConfig.HudDetailMode.CONTEXTUAL)
	await process_frame
	await process_frame

	settings_screen.call("focus_back_button")
	await process_frame
	await process_frame
	settings_screen.call("go_back")
	await process_frame
	await process_frame

	_assert(
		String(game_shell.call("get_active_screen_id")) == "main_menu",
		"Volver desde Settings deberia regresar al menu principal."
	)
	var focus_owner := root.get_viewport().gui_get_focus_owner()
	_assert(
		focus_owner != null and String(focus_owner.name) == "SettingsButton",
		"Al regresar desde Settings, el menu principal deberia restaurar foco en su acceso."
	)

	await _cleanup_current_scene()

	var reopened_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(reopened_shell)
	current_scene = reopened_shell
	await process_frame
	await process_frame

	reopened_shell.call("open_settings")
	await process_frame
	await process_frame

	settings_screen = reopened_shell.call("get_active_screen")
	snapshot = settings_screen.call("get_settings_snapshot") as Dictionary
	_assert(
		is_equal_approx(float(snapshot.get("audio_master_volume", -1.0)), 0.35),
		"Settings deberia persistir master entre sesiones de shell."
	)
	_assert(
		is_equal_approx(float(snapshot.get("audio_music_volume", -1.0)), 0.45),
		"Settings deberia persistir musica entre sesiones de shell."
	)
	_assert(
		is_equal_approx(float(snapshot.get("audio_sfx_volume", -1.0)), 0.55),
		"Settings deberia persistir SFX entre sesiones de shell."
	)
	_assert(
		String(snapshot.get("window_mode", "")) == "borderless",
		"Settings deberia persistir el modo de ventana."
	)
	_assert(
		not bool(snapshot.get("vsync_enabled", true)),
		"Settings deberia persistir el flag de vsync."
	)
	_assert(
		int(snapshot.get("default_hud_detail_mode", -1)) == MatchConfig.HudDetailMode.CONTEXTUAL,
		"Settings deberia persistir el default de HUD."
	)

	await _cleanup_current_scene()
	_cleanup_store(store)
	_cleanup_storage()
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


func _cleanup_store(store: Node) -> void:
	if store == null:
		return
	if store.has_method("set_storage_path_for_tests"):
		store.call("set_storage_path_for_tests", TEST_STORAGE_PATH)
	if store.has_method("reset_to_defaults"):
		store.call("reset_to_defaults")


func _cleanup_storage() -> void:
	if FileAccess.file_exists(TEST_STORAGE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_STORAGE_PATH))


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
