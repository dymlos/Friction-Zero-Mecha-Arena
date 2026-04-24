extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const MAIN_FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MAIN_TEAMS_SCENE := preload("res://scenes/main/main.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _assert_ffa_aftermath_identity()
	await _assert_teams_support_identity()
	_finish()


func _assert_ffa_aftermath_identity() -> void:
	var main := MAIN_FFA_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_prepare_match(match_controller, MatchController.MatchMode.FFA)
	if robots.size() < 4:
		_assert(false, "FFA necesita cuatro robots para validar post-match.")
		await _cleanup(main)
		return
	for index in range(robots.size()):
		robots[index].void_fall_y = -100.0
		robots[index].global_position = Vector3(float(index) * 4.0, 0.0, 0.0)

	robots[0].fall_into_void()
	await create_timer(0.03).timeout
	match_controller.record_ffa_aftermath_collection(robots[3], "impulso", robots[0].get_roster_display_name(), "borde oeste")
	match_controller.record_support_payload_use(robots[3], "interference", robots[1])
	robots[1].fall_into_void()
	await create_timer(0.03).timeout
	robots[2].fall_into_void()
	await create_timer(0.08).timeout

	var review_text := _join_lines(match_controller.get_match_result_lines()) + "\n" + _join_lines(match_controller.get_post_match_snippet_lines())
	_assert(review_text.contains("Oportunidad |"), "FFA con aftermath decisivo debe producir linea Oportunidad.")
	_assert(not review_text.contains("Apoyo activo"), "FFA no debe mezclar Apoyo activo en post-match.")
	_assert(not review_text.contains("nave"), "FFA no debe mencionar nave post-muerte.")
	_assert(not review_text.contains("soporte post-muerte"), "FFA no debe mencionar soporte post-muerte.")
	_assert(not review_text.contains("interferencia"), "FFA no debe serializar payloads de soporte.")
	_assert(match_controller.get_post_match_snippet_lines().size() <= 3, "FFA debe respetar maximo tres snippets.")
	await _cleanup(main)


func _assert_teams_support_identity() -> void:
	var main := MAIN_TEAMS_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_prepare_match(match_controller, MatchController.MatchMode.TEAMS)
	if robots.size() < 4:
		_assert(false, "Teams necesita cuatro robots para validar post-match.")
		await _cleanup(main)
		return
	for robot in robots:
		robot.void_fall_y = -100.0

	match_controller.record_ffa_aftermath_collection(robots[2], "impulso", robots[0].get_roster_display_name(), "borde oeste")
	match_controller.record_support_payload_use(robots[2], "stabilizer", robots[3])
	robots[0].fall_into_void()
	await create_timer(0.03).timeout
	robots[1].fall_into_void()
	await create_timer(0.08).timeout

	var review_text := _join_lines(match_controller.get_match_result_lines()) + "\n" + _join_lines(match_controller.get_post_match_snippet_lines())
	_assert(review_text.contains("apoyo") or review_text.contains("Apoyo"), "Teams con soporte decisivo debe producir lectura de apoyo.")
	_assert(not review_text.contains("Oportunidad |"), "Teams no debe mezclar Oportunidad FFA.")
	_assert(not review_text.contains("botin"), "Teams no debe serializar aftermath FFA.")
	_assert(match_controller.get_post_match_snippet_lines().size() <= 3, "Teams debe respetar maximo tres snippets.")
	await _cleanup(main)


func _prepare_match(match_controller: MatchController, mode: int) -> void:
	match_controller.match_mode = mode
	match_controller.set_runtime_match_restart_enabled(false)
	match_controller.match_config.rounds_to_win = 1
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.round_intro_duration = 0.0
	match_controller.round_reset_delay = 0.1
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	for child in main.get_node("RobotRoot").get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _join_lines(lines: Array) -> String:
	var parts: PackedStringArray = []
	for line in lines:
		parts.append(str(line))
	return "\n".join(parts)


func _cleanup(node: Node) -> void:
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
