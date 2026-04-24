extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_lab_selector_cycles_roster_and_control_mode()
	await _validate_contextual_hud_hides_lab_selection_readability()
	await _validate_lab_selected_controls_follow_support_ship()
	await _validate_lab_selector_cycles_between_robot_and_active_support_slots()
	await _validate_lab_runtime_loadout_reset_clears_support_immediately()
	await _validate_lab_selector_recovers_from_support_after_round_reset()
	await _validate_lab_selector_recovers_from_support_after_manual_restart()
	await _validate_ffa_scoreboard_refreshes_after_runtime_loadout_change()
	_finish()


func _validate_lab_selector_cycles_roster_and_control_mode() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	_assert(main.has_method("cycle_lab_selector_slot"), "Main deberia exponer un selector runtime por slot.")
	_assert(main.has_method("cycle_selected_lab_archetype"), "Main deberia poder ciclar el arquetipo del slot seleccionado.")
	_assert(main.has_method("toggle_selected_lab_control_mode"), "Main deberia poder alternar Simple/Avanzado para el slot seleccionado.")
	_assert(main.has_method("get_lab_selector_summary_line"), "Main deberia exponer un resumen legible del selector runtime.")
	if not (
		main.has_method("cycle_lab_selector_slot")
		and main.has_method("cycle_selected_lab_archetype")
		and main.has_method("toggle_selected_lab_control_mode")
		and main.has_method("get_lab_selector_summary_line")
	):
		await _cleanup_node(main)
		return

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "La escena principal deberia seguir exponiendo cuatro robots jugables.")
	if robots.size() < 4:
		await _cleanup_node(main)
		return

	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel")
	var roster_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RosterLabel")
	_assert(round_label is Label, "El HUD deberia seguir exponiendo RoundLabel.")
	_assert(roster_label is Label, "El HUD deberia seguir exponiendo RosterLabel.")
	if not (round_label is Label) or not (roster_label is Label):
		await _cleanup_node(main)
		return

	var initial_summary := String(main.call("get_lab_selector_summary_line"))
	_assert(initial_summary.contains("P1"), "El selector runtime deberia arrancar apuntando al primer slot.")
	_assert(initial_summary.contains("Ariete"), "El resumen inicial deberia reflejar el arquetipo base del slot 1.")
	_assert(initial_summary.contains("Simple"), "El selector runtime deberia reflejar el modo de control inicial.")
	_assert((round_label as Label).text.contains("Lab |"), "El HUD deberia dejar visible el selector runtime en el laboratorio.")
	_assert(
		(round_label as Label).text.contains("Control P1 | mueve WASD | ataca Space | energia Q/E | overdrive R | suelta C"),
		"El HUD deberia dejar una referencia compacta de controles para el slot seleccionado aunque el roster este en modo contextual."
	)
	_assert(robots[0].has_method("is_lab_selected"), "RobotBase deberia exponer si el selector runtime lo tiene elegido.")
	if robots[0].has_method("is_lab_selected"):
		_assert(bool(robots[0].call("is_lab_selected")), "El slot inicial deberia quedar marcado como seleccionado.")
		_assert(not bool(robots[1].call("is_lab_selected")), "Solo un robot deberia cargar la marca del selector runtime al inicio.")
	var selection_indicator := robots[0].get_node_or_null("LabSelectionIndicator") as MeshInstance3D
	_assert(selection_indicator != null, "El robot seleccionado deberia exponer una pista diegetica de selector runtime.")
	if selection_indicator != null:
		_assert(selection_indicator.visible, "La pista diegetica del selector runtime deberia arrancar visible sobre el slot elegido.")

	main.call("cycle_selected_lab_archetype")
	await process_frame
	await process_frame

	_assert(robots[0].get_archetype_label() == "Grua", "El selector runtime deberia poder cambiar el arquetipo del slot activo.")
	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("Grua"),
		"El resumen del selector runtime deberia reflejar el arquetipo actualizado."
	)
	_assert(
		(roster_label as Label).text.contains("Player 1 / Grua"),
		"El roster del laboratorio deberia refrescar el arquetipo tras un cambio runtime."
	)

	main.call("toggle_selected_lab_control_mode")
	await process_frame
	await process_frame

	_assert(
		robots[0].control_mode == RobotBase.ControlMode.HARD,
		"El selector runtime deberia poder alternar Simple/Avanzado sobre el slot activo."
	)
	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("Avanzado"),
		"El resumen del selector runtime deberia reflejar el nuevo modo de control."
	)
	_assert(
		(round_label as Label).text.contains("Control P1 | mueve WASD | aim TFGX | ataca Space | energia Q/E | overdrive R | suelta C"),
		"Al pasar el slot seleccionado a Hard, la referencia compacta deberia sumar el aim dedicado real."
	)
	_assert(
		(roster_label as Label).text.contains("Avanzado"),
		"El roster deberia reflejar el modo Hard tras alternarlo runtime."
	)

	main.call("cycle_lab_selector_slot")
	await process_frame
	await process_frame

	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P2"),
		"El selector runtime deberia poder moverse al siguiente slot."
	)
	_assert(
		(round_label as Label).text.contains("Control P2 | mueve flechas | ataca Enter | energia ,/. | overdrive M | suelta /"),
		"Al cambiar de slot, la referencia compacta deberia seguir al nuevo jugador seleccionado."
	)
	if robots[0].has_method("is_lab_selected") and robots[1].has_method("is_lab_selected"):
		_assert(not bool(robots[0].call("is_lab_selected")), "Al cambiar de slot la seleccion anterior deberia apagarse.")
		_assert(bool(robots[1].call("is_lab_selected")), "El nuevo slot elegido deberia prender su pista runtime.")
	var second_selection_indicator := robots[1].get_node_or_null("LabSelectionIndicator") as MeshInstance3D
	_assert(second_selection_indicator != null, "Cada robot del laboratorio deberia poder mostrar la pista runtime.")
	if second_selection_indicator != null:
		_assert(second_selection_indicator.visible, "La pista runtime deberia migrar al nuevo slot seleccionado.")

	main.call("cycle_selected_lab_archetype")
	await process_frame
	await process_frame

	_assert(
		robots[1].get_archetype_label() == "Cizalla",
		"Cada slot deberia poder recibir un arquetipo nuevo sin editar la escena."
	)

	await _cleanup_node(main)


