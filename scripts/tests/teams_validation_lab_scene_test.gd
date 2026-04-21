extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var validation_scene := load("res://scenes/main/main_teams_validation.tscn")
	_assert(validation_scene is PackedScene, "El prototipo deberia exponer una escena dedicada para validacion rapida de Teams.")
	if not (validation_scene is PackedScene):
		_finish()
		return

	var main = (validation_scene as PackedScene).instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var arena := main.get_node_or_null("ArenaRoot/ArenaTeamsValidation") as ArenaBase
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena rapida deberia seguir montando MatchController.")
	_assert(arena != null, "La escena rapida deberia usar una arena compacta dedicada.")
	_assert(robots.size() >= 4, "La escena rapida deberia conservar cuatro robots para validar rescate y negacion.")
	if match_controller == null or arena == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	_assert(match_controller.match_mode == MatchController.MatchMode.TEAMS, "La escena rapida deberia permanecer en modo Equipos.")
	_assert(robots[0].is_ally_of(robots[1]), "Player 1 y Player 2 deberian seguir compartiendo equipo en la escena rapida.")
	_assert(not robots[0].is_ally_of(robots[2]), "La escena rapida deberia seguir separando aliados y rivales.")

	var match_config := match_controller.match_config
	_assert(match_config is MatchConfig, "La escena rapida deberia usar un MatchConfig dedicado.")
	if match_config is MatchConfig:
		_assert(match_config.rounds_to_win == 1, "La validacion rapida deberia cerrar la partida a una sola ronda.")
		_assert(match_config.round_time_seconds <= 35, "La validacion rapida deberia acelerar la contraccion con rondas mas cortas.")
	_assert(match_controller.round_reset_delay <= 1.2, "La escena rapida deberia resetear rondas mas rapido que el laboratorio base.")
	_assert(match_controller.match_restart_delay <= 1.8, "La escena rapida deberia reiniciar la partida sin esperas largas.")

	var play_area_size := arena.get_safe_play_area_size()
	_assert(play_area_size.x < 24.0 and play_area_size.y < 16.0, "La arena rapida deberia ser mas compacta que el blockout base.")
	_assert(_robots_spawn_close_to_midrange(robots), "La escena rapida deberia dejar los spawns mas cerca del conflicto que el laboratorio base.")
	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel")
	_assert(round_label is Label, "La escena rapida deberia seguir exponiendo el bloque principal del HUD.")
	if round_label is Label:
		_assert(
			String((round_label as Label).text).contains("Borde |"),
			"La escena rapida deberia seguir mostrando el layout activo del borde para validar incentivos."
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


func _robots_spawn_close_to_midrange(robots: Array[RobotBase]) -> bool:
	for robot in robots:
		var planar_position := Vector2(robot.global_position.x, robot.global_position.z)
		if planar_position.length() > 4.6:
			return false

	return true


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
