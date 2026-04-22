extends SceneTree

const TEAMS_SCENES := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
]
const MatchController = preload("res://scripts/systems/match_controller.gd")
const PilotSupportShip = preload("res://scripts/support/pilot_support_ship.gd")
const PilotSupportPickup = preload("res://scripts/support/pilot_support_pickup.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in TEAMS_SCENES:
		await _verify_stabilizer_defaults_to_most_damaged_ally(scene_path)
		await _verify_stabilizer_retargets_to_new_more_damaged_ally_without_manual_override(scene_path)
		await _verify_interference_defaults_to_unsuppressed_enemy(scene_path)
		await _verify_interference_defaults_to_enemy_without_stability(scene_path)
		await _verify_interference_retargets_when_auto_selected_enemy_becomes_immune(scene_path)
		await _verify_interference_keeps_manual_override_when_selected_enemy_becomes_immune(scene_path)
		await _verify_interference_resumes_auto_targeting_after_manual_cycle_back_to_default(scene_path)
		await _verify_surge_defaults_to_ally_with_useful_remaining_window(scene_path)
		await _verify_mobility_defaults_to_ally_with_useful_remaining_window(scene_path)
	_finish()


func _verify_stabilizer_defaults_to_most_damaged_ally(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena %s deberia ofrecer cuatro robots para validar targeting de apoyo." % scene_path)
	_assert(support_root != null, "La escena %s deberia seguir exponiendo SupportRoot." % scene_path)
	_assert(match_controller != null, "La escena %s deberia seguir exponiendo MatchController." % scene_path)
	if robots.size() < 4 or support_root == null or match_controller == null:
		await _cleanup_main(main)
		return

	robots[0].team_id = 1
	robots[1].team_id = 1
	robots[2].team_id = 1
	robots[3].team_id = 2
	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.start_match()
	await _wait_frames(2)

	robots[0].apply_damage_to_part("left_arm", robots[0].max_part_health * 0.12, Vector3.LEFT)
	robots[2].apply_damage_to_part("right_leg", robots[2].max_part_health * 0.55, Vector3.RIGHT)
	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado con otro duo vivo deberia aparecer una unica nave de apoyo."
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia instanciarse correctamente.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_STABILIZER)
	_assert(stored, "La nave deberia aceptar una carga estabilizadora directa para validar targeting.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == robots[2],
		"La escena %s deberia priorizar con `estabilizador` al aliado mas dañado y no al primero en scene-order." % scene_path
	)

	await _cleanup_main(main)


func _verify_interference_defaults_to_unsuppressed_enemy(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena %s deberia ofrecer cuatro robots para validar targeting enemigo." % scene_path)
	_assert(support_root != null, "La escena %s deberia seguir exponiendo SupportRoot." % scene_path)
	_assert(match_controller != null, "La escena %s deberia seguir exponiendo MatchController." % scene_path)
	if robots.size() < 4 or support_root == null or match_controller == null:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.start_match()
	await _wait_frames(2)

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado en Teams deberia aparecer una nave de apoyo para validar targeting enemigo."
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar la carga de interferencia.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var suppressed_enemy := robots[2]
	var fresh_enemy := robots[3]
	var ship_position := Vector3(0.0, support_ship.global_position.y, 0.0)
	_stabilize_support_target_candidate(support_ship, suppressed_enemy, ship_position + Vector3(0.0, 0.0, 1.0))
	_stabilize_support_target_candidate(support_ship, fresh_enemy, ship_position + Vector3(0.0, 0.0, 1.9))
	var suppressed := suppressed_enemy.apply_control_zone_suppression(1.5, 0.7, 0.7)
	_assert(suppressed, "El rival de control ya suprimido deberia poder prepararse para el test.")

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_INTERFERENCE)
	_assert(stored, "La nave deberia aceptar una carga de interferencia directa para validar targeting.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == fresh_enemy,
		"La escena %s deberia hacer que `interferencia` priorice a un rival no suprimido antes que reciclar el ya afectado." % scene_path
	)

	await _cleanup_main(main)


func _verify_stabilizer_retargets_to_new_more_damaged_ally_without_manual_override(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena %s deberia ofrecer cuatro robots para validar retargeting aliado runtime." % scene_path)
	_assert(support_root != null, "La escena %s deberia seguir exponiendo SupportRoot." % scene_path)
	_assert(match_controller != null, "La escena %s deberia seguir exponiendo MatchController." % scene_path)
	if robots.size() < 4 or support_root == null or match_controller == null:
		await _cleanup_main(main)
		return

	robots[0].team_id = 1
	robots[1].team_id = 1
	robots[2].team_id = 1
	robots[3].team_id = 2
	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.start_match()
	await _wait_frames(2)

	var initially_damaged_ally := robots[0]
	var newly_more_damaged_ally := robots[2]
	var ship_anchor := Vector3(0.0, 0.0, 0.0)
	_stabilize_support_target_candidate(null, initially_damaged_ally, ship_anchor + Vector3(-1.2, 0.0, 1.0))
	_stabilize_support_target_candidate(null, newly_more_damaged_ally, ship_anchor + Vector3(1.2, 0.0, 1.6))
	initially_damaged_ally.apply_damage_to_part("left_arm", initially_damaged_ally.max_part_health * 0.15, Vector3.LEFT)
	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado con otro duo vivo deberia aparecer una unica nave de apoyo."
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia instanciarse correctamente.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_STABILIZER)
	_assert(stored, "La nave deberia aceptar una carga estabilizadora directa para validar retargeting aliado runtime.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == initially_damaged_ally,
		"La escena %s deberia arrancar con el auto-target sobre el unico aliado dañado." % scene_path
	)

	newly_more_damaged_ally.apply_damage_to_part("right_leg", newly_more_damaged_ally.max_part_health * 0.55, Vector3.RIGHT)
	support_ship.call("_refresh_target_selection")
	await _wait_frames(1)

	_assert(
		support_ship.get_selected_target_robot() == newly_more_damaged_ally,
		"La escena %s deberia resincronizar `estabilizador` con el aliado que paso a ser claramente mas urgente durante la ronda." % scene_path
	)

	await _cleanup_main(main)


func _verify_interference_defaults_to_enemy_without_stability(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena %s deberia ofrecer cuatro robots para validar inmunidad utility." % scene_path)
	_assert(support_root != null, "La escena %s deberia seguir exponiendo SupportRoot." % scene_path)
	_assert(match_controller != null, "La escena %s deberia seguir exponiendo MatchController." % scene_path)
	if robots.size() < 4 or support_root == null or match_controller == null:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.start_match()
	await _wait_frames(2)

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado en Teams deberia aparecer una nave de apoyo para validar immunity-targeting."
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar interferencia contra utility.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var stable_enemy := robots[2]
	var fresh_enemy := robots[3]
	var ship_position := Vector3(0.0, support_ship.global_position.y, 0.0)
	_stabilize_support_target_candidate(support_ship, stable_enemy, ship_position + Vector3(0.0, 0.0, 1.0))
	_stabilize_support_target_candidate(support_ship, fresh_enemy, ship_position + Vector3(0.0, 0.0, 1.9))
	var stabilized := stable_enemy.apply_stability_boost(1.5)
	_assert(stabilized, "El rival protegido por utility deberia poder prepararse para el test.")

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_INTERFERENCE)
	_assert(stored, "La nave deberia aceptar una carga de interferencia directa para validar immunity-targeting.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == fresh_enemy,
		"La escena %s deberia hacer que `interferencia` priorice al rival no protegido por `estabilidad`." % scene_path
	)

	await _cleanup_main(main)


func _verify_interference_retargets_when_auto_selected_enemy_becomes_immune(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar retargeting runtime.")
	_assert(support_root != null, "La escena principal deberia seguir exponiendo SupportRoot.")
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController.")
	if robots.size() < 4 or support_root == null or match_controller == null:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.start_match()
	await _wait_frames(2)

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado en Teams deberia aparecer una nave de apoyo para validar retargeting runtime."
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar retargeting runtime.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var auto_target_enemy := robots[3]
	var fallback_enemy := robots[2]
	var ship_position := Vector3(0.0, support_ship.global_position.y, 0.0)
	_stabilize_support_target_candidate(support_ship, auto_target_enemy, ship_position + Vector3(0.0, 0.0, 1.0))
	_stabilize_support_target_candidate(support_ship, fallback_enemy, ship_position + Vector3(0.0, 0.0, 1.8))

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_INTERFERENCE)
	_assert(stored, "La nave deberia aceptar una carga de interferencia directa para validar retargeting runtime.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == auto_target_enemy,
		"Antes del cambio de estado, `interferencia` deberia seguir autoapuntando al rival mas util."
	)

	var stabilized := auto_target_enemy.apply_stability_boost(1.5)
	_assert(stabilized, "El rival autoapuntado deberia poder ganar `estabilidad` durante la ronda.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == fallback_enemy,
		"Si el target auto-seleccionado queda inmune pero hay otro rival util, la nave deberia resincronizarse con ese nuevo mejor objetivo."
	)

	await _cleanup_main(main)


func _verify_interference_keeps_manual_override_when_selected_enemy_becomes_immune(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar override manual.")
	_assert(support_root != null, "La escena principal deberia seguir exponiendo SupportRoot.")
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController.")
	if robots.size() < 4 or support_root == null or match_controller == null:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.start_match()
	await _wait_frames(2)

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado en Teams deberia aparecer una nave de apoyo para validar override manual."
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar override manual.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var auto_target_enemy := robots[3]
	var manually_selected_enemy := robots[2]
	var ship_position := Vector3(0.0, support_ship.global_position.y, 0.0)
	_stabilize_support_target_candidate(support_ship, auto_target_enemy, ship_position + Vector3(0.0, 0.0, 1.0))
	_stabilize_support_target_candidate(support_ship, manually_selected_enemy, ship_position + Vector3(0.0, 0.0, 1.8))

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_INTERFERENCE)
	_assert(stored, "La nave deberia aceptar una carga de interferencia directa para validar override manual.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == auto_target_enemy,
		"Antes del override manual, `interferencia` deberia seguir autoapuntando al rival mas util."
	)

	Input.action_press("p2_energy_next")
	await _wait_frames(2)
	Input.action_release("p2_energy_next")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == manually_selected_enemy,
		"El test deberia poder mover el target a mano antes de invalidarlo."
	)

	var stabilized := manually_selected_enemy.apply_stability_boost(1.5)
	_assert(stabilized, "El rival seleccionado manualmente deberia poder ganar `estabilidad` durante la ronda.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == manually_selected_enemy,
		"Si el jugador eligio ese target a mano, la nave no deberia auto-corregirlo aunque otro rival vuelva a ser mas util."
	)

	await _cleanup_main(main)


