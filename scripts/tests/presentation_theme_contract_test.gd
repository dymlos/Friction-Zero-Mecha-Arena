extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")
const MATCH_HUD_SCENE := preload("res://scenes/ui/match_hud.tscn")
const PRESENTATION_PALETTE_PATH := "res://data/presentation/default_presentation_palette.tres"
const UI_THEME_PATH := "res://data/theme/fz_ui_theme.tres"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var palette := load(PRESENTATION_PALETTE_PATH)
	_assert(palette != null, "El slice M6 deberia exponer una paleta compartida en data/presentation.")
	if palette != null:
		_assert(
			palette.get("surface_background") is Color,
			"La paleta compartida deberia incluir `surface_background`."
		)
		_assert(
			palette.get("accent_warm") is Color,
			"La paleta compartida deberia incluir `accent_warm`."
		)
		_assert(
			palette.get("accent_cool") is Color,
			"La paleta compartida deberia incluir `accent_cool`."
		)

	var ui_theme := load(UI_THEME_PATH)
	_assert(ui_theme is Theme, "El slice M6 deberia exponer un Theme compartido para shell y HUD.")

	var game_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(game_shell)
	current_scene = game_shell
	await process_frame
	await process_frame

	_assert(game_shell.theme != null, "GameShell deberia aplicar el Theme compartido desde la raiz.")
	if game_shell.theme != null:
		_assert(
			game_shell.theme.resource_path == UI_THEME_PATH,
			"GameShell deberia usar fz_ui_theme.tres como base comun."
		)

	await _cleanup_current_scene()

	var match_hud := MATCH_HUD_SCENE.instantiate()
	root.add_child(match_hud)
	current_scene = match_hud
	await process_frame
	await process_frame

	var match_hud_root := match_hud.get_node_or_null("Root") as Control
	_assert(match_hud_root != null, "MatchHud deberia exponer un Root Control para aplicar theme compartido.")
	_assert(match_hud_root != null and match_hud_root.theme != null, "MatchHud deberia aplicar el Theme compartido para overlays.")
	if match_hud_root != null and match_hud_root.theme != null:
		_assert(
			match_hud_root.theme.resource_path == UI_THEME_PATH,
			"MatchHud deberia usar fz_ui_theme.tres como base comun."
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