func _validate_contextual_hud_hides_lab_selection_readability() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller != null:
		match_controller.round_intro_duration = 0.0
		if match_controller.match_config != null:
			match_controller.match_config.round_intro_duration_teams = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	_assert(main.has_method("cycle_hud_detail_mode"), "Main deberia poder alternar el HUD runtime para validar la limpieza contextual.")
	if not main.has_method("cycle_hud_detail_mode"):
		await _cleanup_node(main)
		return

	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var roster_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RosterLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(round_label != null, "El laboratorio Teams deberia seguir exponiendo RoundLabel para validar la limpieza contextual.")
	_assert(roster_label != null, "El laboratorio Teams deberia seguir exponiendo RosterLabel para validar la limpieza contextual.")
	_assert(robots.size() >= 1, "La escena principal deberia seguir exponiendo al menos un robot seleccionable.")
	if round_label == null or roster_label == null or robots.is_empty():
		await _cleanup_node(main)
		return

	var robot_selection_indicator := robots[0].get_node_or_null("LabSelectionIndicator") as MeshInstance3D
	_assert(robot_selection_indicator != null, "El robot seleccionado deberia arrancar con la pista diegetica disponible en ayuda visible.")
	if robot_selection_indicator != null:
		_assert(robot_selection_indicator.visible, "En ayuda visible la pista diegetica del selector deberia estar visible.")

	main.call("cycle_hud_detail_mode")
	await process_frame
	await process_frame

	_assert(not round_label.text.contains("Lab |"), "En HUD contextual deberia desaparecer el resumen del selector runtime.")
	_assert(not round_label.text.contains("Control P1 |"), "En HUD contextual deberia desaparecer la referencia compacta del slot seleccionado.")
	_assert(String(main.call("get_lab_selector_summary_line")).contains("P1 Ariete Simple"), "Cambiar el HUD no deberia perder el slot runtime seleccionado.")
	_assert(roster_label.text == "", "En HUD contextual el roster del laboratorio deberia ocultarse por completo.")
	if robot_selection_indicator != null:
		_assert(not robot_selection_indicator.visible, "En HUD contextual la pista diegetica del robot seleccionado no deberia mostrarse.")

	robots[0].fall_into_void()
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var support_root := main.get_node_or_null("SupportRoot")
	var support_ship: Node = support_root.get_child(0) if support_root != null and support_root.get_child_count() > 0 else null
	_assert(support_ship != null, "La baja del slot seleccionado deberia seguir creando una nave de apoyo para validar la limpieza contextual.")
	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("Apoyo activo"),
		"En contextual el selector runtime deberia conservar el estado del slot aunque el round-state lo oculte."
	)
	_assert(not round_label.text.contains("Apoyo P1 |"), "En HUD contextual el round-state no deberia mostrar la linea accionable del apoyo seleccionado.")
	var support_selection_indicator := support_ship.get_node_or_null("LabSelectionIndicator") as MeshInstance3D if support_ship != null else null
	_assert(support_selection_indicator != null, "La nave de apoyo deberia seguir exponiendo su pista diegetica runtime.")
	if support_ship != null:
		_assert(not bool(support_ship.call("is_lab_selected")), "En HUD contextual la nave de apoyo no deberia quedar resaltada aunque siga siendo el slot seleccionado.")
	if support_selection_indicator != null:
		_assert(not support_selection_indicator.visible, "En HUD contextual la pista diegetica del apoyo seleccionado no deberia mostrarse.")

	main.call("cycle_hud_detail_mode")
	await process_frame
	await process_frame

	_assert(round_label.text.contains("Control P1 | usa C | objetivo Q/E"), "Al volver a explicito deberia reaparecer la referencia real del apoyo seleccionado.")
	_assert(round_label.text.contains("Apoyo P1 | sin carga"), "Al volver a explicito deberia reaparecer la linea accionable del apoyo seleccionado.")
	if support_ship != null:
		_assert(bool(support_ship.call("is_lab_selected")), "Al volver a explicito la nave de apoyo deberia recuperar su marca de seleccion.")
	if support_selection_indicator != null:
		_assert(support_selection_indicator.visible, "Al volver a explicito la pista diegetica del apoyo deberia reaparecer.")

	await _cleanup_node(main)