func _verify_interference_resumes_auto_targeting_after_manual_cycle_back_to_default(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar el regreso al modo auto.")
	_assert(support_root != null, "La escena principal deberia seguir exponiendo SupportRoot.")
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController.")
	if robots.size() < 4 or support_root == null or match_controller == null:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.start_match()
	await _wait_frames(2)

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado en Teams deberia aparecer una nave de apoyo para validar el regreso al modo auto."
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar el regreso al modo auto.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var auto_target_enemy := robots[3]
	var alternate_enemy := robots[2]
	var ship_position := Vector3(0.0, support_ship.global_position.y, 0.0)
	_stabilize_support_target_candidate(support_ship, auto_target_enemy, ship_position + Vector3(0.0, 0.0, 1.0))
	_stabilize_support_target_candidate(support_ship, alternate_enemy, ship_position + Vector3(0.0, 0.0, 1.8))

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_INTERFERENCE)
	_assert(stored, "La nave deberia aceptar una carga de interferencia directa para validar el regreso al modo auto.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == auto_target_enemy,
		"Antes de tocar el target a mano, `interferencia` deberia seguir autoapuntando al rival mas util."
	)

	Input.action_press("p2_energy_next")
	await _wait_frames(2)
	Input.action_release("p2_energy_next")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == alternate_enemy,
		"El test deberia poder mover el target al rival alternativo para entrar en override manual."
	)

	Input.action_press("p2_energy_next")
	await _wait_frames(2)
	Input.action_release("p2_energy_next")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == auto_target_enemy,
		"El test deberia poder volver a mano al mismo target que el auto-target habia elegido por defecto."
	)

	var stabilized := auto_target_enemy.apply_stability_boost(1.5)
	_assert(stabilized, "El target default deberia poder ganar `estabilidad` para invalidar el viejo default.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == alternate_enemy,
		"Si el jugador vuelve a quedar parado sobre el mismo target default, la nave deberia retomar el modo auto y resincronizarse cuando ese objetivo deja de ser util."
	)

	await _cleanup_main(main)


