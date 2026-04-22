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
	_assert(explicit_round.contains("Modo |"), "El HUD explicito deberia dejar visible el modo de match.")
	_assert(explicit_round.contains("Objetivo |"), "El HUD explicito deberia dejar visible el objetivo del match.")
	_assert(explicit_roster.contains("4/4 partes"), "El roster explicito deberia mostrar partes activas incluso si no hubo daño.")
	_assert(explicit_roster.contains("Eq"), "El roster explicito deberia mostrar el estado energetico balanceado.")
	_assert(explicit_roster.contains("WASD"), "El roster explicito deberia mantener visible la referencia de controles.")

	match_controller.cycle_hud_detail_mode()
	await process_frame

	var contextual_round := round_label.text
	var contextual_roster := roster_label.text
	_assert(not contextual_round.contains("Modo |"), "El HUD contextual deberia ocultar el modo fijo para reducir ruido.")
	_assert(not contextual_round.contains("Objetivo |"), "El HUD contextual deberia ocultar el objetivo fijo mientras nada cambie.")
	_assert(not contextual_roster.contains("4/4 partes"), "El roster contextual deberia ocultar partes intactas.")
	_assert(not contextual_roster.contains("Eq"), "El roster contextual deberia ocultar energia balanceada.")
	_assert(not contextual_roster.contains("WASD"), "El roster contextual deberia ocultar hints de control persistentes.")
	_assert(contextual_roster.contains("Activo"), "El roster contextual deberia seguir indicando si el robot esta activo.")

	robots[0].set_energy_focus("left_leg")
	robots[0].store_carried_item("pulse_charge")
	main.call("_refresh_hud")
	await process_frame

	var contextual_focus_roster := roster_label.text
	_assert(
		contextual_focus_roster.contains("Foco pierna izquierda"),
		"El roster contextual deberia volver a mostrar redistribucion cuando deja de estar balanceada."
	)
	_assert(
		contextual_focus_roster.contains("item pulso"),
		"El roster contextual deberia mostrar items cargados porque son informacion tactica inmediata."
	)

	robots[0].apply_damage_to_part("left_arm", robots[0].max_part_health + 5.0, Vector3.LEFT)
	main.call("_refresh_hud")
	await process_frame

	var contextual_damage_roster := roster_label.text
	_assert(
		contextual_damage_roster.contains("3/4 partes"),
		"El roster contextual deberia volver a mostrar partes cuando el robot ya no esta intacto."
	)

	robots[0].fall_into_void()
	await _wait_frames(4)

	var contextual_support_roster := roster_label.text
	var support_line := _find_line_containing(contextual_support_roster, robots[0].display_name)
	_assert(
		support_line.contains("Apoyo activo"),
		"El roster contextual deberia seguir marcando cuando un jugador eliminado continua aportando desde la nave de apoyo."
	)
	_assert(
		support_line.contains(robots[0].get_support_input_hint()),
		"El roster contextual deberia conservar el hint accionable de la nave de apoyo."
	)
	_assert(
		support_line.contains("sin carga"),
		"El roster contextual deberia seguir explicando si la nave de apoyo todavia no lleva payload."
	)
	_assert(
		not support_line.contains("vacio"),
		"En HUD contextual, `Apoyo activo` no deberia repetir la causa de baja si el jugador ya tiene una accion nueva mas relevante."
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


func _find_line_containing(text: String, fragment: String) -> String:
	for line in text.split("\n"):
		if line.contains(fragment):
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
