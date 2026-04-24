extends RefCounted
class_name ShellSettingsCatalog

const MatchConfig = preload("res://scripts/systems/match_config.gd")
const InputPromptCatalog = preload("res://scripts/systems/input_prompt_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const UserSettings = preload("res://scripts/systems/user_settings.gd")


static func get_sections() -> Array[Dictionary]:
	return [
		{
			"id": "audio",
			"title": "Audio",
			"summary": "Master, musica y SFX persisten para shell, match y practica.",
		},
		{
			"id": "video",
			"title": "Video",
			"summary": "Ventana y vsync globales. Solo se tocan desde menu principal.",
		},
		{
			"id": "hud",
			"title": "HUD",
			"summary": "Contextual por defecto en match competitivo; explicito disponible para lectura completa. Practica arranca explicita.",
		},
		{
			"id": "controls",
			"title": "Controles",
			"summary": "Referencia corta de perfiles fijos y joypads conectados.",
		},
	]


static func get_window_mode_options() -> Array[Dictionary]:
	return [
		{"value": UserSettings.WINDOW_MODE_WINDOWED, "label": "Windowed"},
		{"value": UserSettings.WINDOW_MODE_BORDERLESS, "label": "Borderless"},
		{"value": UserSettings.WINDOW_MODE_FULLSCREEN, "label": "Fullscreen"},
	]


static func get_hud_mode_options() -> Array[Dictionary]:
	return [
		{"value": MatchConfig.HudDetailMode.CONTEXTUAL, "label": "Contextual"},
		{"value": MatchConfig.HudDetailMode.EXPLICIT, "label": "Explicito"},
	]


static func get_keyboard_profile_lines() -> Array[String]:
	var lines: Array[String] = []
	for profile in [
		RobotBase.KeyboardProfile.WASD_SPACE,
		RobotBase.KeyboardProfile.ARROWS_ENTER,
		RobotBase.KeyboardProfile.NUMPAD,
		RobotBase.KeyboardProfile.IJKL,
	]:
		var label := String(RobotBase.KEYBOARD_PROFILE_LABELS.get(profile, "teclado"))
		var attack := String(RobotBase.KEYBOARD_PROFILE_ATTACK_LABELS.get(profile, "?"))
		var energy := String(RobotBase.KEYBOARD_PROFILE_ENERGY_LABELS.get(profile, "?/?"))
		lines.append("%s | ataque %s | energia %s" % [label, attack, energy])
	return lines


static func get_control_mode_lines() -> Array[String]:
	return [
		"Easy | apunta con el movimiento",
		"Hard | torso independiente y aim dedicado",
	]


static func get_connected_joypad_lines() -> Array[String]:
	return InputPromptCatalog.get_connected_joypad_lines()


static func get_controls_note() -> String:
	return (
		"Menu | %s. Sin remapeo libre en M9: perfiles de teclado fijos y referencia visible."
		% InputPromptCatalog.get_menu_navigation_help_line(true, true)
	)
