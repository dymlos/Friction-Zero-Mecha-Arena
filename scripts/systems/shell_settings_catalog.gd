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
			"summary": "Volumen general, musica y efectos.",
		},
		{
			"id": "video",
			"title": "Video",
			"summary": "Modo de ventana y sincronizacion vertical.",
		},
		{
			"id": "hud",
			"title": "Ayudas",
			"summary": "Elige cuanta informacion se muestra durante la partida.",
		},
		{
			"id": "controls",
			"title": "Controles",
			"summary": "Consulta botones de teclado y joysticks conectados.",
		},
	]


static func get_window_mode_options() -> Array[Dictionary]:
	return [
		{"value": UserSettings.WINDOW_MODE_WINDOWED, "label": "Ventana"},
		{"value": UserSettings.WINDOW_MODE_BORDERLESS, "label": "Sin bordes"},
		{"value": UserSettings.WINDOW_MODE_FULLSCREEN, "label": "Pantalla completa"},
	]


static func get_hud_mode_options() -> Array[Dictionary]:
	return [
		{"value": MatchConfig.HudDetailMode.CONTEXTUAL, "label": "Limpia"},
		{"value": MatchConfig.HudDetailMode.EXPLICIT, "label": "Completa"},
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
		"Simple | el robot mira hacia donde se mueve",
		"Avanzado | el torso apunta separado del movimiento",
	]


static func get_connected_joypad_lines() -> Array[String]:
	return InputPromptCatalog.get_connected_joypad_lines()


static func get_controls_note() -> String:
	return (
		"Menu | %s. Por ahora se usan perfiles fijos; remapeo libre vendra despues."
		% InputPromptCatalog.get_menu_navigation_help_line(true, true)
	)
