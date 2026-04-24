extends RefCounted
class_name PracticeCatalog

const FIRST_PASS_MODULE_IDS := ["movimiento", "impacto", "partes", "sandbox"]
const PLAYER_SCOPE_LABEL := "1-2 jugadores locales"
const HUD_DEFAULT_LABEL := "explicito"


static func get_modules() -> Array:
	return [
		{
			"id": "movimiento",
			"label": "Movimiento",
			"summary": "Patinar, frenar y volver a entrar con control usando la misma pista en Easy o Hard.",
			"recommended_roster_entry_id": "patin",
			"onboarding_topic_ids": ["controls"],
			"lane_scene_path": "res://scenes/practice/stations/movement_lane.tscn",
			"supports_two_players": true,
			"explicit_hud_default": true,
			"player_scope": PLAYER_SCOPE_LABEL,
			"hud_default": HUD_DEFAULT_LABEL,
			"teaching_tags": ["movimiento", "easy_hard", "control"],
			"context_card": {
				"title": "Que probar",
				"lines": [
					"Arranca tarde, desliza libre y frena antes de perder lectura.",
					"Compara Easy y Hard sin cambiar la pista.",
				],
			},
		},
		{
			"id": "impacto",
			"label": "Impacto",
			"summary": "Leer angulo, timing y borde para desplazar un objetivo con un choque decisivo.",
			"recommended_roster_entry_id": "ariete",
			"onboarding_topic_ids": ["victory", "controls"],
			"lane_scene_path": "res://scenes/practice/stations/impact_lane.tscn",
			"supports_two_players": true,
			"explicit_hud_default": true,
			"player_scope": PLAYER_SCOPE_LABEL,
			"hud_default": HUD_DEFAULT_LABEL,
			"teaching_tags": ["choque", "borde", "timing"],
			"context_card": {
				"title": "Que probar",
				"lines": [
					"Busca angulo y timing antes de acelerar.",
					"El objetivo es desplazar, no solo tocar.",
				],
			},
		},
		{
			"id": "energia",
			"label": "Energia",
			"summary": "Sentir la diferencia entre piernas, brazos y Overdrive con cambios visibles en juego.",
			"recommended_roster_entry_id": "aguja",
			"onboarding_topic_ids": ["energy"],
			"lane_scene_path": "res://scenes/practice/stations/energy_lane.tscn",
			"supports_two_players": true,
			"explicit_hud_default": true,
			"player_scope": PLAYER_SCOPE_LABEL,
			"hud_default": HUD_DEFAULT_LABEL,
			"teaching_tags": ["energia", "overdrive", "recursos"],
			"context_card": {
				"title": "Que probar",
				"lines": [
					"Piernas cambian control; brazos cambian empuje.",
					"Overdrive es una apuesta corta con castigo despues.",
				],
			},
		},
		{
			"id": "partes",
			"label": "Partes",
			"summary": "Usar Corte para abrir una ventana de desarme y leer dano modular en el cuerpo.",
			"recommended_roster_entry_id": "cizalla",
			"onboarding_topic_ids": ["parts"],
			"lane_scene_path": "res://scenes/practice/stations/parts_lane.tscn",
			"supports_two_players": true,
			"explicit_hud_default": true,
			"player_scope": PLAYER_SCOPE_LABEL,
			"hud_default": HUD_DEFAULT_LABEL,
			"teaching_tags": ["skill", "dano_modular", "corte", "lectura_corporal"],
			"context_card": {
				"title": "Que probar",
				"lines": [
					"Activa Corte antes de castigar una parte tocada.",
					"Mira el cuerpo: brazos al frente, piernas atras.",
				],
			},
		},
		{
			"id": "recuperacion",
			"label": "Recuperacion",
			"summary": "Devolver una parte aliada o negar una rival sin salir del espacio jugable.",
			"recommended_roster_entry_id": "grua",
			"onboarding_topic_ids": ["recovery", "parts"],
			"lane_scene_path": "res://scenes/practice/stations/recovery_lane.tscn",
			"supports_two_players": true,
			"explicit_hud_default": true,
			"player_scope": PLAYER_SCOPE_LABEL,
			"hud_default": HUD_DEFAULT_LABEL,
			"teaching_tags": ["recuperacion", "negacion", "partes"],
			"context_card": {
				"title": "Que probar",
				"lines": [
					"Devuelve una parte aliada o niega una rival.",
					"Cargar partes bloquea otras acciones activas.",
				],
			},
		},
		{
			"id": "sandbox",
			"label": "Sandbox",
			"summary": "Combinar movimiento, impacto, energia y partes sin objetivo de fallo.",
			"recommended_roster_entry_id": "patin",
			"alternate_roster_entry_ids": ["ancla"],
			"onboarding_topic_ids": ["controls", "energy", "parts", "recovery"],
			"lane_scene_path": "res://scenes/practice/stations/sandbox_lane.tscn",
			"supports_two_players": true,
			"explicit_hud_default": true,
			"player_scope": PLAYER_SCOPE_LABEL,
			"hud_default": HUD_DEFAULT_LABEL,
			"teaching_tags": ["sandbox_guiado", "skill", "movimiento", "choque", "dano_modular"],
			"context_card": {
				"title": "Que probar",
				"lines": [
					"Combina movimiento, impacto, energia y partes sin fallo.",
					"Experimenta sin perder lectura de borde y cuerpo.",
				],
			},
		},
	]


static func get_first_pass_module_ids() -> Array[String]:
	var module_ids: Array[String] = []
	for module_id in FIRST_PASS_MODULE_IDS:
		module_ids.append(String(module_id))
	return module_ids


static func get_module(module_id: String) -> Dictionary:
	for module_spec in get_modules():
		if String(module_spec.get("id", "")) == module_id:
			return module_spec

	return {}
