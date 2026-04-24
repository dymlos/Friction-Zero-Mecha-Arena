extends SceneTree

const LOCAL_MATCH_SETUP_SCENE := preload("res://scenes/shell/local_match_setup.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var setup := LOCAL_MATCH_SETUP_SCENE.instantiate()
	root.add_child(setup)
	await process_frame
	await process_frame

	_assert(setup.has_method("get_map_summary_line"), "Setup debe exponer get_map_summary_line().")
	_assert(setup.has_method("get_map_focus_line"), "Setup debe exponer get_map_focus_line().")
	_assert(setup.has_method("cycle_selected_map"), "Setup debe exponer cycle_selected_map() aunque hoy haya un mapa por rango/modo.")

	_assert(String(setup.call("get_map_summary_line")).contains("Fundicion compacta"), "Setup default 4P debe mostrar el mapa compacto.")
	_assert(String(setup.call("get_map_summary_line")).contains("2-4 pulido"), "Setup default 4P debe mostrar el rango pulido.")
	_assert(String(setup.call("get_map_focus_line")).contains("borde"), "Setup debe comunicar borde valioso/peligroso.")
	_assert(String(setup.call("get_map_focus_line")).contains("transicion") or String(setup.call("get_map_focus_line")).contains("rotacion") or String(setup.call("get_map_focus_line")).contains("rescate"), "Setup debe comunicar la intencion espacial del mapa.")

	for slot in range(5, 9):
		setup.call("set_slot_active", slot, true)
		setup.call("set_slot_input_source", slot, "joypad")
		setup.call("reserve_joypad_for_slot", slot, 80 + slot, true)

	_assert(String(setup.call("get_map_summary_line")).contains("5-8 validacion"), "Setup 8P debe cambiar al rango 5-8.")
	var launch_config = setup.call("build_launch_config")
	_assert(String(launch_config.target_scene_path) == "res://scenes/main/main_teams_large.tscn", "Teams 8P debe lanzar el mapa fuerte de Teams 5-8.")
	_assert(String(launch_config.map_id) == "borde_fundicion_teams_5_8", "LaunchConfig debe transportar el map_id de Teams 5-8.")

	setup.call("set_match_mode", MatchController.MatchMode.FFA)
	_assert(String(setup.call("get_map_summary_line")).contains("Fundicion rotativa"), "FFA 8P debe mostrar el mapa de rotacion.")
	_assert(String(setup.call("get_map_focus_line")).contains("third-party"), "FFA 8P debe declarar third-party.")
	var ffa_launch_config = setup.call("build_launch_config")
	_assert(String(ffa_launch_config.target_scene_path) == "res://scenes/main/main_ffa_large.tscn", "FFA 8P debe lanzar el mapa fuerte de FFA 5-8.")
	_assert(String(ffa_launch_config.map_id) == "borde_fundicion_ffa_5_8", "LaunchConfig debe transportar el map_id de FFA 5-8.")

	root.remove_child(setup)
	setup.free()
	await process_frame
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
