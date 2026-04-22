extends SceneTree

const TEAMS_SCENES := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
]
const MatchController = preload("res://scripts/systems/match_controller.gd")
const PilotSupportPickup = preload("res://scripts/support/pilot_support_pickup.gd")
const PilotSupportShip = preload("res://scripts/support/pilot_support_ship.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in TEAMS_SCENES:
		await _verify_surge_does_not_spend_itself_on_full_window_target(scene_path)
		await _verify_mobility_does_not_spend_itself_on_full_window_target(scene_path)
		await _verify_surge_can_be_redirected_after_manual_redundant_selection(scene_path)
		await _verify_mobility_can_be_redirected_after_manual_redundant_selection(scene_path)
	_finish()


func _verify_surge_does_not_spend_itself_on_full_window_target(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(support_root != null, "La escena %s deberia seguir exponiendo SupportRoot." % scene_path)
	_assert(robots.size() >= 4, "La escena %s deberia seguir ofreciendo cuatro robots." % scene_path)
	if support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	robots[1].fall_into_void()
	await _wait_frames(4)

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar el gasto real de `surge`.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var target_ally := robots[0]
	target_ally.apply_energy_surge(float(support_ship.support_energy_surge_duration) + 1.0)
	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_SURGE)
	_assert(stored, "La nave deberia aceptar una carga `surge` directa para validar el no-op.")
	await _wait_frames(2)

	_assert(
		support_ship.get_status_summary().contains("ya activo"),
		"El soporte deberia seguir marcando `ya activo` antes de intentar gastar `surge`."
	)

	var used := support_ship.use_support_payload()
	_assert(
		not used,
		"Si el target ya tiene toda la ventana util de `surge`, la nave no deberia gastar la carga en un no-op."
	)
	_assert(
		support_ship.has_support_payload(),
		"Una carga `surge` redundante deberia quedar disponible para redirigirla a otro aliado."
	)

	await _cleanup_main(main)


func _verify_mobility_does_not_spend_itself_on_full_window_target(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(support_root != null, "La escena %s deberia seguir exponiendo SupportRoot." % scene_path)
	_assert(robots.size() >= 4, "La escena %s deberia seguir ofreciendo cuatro robots." % scene_path)
	if support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	robots[1].fall_into_void()
	await _wait_frames(4)

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar el gasto real de `movilidad`.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var target_ally := robots[0]
	var applied_duration := float(support_ship.support_mobility_boost_duration)
	applied_duration *= target_ally.get_mobility_boost_duration_multiplier()
	target_ally.apply_mobility_boost(applied_duration + 1.0)
	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_MOBILITY)
	_assert(stored, "La nave deberia aceptar una carga `movilidad` directa para validar el no-op.")
	await _wait_frames(2)

	_assert(
		support_ship.get_status_summary().contains("ya activo"),
		"El soporte deberia seguir marcando `ya activo` antes de intentar gastar `movilidad`."
	)

	var used := support_ship.use_support_payload()
	_assert(
		not used,
		"Si el target ya tiene toda la ventana util de `movilidad`, la nave no deberia gastar la carga en un no-op."
	)
	_assert(
		support_ship.has_support_payload(),
		"Una carga `movilidad` redundante deberia quedar disponible para redirigirla a otro aliado."
	)

	await _cleanup_main(main)


func _verify_surge_can_be_redirected_after_manual_redundant_selection(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(support_root != null, "La escena %s deberia seguir exponiendo SupportRoot." % scene_path)
	_assert(robots.size() >= 4, "La escena %s deberia seguir ofreciendo cuatro robots." % scene_path)
	_assert(match_controller != null, "La escena %s deberia seguir exponiendo MatchController." % scene_path)
	if support_root == null or robots.size() < 4 or match_controller == null:
		await _cleanup_main(main)
		return

	await _configure_multi_ally_teams_match(match_controller, robots)
	robots[1].fall_into_void()
	await _wait_frames(4)

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar el redireccionamiento real de `surge`.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var redundant_ally := robots[0]
	var useful_ally := robots[2]
	var payload_duration := float(support_ship.support_energy_surge_duration)
	redundant_ally.apply_energy_surge(payload_duration + 1.0)
	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_SURGE)
	_assert(stored, "La nave deberia aceptar una carga `surge` directa para validar el redireccionamiento.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == useful_ally,
		"Con otro aliado realmente util, `surge` deberia arrancar sobre ese target y no sobre el saturado."
	)

	Input.action_press("p2_energy_prev")
	await _wait_frames(2)
	Input.action_release("p2_energy_prev")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == redundant_ally,
		"El test deberia poder forzar una mala seleccion manual hacia el aliado saturado."
	)
	_assert(
		support_ship.get_status_summary().contains("ya activo"),
		"La lectura compacta deberia seguir avisando `ya activo` al quedar clavado sobre un target redundante."
	)

	var used_on_redundant_target := support_ship.use_support_payload()
	_assert(
		not used_on_redundant_target,
		"Una mala seleccion manual de `surge` no deberia gastar la carga si el target sigue completamente saturado."
	)
	_assert(
		support_ship.has_support_payload(),
		"Tras bloquear el no-op de `surge`, la carga deberia seguir disponible para corregir la decision."
	)

	Input.action_press("p2_energy_next")
	await _wait_frames(2)
	Input.action_release("p2_energy_next")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == useful_ally,
		"En el setup Teams actual, una sola correccion manual deberia devolver `surge` al aliado util."
	)

	var used_on_useful_target := support_ship.use_support_payload()
	_assert(
		used_on_useful_target,
		"Tras reciclar el target una vez, `surge` deberia poder gastarse enseguida sobre el aliado util."
	)
	_assert(
		not support_ship.has_support_payload(),
		"Despues de redirigir `surge` a un target util, la nave deberia quedar sin carga pendiente."
	)
	_assert(
		useful_ally.is_energy_surge_active(),
		"El aliado util deberia terminar con `surge` activo al cerrar la correccion manual."
	)

	await _cleanup_main(main)


