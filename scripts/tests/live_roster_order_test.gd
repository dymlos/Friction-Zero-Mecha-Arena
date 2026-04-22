extends SceneTree

const TEAMS_SCENES := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
]
const FFA_SCENES := [
	"res://scenes/main/main_ffa.tscn",
	"res://scenes/main/main_ffa_validation.tscn",
]
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in FFA_SCENES:
		await _validate_ffa_live_roster_uses_standings_order(scene_path)
	for scene_path in TEAMS_SCENES:
		await _validate_teams_live_roster_prioritizes_surviving_teammate(scene_path)
		await _validate_teams_live_roster_marks_support_active_players(scene_path)
		await _validate_teams_live_roster_marks_unarmed_support_active_players(scene_path)
		await _validate_teams_live_roster_uses_support_controls_only_for_support_active_players(scene_path)
		await _validate_teams_live_roster_hides_stale_robot_combat_state_during_active_support(scene_path)
	_finish()


func _validate_ffa_live_roster_uses_standings_order(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena %s deberia exponer MatchController." % scene_path)
	_assert(
		robots.size() >= 4,
		"La escena %s deberia ofrecer cuatro robots para validar el roster vivo." % scene_path
	)
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
		"La escena %s deberia ordenar primero al lider actual y no volver a scene-order." % scene_path
	)

	await _cleanup_node(main)


func _validate_teams_live_roster_prioritizes_surviving_teammate(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena %s deberia exponer MatchController." % scene_path)
	_assert(
		robots.size() >= 4,
		"La escena %s deberia ofrecer cuatro robots para validar el roster vivo." % scene_path
	)
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
		"La escena %s deberia priorizar al aliado que sigue en pie antes que al eliminado dentro del mismo equipo." % scene_path
	)

	await _cleanup_node(main)


func _validate_teams_live_roster_marks_support_active_players(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
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
	_assert(match_controller != null, "La escena %s deberia exponer MatchController." % scene_path)
	_assert(
		robots.size() >= 4,
		"La escena %s deberia ofrecer cuatro robots para validar el soporte activo en roster." % scene_path
	)
	if match_controller == null or robots.size() < 4:
		await _cleanup_node(main)
		return

	robots[0].fall_into_void()
	await _wait_frames(4)

	var roster_lines := match_controller.get_robot_status_lines()
	var player_one_line := _find_line_containing(roster_lines, robots[0].display_name)
	_assert(
		player_one_line.contains("Apoyo activo"),
		"La escena %s deberia marcar cuando un jugador eliminado sigue aportando desde la nave de apoyo." % scene_path
	)
	_assert(
		player_one_line.contains("usa "),
		"La escena %s deberia conservar el hint de uso mientras el apoyo post-muerte sigue activo." % scene_path
	)
	_assert(
		player_one_line.find("Apoyo activo") < player_one_line.find(robots[0].get_support_input_hint()),
		"La escena %s deberia mostrar primero el nuevo estado jugable y luego el hint accionable del soporte." % scene_path
	)
	_assert(
		player_one_line.find(robots[0].get_support_input_hint()) < player_one_line.find("vacio"),
		"La escena %s deberia dejar la causa de baja despues del hint accionable del soporte." % scene_path
	)

	await _cleanup_node(main)


func _validate_teams_live_roster_marks_unarmed_support_active_players(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
		if match_controller_preload.match_config != null:
			match_controller_preload.match_config.round_intro_duration_teams = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena %s deberia exponer MatchController." % scene_path)
	_assert(support_root != null, "La escena %s deberia exponer SupportRoot." % scene_path)
	_assert(
		robots.size() >= 4,
		"La escena %s deberia ofrecer cuatro robots para validar el estado vacio del soporte." % scene_path
	)
	if match_controller == null or support_root == null or robots.size() < 4:
		await _cleanup_node(main)
		return

	robots[0].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado en Teams deberia aparecer una sola nave de apoyo para validar su estado inicial."
	)
	var support_ship := support_root.get_child(0)
	_assert(support_ship != null and support_ship.has_method("has_support_payload"), "La nave de apoyo deberia exponer si ya viene armada.")
	if support_ship != null and support_ship.has_method("has_support_payload"):
		_assert(
			not bool(support_ship.call("has_support_payload")),
			"La escena %s no deberia recolectar un payload gratis al aparecer en el carril externo." % scene_path
		)

	var player_one_line := _find_line_containing(match_controller.get_robot_status_lines(), robots[0].display_name)
	_assert(
		player_one_line.contains("sin carga"),
		"La escena %s deberia aclarar cuando `Apoyo activo` todavia no lleva ningun payload." % scene_path
	)
	_assert(
		not player_one_line.contains("movilidad >")
			and not player_one_line.contains("energia >")
			and not player_one_line.contains("estabilizador >")
			and not player_one_line.contains("interferencia >"),
		"La escena %s no deberia aparecer ya con un payload seleccionado antes de moverse por el carril." % scene_path
	)

	await _cleanup_node(main)


func _validate_teams_live_roster_uses_support_controls_only_for_support_active_players(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
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
	_assert(match_controller != null, "La escena %s deberia exponer MatchController." % scene_path)
	_assert(
		robots.size() >= 4,
		"La escena %s deberia ofrecer cuatro robots para validar los hints de apoyo en roster." % scene_path
	)
	if match_controller == null or robots.size() < 4:
		await _cleanup_node(main)
		return

	robots[0].fall_into_void()
	await _wait_frames(4)

	var player_one_line := _find_line_containing(match_controller.get_robot_status_lines(), robots[0].display_name)
	_assert(
		player_one_line.contains(robots[0].get_support_input_hint()),
		"La escena %s deberia conservar el hint de controles de la nave de apoyo." % scene_path
	)
	_assert(
		not player_one_line.contains(robots[0].get_input_hint()),
		"La escena %s no deberia mezclar el hint del robot caido con el de la nave de apoyo activa." % scene_path
	)

	await _cleanup_node(main)


func _validate_teams_live_roster_hides_stale_robot_combat_state_during_active_support(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
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
	_assert(match_controller != null, "La escena %s deberia exponer MatchController." % scene_path)
	_assert(
		robots.size() >= 4,
		"La escena %s deberia ofrecer cuatro robots para validar el estado compacto de apoyo." % scene_path
	)
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
		"La escena %s no deberia seguir mostrando items del robot caido cuando el jugador ya esta en `Apoyo activo`." % scene_path
	)
	_assert(
		not player_line.contains(stale_core_skill_summary),
		"La escena %s no deberia seguir mostrando la skill del robot caido cuando el jugador ya esta en `Apoyo activo`." % scene_path
	)
	_assert(
		not player_line.contains(stale_energy_summary),
		"La escena %s no deberia seguir mostrando el estado energetico del robot caido cuando el jugador ya esta en `Apoyo activo`." % scene_path
	)

	await _cleanup_node(main)


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia seguir existiendo." % scene_path)
	if not (packed_scene is PackedScene):
		return Node.new()

	return (packed_scene as PackedScene).instantiate()


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
