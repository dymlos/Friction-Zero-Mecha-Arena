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
	_assert(_uses_distinct_ffa_spawn_layout(robots), "La escena FFA deberia usar spawns diagonales propios, no las lineas cardinales del laboratorio 2v2.")
	_assert(_all_robots_face_center(robots), "Los spawns FFA deberian mirar hacia el centro para abrir tanteo y third-party desde el arranque.")

	var round_lines := match_controller.get_round_state_lines()
	var score_line := _find_line_with_prefix(round_lines, "Marcador |")
	_assert(
		score_line == "",
		"La escena FFA deberia arrancar con un opening neutral limpio, sin `Marcador | ...` mientras nadie fue eliminado y todo sigue empatado."
	)

	var roster_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RosterLabel")
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


func _find_line_with_prefix(lines: Array[String], prefix: String) -> String:
	for line in lines:
		if line.begins_with(prefix):
			return line

	return ""


func _uses_distinct_ffa_spawn_layout(robots: Array[RobotBase]) -> bool:
	if robots.size() < 4:
		return false

	var seen_quadrants := {}
	for robot in robots:
		var planar_position := Vector2(robot.global_position.x, robot.global_position.z)
		if planar_position.length() < 3.5:
			return false
		if absf(planar_position.x) < 1.0 or absf(planar_position.y) < 1.0:
			return false

		var quadrant_key := "%s:%s" % [signi(planar_position.x), signi(planar_position.y)]
		seen_quadrants[quadrant_key] = true

	return seen_quadrants.size() == 4


func _all_robots_face_center(robots: Array[RobotBase]) -> bool:
	for robot in robots:
		var planar_position := Vector2(robot.global_position.x, robot.global_position.z)
		if planar_position.length() < 0.1:
			return false

		var forward := Vector2(-robot.global_basis.z.x, -robot.global_basis.z.z).normalized()
		var to_center := (-planar_position).normalized()
		if forward.dot(to_center) < 0.9:
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
