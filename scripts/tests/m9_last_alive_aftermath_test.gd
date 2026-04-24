extends SceneTree

const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const FfaAftermathRules = preload("res://scripts/systems/ffa_aftermath_rules.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const FfaAftermathPickup = preload("res://scripts/pickups/ffa_aftermath_pickup.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(
		FfaAftermathRules.should_spawn_aftermath(
			MatchController.MatchMode.FFA,
			true,
			2,
			MatchModeVariantCatalog.VARIANT_LAST_ALIVE
		),
		"Aftermath FFA no debe depender de score_by_cause."
	)

	var main := FFA_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	match_controller.set_mode_variant_id(MatchModeVariantCatalog.VARIANT_LAST_ALIVE)
	match_controller.match_config.rounds_to_win = 1
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.set_runtime_match_restart_enabled(false)
	match_controller.start_match()
	await process_frame

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "Ultimo vivo necesita cuatro robots FFA.")
	if robots.size() < 4:
		await _cleanup_node(main)
		_finish()
		return

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[0].fall_into_void()
	await create_timer(0.1).timeout
	_assert(get_nodes_in_group("ffa_aftermath_pickups").size() == 1, "Ultimo vivo debe conservar aftermath neutral en baja no final.")
	var pickup := get_nodes_in_group("ffa_aftermath_pickups")[0] as FfaAftermathPickup
	if pickup != null:
		_assert(not pickup.has_method("use_support_payload"), "El botin FFA no debe exponer uso de payload de nave.")
		_assert(not pickup.has_method("cycle_target"), "El botin FFA no debe exponer seleccion de objetivo.")
		_assert(not pickup.has_method("set_owner_player"), "El botin FFA no debe tener ownership del eliminado.")
		_assert(not pickup.has_method("process_player_input"), "El botin FFA no debe procesar input ofensivo del eliminado.")

	robots[1].fall_into_void()
	await create_timer(0.1).timeout
	var count_before_final := get_nodes_in_group("ffa_aftermath_pickups").size()
	robots[2].fall_into_void()
	await create_timer(0.1).timeout
	_assert(not match_controller.is_round_active(), "Ultimo vivo debe cerrar al quedar uno.")
	_assert(get_nodes_in_group("ffa_aftermath_pickups").size() == count_before_final, "La baja final no debe crear nuevo aftermath.")

	var joined_result := "\n".join(PackedStringArray(match_controller.get_match_result_lines()))
	_assert(not joined_result.contains("puntos por causa"), "Ultimo vivo no debe explicar score por causa.")
	_assert(
		joined_result.contains("supervivencia") or joined_result.contains("ultimo vivo"),
		"Review debe leer supervivencia o ultimo vivo."
	)

	await _cleanup_node(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	for child in main.get_node("RobotRoot").get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _cleanup_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