func _verify_surge_defaults_to_ally_with_useful_remaining_window(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar targeting de energia.")
	_assert(support_root != null, "La escena principal deberia seguir exponiendo SupportRoot.")
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController.")
	if robots.size() < 4 or support_root == null or match_controller == null:
		await _cleanup_main(main)
		return

	robots[0].team_id = 1
	robots[1].team_id = 1
	robots[2].team_id = 1
	robots[3].team_id = 2
	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.start_match()
	await _wait_frames(2)

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado con otro duo vivo deberia aparecer una unica nave de apoyo."
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia instanciarse correctamente.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var payload_duration := float(support_ship.get("support_energy_surge_duration"))
	var redundant_ally := robots[0]
	var useful_ally := robots[2]
	redundant_ally.apply_energy_surge(payload_duration + 1.0)
	useful_ally.apply_energy_surge(maxf(payload_duration * 0.35, 0.2))

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_SURGE)
	_assert(stored, "La nave deberia aceptar una carga de energia directa para validar targeting.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == useful_ally,
		"Si ambos aliados ya tienen `surge`, el targeting por defecto deberia priorizar al que aun ganaria ventana real."
	)

	await _cleanup_main(main)


func _verify_mobility_defaults_to_ally_with_useful_remaining_window(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar targeting de movilidad.")
	_assert(support_root != null, "La escena principal deberia seguir exponiendo SupportRoot.")
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController.")
	if robots.size() < 4 or support_root == null or match_controller == null:
		await _cleanup_main(main)
		return

	robots[0].team_id = 1
	robots[1].team_id = 1
	robots[2].team_id = 1
	robots[3].team_id = 2
	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.start_match()
	await _wait_frames(2)

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado con otro duo vivo deberia aparecer una unica nave de apoyo."
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia instanciarse correctamente.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var redundant_ally := robots[0]
	var useful_ally := robots[2]
	var applied_duration := float(support_ship.get("support_mobility_boost_duration"))
	applied_duration *= useful_ally.get_mobility_boost_duration_multiplier()
	redundant_ally.apply_mobility_boost(applied_duration + 1.0)
	useful_ally.apply_mobility_boost(maxf(applied_duration * 0.35, 0.2))

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_MOBILITY)
	_assert(stored, "La nave deberia aceptar una carga de movilidad directa para validar targeting.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == useful_ally,
		"Si ambos aliados ya tienen `movilidad`, el targeting por defecto deberia priorizar al que aun ganaria ventana real."
	)

	await _cleanup_main(main)


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


func _wait_frames(count: int) -> void:
	for _step in range(count):
		await physics_frame
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _stabilize_support_target_candidate(
	support_ship: PilotSupportShip,
	robot: RobotBase,
	target_position: Vector3
) -> void:
	if support_ship != null:
		support_ship.global_position = Vector3(0.0, support_ship.global_position.y, 0.0)
	if robot == null:
		return

	robot.is_player_controlled = false
	robot.global_position = target_position
	robot.velocity = Vector3.ZERO
	robot.set("_planar_velocity", Vector3.ZERO)
	robot.set("external_impulse", Vector3.ZERO)


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
