extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const MAIN_FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_FFA_SCENE.instantiate()
	root.add_child(main)
	current_scene = main

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "FFA deberia exponer MatchController.")
	_assert(robots.size() >= 4, "FFA deberia ofrecer cuatro robots para validar aftermath post-match.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_current_scene()
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.FFA
	match_controller.set_runtime_match_restart_enabled(false)
	match_controller.match_config.rounds_to_win = 1
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.round_intro_duration = 0.0
	match_controller.round_reset_delay = 0.1
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame

	for index in range(robots.size()):
		robots[index].void_fall_y = -100.0
		robots[index].global_position = Vector3(float(index) * 4.0, 0.0, 0.0)

	robots[0].fall_into_void()
	await create_timer(0.03).timeout
	match_controller.record_ffa_aftermath_collection(
		robots[3],
		"impulso",
		robots[0].get_roster_display_name(),
		"borde oeste"
	)
	robots[1].fall_into_void()
	await create_timer(0.03).timeout
	robots[2].fall_into_void()
	await create_timer(0.08).timeout

	_assert(match_controller.is_match_over(), "FFA deberia cerrar el match tras quedar un ganador.")
	var result_lines := match_controller.get_match_result_lines()
	var snippet_lines := match_controller.get_post_match_snippet_lines()
	_assert(
		_has_line_containing(result_lines, "Oportunidad |"),
		"Resultado FFA deberia mencionar aftermath solo cuando afecto el cierre."
	)
	_assert(
		snippet_lines.size() <= 3,
		"Los snippets post-match deberian mantenerse en maximo tres lineas."
	)
	_assert(
		_has_line_containing(snippet_lines, "botin"),
		"Aftermath decisivo deberia poder entrar como snippet compacto."
	)

	await _cleanup_current_scene()
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _has_line_containing(lines: Array, expected_fragment: String) -> bool:
	for line in lines:
		if str(line).contains(expected_fragment):
			return true
	return false


func _cleanup_current_scene() -> void:
	if current_scene == null or not is_instance_valid(current_scene):
		return

	var scene := current_scene
	var parent := scene.get_parent()
	if parent != null:
		parent.remove_child(scene)
	scene.free()
	current_scene = null
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