func _validate_ffa_scoreboard_refreshes_after_runtime_loadout_change() -> void:
	var ffa := FFA_SCENE.instantiate()
	root.add_child(ffa)

	await process_frame
	await process_frame

	var match_controller := ffa.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(ffa)
	_assert(match_controller != null, "La escena FFA deberia seguir exponiendo MatchController.")
	_assert(ffa.has_method("cycle_selected_lab_archetype"), "El selector runtime deberia reutilizarse tambien en FFA.")
	if match_controller == null or not ffa.has_method("cycle_selected_lab_archetype") or robots.size() < 4:
		await _cleanup_node(ffa)
		return

	ffa.call("cycle_selected_lab_archetype")
	await process_frame
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[0].fall_into_void()
	await create_timer(0.05).timeout
	robots[2].fall_into_void()
	await create_timer(0.05).timeout
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	var score_line := _find_line_with_prefix(match_controller.get_round_state_lines(), "Marcador |")
	_assert(
		score_line.contains("[Grua]"),
		"Cuando el marcador FFA reaparece tras una baja real, deberia refrescar el arquetipo visible despues de un cambio runtime."
	)
	_assert(
		not score_line.contains("[Ariete]"),
		"Cuando el marcador FFA reaparece tras una baja real, no deberia conservar etiquetas stale despues del cambio runtime."
	)
	_assert(
		String(ffa.call("get_lab_selector_summary_line")).contains("Grua"),
		"El resumen del selector runtime deberia mantenerse sincronizado en FFA."
	)

	await _cleanup_node(ffa)


