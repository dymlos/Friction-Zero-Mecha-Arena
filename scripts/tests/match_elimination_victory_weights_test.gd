extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _run_weighted_score_validation(
		"Teams",
		MAIN_SCENE,
		MatchController.MatchMode.TEAMS,
	)
	await _run_weighted_score_validation(
		"FFA",
		FFA_SCENE,
		MatchController.MatchMode.FFA,
	)

	_finish()


func _run_weighted_score_validation(
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
	_assert(match_controller != null, "%s: escena debería exponer MatchController." % label)
	_assert(robots.size() >= 4, "%s: escena debería tener 4 robots para test cerrado." % label)
	_assert(match_controller.match_config != null, "%s: el MatchController debe cargar una config editable." % label)
	if match_controller == null or robots.size() < 4 or match_controller.match_config == null:
		await _cleanup_main(main)
		return

	match_controller.match_mode = test_mode
	match_controller.match_config.rounds_to_win = 20
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.round_reset_delay = 0.15
	match_controller.round_intro_duration = 0.0
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0
		robot.disabled_explosion_delay = 0.05

	_assert(match_controller.is_round_active(), "%s: la ronda debería arrancar activa." % label)
	_assert(match_controller.get_round_status_line().contains("Ronda 1"), "%s: la ronda visible debe arrancar en Ronda 1." % label)

	if test_mode == MatchController.MatchMode.FFA:
		_eliminate_three_by_void(robots)
	else:
		_eliminate_team_two_by_void(robots)
	await create_timer(0.12).timeout

	if test_mode == MatchController.MatchMode.TEAMS:
		_assert(match_controller.get_team_score(1) == 2, "%s: el primer equipo debería sumar 2 por ring-out." % label)
		_assert(match_controller.get_team_score(2) == 0, "%s: el equipo derrotado no suma puntos." % label)
	else:
		_assert(_read_ffa_score_from_hud(match_controller, robots[0]) == 2, "%s: el vencedor debería tener 2 por ring-out." % label)

	_assert(match_controller.get_last_elimination_summary().contains("vacio"), "%s: la causa de cierre debe ser ring-out." % label)
	_assert(not match_controller.is_match_over(), "%s: con objetivo 20 aún no debería terminar el match por la primera ronda." % label)

	await create_timer(match_controller.round_reset_delay + 0.2).timeout
	_assert(match_controller.is_round_active(), "%s: la segunda ronda debería reiniciar tras cierre." % label)
	_assert(match_controller.get_round_status_line().contains("Ronda 2"), "%s: el estado debe mostrar Ronda 2." % label)

	if test_mode == MatchController.MatchMode.FFA:
		_eliminate_three_by_unstable_explosion(robots)
	else:
		_eliminate_team_two_by_unstable_explosion(robots)
	await create_timer(0.18).timeout
	_assert(match_controller.get_last_elimination_summary().contains("exploto en sobrecarga"), "%s: la segunda ronda debe cerrar en explosion inestable." % label)
	if test_mode == MatchController.MatchMode.TEAMS:
		_assert(match_controller.get_team_score(1) == 6, "%s: el puntaje debería sumar 2 + 4 con el peso actual de unstable." % label)
	else:
		_assert(_read_ffa_score_from_hud(match_controller, robots[0]) == 6, "%s: el ganador debería sumar 2 + 4 con el peso actual de unstable." % label)
	_assert(not match_controller.is_match_over(), "%s: el match no debería cerrar con objetivo 20." % label)

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


func _read_ffa_score_from_hud(match_controller: MatchController, robot: RobotBase) -> int:
	for line in match_controller.get_round_state_lines():
		if not line.begins_with("Marcador | "):
			continue

		var score_segment := line.substr(11)
		var parts := score_segment.split(" | ")
		for part in parts:
			var robot_label := robot.display_name
			var prefix := "%s " % robot_label
			if not part.begins_with(prefix):
				continue

			var remaining := part.substr(prefix.length())
			var tokens := remaining.split(" ")
			for token in tokens:
				if token.is_valid_int():
					return int(token)

	return -1


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


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
