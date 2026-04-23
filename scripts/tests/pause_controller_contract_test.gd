extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const PAUSE_CONTROLLER_SCRIPT := "res://scripts/systems/pause_controller.gd"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var pause_controller_script := load(PAUSE_CONTROLLER_SCRIPT)
	_assert(pause_controller_script != null, "El contrato de pausa deberia vivir en scripts/systems/pause_controller.gd.")

	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia seguir montando MatchController.")
	_assert(robots.size() >= 4, "La escena principal deberia seguir ofreciendo cuatro robots del laboratorio.")
	_assert(main.has_method("request_pause_for_slot"), "Main deberia exponer una API de pausa por slot.")
	_assert(main.has_method("request_resume_for_slot"), "Main deberia exponer una API de reanudacion por slot.")
	_assert(main.has_method("request_restart_from_pause"), "Main deberia exponer reinicio seguro desde pausa.")
	if match_controller == null or robots.size() < 4 or not main.has_method("request_pause_for_slot"):
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.round_reset_delay = 0.01
	if match_controller.match_config != null:
		match_controller.match_config.round_intro_duration_teams = 0.0
		match_controller.match_config.rounds_to_win = 3
	match_controller.start_match()
	match_controller.set("_round_number", 2)
	match_controller.set("_round_status_line", "Ronda 2 en juego")
	match_controller.set("_competitor_scores", {
		"team_1": 1,
		"team_2": 0,
	})

	_assert(
		match_controller.get_team_score(1) == 1,
		"La fixture deberia ensuciar el score antes de probar el reinicio desde pausa."
	)
	_assert(
		match_controller.get_round_status_line().contains("Ronda 2"),
		"La fixture deberia avanzar al menos a la ronda 2 antes de pausar."
	)

	var pause_requested := bool(main.call("request_pause_for_slot", 2))
	_assert(pause_requested, "Un slot ocupado deberia poder abrir la pausa.")
	_assert(paused, "La pausa deberia congelar el gameplay del arbol principal.")
	_assert(
		match_controller.has_method("is_paused_by_owner") and match_controller.call("is_paused_by_owner"),
		"MatchController deberia publicar que la partida esta pausada por un owner."
	)
	_assert(
		match_controller.has_method("get_pause_owner_slot") and int(match_controller.call("get_pause_owner_slot")) == 2,
		"El slot que pausa deberia quedar registrado como owner."
	)

	var resume_from_non_owner := bool(main.call("request_resume_for_slot", 1))
	_assert(not resume_from_non_owner, "Un slot no owner no deberia poder reanudar la partida.")
	_assert(paused, "La pausa deberia seguir activa tras un intento de resume invalido.")

	var restart_from_non_owner := bool(main.call("request_restart_from_pause", 1))
	_assert(not restart_from_non_owner, "Un slot no owner no deberia poder reiniciar desde pausa.")

	var restart_from_owner := bool(main.call("request_restart_from_pause", 2))
	_assert(restart_from_owner, "El pause owner deberia poder reiniciar desde pausa.")

	await process_frame
	await process_frame

	_assert(not paused, "El reinicio desde pausa deberia limpiar el estado paused.")
	_assert(not match_controller.is_match_over(), "El reinicio desde pausa deberia devolver el match a un estado jugable.")
	_assert(match_controller.is_round_active(), "Tras reiniciar desde pausa deberia arrancar una ronda nueva.")
	_assert(
		match_controller.get_round_status_line().contains("Ronda 1"),
		"El reinicio desde pausa deberia volver a un match limpio desde la ronda 1."
	)
	_assert(match_controller.get_team_score(1) == 0, "El reinicio desde pausa deberia limpiar el score previo.")
	_assert(match_controller.get_team_score(2) == 0, "El reinicio desde pausa deberia limpiar el score rival.")
	_assert(
		main.get_lab_selector_summary_line().contains("Lab |"),
		"El selector runtime del laboratorio no deberia quedar stale tras reiniciar desde pausa."
	)

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_main(main: Node) -> void:
	if not is_instance_valid(main):
		return

	paused = false
	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
