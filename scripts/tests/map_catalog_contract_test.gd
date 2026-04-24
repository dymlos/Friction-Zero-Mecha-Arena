extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MapCatalog = preload("res://scripts/systems/map_catalog.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(MapCatalog.get_all_maps().size() == 4, "M2 debe exponer una familia inicial de cuatro entradas: Teams/FFA x 2-4/5-8.")

	_assert_default_map(
		MatchController.MatchMode.TEAMS,
		4,
		"borde_fundicion_teams_2_4",
		"res://scenes/main/main.tscn",
		"2-4 pulido"
	)
	_assert_default_map(
		MatchController.MatchMode.FFA,
		4,
		"borde_fundicion_ffa_2_4",
		"res://scenes/main/main_ffa.tscn",
		"2-4 pulido"
	)
	_assert_default_map(
		MatchController.MatchMode.TEAMS,
		8,
		"borde_fundicion_teams_5_8",
		"res://scenes/main/main_teams_large.tscn",
		"5-8 validacion"
	)
	_assert_default_map(
		MatchController.MatchMode.FFA,
		8,
		"borde_fundicion_ffa_5_8",
		"res://scenes/main/main_ffa_large.tscn",
		"5-8 validacion"
	)

	var teams_large := MapCatalog.get_map("borde_fundicion_teams_5_8")
	_assert(String(teams_large.get("mode_focus", "")).contains("rescate"), "Teams 5-8 debe declarar rescate como foco.")
	_assert(String(teams_large.get("mode_focus", "")).contains("coordinacion lateral"), "Teams 5-8 debe declarar coordinacion lateral como foco.")

	var ffa_large := MapCatalog.get_map("borde_fundicion_ffa_5_8")
	_assert(String(ffa_large.get("mode_focus", "")).contains("rotacion"), "FFA 5-8 debe declarar rotacion como foco.")
	_assert(String(ffa_large.get("mode_focus", "")).contains("third-party"), "FFA 5-8 debe declarar third-party como foco.")

	for map_entry in MapCatalog.get_all_maps():
		_assert(String(map_entry.get("edge_goal", "")).contains("borde"), "Cada mapa debe explicar el valor/peligro del borde.")
		_assert(String(map_entry.get("center_goal", "")).contains("transicion"), "Cada mapa debe explicar el centro como transicion.")
		_assert(String(map_entry.get("route_goal", "")).length() >= 20, "Cada mapa debe explicar rutas utiles, no solo tamano.")
		_assert(load(String(map_entry.get("scene_path", ""))) is PackedScene, "La escena del mapa debe existir: %s" % String(map_entry.get("scene_path", "")))

	_finish()


func _assert_default_map(match_mode: int, active_slots: int, expected_id: String, expected_scene: String, expected_tier: String) -> void:
	var map_id := MapCatalog.get_default_map_id(match_mode, active_slots)
	var map_entry := MapCatalog.get_map(map_id)
	_assert(map_id == expected_id, "Mapa default inesperado para modo %s con %s slots: %s" % [match_mode, active_slots, map_id])
	_assert(String(map_entry.get("scene_path", "")) == expected_scene, "Escena inesperada para %s." % expected_id)
	_assert(String(map_entry.get("range_label", "")) == expected_tier, "Tier inesperado para %s." % expected_id)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
