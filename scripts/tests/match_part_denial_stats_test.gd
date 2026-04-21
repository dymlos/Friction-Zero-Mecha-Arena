extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia exponer MatchController para medir negaciones.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para cerrar una partida Teams.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.rounds_to_win = 1
	match_controller.round_reset_delay = 0.15
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.set_physics_process(false)
		robot.gravity = 0.0
		robot.void_fall_y = -100.0

	var owner := robots[0]
	var enemy_carrier := robots[2]
	var enemy_partner := robots[3]
	owner.apply_damage_to_part("left_arm", owner.max_part_health + 5.0, Vector3.LEFT)
	await process_frame

	var detached_part := _get_only_detached_part()
	_assert(detached_part != null, "La parte destruida deberia existir en escena para poder negar su rescate.")
	if detached_part == null:
		await _cleanup_main(main)
		_finish()
		return

	await create_timer(detached_part.pickup_delay + 0.05).timeout
	enemy_carrier.global_position = detached_part.global_position
	var picked_up := detached_part.try_pick_up(enemy_carrier)
	_assert(picked_up, "Un rival deberia poder capturar la parte desprendida antes de negarla.")
	if not picked_up:
		await _cleanup_main(main)
		_finish()
		return

	enemy_carrier.fall_into_void()
	await create_timer(0.05).timeout
	await process_frame

	_assert(
		not is_instance_valid(detached_part),
		"La pieza cargada por el rival deberia perderse al vacio al caer su portador."
	)

	enemy_partner.fall_into_void()
	await create_timer(0.05).timeout

	_assert(match_controller.is_match_over(), "La ronda objetivo deberia cerrar la partida tras eliminar al equipo rival.")
	_assert(
		_has_line_containing(
			match_controller.get_match_result_lines(),
			"Stats | Equipo 2 | negaciones 1 | bajas 2 (2 vacio)"
		),
		"El cierre de partida deberia acreditar la negacion exitosa al equipo que lanzo la pieza al vacio."
	)
	_assert(
		_has_line_containing(
			match_controller.get_round_recap_panel_lines(),
			"Stats | Equipo 2 | negaciones 1 | bajas 2 (2 vacio)"
		),
		"El recap lateral deberia reutilizar la misma lectura compacta de negaciones."
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


func _get_only_detached_part() -> DetachedPart:
	var detached_parts := get_nodes_in_group("detached_parts")
	_assert(detached_parts.size() == 1, "Se esperaba exactamente una parte desprendida para esta validacion.")
	if detached_parts.size() != 1:
		return null

	return detached_parts[0] as DetachedPart


func _has_line_containing(lines: Array[String], expected_fragment: String) -> bool:
	for line in lines:
		if line.contains(expected_fragment):
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
