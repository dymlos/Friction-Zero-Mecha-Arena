extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_match_closing_cause_summary(
		"Teams",
		MAIN_SCENE,
		MatchController.MatchMode.TEAMS,
	)
	await _verify_match_closing_cause_summary(
		"FFA",
		FFA_SCENE,
		MatchController.MatchMode.FFA,
	)
	_finish()


func _verify_match_closing_cause_summary(
	label: String,
	scene_resource: PackedScene,
	test_mode: MatchController.MatchMode
) -> void:
	var main = scene_resource.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s: la escena deberia exponer MatchController." % label)
	_assert(robots.size() >= 4, "%s: la escena deberia ofrecer cuatro robots para cerrar dos rondas." % label)
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = test_mode
	_assert(match_controller.match_config != null, "%s: el MatchController deberia cargar MatchConfig." % label)
	if match_controller.match_config == null:
		await _cleanup_main(main)
		return

	var expected_points_line := _build_expected_closing_points_line(match_controller)
	var expected_round_closing_line := _build_expected_round_closing_line(
		match_controller,
		MatchController.EliminationCause.VOID
	)
	var expected_decisive_line := _build_expected_decisive_closing_line(
		match_controller,
		MatchController.EliminationCause.UNSTABLE_EXPLOSION
	)
	match_controller.match_config.rounds_to_win = 6
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.round_reset_delay = 0.15
	match_controller.round_intro_duration = 0.0
	match_controller.match_restart_delay = 2.0
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0
		robot.disabled_explosion_delay = 0.05

	if test_mode == MatchController.MatchMode.FFA:
		_eliminate_three_by_void(robots)
	else:
		_eliminate_team_two_by_void(robots)
	await create_timer(0.12).timeout
	_assert(not match_controller.is_match_over(), "%s: la primera ronda por ring-out no deberia cerrar el match." % label)
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), expected_round_closing_line),
		"%s: el recap de ronda deberia decir que causa la cerro y cuantos puntos otorgo aunque el match siga abierto." % label
	)

	await create_timer(match_controller.round_reset_delay + 0.2).timeout

	if test_mode == MatchController.MatchMode.FFA:
		_eliminate_three_by_unstable_explosion(robots)
	else:
		_eliminate_team_two_by_unstable_explosion(robots)
	await create_timer(0.18).timeout

	_assert(match_controller.is_match_over(), "%s: la segunda ronda deberia cerrar el match con score 2 + 4." % label)
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), "Cierres | ring-out 1 | explosion inestable 1"),
		"%s: el recap final deberia resumir la mezcla acumulada de cierres por causa." % label
	)
	_assert(
		_has_line(match_controller.get_match_result_lines(), "Cierres | ring-out 1 | explosion inestable 1"),
		"%s: el panel final deberia repetir la mezcla acumulada de cierres por causa." % label
	)
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), expected_points_line),
		"%s: el recap final deberia publicar el perfil activo de puntos por causa para leer el peso real del cierre." % label
	)
	_assert(
		_has_line(match_controller.get_match_result_lines(), expected_points_line),
		"%s: el panel final deberia repetir el perfil activo de puntos por causa." % label
	)
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), expected_decisive_line),
		"%s: el recap final deberia decir que causa cerro la ronda decisiva y cuantos puntos otorgo." % label
	)
	_assert(
		_has_line(match_controller.get_match_result_lines(), expected_decisive_line),
		"%s: el panel final deberia repetir la causa decisiva del cierre con su puntaje real." % label
	)

	await _cleanup_main(main)


func _eliminate_team_two_by_void(robots: Array[RobotBase]) -> void:
	robots[2].fall_into_void()
	robots[3].fall_into_void()


func _eliminate_three_by_void(robots: Array[RobotBase]) -> void:
	robots[1].fall_into_void()
	robots[2].fall_into_void()
	robots[3].fall_into_void()


func _eliminate_three_by_unstable_explosion(robots: Array[RobotBase]) -> void:
	for enemy in [robots[1], robots[2], robots[3]]:
		enemy.set_energy_focus("left_arm")
		enemy.activate_overdrive()

	for enemy in [robots[1], robots[2], robots[3]]:
		for part_name in enemy.BODY_PARTS:
			enemy.apply_damage_to_part(part_name, enemy.max_part_health + 10.0, Vector3.LEFT)


func _eliminate_team_two_by_unstable_explosion(robots: Array[RobotBase]) -> void:
	for enemy in [robots[2], robots[3]]:
		enemy.set_energy_focus("left_arm")
		enemy.activate_overdrive()

	for enemy in [robots[2], robots[3]]:
		for part_name in enemy.BODY_PARTS:
			enemy.apply_damage_to_part(part_name, enemy.max_part_health + 10.0, Vector3.LEFT)


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _has_line(lines: Array[String], expected: String) -> bool:
	for line in lines:
		if line == expected:
			return true

	return false


func _build_expected_closing_points_line(match_controller: MatchController) -> String:
	var match_config := match_controller.match_config
	return "Puntos cierre | ring-out %s | destruccion total %s | explosion inestable %s" % [
		match_config.void_elimination_round_points,
		match_config.destruction_elimination_round_points,
		match_config.unstable_elimination_round_points,
	]


func _build_expected_decisive_closing_line(
	match_controller: MatchController,
	cause: MatchController.EliminationCause
) -> String:
	return "Cierre decisivo | %s (+%s)" % [
		_get_cause_label(cause),
		match_controller.match_config.get_round_victory_points_for_cause(int(cause)),
	]


func _build_expected_round_closing_line(
	match_controller: MatchController,
	cause: MatchController.EliminationCause
) -> String:
	return "Cierre ronda | %s (+%s)" % [
		_get_cause_label(cause),
		match_controller.match_config.get_round_victory_points_for_cause(int(cause)),
	]


func _get_cause_label(cause: MatchController.EliminationCause) -> String:
	if cause == MatchController.EliminationCause.VOID:
		return "ring-out"
	if cause == MatchController.EliminationCause.EXPLOSION:
		return "destruccion total"

	return "explosion inestable"


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
