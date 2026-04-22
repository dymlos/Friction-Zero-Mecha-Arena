extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_ffa_live_roster_uses_standings_order()
	await _validate_teams_live_roster_prioritizes_surviving_teammate()
	await _validate_teams_live_roster_marks_support_active_players()
	await _validate_teams_live_roster_uses_support_controls_only_for_support_active_players()
	await _validate_teams_live_roster_hides_stale_robot_combat_state_during_active_support()
	_finish()


func _validate_ffa_live_roster_uses_standings_order() -> void:
	var main := FFA_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena FFA deberia exponer MatchController.")
	_assert(robots.size() >= 4, "La escena FFA deberia ofrecer cuatro robots para validar el roster vivo.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_node(main)
		return

	match_controller.round_intro_duration = 0.0
	for robot in robots:
		robot.void_fall_y = -100.0

	robots[0].fall_into_void()
	await create_timer(0.05).timeout
	robots[1].fall_into_void()
	await create_timer(0.05).timeout
	robots[2].fall_into_void()
	await create_timer(0.05).timeout

	var roster_lines := match_controller.get_robot_status_lines()
	var player_four_index := _find_line_index_containing(roster_lines, robots[3].display_name)
	var player_one_index := _find_line_index_containing(roster_lines, robots[0].display_name)
	_assert(player_four_index >= 0, "El roster vivo FFA deberia seguir mostrando al ganador actual.")
	_assert(player_one_index >= 0, "El roster vivo FFA deberia seguir mostrando a los eliminados.")
	_assert(
		player_four_index < player_one_index,
		"El roster vivo FFA deberia ordenar primero al lider actual y no volver a scene-order."
	)

	await _cleanup_node(main)


func _validate_teams_live_roster_prioritizes_surviving_teammate() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena Teams deberia exponer MatchController.")
	_assert(robots.size() >= 4, "La escena Teams deberia ofrecer cuatro robots para validar el roster vivo.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_node(main)
		return

	robots[0].fall_into_void()
	await create_timer(0.05).timeout

	var roster_lines := match_controller.get_robot_status_lines()
	var player_two_index := _find_line_index_containing(roster_lines, robots[1].display_name)
	var player_one_index := _find_line_index_containing(roster_lines, robots[0].display_name)
	_assert(player_two_index >= 0, "El roster vivo Teams deberia seguir mostrando al aliado superviviente.")
	_assert(player_one_index >= 0, "El roster vivo Teams deberia seguir mostrando al aliado caido.")
	_assert(
		player_two_index < player_one_index,
		"El roster vivo Teams deberia priorizar al aliado que sigue en pie antes que al eliminado dentro del mismo equipo."
	)

	await _cleanup_node(main)


func _validate_teams_live_roster_marks_support_active_players() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
		if match_controller_preload.match_config != null:
			match_controller_preload.match_config.round_intro_duration_teams = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena Teams deberia exponer MatchController.")
	_assert(robots.size() >= 4, "La escena Teams deberia ofrecer cuatro robots para validar el soporte activo en roster.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_node(main)
		return

	robots[0].fall_into_void()
	await _wait_frames(4)

	var roster_lines := match_controller.get_robot_status_lines()
	var player_one_line := _find_line_containing(roster_lines, robots[0].display_name)
	_assert(
		player_one_line.contains("Apoyo activo | vacio"),
		"El roster vivo Teams deberia marcar cuando un jugador eliminado sigue aportando desde la nave de apoyo."
	)
	_assert(
		player_one_line.contains("usa "),
		"El roster vivo Teams deberia conservar el hint de uso mientras el apoyo post-muerte sigue activo."
	)

	await _cleanup_node(main)


func _validate_teams_live_roster_uses_support_controls_only_for_support_active_players() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
		if match_controller_preload.match_config != null:
			match_controller_preload.match_config.round_intro_duration_teams = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena Teams deberia exponer MatchController.")
	_assert(robots.size() >= 4, "La escena Teams deberia ofrecer cuatro robots para validar los hints de apoyo en roster.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_node(main)
		return

	robots[0].fall_into_void()
	await _wait_frames(4)

	var player_one_line := _find_line_containing(match_controller.get_robot_status_lines(), robots[0].display_name)
	_assert(
		player_one_line.contains(robots[0].get_support_input_hint()),
		"El roster vivo Teams deberia conservar el hint de controles de la nave de apoyo."
	)
	_assert(
		not player_one_line.contains(robots[0].get_input_hint()),
		"El roster vivo Teams no deberia mezclar el hint del robot caido con el de la nave de apoyo activa."
	)

	await _cleanup_node(main)


func _validate_teams_live_roster_hides_stale_robot_combat_state_during_active_support() -> void:
	var main := MAIN_SCENE.instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
		if match_controller_preload.match_config != null:
			match_controller_preload.match_config.round_intro_duration_teams = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena Teams deberia exponer MatchController.")
	_assert(robots.size() >= 4, "La escena Teams deberia ofrecer cuatro robots para validar el estado compacto de apoyo.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_node(main)
		return

	var eliminated_robot := robots[0]
	eliminated_robot.store_carried_item("pulse_charge")
	eliminated_robot.apply_energy_surge(3.0)
	var stale_core_skill_summary := eliminated_robot.get_core_skill_status_summary()
	var stale_energy_summary := eliminated_robot.get_energy_state_summary()

	eliminated_robot.fall_into_void()
	await _wait_frames(4)

	var player_line := _find_line_containing(match_controller.get_robot_status_lines(), eliminated_robot.display_name)
	_assert(
		not player_line.contains("item pulso"),
		"El roster vivo Teams no deberia seguir mostrando items del robot caido cuando el jugador ya esta en `Apoyo activo`."
	)
	_assert(
		not player_line.contains(stale_core_skill_summary),
		"El roster vivo Teams no deberia seguir mostrando la skill del robot caido cuando el jugador ya esta en `Apoyo activo`."
	)
	_assert(
		not player_line.contains(stale_energy_summary),
		"El roster vivo Teams no deberia seguir mostrando el estado energetico del robot caido cuando el jugador ya esta en `Apoyo activo`."
	)

	await _cleanup_node(main)


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _find_line_index_containing(lines: Array[String], fragment: String) -> int:
	for index in range(lines.size()):
		if lines[index].contains(fragment):
			return index

	return -1


func _find_line_containing(lines: Array[String], fragment: String) -> String:
	for line in lines:
		if line.contains(fragment):
			return line

	return ""


func _wait_frames(count: int) -> void:
	for _step in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
