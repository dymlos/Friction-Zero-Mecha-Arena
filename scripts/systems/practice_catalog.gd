extends RefCounted
class_name PracticeCatalog


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
		},
		{
			"id": "impacto",
			"label": "Impacto",
			"summary": "Leer angulo, timing y borde para desplazar un objetivo con un choque decisivo.",
			"recommended_roster_entry_id": "ariete",
			"onboarding_topic_ids": ["victory", "controls"],
			"lane_scene_path": "res://scenes/practice/stations/impact_lane.tscn",
			"supports_two_players": true,
		},
		{
			"id": "energia",
			"label": "Energia",
			"summary": "Sentir la diferencia entre piernas, brazos y Overdrive con cambios visibles en juego.",
			"recommended_roster_entry_id": "grua",
			"onboarding_topic_ids": ["energy"],
			"lane_scene_path": "res://scenes/practice/stations/energy_lane.tscn",
			"supports_two_players": true,
		},
		{
			"id": "partes",
			"label": "Partes",
			"summary": "Practicar dano modular y leer que cambia cuando un robot pierde brazos o piernas.",
			"recommended_roster_entry_id": "cizalla",
			"onboarding_topic_ids": ["parts"],
			"lane_scene_path": "res://scenes/practice/stations/parts_lane.tscn",
			"supports_two_players": true,
		},
		{
			"id": "recuperacion",
			"label": "Recuperacion",
			"summary": "Devolver una parte aliada o negar una rival sin salir del espacio jugable.",
			"recommended_roster_entry_id": "grua",
			"onboarding_topic_ids": ["recovery", "parts"],
			"lane_scene_path": "res://scenes/practice/stations/recovery_lane.tscn",
			"supports_two_players": true,
		},
		{
			"id": "sandbox",
			"label": "Sandbox",
			"summary": "Combinar movimiento, impacto, energia y partes sin objetivo de fallo.",
			"recommended_roster_entry_id": "patin",
			"onboarding_topic_ids": ["controls", "energy", "parts", "recovery"],
			"lane_scene_path": "res://scenes/practice/stations/sandbox_lane.tscn",
			"supports_two_players": true,
		},
	]


static func get_module(module_id: String) -> Dictionary:
	for module_spec in get_modules():
		if String(module_spec.get("id", "")) == module_id:
			return module_spec

	return {}