func _validate_lab_selected_controls_follow_support_ship() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller != null:
		match_controller.round_intro_duration = 0.0
		if match_controller.match_config != null:
			match_controller.match_config.round_intro_duration_teams = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(round_label != null, "El HUD deberia seguir exponiendo RoundLabel en el laboratorio Teams.")
	_assert(robots.size() >= 2, "El laboratorio Teams deberia seguir exponiendo al menos dos robots aliados para el soporte.")
	if round_label == null or robots.size() < 2:
		await _cleanup_node(main)
		return

	_assert(
		round_label.text.contains("Control P1 | mueve WASD | ataca Space | energia Q/E | overdrive R | suelta C"),
		"Antes de una baja, la referencia compacta deberia seguir mostrando los controles normales del slot seleccionado."
	)
	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P1 Ariete Simple"),
		"Antes de una baja, el resumen del selector runtime deberia seguir describiendo el robot seleccionado."
	)
	_assert(
		not round_label.text.contains("Apoyo P1 |"),
		"Antes de una baja, el round-state no deberia anunciar una linea de apoyo para un robot que sigue activo."
	)
	var robot_selection_indicator := robots[0].get_node_or_null("LabSelectionIndicator") as MeshInstance3D
	_assert(robot_selection_indicator != null, "El robot seleccionado deberia arrancar con la pista diegetica del laboratorio disponible.")
	if robot_selection_indicator != null:
		_assert(robot_selection_indicator.visible, "Antes de una baja, la pista diegetica deberia seguir visible sobre el robot seleccionado.")

	robots[0].fall_into_void()
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	_assert(
		round_label.text.contains("Control P1 | usa C | objetivo Q/E"),
		"Si el slot seleccionado pasa a `Apoyo activo`, la referencia compacta deberia migrar a los controles reales de la nave de soporte."
	)
	_assert(
		not round_label.text.contains("Control P1 | mueve WASD"),
		"Cuando el jugador ya esta en la nave de apoyo, la referencia compacta no deberia seguir mostrando los controles del robot caido."
	)
	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("Apoyo activo"),
		"Si el slot seleccionado ya paso a la nave post-muerte, el resumen `Lab | ...` deberia dejar visible ese estado y no solo el loadout previo."
	)
	_assert(
		not String(main.call("get_lab_selector_summary_line")).contains("Ariete Simple"),
		"Si el slot seleccionado ya esta en `Apoyo activo`, el resumen del laboratorio no deberia seguir anunciandolo como si controlara el robot original."
	)
	_assert(
		round_label.text.contains("Apoyo P1 | sin carga"),
		"Si el slot seleccionado pasa a la nave de apoyo, el round-state deberia dejar visible tambien su estado accionable persistente."
	)
	if robot_selection_indicator != null:
		_assert(
			not robot_selection_indicator.visible,
			"Cuando el slot seleccionado ya controla la nave de apoyo, la pista diegetica no deberia seguir pegada al robot caido."
		)
	var support_root := main.get_node_or_null("SupportRoot")
	var support_ship: Node = support_root.get_child(0) if support_root != null and support_root.get_child_count() > 0 else null
	_assert(
		support_ship != null and support_ship.has_method("is_lab_selected"),
		"La nave de apoyo deberia exponer tambien el estado de seleccion runtime para que el laboratorio siga al actor jugable."
	)
	if support_ship != null:
		_assert(
			bool(support_ship.call("is_lab_selected")),
			"Si el slot seleccionado ya esta en `Apoyo activo`, la nave de apoyo deberia quedar marcada como seleccionada."
		)
	var support_selection_indicator := support_ship.get_node_or_null("LabSelectionIndicator") as MeshInstance3D if support_ship != null else null
	_assert(
		support_selection_indicator != null,
		"La nave de apoyo del slot seleccionado deberia mostrar tambien una pista diegetica del selector runtime."
	)
	if support_selection_indicator != null:
		_assert(
			support_selection_indicator.visible,
			"Si el slot seleccionado ya esta en `Apoyo activo`, la pista diegetica deberia migrar a la nave de apoyo."
		)

	await _cleanup_node(main)


