extends SceneTree

const RobotBase = preload("res://scripts/robots/robot_base.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ffa_scene := load("res://scenes/main/main_ffa.tscn")
	_assert(ffa_scene is PackedScene, "El prototipo deberia exponer una escena jugable dedicada para FFA.")
	if not (ffa_scene is PackedScene):
		_finish()
		return

	var main = (ffa_scene as PackedScene).instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena FFA deberia instanciar MatchController.")
	_assert(robots.size() >= 4, "La escena FFA deberia ofrecer cuatro robots para el laboratorio libre.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	_assert(match_controller.match_mode == MatchController.MatchMode.FFA, "La escena dedicada deberia bootear en FFA.")
	_assert(not robots[0].is_ally_of(robots[1]), "La escena FFA no deberia conservar alianzas entre Player 1 y Player 2.")
	_assert(not robots[2].is_ally_of(robots[3]), "La escena FFA no deberia conservar alianzas entre Player 3 y Player 4.")

	var round_lines := match_controller.get_round_state_lines()
	var score_line := round_lines[2] if round_lines.size() > 2 else ""
	_assert(score_line.contains("Player 1"), "El marcador FFA deberia listar jugadores individuales.")
	_assert(score_line.contains("Player 4"), "El marcador FFA deberia incluir a todos los competidores visibles.")
	_assert(not score_line.contains("Equipo"), "La escena FFA no deberia presentar marcador por equipos.")

	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel")
	_assert(roster_label is Label, "La escena FFA deberia conservar el roster compacto.")
	if roster_label is Label:
		var roster_text := (roster_label as Label).text
		_assert(roster_text.contains("Player 1"), "El roster FFA deberia listar a Player 1.")
		_assert(roster_text.contains("Player 4"), "El roster FFA deberia listar a Player 4.")

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
