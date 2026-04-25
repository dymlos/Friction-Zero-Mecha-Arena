extends RefCounted
class_name MapCatalog

const MatchController = preload("res://scripts/systems/match_controller.gd")

const MAP_TEAMS_2_4 := "borde_fundicion_teams_2_4"
const MAP_FFA_2_4 := "borde_fundicion_ffa_2_4"
const MAP_TEAMS_5_8 := "borde_fundicion_teams_5_8"
const MAP_FFA_5_8 := "borde_fundicion_ffa_5_8"

const MAPS := [
	{
		"id": MAP_TEAMS_2_4,
		"label": "Fundicion compacta",
		"setup_label": "Fundicion compacta | Equipos",
		"mode": MatchController.MatchMode.TEAMS,
		"min_players": 1,
		"max_players": 4,
		"range_label": "ideal para 2-4",
		"scene_path": "res://scenes/main/main.tscn",
		"mode_focus": "duelos claros, rescate cercano y choques legibles",
		"route_goal": "rutas cortas para volver al choque sin convertir el centro en objetivo permanente",
		"edge_goal": "borde valioso y peligroso como amenaza principal de ring-out",
		"center_goal": "centro de transicion para reposicionar, no zona de control estable",
	},
	{
		"id": MAP_FFA_2_4,
		"label": "Fundicion compacta",
		"setup_label": "Fundicion compacta | Todos contra todos",
		"mode": MatchController.MatchMode.FFA,
		"min_players": 1,
		"max_players": 4,
		"range_label": "ideal para 2-4",
		"scene_path": "res://scenes/main/main_ffa.tscn",
		"mode_focus": "supervivencia, oportunismo y cruces rapidos",
		"route_goal": "rotacion corta entre duelos sin depender de reglas de equipo",
		"edge_goal": "borde valioso y peligroso para premiar lectura de ring-out",
		"center_goal": "centro de transicion para escapar y entrar a terceros",
	},
	{
		"id": MAP_TEAMS_5_8,
		"label": "Fundicion lateral",
		"setup_label": "Fundicion lateral | Equipos 4v4",
		"mode": MatchController.MatchMode.TEAMS,
		"min_players": 5,
		"max_players": 8,
		"range_label": "para 5-8 jugadores",
		"scene_path": "res://scenes/main/main_teams_large.tscn",
		"mode_focus": "rescate, pushes coordinados y coordinacion lateral",
		"route_goal": "dos carriles laterales utiles conectan aliados, soporte post-muerte y retornos al borde",
		"edge_goal": "borde valioso y peligroso con pickups que fuerzan compromisos de equipo",
		"center_goal": "centro de transicion que permite reagrupar sin volverse refugio permanente",
	},
	{
		"id": MAP_FFA_5_8,
		"label": "Fundicion rotativa",
		"setup_label": "Fundicion rotativa | Todos contra todos",
		"mode": MatchController.MatchMode.FFA,
		"min_players": 5,
		"max_players": 8,
		"range_label": "para 5-8 jugadores",
		"scene_path": "res://scenes/main/main_ffa_large.tscn",
		"mode_focus": "rotacion, third-party y supervivencia oportunista",
		"route_goal": "rutas diagonales y laterales permiten entrar/salir de duelos sin llenar el mapa de distancia vacia",
		"edge_goal": "borde valioso y peligroso con pickups que tientan a exponerse",
		"center_goal": "centro de transicion que acelera cruces y evita ownership estable",
	},
]


static func get_all_maps() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for map_entry in MAPS:
		result.append((map_entry as Dictionary).duplicate(true))
	return result


static func get_map(map_id: String) -> Dictionary:
	for map_entry in MAPS:
		if String((map_entry as Dictionary).get("id", "")) == map_id:
			return (map_entry as Dictionary).duplicate(true)
	return {}


static func get_maps_for(match_mode: int, active_slots: int) -> Array[Dictionary]:
	var clamped_slots := clampi(active_slots, 1, 8)
	var result: Array[Dictionary] = []
	for map_entry in MAPS:
		var typed_entry := map_entry as Dictionary
		if int(typed_entry.get("mode", -1)) != match_mode:
			continue
		if clamped_slots < int(typed_entry.get("min_players", 1)):
			continue
		if clamped_slots > int(typed_entry.get("max_players", 8)):
			continue
		result.append(typed_entry.duplicate(true))
	return result


static func get_default_map_id(match_mode: int, active_slots: int) -> String:
	var candidates := get_maps_for(match_mode, active_slots)
	if candidates.is_empty():
		return ""
	return String(candidates[0].get("id", ""))


static func sanitize_map_id(map_id: String, match_mode: int, active_slots: int) -> String:
	var candidates := get_maps_for(match_mode, active_slots)
	for map_entry in candidates:
		if String(map_entry.get("id", "")) == map_id:
			return map_id
	return get_default_map_id(match_mode, active_slots)


static func resolve_scene_path(map_id: String, match_mode: int, active_slots: int) -> String:
	var sanitized_id := sanitize_map_id(map_id, match_mode, active_slots)
	var map_entry := get_map(sanitized_id)
	return String(map_entry.get("scene_path", ""))


static func get_setup_summary_line(map_id: String, match_mode: int, active_slots: int) -> String:
	var sanitized_id := sanitize_map_id(map_id, match_mode, active_slots)
	var map_entry := get_map(sanitized_id)
	return "Mapa | %s" % String(map_entry.get("label", ""))


static func get_setup_focus_line(map_id: String, match_mode: int, active_slots: int) -> String:
	var sanitized_id := sanitize_map_id(map_id, match_mode, active_slots)
	var map_entry := get_map(sanitized_id)
	return "Idea del mapa | %s" % String(map_entry.get("mode_focus", ""))