func _validate_lab_selector_cycles_between_robot_and_active_support_slots() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller != null:
		match_controller.round_intro_duration = 0.0
		if match_controller.match_config != null:
			match_controller.match_config.round_intro_duration_teams = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(round_label != null, "El laboratorio Teams deberia seguir exponiendo RoundLabel para validar `F2` entre robot y `Apoyo activo`.")
	_assert(robots.size() >= 2, "La escena principal deberia seguir exponiendo dos slots jugables para validar `F2` con soporte post-muerte.")
	if round_label == null or robots.size() < 2:
		await _cleanup_node(main)
		return

	robots[0].fall_into_void()
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P1 Apoyo activo"),
		"Antes de usar `F2`, el selector runtime deberia seguir mostrando el soporte del slot que acaba de caer."
	)
	_assert(
		round_label.text.contains("Control P1 | usa C | objetivo Q/E"),
		"Antes de usar `F2`, la referencia compacta deberia seguir anclada a los controles reales del soporte activo."
	)
	_assert(
		round_label.text.contains("Apoyo P1 | sin carga"),
		"Antes de usar `F2`, el round-state deberia seguir exponiendo la linea accionable del soporte seleccionado."
	)

	main.call("cycle_lab_selector_slot")
	await process_frame
	await process_frame

	_assert(
		String(main.call("get_lab_selector_summary_line")).contains(
			"P2 %s Simple" % robots[1].get_archetype_label()
		),
		"Al ciclar `F2` desde `Apoyo activo`, el selector runtime deberia volver a describir el robot vivo del siguiente slot."
	)
	_assert(
		not String(main.call("get_lab_selector_summary_line")).contains("Apoyo activo"),
		"Al ciclar `F2` hacia un robot vivo, el resumen del laboratorio no deberia arrastrar el soporte del slot anterior."
	)
	_assert(
		round_label.text.contains("Control P2 | mueve flechas | ataca Enter | energia ,/. | overdrive M | suelta /"),
		"Al ciclar `F2` hacia un robot vivo, la referencia compacta deberia cambiar a sus controles reales."
	)
	_assert(
		not round_label.text.contains("Apoyo P1 |"),
		"Al ciclar `F2` hacia un robot vivo, la linea persistente del soporte no deberia seguir colgada del slot anterior."
	)
	_assert(
		bool(robots[1].call("is_lab_selected")),
		"Al ciclar `F2` hacia un robot vivo, la pista diegetica deberia migrar al nuevo slot seleccionado."
	)

	for _index in range(3):
		main.call("cycle_lab_selector_slot")
		await process_frame
		await process_frame

	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P1 Apoyo activo"),
		"Al volver con `F2` al slot caido, el selector runtime deberia recuperar la identidad `Apoyo activo` de ese jugador."
	)
	_assert(
		round_label.text.contains("Control P1 | usa C | objetivo Q/E"),
		"Al volver con `F2` al slot caido, la referencia compacta deberia retomar los controles del soporte."
	)
	_assert(
		round_label.text.contains("Apoyo P1 | sin carga"),
		"Al volver con `F2` al slot caido, la linea accionable del soporte deberia reaparecer."
	)
	var support_root := main.get_node_or_null("SupportRoot")
	var support_ship := support_root.get_child(0) if support_root != null and support_root.get_child_count() > 0 else null
	_assert(
		support_ship != null and bool(support_ship.call("is_lab_selected")),
		"Al volver con `F2` al slot caido, la nave de apoyo deberia recuperar tambien la marca runtime."
	)

	await _cleanup_node(main)


