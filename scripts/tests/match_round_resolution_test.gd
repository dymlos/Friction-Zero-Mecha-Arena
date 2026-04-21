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
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia instanciar MatchController.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para el laboratorio 2v2.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.round_reset_delay = 0.2

	for robot in robots:
		robot.void_fall_y = -100.0
		robot.disabled_explosion_delay = 0.05

	_assert(match_controller.is_round_active(), "La ronda deberia iniciar activa al cargar la escena.")
	_assert(
		match_controller.get_round_status_line().contains("Ronda 1"),
		"El estado inicial deberia identificar la primera ronda."
	)

	robots[2].fall_into_void()
	await create_timer(0.05).timeout
	_assert(
		match_controller.get_last_elimination_summary().contains("vacio"),
		"El controller deberia registrar la baja por vacio."
	)

	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	_assert(not match_controller.is_round_active(), "La ronda deberia cerrarse cuando solo queda un equipo.")
	_assert(
		match_controller.get_round_status_line().contains("Equipo 1"),
		"El estado de ronda deberia anunciar al equipo ganador."
	)
	_assert(match_controller.get_team_score(1) == 1, "El equipo ganador deberia sumar un punto.")
	_assert(match_controller.get_team_score(2) == 0, "El equipo rival no deberia sumar puntos.")

	await create_timer(match_controller.round_reset_delay + 0.25).timeout

	_assert(match_controller.is_round_active(), "Tras el reset deberia iniciar la siguiente ronda.")
	_assert(
		match_controller.get_round_status_line().contains("Ronda 2"),
		"La siguiente ronda deberia incrementar el contador visible."
	)
	_assert(robots[2].visible, "El robot eliminado por vacio deberia volver para la ronda siguiente.")
	_assert(robots[3].visible, "El segundo robot eliminado deberia volver para la ronda siguiente.")

	for part_name in robots[2].BODY_PARTS:
		robots[2].apply_damage_to_part(part_name, robots[2].max_part_health + 10.0, Vector3.LEFT)
	for part_name in robots[3].BODY_PARTS:
		robots[3].apply_damage_to_part(part_name, robots[3].max_part_health + 10.0, Vector3.RIGHT)

	await create_timer(0.2).timeout

	_assert(
		match_controller.get_last_elimination_summary().contains("explosion"),
		"Las bajas por destruccion total deberian registrarse como explosion."
	)
	_assert(match_controller.get_team_score(1) == 2, "La segunda ronda ganada deberia reflejarse en el scoreboard.")

	await create_timer(0.8).timeout
	await _cleanup_main(main)
	_finish()


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
