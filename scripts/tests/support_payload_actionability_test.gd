extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const PilotSupportPickup = preload("res://scripts/support/pilot_support_pickup.gd")
const PilotSupportShip = preload("res://scripts/support/pilot_support_ship.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_surge_does_not_spend_itself_on_full_window_target()
	await _verify_mobility_does_not_spend_itself_on_full_window_target()
	_finish()


func _verify_surge_does_not_spend_itself_on_full_window_target() -> void:
	var main := await _instantiate_main_scene()
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(support_root != null, "La escena Teams deberia seguir exponiendo SupportRoot.")
	_assert(robots.size() >= 4, "La escena Teams deberia seguir ofreciendo cuatro robots.")
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


func _verify_mobility_does_not_spend_itself_on_full_window_target() -> void:
	var main := await _instantiate_main_scene()
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(support_root != null, "La escena Teams deberia seguir exponiendo SupportRoot.")
	_assert(robots.size() >= 4, "La escena Teams deberia seguir ofreciendo cuatro robots.")
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