func _validate_lab_runtime_loadout_reset_clears_support_immediately() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller != null:
		match_controller.round_intro_duration = 0.0
		if match_controller.match_config != null:
			match_controller.match_config.round_intro_duration_teams = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	_assert(round_label != null, "El laboratorio Teams deberia seguir exponiendo RoundLabel para validar F3/F4 desde `Apoyo activo`.")
	_assert(robots.size() >= 1, "El laboratorio Teams deberia seguir exponiendo al menos un robot para validar el reset inmediato del selector.")
	_assert(support_root != null, "La escena principal deberia seguir exponiendo SupportRoot para validar el cleanup inmediato del carril.")
	if round_label == null or robots.size() < 1 or support_root == null:
		await _cleanup_node(main)
		return

	main.call("cycle_selected_lab_archetype")
	await process_frame
	await process_frame
	main.call("toggle_selected_lab_control_mode")
	await process_frame
	await process_frame

	robots[0].fall_into_void()
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P1 Apoyo activo"),
		"Antes de reconfigurar el slot desde `Apoyo activo`, el selector runtime deberia seguir el soporte post-muerte."
	)
	_assert(
		round_label.text.contains("Apoyo P1 | sin carga"),
		"Antes de usar F3/F4 desde `Apoyo activo`, el HUD deberia seguir exponiendo el estado accionable del soporte."
	)
	_assert(support_root.get_child_count() > 0, "Antes del reset runtime deberia existir una nave de apoyo viva en `SupportRoot`.")

	main.call("cycle_selected_lab_archetype")

	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P1 Cizalla Avanzado"),
		"Al usar F3 desde `Apoyo activo`, el selector runtime deberia volver inmediatamente al robot con el nuevo loadout."
	)
	_assert(
		not String(main.call("get_lab_selector_summary_line")).contains("Apoyo activo"),
		"Al usar F3 desde `Apoyo activo`, el resumen del laboratorio no deberia arrastrar el soporte stale hasta el frame siguiente."
	)
	_assert(
		round_label.text.contains("Control P1 | mueve WASD | aim TFGX | ataca Space | energia Q/E | overdrive R | suelta C"),
		"Al usar F3 desde `Apoyo activo`, la referencia compacta deberia volver inmediatamente a los controles del robot Hard."
	)
	_assert(
		not round_label.text.contains("Apoyo P1 |"),
		"Al usar F3 desde `Apoyo activo`, la linea persistente de soporte deberia desaparecer inmediatamente."
	)
	_assert(
		support_root.get_child_count() == 0,
		"Al usar F3 desde `Apoyo activo`, `SupportRoot` no deberia conservar naves stale hasta el siguiente frame."
	)
	_assert(
		bool(robots[0].call("is_lab_selected")),
		"Al usar F3 desde `Apoyo activo`, la marca diegetica deberia volver inmediatamente al robot seleccionado."
	)

	robots[0].fall_into_void()
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	main.call("toggle_selected_lab_control_mode")

	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P1 Cizalla Simple"),
		"Al usar F4 desde `Apoyo activo`, el selector runtime deberia volver inmediatamente al robot con el nuevo modo."
	)
	_assert(
		not String(main.call("get_lab_selector_summary_line")).contains("Apoyo activo"),
		"Al usar F4 desde `Apoyo activo`, el laboratorio tampoco deberia arrastrar soporte stale."
	)
	_assert(
		round_label.text.contains("Control P1 | mueve WASD | ataca Space | energia Q/E | overdrive R | suelta C"),
		"Al usar F4 desde `Apoyo activo`, la referencia compacta deberia volver inmediatamente a los controles Easy."
	)
	_assert(
		not round_label.text.contains("Apoyo P1 |"),
		"Al usar F4 desde `Apoyo activo`, la linea de soporte tambien deberia desaparecer inmediatamente."
	)
	_assert(
		support_root.get_child_count() == 0,
		"Al usar F4 desde `Apoyo activo`, `SupportRoot` tampoco deberia quedar con soporte stale."
	)

	await _cleanup_node(main)


