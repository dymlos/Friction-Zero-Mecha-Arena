extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
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
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapLabel") as Label
	var match_result_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia exponer MatchController.")
	_assert(recap_label != null, "La escena principal deberia exponer el recap para validar atribucion entre rondas.")
	_assert(match_result_label != null, "La escena principal deberia exponer el resultado final para validar atribucion entre rondas.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar el reset de atribucion.")
	if match_controller == null or recap_label == null or match_result_label == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.rounds_to_win = 2
	match_controller.round_reset_delay = 0.35

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[2].apply_damage_to_part("left_leg", 6.0, Vector3.LEFT, robots[0])
	robots[2].fall_into_void()
	await create_timer(0.05).timeout
	robots[3].apply_damage_to_part("right_leg", 6.0, Vector3.RIGHT, robots[1])
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	_assert(
		_has_line_with_fragment(
			match_controller.get_round_state_lines(),
			"Ultima baja | Player 4 cayo al vacio por Player 2"
		),
		"La primera ronda deberia registrar la atribucion valida antes del reset."
	)

	await create_timer(maxf(match_controller.round_reset_delay + 0.2, 0.7)).timeout

	robots[2].fall_into_void()
	await create_timer(0.05).timeout

	robots[3].apply_damage_to_part("left_leg", 6.0, Vector3.LEFT, robots[1])
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	_assert(
		recap_label.text.contains("Player 3 / Cizalla | baja 1 | vacio"),
		"El recap de la ronda nueva deberia seguir mostrando la baja actual del robot sin agresor."
	)
	_assert(
		not recap_label.text.contains("Player 3 / Cizalla | baja 1 | vacio por Player 1"),
		"La atribucion de una ronda anterior no deberia sobrevivir en el recap cuando la nueva baja no tiene agresor."
	)
	_assert(
		match_result_label.text.contains("Player 3 / Cizalla | baja 1 | vacio"),
		"El resultado final deberia conservar la baja sin agresor de la ronda nueva."
	)
	_assert(
		not match_result_label.text.contains("Player 3 / Cizalla | baja 1 | vacio por Player 1"),
		"La atribucion stale tampoco deberia sobrevivir en el resultado final."
	)

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _has_line_with_fragment(lines: Array[String], fragment: String) -> bool:
	for line in lines:
		if line.contains(fragment):
			return true

	return false


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
