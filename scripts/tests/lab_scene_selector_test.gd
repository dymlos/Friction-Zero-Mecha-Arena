extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const EXPECTED_SCENE_ORDER := [
	{
		"path": "res://scenes/main/main.tscn",
		"label": "Equipos base",
	},
	{
		"path": "res://scenes/main/main_teams_validation.tscn",
		"label": "Equipos rapido",
	},
	{
		"path": "res://scenes/main/main_teams_large_validation.tscn",
		"label": "Equipos grande",
	},
	{
		"path": "res://scenes/main/main_ffa.tscn",
		"label": "FFA base",
	},
	{
		"path": "res://scenes/main/main_ffa_validation.tscn",
		"label": "FFA rapido",
	},
	{
		"path": "res://scenes/main/main_ffa_large_validation.tscn",
		"label": "FFA grande",
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_lab_scene_selector_cycles_between_variants()
	await _validate_lab_scene_selector_preserves_runtime_loadout_between_variants()
	await _validate_lab_scene_selector_preserves_hud_detail_mode_between_variants()
	await _validate_lab_scene_selector_clears_selected_support_state_between_variants()
	_finish()


func _validate_lab_scene_selector_cycles_between_variants() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	current_scene = main

	await process_frame
	await process_frame

	_assert(main.has_method("cycle_lab_scene_variant"), "Main deberia poder ciclar escenas/laboratorios runtime.")
	_assert(main.has_method("get_lab_scene_variant_summary_line"), "Main deberia exponer un resumen legible de la escena activa.")
	if not main.has_method("cycle_lab_scene_variant") or not main.has_method("get_lab_scene_variant_summary_line"):
		await _cleanup_current_scene()
		return

	_assert(
		String(main.call("get_lab_scene_variant_summary_line")).contains("Equipos base"),
		"El resumen runtime deberia arrancar identificando la escena base de Equipos."
	)

	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	_assert(round_label != null, "El HUD deberia seguir exponiendo RoundLabel.")
	if round_label != null:
		_assert(
			round_label.text.contains("Escena | Equipos base"),
			"El HUD deberia dejar visible la escena activa para el loop de laboratorio."
		)
		_assert(
			round_label.text.contains("HUD | explicito | F1 cambia"),
			"El HUD del laboratorio deberia dejar visible tambien el modo HUD activo para no depender solo del status temporal."
		)

	for index in range(1, EXPECTED_SCENE_ORDER.size()):
		var expected: Dictionary = EXPECTED_SCENE_ORDER[index]
		current_scene.call("cycle_lab_scene_variant")
		await process_frame
		await process_frame
		await process_frame

		var active_scene := current_scene
		_assert(active_scene != null, "El ciclo runtime deberia dejar una escena activa tras cambiar de laboratorio.")
		if active_scene == null:
			return

		_assert(
			String(active_scene.scene_file_path) == String(expected.path),
			"El selector runtime deberia avanzar al siguiente laboratorio esperado."
		)
		_assert(
			active_scene.has_method("get_lab_scene_variant_summary_line"),
			"La escena recargada deberia conservar el resumen del selector runtime."
		)
		if active_scene.has_method("get_lab_scene_variant_summary_line"):
			_assert(
				String(active_scene.call("get_lab_scene_variant_summary_line")).contains(String(expected.label)),
				"Cada laboratorio deberia anunciar su variante activa al cargarse."
			)

		round_label = active_scene.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
		_assert(round_label != null, "Cada laboratorio deberia seguir exponiendo RoundLabel.")
		if round_label != null:
			_assert(
				round_label.text.contains("Escena | %s" % expected.label),
				"El HUD del laboratorio recargado deberia reflejar la escena activa."
			)

	current_scene.call("cycle_lab_scene_variant")
	await process_frame
	await process_frame
	await process_frame

	var wrapped_scene := current_scene
	_assert(wrapped_scene != null, "El ciclo runtime deberia poder volver a una escena valida.")
	if wrapped_scene != null:
		_assert(
			String(wrapped_scene.scene_file_path) == String(EXPECTED_SCENE_ORDER[0].path),
			"El selector runtime deberia wrapear de nuevo al laboratorio base inicial."
		)

	await _cleanup_current_scene()


func _validate_lab_scene_selector_preserves_runtime_loadout_between_variants() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	current_scene = main

	await process_frame
	await process_frame

	_assert(main.has_method("cycle_selected_lab_archetype"), "Main deberia poder cambiar arquetipos runtime antes de saltar de escena.")
	_assert(main.has_method("toggle_selected_lab_control_mode"), "Main deberia poder alternar Simple/Avanzado runtime antes de saltar de escena.")
	_assert(main.has_method("cycle_lab_selector_slot"), "Main deberia poder mover el selector runtime antes de saltar de escena.")
	if not (
		main.has_method("cycle_selected_lab_archetype")
		and main.has_method("toggle_selected_lab_control_mode")
		and main.has_method("cycle_lab_selector_slot")
	):
		await _cleanup_current_scene()
		return

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 2, "La escena principal deberia exponer al menos dos robots para validar persistencia runtime.")
	if robots.size() < 2:
		await _cleanup_current_scene()
		return

	main.call("cycle_selected_lab_archetype")
	await process_frame
	await process_frame
	main.call("toggle_selected_lab_control_mode")
	await process_frame
	await process_frame
	main.call("cycle_lab_selector_slot")
	await process_frame
	await process_frame
	main.call("cycle_selected_lab_archetype")
	await process_frame
	await process_frame

	_assert(robots[0].get_archetype_label() == "Grua", "El setup runtime previo al cambio de escena deberia dejar a P1 como Grua.")
	_assert(robots[0].control_mode == RobotBase.ControlMode.HARD, "El setup runtime previo al cambio de escena deberia dejar a P1 en Hard.")
	_assert(robots[1].get_archetype_label() == "Cizalla", "El setup runtime previo al cambio de escena deberia dejar a P2 como Cizalla.")
	_assert(bool(robots[1].call("is_lab_selected")), "Antes del salto de escena, el selector runtime deberia quedar sobre P2.")

	current_scene.call("cycle_lab_scene_variant")
	await process_frame
	await process_frame
	await process_frame

	var active_scene := current_scene
	_assert(active_scene != null, "El salto de laboratorio deberia dejar una escena activa para validar persistencia runtime.")
	if active_scene == null:
		return

	robots = _get_scene_robots(active_scene)
	_assert(robots.size() >= 2, "La escena recargada deberia conservar suficientes robots para validar persistencia runtime.")
	if robots.size() < 2:
		await _cleanup_current_scene()
		return

	_assert(
		robots[0].get_archetype_label() == "Grua",
		"Tras cambiar de escena con F6, P1 deberia conservar el arquetipo runtime que tenia en el laboratorio anterior."
	)
	_assert(
		robots[0].control_mode == RobotBase.ControlMode.HARD,
		"Tras cambiar de escena con F6, P1 deberia conservar tambien su modo Hard runtime."
	)
	_assert(
		robots[1].get_archetype_label() == "Cizalla",
		"Tras cambiar de escena con F6, P2 deberia conservar su arquetipo runtime."
	)
	_assert(
		bool(robots[1].call("is_lab_selected")),
		"Tras cambiar de escena con F6, el selector runtime deberia seguir apuntando al mismo slot elegido."
	)
	_assert(
		String(active_scene.call("get_lab_selector_summary_line")).contains("P2 Cizalla Simple"),
		"El resumen runtime de la escena recargada deberia reflejar el slot y loadout persistidos."
	)

	await _cleanup_current_scene()


func _validate_lab_scene_selector_preserves_hud_detail_mode_between_variants() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	current_scene = main

	await process_frame
	await process_frame

	_assert(main.has_method("cycle_hud_detail_mode"), "Main deberia poder alternar el HUD runtime antes de saltar de escena.")
	if not main.has_method("cycle_hud_detail_mode"):
		await _cleanup_current_scene()
		return

	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var status_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/StatusLabel") as Label
	_assert(round_label != null, "La escena principal deberia seguir exponiendo RoundLabel para validar HUD runtime.")
	_assert(status_label != null, "La escena principal deberia seguir exponiendo StatusLabel para validar HUD runtime.")
	if round_label == null or status_label == null:
		await _cleanup_current_scene()
		return

	_assert(
		round_label.text.contains("Modo |"),
		"El laboratorio base deberia arrancar en ayuda visible para validar el override runtime."
	)

	main.call("cycle_hud_detail_mode")
	await process_frame
	await process_frame

	_assert(
		not round_label.text.contains("Modo |"),
		"Antes del salto de escena, F1 deberia haber movido el HUD al modo contextual."
	)
	_assert(
		not round_label.text.contains("HUD |"),
		"Tras alternar con F1, el round-state contextual no deberia seguir mostrando metadata del HUD."
	)
	_assert(
		not round_label.text.contains("Escena |"),
		"Tras alternar con F1, el round-state contextual no deberia seguir mostrando metadata del laboratorio."
	)
	_assert(
		status_label.text.contains("HUD contextual"),
		"El status runtime deberia anunciar el HUD contextual antes de persistirlo entre escenas."
	)

	current_scene.call("cycle_lab_scene_variant")
	await process_frame
	await process_frame
	await process_frame

	var active_scene := current_scene
	_assert(active_scene != null, "El salto de laboratorio deberia dejar una escena activa para validar HUD persistido.")
	if active_scene == null:
		return

	var reloaded_round_label := active_scene.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var reloaded_status_label := active_scene.get_node_or_null("UI/MatchHud/Root/TopLeftStack/StatusLabel") as Label
	_assert(reloaded_round_label != null, "La escena recargada deberia seguir exponiendo RoundLabel.")
	_assert(reloaded_status_label != null, "La escena recargada deberia seguir exponiendo StatusLabel.")
	if reloaded_round_label == null or reloaded_status_label == null:
		await _cleanup_current_scene()
		return

	_assert(
		not reloaded_round_label.text.contains("Modo |"),
		"Tras cambiar de escena con F6, el override runtime del HUD deberia seguir en contextual."
	)
	_assert(
		not reloaded_round_label.text.contains("HUD |"),
		"Tras cambiar de escena con F6, el round-state contextual no deberia volver a poblar metadata del HUD."
	)
	_assert(
		not reloaded_round_label.text.contains("Escena |"),
		"Tras cambiar de escena con F6, el round-state contextual no deberia recuperar metadata del laboratorio."
	)
	_assert(
		reloaded_status_label.text.contains("HUD contextual"),
		"Tras cambiar de escena con F6, el estado visible deberia seguir anunciando el HUD persistido."
	)

	await _cleanup_current_scene()


func _validate_lab_scene_selector_clears_selected_support_state_between_variants() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	current_scene = main

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController")
	if match_controller != null:
		match_controller.round_intro_duration = 0.0
		if match_controller.match_config != null:
			match_controller.match_config.round_intro_duration_teams = 0.0

	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(round_label != null, "La escena principal deberia seguir exponiendo RoundLabel para validar el salto de escena desde `Apoyo activo`.")
	_assert(robots.size() >= 2, "La escena principal deberia exponer suficientes robots para entrar en `Apoyo activo` antes de cambiar de laboratorio.")
	if round_label == null or robots.size() < 2:
		await _cleanup_current_scene()
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
		String(main.call("get_lab_selector_summary_line")).contains("Apoyo activo"),
		"Antes de cambiar de laboratorio, el selector runtime deberia reflejar que el slot seleccionado ya paso a `Apoyo activo`."
	)
	_assert(
		round_label.text.contains("Control P1 | usa C | objetivo Q/E"),
		"Antes de cambiar de laboratorio, la referencia compacta deberia seguir los controles reales del soporte seleccionado."
	)
	_assert(
		round_label.text.contains("Apoyo P1 | sin carga"),
		"Antes de cambiar de laboratorio, el round-state deberia seguir exponiendo la capa accionable del soporte seleccionado."
	)

	current_scene.call("cycle_lab_scene_variant")
	await process_frame
	await process_frame
	await process_frame

	var active_scene := current_scene
	_assert(active_scene != null, "El cambio de laboratorio desde `Apoyo activo` deberia dejar una escena activa.")
	if active_scene == null:
		return

	round_label = active_scene.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	robots = _get_scene_robots(active_scene)
	_assert(round_label != null, "La escena recargada deberia seguir exponiendo RoundLabel tras un salto desde `Apoyo activo`.")
	_assert(robots.size() >= 1, "La escena recargada deberia conservar al menos el slot seleccionado para validar su reset.")
	if round_label == null or robots.is_empty():
		await _cleanup_current_scene()
		return

	_assert(
		String(active_scene.call("get_lab_scene_variant_summary_line")).contains("Equipos rapido"),
		"Tras `F6`, el laboratorio deberia avanzar al siguiente variante esperada."
	)
	_assert(
		String(active_scene.call("get_lab_selector_summary_line")).contains("P1 Grua Avanzado"),
		"Tras `F6`, el selector runtime deberia recuperar el loadout runtime del slot seleccionado y volver a describir el robot activo."
	)
	_assert(
		not String(active_scene.call("get_lab_selector_summary_line")).contains("Apoyo activo"),
		"Tras `F6`, el selector runtime no deberia arrastrar el estado `Apoyo activo` del laboratorio anterior."
	)
	_assert(
		round_label.text.contains("Control P1 | mueve WASD | aim TFGX | ataca Space | energia Q/E | overdrive R | suelta C"),
		"Tras `F6`, la referencia compacta deberia volver a los controles del robot con el modo Hard runtime restaurado."
	)
	_assert(
		not round_label.text.contains("Apoyo P1 |"),
		"Tras `F6`, el round-state no deberia conservar la linea accionable del soporte del laboratorio anterior."
	)

	await _cleanup_current_scene()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_current_scene() -> void:
	var active_scene := current_scene
	if not is_instance_valid(active_scene):
		return

	var parent := active_scene.get_parent()
	if parent != null:
		parent.remove_child(active_scene)
	active_scene.free()
	current_scene = null
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