func _validate_lab_selector_recovers_from_support_after_manual_restart() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller != null:
		match_controller.round_intro_duration = 0.0
		match_controller.match_restart_delay = 0.25
		if match_controller.match_config != null:
			match_controller.match_config.round_intro_duration_teams = 0.0
			match_controller.match_config.rounds_to_win = 1
	root.add_child(main)

	await process_frame
	await process_frame

	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(round_label != null, "El HUD deberia seguir exponiendo RoundLabel para validar reinicio manual del selector runtime.")
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController para validar reinicio manual.")
	_assert(robots.size() >= 4, "La escena principal deberia seguir exponiendo cuatro robots para validar el reinicio manual del selector runtime.")
	if round_label == null or match_controller == null or robots.size() < 4:
		await _cleanup_node(main)
		return

	main.call("cycle_selected_lab_archetype")
	await process_frame
	await process_frame
	main.call("toggle_selected_lab_control_mode")
	await process_frame
	await process_frame

	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P1 Grua Avanzado"),
		"Antes de la baja, el selector runtime deberia reflejar el loadout runtime elegido para P1."
	)
	_assert(
		round_label.text.contains("Control P1 | mueve WASD | aim TFGX | ataca Space | energia Q/E | overdrive R | suelta C"),
		"Antes de la baja, la referencia compacta deberia reflejar el modo Hard runtime del slot seleccionado."
	)

	robots[0].fall_into_void()
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("Apoyo activo"),
		"Antes del reinicio manual, el selector runtime deberia pasar a `Apoyo activo` si el slot seleccionado cae."
	)
	_assert(
		round_label.text.contains("Apoyo P1 | sin carga"),
		"Antes del reinicio manual, el round-state deberia seguir exponiendo la capa accionable del soporte seleccionado."
	)

	robots[1].fall_into_void()
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	_assert(
		match_controller.is_match_over(),
		"El reinicio manual con F5 solo deberia validarse una vez que la partida ya esta realmente cerrada."
	)

	var restart_event := InputEventKey.new()
	restart_event.pressed = true
	restart_event.keycode = KEY_F5
	main._unhandled_input(restart_event)

	await process_frame
	await process_frame
	await process_frame
	await process_frame

	_assert(
		match_controller.get_round_status_line().contains("Ronda 1"),
		"Tras F5, el laboratorio deberia volver a una partida limpia desde la ronda 1."
	)
	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P1 Grua Avanzado"),
		"Tras F5, el selector runtime deberia volver a describir el robot seleccionado y conservar su loadout runtime."
	)
	_assert(
		not String(main.call("get_lab_selector_summary_line")).contains("Apoyo activo"),
		"Tras F5, el selector runtime no deberia seguir anunciando `Apoyo activo` para un soporte ya limpiado."
	)
	_assert(
		round_label.text.contains("Control P1 | mueve WASD | aim TFGX | ataca Space | energia Q/E | overdrive R | suelta C"),
		"Tras F5, la referencia compacta deberia volver a los controles del robot seleccionado y conservar el modo Hard runtime."
	)
	_assert(
		not round_label.text.contains("Apoyo P1 |"),
		"Tras F5, el round-state no deberia conservar la linea accionable del soporte seleccionado."
	)

	await _cleanup_node(main)