func _verify_mobility_can_be_redirected_after_manual_redundant_selection(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(support_root != null, "La escena %s deberia seguir exponiendo SupportRoot." % scene_path)
	_assert(robots.size() >= 4, "La escena %s deberia seguir ofreciendo cuatro robots." % scene_path)
	_assert(match_controller != null, "La escena %s deberia seguir exponiendo MatchController." % scene_path)
	if support_root == null or robots.size() < 4 or match_controller == null:
		await _cleanup_main(main)
		return

	await _configure_multi_ally_teams_match(match_controller, robots)
	robots[1].fall_into_void()
	await _wait_frames(4)

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar el redireccionamiento real de `movilidad`.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var redundant_ally := robots[0]
	var useful_ally := robots[2]
	var payload_duration := float(support_ship.support_mobility_boost_duration)
	payload_duration *= redundant_ally.get_mobility_boost_duration_multiplier()
	redundant_ally.apply_mobility_boost(payload_duration + 1.0)
	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_MOBILITY)
	_assert(stored, "La nave deberia aceptar una carga `movilidad` directa para validar el redireccionamiento.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == useful_ally,
		"Con otro aliado realmente util, `movilidad` deberia arrancar sobre ese target y no sobre el saturado."
	)

	Input.action_press("p2_energy_prev")
	await _wait_frames(2)
	Input.action_release("p2_energy_prev")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == redundant_ally,
		"El test deberia poder forzar una mala seleccion manual hacia el aliado saturado."
	)
	_assert(
		support_ship.get_status_summary().contains("ya activo"),
		"La lectura compacta deberia seguir avisando `ya activo` al quedar clavado sobre un target redundante."
	)

	var used_on_redundant_target := support_ship.use_support_payload()
	_assert(
		not used_on_redundant_target,
		"Una mala seleccion manual de `movilidad` no deberia gastar la carga si el target sigue completamente saturado."
	)
	_assert(
		support_ship.has_support_payload(),
		"Tras bloquear el no-op de `movilidad`, la carga deberia seguir disponible para corregir la decision."
	)

	Input.action_press("p2_energy_next")
	await _wait_frames(2)
	Input.action_release("p2_energy_next")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == useful_ally,
		"En el setup Teams actual, una sola correccion manual deberia devolver `movilidad` al aliado util."
	)

	var used_on_useful_target := support_ship.use_support_payload()
	_assert(
		used_on_useful_target,
		"Tras reciclar el target una vez, `movilidad` deberia poder gastarse enseguida sobre el aliado util."
	)
	_assert(
		not support_ship.has_support_payload(),
		"Despues de redirigir `movilidad` a un target util, la nave deberia quedar sin carga pendiente."
	)
	_assert(
		useful_ally.is_mobility_boost_active(),
		"El aliado util deberia terminar con `movilidad` activa al cerrar la correccion manual."
	)

	await _cleanup_main(main)


func _configure_multi_ally_teams_match(match_controller: MatchController, robots: Array[RobotBase]) -> void:
	robots[0].team_id = 1
	robots[1].team_id = 1
	robots[2].team_id = 1
	robots[3].team_id = 2
	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.start_match()
	await _wait_frames(2)


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia seguir existiendo." % scene_path)
	if not (packed_scene is PackedScene):
		return Node.new()

	var main = (packed_scene as PackedScene).instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null and match_controller_preload.match_config != null:
		match_controller_preload.match_config.round_intro_duration_teams = 0.0
		match_controller_preload.match_config.progressive_space_reduction = false
		match_controller_preload.match_config.round_time_seconds = maxf(
			float(match_controller_preload.match_config.round_time_seconds),
			120.0
		)
	root.add_child(main)
	await process_frame
	await process_frame
	return main


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
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
