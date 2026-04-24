extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var round_label := main.get_node("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var roster_label := main.get_node("UI/MatchHud/Root/TopLeftStack/RosterLabel") as Label
	var robots := _get_scene_robots(main)

	_assert(match_controller != null, "La escena principal deberia exponer MatchController.")
	_assert(round_label != null, "El HUD deberia exponer RoundLabel para validar el modo de detalle.")
	_assert(roster_label != null, "El HUD deberia exponer RosterLabel para validar el modo de detalle.")
	_assert(robots.size() >= 1, "La escena principal deberia ofrecer al menos un robot para validar el roster.")
	if match_controller == null or round_label == null or roster_label == null or robots.size() < 1:
		await _cleanup_main(main)
		_finish()
		return

	_assert(
		_has_property(match_controller.match_config, "hud_detail_mode"),
		"MatchConfig deberia exponer un modo de detalle configurable para el HUD."
	)
	if not _has_property(match_controller.match_config, "hud_detail_mode"):
		await _cleanup_main(main)
		_finish()
		return

	var explicit_round := round_label.text
	var explicit_roster := roster_label.text
	var explicit_score_line := _find_line_with_prefix(explicit_round, "Marcador |")
	_assert(explicit_round.contains("Modo |"), "El ayuda visible deberia dejar visible el modo de match.")
	_assert(explicit_round.contains("Objetivo |"), "El ayuda visible deberia dejar visible el objetivo del match.")
	_assert(explicit_round.contains("Lab |"), "El ayuda visible deberia dejar visible la metadata del laboratorio.")
	_assert(explicit_round.contains("Control P1 |"), "El ayuda visible deberia dejar visible la referencia compacta del slot seleccionado.")
	_assert(explicit_roster.contains("4/4 partes"), "El roster explicito deberia mostrar partes activas incluso si no hubo daño.")
	_assert(explicit_roster.contains("Eq"), "El roster explicito deberia mostrar el estado energetico balanceado.")
	_assert(explicit_roster.contains("WASD"), "El roster explicito deberia mantener visible la referencia de controles.")

	match_controller.cycle_hud_detail_mode()
	await process_frame

	var contextual_round := round_label.text
	var contextual_roster := roster_label.text
	_assert(contextual_round.contains(match_controller.get_round_status_line()), "El HUD contextual deberia seguir mostrando el estado actual de la ronda.")
	if explicit_score_line != "":
		_assert(contextual_round.contains(explicit_score_line), "El HUD contextual deberia conservar la lectura persistente del marcador.")
	_assert(not contextual_round.contains("Modo |"), "El HUD contextual deberia ocultar el modo fijo para reducir ruido.")
	_assert(not contextual_round.contains("Objetivo |"), "El HUD contextual deberia ocultar el objetivo fijo mientras nada cambie.")
	_assert(not contextual_round.contains("HUD |"), "El HUD contextual no deberia seguir mostrando su propia metadata runtime.")
	_assert(not contextual_round.contains("Lab |"), "El HUD contextual deberia ocultar la metadata del selector runtime.")
	_assert(not contextual_round.contains("Control P1 |"), "El HUD contextual deberia ocultar la referencia compacta del slot seleccionado.")
	_assert(not contextual_round.contains("Borde |"), "El HUD contextual deberia ocultar la metadata de pickups de borde.")
	_assert(contextual_roster == "", "El HUD contextual deberia ocultar por completo el roster vivo.")

	robots[0].set_energy_focus("left_leg")
	robots[0].store_carried_item("pulse_charge")
	main.call("_refresh_hud")
	await process_frame

	var contextual_focus_round := round_label.text
	_assert(
		contextual_focus_round == contextual_round,
		"El HUD contextual no deberia volver a poblar texto tactico accesorio al cambiar energia o item."
	)
	_assert(roster_label.text == "", "El roster deberia seguir oculto aunque el robot tenga foco e item.")

	robots[0].apply_damage_to_part("left_arm", robots[0].max_part_health + 5.0, Vector3.LEFT)
	main.call("_refresh_hud")
	await process_frame

	_assert(
		roster_label.text == "",
		"El HUD contextual deberia seguir ocultando el roster aun cuando haya daño modular."
	)

	robots[0].fall_into_void()
	await _wait_frames(4)

	_assert(
		roster_label.text == "",
		"El HUD contextual deberia seguir ocultando el roster incluso si el slot seleccionado ya entro en apoyo."
	)

	# HUD: validar defaults por modo desde MatchConfig (sin override runtime).
	var original_config := match_controller.match_config
	var original_mode := match_controller.match_mode
	var teams_default_config := MatchConfig.new()
	var ffa_default_config := MatchConfig.new()

	teams_default_config.hud_detail_mode_ffa = MatchConfig.HudDetailMode.EXPLICIT
	teams_default_config.hud_detail_mode_teams = MatchConfig.HudDetailMode.CONTEXTUAL
	teams_default_config.hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT
	ffa_default_config.hud_detail_mode_ffa = MatchConfig.HudDetailMode.CONTEXTUAL
	ffa_default_config.hud_detail_mode_teams = MatchConfig.HudDetailMode.EXPLICIT
	ffa_default_config.hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT

	match_controller.match_config = teams_default_config
	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.set("_hud_detail_mode_override", -1)
	_assert(
		match_controller.get_hud_detail_mode() == MatchConfig.HudDetailMode.CONTEXTUAL,
		"Teams debe usar hud_detail_mode_teams como default de arranque."
	)

	match_controller.match_config = ffa_default_config
	match_controller.match_mode = MatchController.MatchMode.FFA
	match_controller.set("_hud_detail_mode_override", -1)
	_assert(
		match_controller.get_hud_detail_mode() == MatchConfig.HudDetailMode.CONTEXTUAL,
		"FFA debe usar hud_detail_mode_ffa como default de arranque."
	)

	# Restaurar estado para no influir en el resto del test y el cleanup.
	match_controller.match_config = original_config
	match_controller.match_mode = original_mode

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false

	for property_info in target.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true

	return false


func _find_line_with_prefix(text: String, prefix: String) -> String:
	for line in text.split("\n"):
		if line.begins_with(prefix):
			return line

	return ""


func _wait_frames(count: int) -> void:
	for _step in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_main(main: Node) -> void:
	if not is_instance_valid(main):
		return

	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
