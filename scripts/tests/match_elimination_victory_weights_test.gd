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
	_assert(match_controller != null, "La escena principal deberia exponer MatchController para puntuar por causa.")
	_assert(robots.size() >= 4, "La escena principal deberia tener robots para cubrir escenario 2v2 en el test.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	_assert(match_controller.match_config != null, "El controller deberia cargar una MatchConfig base editable.")
	if match_controller.match_config == null:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_config.rounds_to_win = 20
	match_controller.match_config.void_elimination_round_points = 2
	match_controller.match_config.destruction_elimination_round_points = 1
	match_controller.match_config.unstable_elimination_round_points = 4
	match_controller.round_reset_delay = 0.15

	for robot in robots:
		robot.void_fall_y = -100.0
		robot.disabled_explosion_delay = 0.05

	_assert(match_controller.is_round_active(), "La ronda deberia iniciar activa para comenzar el test.")
	_assert(match_controller.get_round_status_line().contains("Ronda 1"), "El estado inicial deberia mostrar la primera ronda.")

	_eliminate_team_two_by_void(robots)
	await create_timer(0.12).timeout
	_assert(match_controller.get_team_score(1) == 2, "La primera ronda ganada por ring-out debe sumar el peso configurado (2).")
	_assert(match_controller.get_team_score(2) == 0, "El equipo derrotado no debe sumar puntos.")
	_assert(match_controller.get_last_elimination_summary().contains("vacio"), "La causa de final de ronda debe seguir siendo ring-out.")
	_assert(not match_controller.is_match_over(), "Con objetivo 20 no deberia cerrarse la partida aun con ring-out.")

	await create_timer(match_controller.round_reset_delay + 0.2).timeout
	_assert(match_controller.is_round_active(), "La segunda ronda deberia reiniciar tras el cierre.")
	_assert(match_controller.get_round_status_line().contains("Ronda 2"), "La ronda visible deberia avanzar.")

	_eliminate_team_two_by_unstable_explosion(robots)
	await create_timer(0.18).timeout
	_assert(match_controller.get_last_elimination_summary().contains("exploto en sobrecarga"), "La segunda eliminacion debería verse como sobrecarga.")
	_assert(match_controller.get_team_score(1) == 6, "El puntaje de victoria debe sumar el peso de causa actual (4) sobre el resultado anterior (2).")
	_assert(not match_controller.is_match_over(), "Con objetivo 20, aun con sobrecarga el match debe seguir abierto.")

	await _cleanup_main(main)
	_finish()


func _eliminate_team_two_by_void(robots: Array[RobotBase]) -> void:
	robots[2].fall_into_void()
	robots[3].fall_into_void()


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
