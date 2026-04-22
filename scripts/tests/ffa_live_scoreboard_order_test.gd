extends SceneTree

const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = FFA_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena FFA deberia exponer MatchController.")
	_assert(robots.size() >= 4, "La escena FFA deberia ofrecer cuatro robots para validar el orden del marcador.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.round_reset_delay = 0.2
	match_controller.round_intro_duration = 0.0
	var void_round_points := 1
	if match_controller.match_config != null:
		void_round_points = match_controller.match_config.get_round_victory_points_for_cause(
			int(MatchController.EliminationCause.VOID)
		)
	for robot in robots:
		robot.void_fall_y = -100.0

	robots[0].fall_into_void()
	await create_timer(0.05).timeout
	robots[1].fall_into_void()
	await create_timer(0.05).timeout
	robots[2].fall_into_void()
	await create_timer(0.05).timeout

	var score_line := _find_line_with_prefix(match_controller.get_round_state_lines(), "Marcador |")
	var player_four_fragment := "%s %s [%s]" % [
		robots[3].display_name,
		void_round_points,
		robots[3].get_archetype_label(),
	]
	var player_one_fragment := "%s 0 [%s]" % [robots[0].display_name, robots[0].get_archetype_label()]
	_assert(
		score_line.contains(player_four_fragment),
		"El marcador FFA deberia reflejar los puntos configurados para el ganador."
	)
	_assert(
		_index_of_fragment(score_line, player_four_fragment) < _index_of_fragment(score_line, player_one_fragment),
		"El marcador FFA deberia ordenar al lider actual antes que los rivales con menos score."
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


func _find_line_with_prefix(lines: Array[String], prefix: String) -> String:
	for line in lines:
		if line.begins_with(prefix):
			return line

	return ""


func _index_of_fragment(text: String, fragment: String) -> int:
	return text.find(fragment)


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
