extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const PostMatchEvent = preload("res://scripts/systems/post_match_event.gd")
const PostMatchReview = preload("res://scripts/systems/post_match_review.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_review_snippet_limits()
	_assert_draw_has_no_loser_reading()
	await _assert_four_player_result_line_limit()
	_finish()


func _assert_review_snippet_limits() -> void:
	var review := PostMatchReview.new()
	for index in range(6):
		var headline := "Baja repetida" if index >= 4 else "Baja %s" % index
		review.record_event(PostMatchEvent.make_event(
			index + 1,
			1,
			float(index),
			PostMatchEvent.TYPE_ELIMINATION,
			70 - index,
			headline,
			"",
			{"arena_zone": "borde este", "cause_label": "ring-out", "competitor_label": "Player %s" % index}
		))
	review.build_review(_teams_context(false))
	var snippets := review.get_snippet_lines()
	_assert(snippets.size() == 3, "La revision deberia limitar snippets visibles a tres.")
	_assert(_count_lines_containing(snippets, "Baja repetida") <= 1, "La revision no deberia duplicar el mismo headline.")


func _assert_draw_has_no_loser_reading() -> void:
	var review := PostMatchReview.new()
	var summary := review.build_review(_teams_context(true))
	var story := summary.get("story", []) as Array
	_assert(_has_line_containing(story, "Nadie cerro la ronda"), "Un empate deberia tener lectura de draw sin ganador.")
	_assert(review.get_loser_reading_lines().is_empty(), "Un empate no deberia generar Como perdiste.")


func _assert_four_player_result_line_limit() -> void:
	var main := await _instantiate_scene("res://scenes/main/main.tscn")
	if main == null:
		return

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena base deberia exponer MatchController.")
	_assert(robots.size() >= 4, "La escena base deberia ofrecer cuatro robots.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.rounds_to_win = 1
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.round_intro_duration = 0.0
	match_controller.round_reset_delay = 0.1
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[2].fall_into_void()
	robots[3].fall_into_void()
	await create_timer(0.08).timeout

	var lines := match_controller.get_match_result_lines()
	_assert(match_controller.is_match_over(), "La escena base deberia cerrar el match.")
	_assert(lines.size() <= 22, "El resultado base de cuatro jugadores no deberia superar 22 lineas.")

	await _cleanup_main(main)


func _teams_context(is_draw: bool) -> Dictionary:
	return {
		"match_mode": "Teams",
		"winner_label": "" if is_draw else "Equipo 1",
		"winner_key": "" if is_draw else "team_1",
		"is_draw": is_draw,
		"score_line": "Marcador | Equipo 1 0 | Equipo 2 0",
		"closing_cause_label": "",
		"closing_summary_line": "",
		"part_loss_lines": [],
		"support_summary_line": "",
		"last_elimination_line": "",
	}


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia seguir existiendo." % scene_path)
	if not (packed_scene is PackedScene):
		return null

	var main := (packed_scene as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	return main


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


func _count_lines_containing(lines: Array, expected_fragment: String) -> int:
	var count := 0
	for line in lines:
		if str(line).contains(expected_fragment):
			count += 1
	return count


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
