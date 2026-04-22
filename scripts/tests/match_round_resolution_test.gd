extends SceneTree

const SCENE_PATHS := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
]
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in SCENE_PATHS:
		var scene_resource := load(scene_path) as PackedScene
		var main = scene_resource.instantiate()
		root.add_child(main)

		await process_frame
		await process_frame

		var match_controller := main.get_node("Systems/MatchController") as MatchController
		var robots := _get_scene_robots(main)
		_assert(match_controller != null, "%s deberia instanciar MatchController." % scene_path)
		_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para el laboratorio 2v2." % scene_path)
		if match_controller == null or robots.size() < 4:
			await _cleanup_main(main)
			_finish()
			return

		match_controller.match_mode = MatchController.MatchMode.TEAMS
		match_controller.round_reset_delay = 0.2
		var void_round_points := 1
		var explosion_round_points := 1
		if match_controller.match_config != null:
			match_controller.match_config.rounds_to_win = 3
			void_round_points = match_controller.match_config.get_round_victory_points_for_cause(
				int(MatchController.EliminationCause.VOID)
			)
			explosion_round_points = match_controller.match_config.get_round_victory_points_for_cause(
				int(MatchController.EliminationCause.EXPLOSION)
			)

		for robot in robots:
			robot.void_fall_y = -100.0
			robot.disabled_explosion_delay = 0.05

		_assert(match_controller.is_round_active(), "%s deberia iniciar la ronda activa al cargar." % scene_path)
		_assert(
			match_controller.get_round_status_line().contains("Ronda 1"),
			"%s deberia identificar la primera ronda." % scene_path
		)

		robots[2].fall_into_void()
		await create_timer(0.05).timeout
		_assert(
			match_controller.get_last_elimination_summary().contains("vacio"),
			"%s deberia registrar la baja por vacio." % scene_path
		)

		robots[3].fall_into_void()
		await create_timer(0.05).timeout

		_assert(not match_controller.is_round_active(), "%s deberia cerrar la ronda al quedar un solo equipo." % scene_path)
		_assert(
			match_controller.get_round_status_line().contains("Equipo 1"),
			"%s deberia anunciar al equipo ganador." % scene_path
		)
		_assert(
			match_controller.get_team_score(1) == void_round_points,
			"%s deberia sumar los puntos por vacio al equipo ganador." % scene_path
		)
		_assert(match_controller.get_team_score(2) == 0, "%s no deberia sumar puntos al rival." % scene_path)

		await create_timer(match_controller.round_reset_delay + 0.25).timeout

		_assert(match_controller.is_round_active(), "%s deberia iniciar la siguiente ronda tras el reset." % scene_path)
		_assert(
			match_controller.get_round_status_line().contains("Ronda 2"),
			"%s deberia incrementar el contador visible." % scene_path
		)
		_assert(robots[2].visible, "%s deberia restaurar el robot eliminado por vacio." % scene_path)
		_assert(robots[3].visible, "%s deberia restaurar el segundo robot eliminado." % scene_path)

		for part_name in robots[2].BODY_PARTS:
			robots[2].apply_damage_to_part(part_name, robots[2].max_part_health + 10.0, Vector3.LEFT)
		for part_name in robots[3].BODY_PARTS:
			robots[3].apply_damage_to_part(part_name, robots[3].max_part_health + 10.0, Vector3.RIGHT)

		await create_timer(0.2).timeout

		_assert(
			match_controller.get_last_elimination_summary().contains("explosion"),
			"%s deberia registrar la destruccion total como explosion." % scene_path
		)
		_assert(
			match_controller.get_team_score(1) == void_round_points + explosion_round_points,
			"%s deberia acumular los puntos configurados por causa de cierre." % scene_path
		)

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
