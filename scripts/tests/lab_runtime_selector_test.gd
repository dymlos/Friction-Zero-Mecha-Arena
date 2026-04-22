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
	await _validate_lab_selected_controls_follow_support_ship()
	await _validate_ffa_scoreboard_refreshes_after_runtime_loadout_change()
	_finish()


func _validate_lab_selector_cycles_roster_and_control_mode() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	_assert(main.has_method("cycle_lab_selector_slot"), "Main deberia exponer un selector runtime por slot.")
	_assert(main.has_method("cycle_selected_lab_archetype"), "Main deberia poder ciclar el arquetipo del slot seleccionado.")
	_assert(main.has_method("toggle_selected_lab_control_mode"), "Main deberia poder alternar Easy/Hard para el slot seleccionado.")
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

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel")
	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel")
	_assert(round_label is Label, "El HUD deberia seguir exponiendo RoundLabel.")
	_assert(roster_label is Label, "El HUD deberia seguir exponiendo RosterLabel.")
	if not (round_label is Label) or not (roster_label is Label):
		await _cleanup_node(main)
		return

	var initial_summary := String(main.call("get_lab_selector_summary_line"))
	_assert(initial_summary.contains("P1"), "El selector runtime deberia arrancar apuntando al primer slot.")
	_assert(initial_summary.contains("Ariete"), "El resumen inicial deberia reflejar el arquetipo base del slot 1.")
	_assert(initial_summary.contains("Easy"), "El selector runtime deberia reflejar el modo de control inicial.")
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
		"El selector runtime deberia poder alternar Easy/Hard sobre el slot activo."
	)
	_assert(
		String(main.call("get_lab_selector_summary_line")).contains("Hard"),
		"El resumen del selector runtime deberia reflejar el nuevo modo de control."
	)
	_assert(
		(round_label as Label).text.contains("Control P1 | mueve WASD | aim TFGX | ataca Space | energia Q/E | overdrive R | suelta C"),
		"Al pasar el slot seleccionado a Hard, la referencia compacta deberia sumar el aim dedicado real."
	)
	_assert(
		(roster_label as Label).text.contains("Hard"),
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

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel") as Label
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
		String(main.call("get_lab_selector_summary_line")).contains("P1 Ariete Easy"),
		"Antes de una baja, el resumen del selector runtime deberia seguir describiendo el robot seleccionado."
	)

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
		not String(main.call("get_lab_selector_summary_line")).contains("Ariete Easy"),
		"Si el slot seleccionado ya esta en `Apoyo activo`, el resumen del laboratorio no deberia seguir anunciandolo como si controlara el robot original."
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
