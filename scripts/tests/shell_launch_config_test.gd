extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")

const MATCH_LAUNCH_CONFIG_SCRIPT := "res://scripts/systems/match_launch_config.gd"
const SHELL_SESSION_SCRIPT := "res://scripts/systems/shell_session.gd"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var match_launch_config_script := load(MATCH_LAUNCH_CONFIG_SCRIPT)
	_assert(
		match_launch_config_script != null,
		"El contrato de lanzamiento deberia vivir en scripts/systems/match_launch_config.gd."
	)
	var shell_session_script := load(SHELL_SESSION_SCRIPT)
	_assert(
		shell_session_script != null,
		"La sesion de shell deberia vivir en scripts/systems/shell_session.gd."
	)
	if match_launch_config_script == null or shell_session_script == null:
		_finish()
		return

	var launch_config = match_launch_config_script.new()
	var shell_session = shell_session_script.new()
	_assert(
		launch_config != null and shell_session != null,
		"El slice M3 necesita instanciar el contrato de launch y la sesion de shell."
	)
	if launch_config == null or shell_session == null:
		_finish()
		return

	_assert(
		launch_config.has_method("configure_for_local_match"),
		"MatchLaunchConfig deberia exponer una configuracion minima para partidas locales."
	)
	_assert(
		_has_property(launch_config, "mode_variant_id"),
		"MatchLaunchConfig deberia transportar la variante visible de modo."
	)
	_assert(
		shell_session.has_method("store_match_launch_config"),
		"ShellSession deberia poder almacenar un launch config pendiente."
	)
	_assert(
		shell_session.has_method("consume_match_launch_config"),
		"ShellSession deberia poder consumir un launch config una sola vez."
	)
	if not launch_config.has_method("configure_for_local_match"):
		_finish()
		return

	launch_config.call(
		"configure_for_local_match",
		MatchController.MatchMode.FFA,
		"res://scenes/main/main_ffa.tscn",
		[
			{"slot": 1, "control_mode": 0, "input_source": "keyboard", "keyboard_profile": 1, "roster_entry_id": "ancla"},
			{"slot": 2, "control_mode": 1, "input_source": "joypad", "device_id": 24, "device_connected": true, "archetype_path": "res://data/config/robots/aguja_archetype.tres"},
			{"slot": 2, "control_mode": 0},
			{"slot": 9, "control_mode": 1},
		]
	)

	_assert(
		int(launch_config.get("match_mode")) == MatchController.MatchMode.FFA,
		"El launch config deberia conservar el modo de match elegido en shell."
	)
	_assert(
		String(launch_config.get("target_scene_path")) == "res://scenes/main/main_ffa.tscn",
		"El launch config deberia apuntar a la escena destino estable elegida desde shell."
	)
	_assert(
		String(launch_config.get("entry_context")) == "player_shell",
		"El launch config deberia marcar que la ruta viene desde player shell."
	)
	_assert(
		_get_string_property(launch_config, "mode_variant_id") == "score_by_cause",
		"El launch config deberia usar score_by_cause como variante default visible."
	)
	var launch_slots: Array = Array(launch_config.get("local_slots"))
	_assert(
		launch_slots.size() == 2,
		"El launch config deberia filtrar slots invalidos/duplicados y conservar solo el resumen local util."
	)
	_assert(
		int(launch_slots[0].get("slot", -1)) == 1 and int(launch_slots[1].get("slot", -1)) == 2,
		"El launch config deberia ordenar slots locales por indice ascendente."
	)
	_assert(
		int(launch_slots[1].get("control_mode", -1)) == 1,
		"El primer valor valido por slot deberia quedar congelado para evitar drift entre setup y match."
	)
	_assert(
		String(launch_slots[1].get("input_source", "")) == "joypad"
		and int(launch_slots[1].get("device_id", -1)) == 24,
		"El launch config deberia transportar fuente de input y device_id completos."
	)
	_assert(
		int(launch_slots[1].get("keyboard_profile", -2)) == 0,
		"Un slot joypad no deberia arrastrar perfil de teclado."
	)
	_assert(
		String(launch_slots[0].get("roster_entry_id", "")) == "ancla"
		and String(launch_slots[0].get("archetype_path", "")).ends_with("ancla_archetype.tres"),
		"El launch config deberia resolver y transportar el loadout elegido por roster_entry_id."
	)
	_assert(
		String(launch_slots[1].get("roster_entry_id", "")) == "aguja"
		and String(launch_slots[1].get("archetype_path", "")).ends_with("aguja_archetype.tres"),
		"El launch config deberia resolver roster_entry_id desde archetype_path cuando haga falta."
	)

	shell_session.call("store_match_launch_config", launch_config)
	launch_slots[0]["slot"] = 99

	var stored_config = shell_session.call("consume_match_launch_config")
	_assert(stored_config != null, "ShellSession deberia devolver el launch config pendiente.")
	if stored_config != null:
		var stored_slots: Array = Array(stored_config.get("local_slots"))
		_assert(
			stored_slots.size() == 2 and int(stored_slots[0].get("slot", -1)) == 1,
			"ShellSession deberia clonar el config al guardarlo para no compartir referencias mutables."
		)
		_assert(
			String(stored_config.get("entry_context")) == "player_shell",
			"El contexto de entrada debe sobrevivir al salto de escenas."
		)
		_assert(
			_get_string_property(stored_config, "mode_variant_id") == "score_by_cause",
			"La variante de modo deberia sobrevivir al clone de runtime."
		)

	var consumed_twice = shell_session.call("consume_match_launch_config")
	_assert(
		consumed_twice == null,
		"Consumir la sesion por segunda vez no deberia devolver estado stale."
	)

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	for property_info in target.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false


func _get_string_property(target: Object, property_name: String) -> String:
	if target == null or not _has_property(target, property_name):
		return ""
	return String(target.get(property_name))


func _finish() -> void:
	quit(1 if _failed else 0)
