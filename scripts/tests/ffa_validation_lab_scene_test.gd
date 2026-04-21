extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var validation_scene := load("res://scenes/main/main_ffa_validation.tscn")
	_assert(validation_scene is PackedScene, "El prototipo deberia exponer una escena dedicada para validacion rapida FFA.")
	if not (validation_scene is PackedScene):
		_finish()
		return

	var main = (validation_scene as PackedScene).instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var arena := main.get_node_or_null("ArenaRoot/ArenaFFAValidation") as ArenaBase
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena rapida FFA deberia seguir montando MatchController.")
	_assert(arena != null, "La escena rapida FFA deberia usar una arena compacta dedicada.")
	_assert(robots.size() >= 4, "La escena rapida FFA deberia conservar cuatro robots para validar third-party y oportunismo.")
	if match_controller == null or arena == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	_assert(match_controller.match_mode == MatchController.MatchMode.FFA, "La escena rapida FFA deberia bootear en modo FFA.")
	_assert(not robots[0].is_ally_of(robots[1]), "La escena rapida FFA no deberia conservar alianzas heredadas del laboratorio 2v2.")
	_assert(not robots[2].is_ally_of(robots[3]), "La escena rapida FFA no deberia agrupar rivales como aliados.")

	var match_config := match_controller.match_config
	_assert(match_config is MatchConfig, "La escena rapida FFA deberia usar un MatchConfig dedicado.")
	if match_config is MatchConfig:
		_assert(match_config.rounds_to_win == 1, "La escena rapida FFA deberia cerrar la partida en una sola ronda.")
		_assert(match_config.round_time_seconds <= 32, "La escena rapida FFA deberia comprimir el tiempo de ronda para iteracion corta.")
	_assert(match_controller.round_reset_delay <= 1.1, "La escena rapida FFA deberia resetear rondas mas rapido que el laboratorio base.")
	_assert(match_controller.match_restart_delay <= 1.7, "La escena rapida FFA deberia reiniciar la partida sin esperas largas.")

	var play_area_size := arena.get_safe_play_area_size()
	_assert(play_area_size.x < 24.0 and play_area_size.y < 16.0, "La arena rapida FFA deberia ser mas compacta que el blockout base.")
	_assert(_uses_distinct_ffa_spawn_layout(robots), "La escena rapida FFA deberia seguir usando spawns diagonales propios.")
	_assert(_robots_spawn_close_to_midrange(robots), "La escena rapida FFA deberia arrancar mas cerca del conflicto que el laboratorio libre base.")

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel")
	_assert(round_label is Label, "La escena rapida FFA deberia seguir exponiendo el bloque principal del HUD.")
	if round_label is Label:
		var round_text := String((round_label as Label).text)
		_assert(round_text.contains("Modo | FFA"), "La escena rapida FFA deberia seguir declarando el modo para el laboratorio.")
		_assert(round_text.contains("Borde |"), "La escena rapida FFA deberia mostrar el layout activo del borde para validar incentivos.")

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _uses_distinct_ffa_spawn_layout(robots: Array[RobotBase]) -> bool:
	if robots.size() < 4:
		return false

	var seen_quadrants := {}
	for robot in robots:
		var planar_position := Vector2(robot.global_position.x, robot.global_position.z)
		if planar_position.length() < 2.8:
			return false
		if absf(planar_position.x) < 0.8 or absf(planar_position.y) < 0.8:
			return false

		var quadrant_key := "%s:%s" % [signi(planar_position.x), signi(planar_position.y)]
		seen_quadrants[quadrant_key] = true

	return seen_quadrants.size() == 4


func _robots_spawn_close_to_midrange(robots: Array[RobotBase]) -> bool:
	for robot in robots:
		var planar_position := Vector2(robot.global_position.x, robot.global_position.z)
		if planar_position.length() > 5.2:
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
