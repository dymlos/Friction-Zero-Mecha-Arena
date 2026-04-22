extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const EdgeRepairPickup = preload("res://scripts/pickups/edge_repair_pickup.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var recap_panel := main.get_node_or_null("UI/MatchHud/Root/RecapPanel") as Control
	var recap_title_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapTitleLabel") as Label
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapLabel") as Label
	var match_result_panel := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel") as Control
	var match_result_title_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultTitleLabel") as Label
	var match_result_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultLabel") as Label
	var repair_pickup := _get_first_edge_repair_pickup() as EdgeRepairPickup
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia instanciar MatchController.")
	_assert(recap_panel != null, "El HUD deberia exponer un panel de recap para cierres de match.")
	_assert(recap_title_label != null, "El recap deberia exponer un titulo legible.")
	_assert(recap_label != null, "El recap deberia exponer un bloque de detalle legible.")
	_assert(match_result_panel != null, "El HUD deberia exponer un panel dedicado al resultado final del match.")
	_assert(match_result_title_label != null, "El resultado final deberia tener un titulo prominente.")
	_assert(match_result_label != null, "El resultado final deberia detallar marcador y reinicio.")
	_assert(repair_pickup != null, "La escena principal deberia seguir exponiendo al menos un pickup de borde para telemetria.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para el laboratorio 2v2.")
	if match_controller == null or recap_panel == null or recap_title_label == null or recap_label == null or match_result_panel == null or match_result_title_label == null or match_result_label == null or repair_pickup == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	_assert(match_controller.match_config != null, "El controller deberia cargar una MatchConfig base.")
	if match_controller.match_config == null:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_config.rounds_to_win = 2
	match_controller.round_reset_delay = 0.15
	match_controller.match_restart_delay = 0.2

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[0].apply_damage_to_part("left_arm", robots[0].max_part_health + 5.0)
	var restored := robots[0].restore_part_from_return("left_arm", robots[1])
	_assert(restored, "La prueba deberia poder registrar al menos un rescate antes del cierre del match.")
	repair_pickup.pickup_collected.emit(robots[1], "left_arm")
	await process_frame

	_eliminate_team_two(robots)
	await create_timer(0.05).timeout

	_assert(
		not match_controller.is_match_over(),
		"La primera ronda ganada no deberia cerrar el match si el objetivo es 2."
	)
	_assert(
		match_controller.get_round_status_line().contains("gana la ronda"),
		"Antes de llegar al objetivo el estado visible deberia seguir siendo de ronda ganada."
	)

	await create_timer(match_controller.round_reset_delay + 0.15).timeout

	_assert(match_controller.is_round_active(), "La segunda ronda deberia arrancar tras el reset normal.")
	_assert(
		match_controller.get_round_status_line().contains("Ronda 2"),
		"Tras la primera victoria el prototipo deberia avanzar a la ronda 2."
	)

	_eliminate_team_two(robots)
	await create_timer(0.05).timeout

	_assert(match_controller.is_match_over(), "El match deberia cerrarse al alcanzar el score objetivo.")
	_assert(
		not match_controller.is_round_active(),
		"Cuando el match termina no deberia arrancar otra ronda inmediatamente."
	)
	_assert(
		match_controller.get_round_status_line().contains("gana la partida"),
		"El estado visible deberia anunciar al ganador del match, no solo de la ronda."
	)
	_assert(recap_panel.visible, "Al terminar el match deberia aparecer el recap dedicado.")
	_assert(
		recap_title_label.text.contains("Resultado de partida"),
		"El recap deberia distinguir un match cerrado de una ronda comun."
	)
	_assert(
		recap_label.text.contains("Equipo 1 gana la partida 2-0"),
		"El recap deberia dejar visible el resultado final del match."
	)
	_assert(
		recap_label.text.contains("Player 3 | baja 1 | vacio"),
		"El recap final deberia seguir explicando las bajas que cerraron la partida."
	)
	_assert(match_result_panel.visible, "Al cerrar la partida deberia aparecer una presentacion dedicada del resultado final.")
	_assert(
		match_result_title_label.text.contains("Partida cerrada"),
		"El panel final deberia diferenciarse claramente del recap lateral."
	)
	_assert(
		match_result_label.text.contains("Equipo 1 gana la partida 2-0"),
		"El panel final deberia reiterar el ganador del match."
	)
	_assert(
		match_result_label.text.contains("Stats | Equipo 1 | rescates 1 | borde 1 | partes perdidas 1 (1 brazo) | bajas sufridas 0"),
		"El panel final deberia resumir rescates, borde, desgaste modular y bajas sufridas del equipo ganador."
	)
	_assert(
		match_result_label.text.contains("Stats | Equipo 2 | bajas sufridas 4 (4 vacio)"),
		"El panel final deberia distinguir la causa acumulada de las bajas del rival a lo largo del match."
	)
	_assert(
		match_result_label.text.contains("Player 3 | baja 1 | vacio"),
		"El panel final deberia repetir el detalle compacto por robot para explicar como cayo cada rival sin depender del recap lateral."
	)
	_assert(
		recap_label.text.contains("Stats | Equipo 1 | rescates 1 | borde 1 | partes perdidas 1 (1 brazo) | bajas sufridas 0"),
		"El recap lateral deberia compartir la misma telemetria simple del cierre de match, incluyendo desgaste modular."
	)
	_assert(
		match_result_label.text.contains("Reinicio | F5"),
		"El panel final deberia dejar visible la accion de reinicio inmediato."
	)
	_assert(match_controller.get_team_score(1) == 2, "El score final del ganador deberia conservar la segunda ronda.")
	_assert(
		_has_target_score_line(match_controller.get_round_state_lines(), 2),
		"El HUD deberia informar el objetivo de rondas del match."
	)
	_assert(
		_has_line_prefix(match_controller.get_round_state_lines(), "Reinicio | F5"),
		"El bloque principal del HUD deberia dejar visible que el match puede reiniciarse desde el laboratorio."
	)

	await create_timer(match_controller.match_restart_delay + 0.2).timeout

	_assert(
		not match_controller.is_match_over(),
		"Tras mostrar al ganador, el prototipo deberia reiniciar un match nuevo para seguir siendo jugable."
	)
	_assert(match_controller.is_round_active(), "El nuevo match deberia reiniciar una ronda activa.")
	_assert(
		match_controller.get_round_status_line().contains("Ronda 1"),
		"El reinicio completo deberia volver a la ronda 1."
	)
	_assert(match_controller.get_team_score(1) == 0, "El score del match nuevo deberia reiniciarse.")
	_assert(match_controller.get_team_score(2) == 0, "El rival tambien deberia reiniciarse a cero.")
	_assert(robots[2].visible, "Los robots eliminados deberian volver para el match siguiente.")
	_assert(robots[3].visible, "El reinicio de match deberia restaurar a todo el equipo derrotado.")
	_assert(not recap_panel.visible, "Tras reiniciar el match el recap anterior deberia ocultarse.")
	_assert(not match_result_panel.visible, "Tras reiniciar el match el panel de resultado final deberia ocultarse.")

	await create_timer(0.4).timeout
	await _cleanup_main(main)
	_finish()


func _eliminate_team_two(robots: Array[RobotBase]) -> void:
	robots[2].fall_into_void()
	robots[3].fall_into_void()


func _has_target_score_line(lines: Array[String], target_score: int) -> bool:
	for line in lines:
		if line.contains("Primero a %s" % target_score):
			return true

	return false


func _has_line_prefix(lines: Array[String], prefix: String) -> bool:
	for line in lines:
		if line.begins_with(prefix):
			return true

	return false


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _get_first_edge_repair_pickup() -> EdgeRepairPickup:
	for node in Engine.get_main_loop().get_nodes_in_group("edge_repair_pickups"):
		if node is EdgeRepairPickup:
			return node as EdgeRepairPickup

	return null


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