func _validate_lab_selector_recovers_from_support_after_round_reset() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller != null:
		match_controller.round_intro_duration = 0.0
		match_controller.round_reset_delay = 0.15
		if match_controller.match_config != null:
			match_controller.match_config.round_intro_duration_teams = 0.0
			match_controller.match_config.rounds_to_win = 2
			match_controller.match_config.void_elimination_round_points = 1
			match_controller.match_config.destruction_elimination_round_points = 1
			match_controller.match_config.unstable_elimination_round_points = 1
	root.add_child(main)

	await process_frame
	await process_frame

	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(round_label != null, "El HUD deberia seguir exponiendo RoundLabel para validar el reset automatico del selector runtime.")
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController para validar el reset automatico.")
	_assert(robots.size() >= 4, "La escena principal deberia seguir exponiendo cuatro robots para validar el reset automatico del selector runtime.")
	if round_label == null or match_controller == null or robots.size() < 4:
		await _cleanup_node(main)
		return

	main.call("cycle_selected_lab_archetype")
	await process_frame
	await process_frame
	main.call("toggle_selected_lab_control_mode")
	await process_frame
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[0].fall_into_void()
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P1 Apoyo activo"),
		"Antes del reset automatico, el selector runtime deberia seguir al slot seleccionado si entro en `Apoyo activo`."
	)
	_assert(
		round_label.text.contains("Control P1 | usa C | objetivo Q/E"),
		"Antes del reset automatico, la referencia compacta deberia seguir mostrando los controles reales del soporte seleccionado."
	)
	_assert(
		round_label.text.contains("Apoyo P1 | sin carga"),
		"Antes del reset automatico, el round-state deberia seguir exponiendo el estado accionable del soporte seleccionado."
	)

	robots[2].fall_into_void()
	robots[3].fall_into_void()
	await create_timer(match_controller.round_reset_delay + 0.2).timeout
	await process_frame
	await process_frame

	_assert(
		match_controller.is_round_active(),
		"Tras cerrar una ronda no final, el match deberia volver a una ronda activa."
	)
	_assert(
		match_controller.get_round_status_line().contains("Ronda 2"),
		"Tras el reset automatico, la partida deberia avanzar a la siguiente ronda."
	)
	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("P1 Grua Avanzado"),
		"Tras el reset automatico, el selector runtime deberia volver a mostrar el robot/loadout runtime del slot seleccionado."
	)
	_assert(
		not String(main.call("get_lab_selector_summary_line")).contains("Apoyo activo"),
		"Tras el reset automatico, el selector runtime no deberia arrastrar `Apoyo activo` de la ronda anterior."
	)
	_assert(
		round_label.text.contains("Control P1 | mueve WASD | aim TFGX | ataca Space | energia Q/E | overdrive R | suelta C"),
		"Tras el reset automatico, la referencia compacta deberia volver a los controles reales del robot seleccionado."
	)
	_assert(
		not round_label.text.contains("Apoyo P1 |"),
		"Tras el reset automatico, el round-state no deberia arrastrar la linea de apoyo del slot seleccionado."
	)
	var support_root := main.get_node_or_null("SupportRoot")
	var support_ship := support_root.get_child(0) if support_root != null and support_root.get_child_count() > 0 else null
	_assert(
		support_ship == null,
		"Tras el reset automatico, no deberia quedar una nave de apoyo runtime para el slot seleccionado."
	)
	var robot_selection_indicator := robots[0].get_node_or_null("LabSelectionIndicator") as MeshInstance3D
	_assert(robot_selection_indicator != null, "El robot seleccionado deberia seguir exponiendo la pista diegetica del laboratorio tras el reset automatico.")
	if robot_selection_indicator != null:
		_assert(
			robot_selection_indicator.visible,
			"Tras el reset automatico, la pista diegetica deberia volver al robot seleccionado."
		)

	await _cleanup_node(main)


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _find_line_with_prefix(lines: Array[String], prefix: String) -> String:
	for line in lines:
		if line.begins_with(prefix):
			return line

	return ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
