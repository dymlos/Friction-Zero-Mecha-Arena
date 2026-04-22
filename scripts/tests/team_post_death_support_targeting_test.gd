extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const PilotSupportShip = preload("res://scripts/support/pilot_support_ship.gd")
const PilotSupportPickup = preload("res://scripts/support/pilot_support_pickup.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_stabilizer_defaults_to_most_damaged_ally()
	await _verify_interference_defaults_to_unsuppressed_enemy()
	await _verify_interference_defaults_to_enemy_without_stability()
	_finish()


func _verify_stabilizer_defaults_to_most_damaged_ally() -> void:
	var main := await _instantiate_main_scene()
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar targeting de apoyo.")
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
		"Con varios aliados vivos, `estabilizador` deberia priorizar al aliado mas dañado y no al primero en scene-order."
	)

	await _cleanup_main(main)


func _verify_interference_defaults_to_unsuppressed_enemy() -> void:
	var main := await _instantiate_main_scene()
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar targeting enemigo.")
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
	support_ship.global_position = ship_position
	suppressed_enemy.global_position = ship_position + Vector3(0.0, 0.0, 1.0)
	fresh_enemy.global_position = ship_position + Vector3(0.0, 0.0, 1.9)
	var suppressed := suppressed_enemy.apply_control_zone_suppression(1.5, 0.7, 0.7)
	_assert(suppressed, "El rival de control ya suprimido deberia poder prepararse para el test.")

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_INTERFERENCE)
	_assert(stored, "La nave deberia aceptar una carga de interferencia directa para validar targeting.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == fresh_enemy,
		"Si hay mas de un rival valido, `interferencia` deberia priorizar a uno no suprimido antes que reciclar el ya afectado."
	)

	await _cleanup_main(main)


func _verify_interference_defaults_to_enemy_without_stability() -> void:
	var main := await _instantiate_main_scene()
	var robots := _get_scene_robots(main)
	var support_root := main.get_node_or_null("SupportRoot")
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar inmunidad utility.")
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
	support_ship.global_position = ship_position
	stable_enemy.global_position = ship_position + Vector3(0.0, 0.0, 1.0)
	fresh_enemy.global_position = ship_position + Vector3(0.0, 0.0, 1.9)
	var stabilized := stable_enemy.apply_stability_boost(1.5)
	_assert(stabilized, "El rival protegido por utility deberia poder prepararse para el test.")

	var stored := support_ship.store_support_payload(PilotSupportPickup.PAYLOAD_INTERFERENCE)
	_assert(stored, "La nave deberia aceptar una carga de interferencia directa para validar immunity-targeting.")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == fresh_enemy,
		"Si hay mas de un rival valido, `interferencia` deberia priorizar al que no esta protegido por `estabilidad`."
	)

	await _cleanup_main(main)


func _instantiate_main_scene() -> Node:
	var main = MAIN_SCENE.instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null and match_controller_preload.match_config != null:
		match_controller_preload.match_config.round_intro_duration_teams = 0.0
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
