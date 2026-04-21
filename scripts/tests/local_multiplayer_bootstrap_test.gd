extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var robot_root := main.get_node("RobotRoot")
	var robots: Array[RobotBase] = []
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	_assert(robots.size() >= 2, "La escena principal deberia exponer al menos dos robots para el prototipo local.")
	if robots.size() < 2:
		_finish()
		return
	_assert(robots[0].is_player_controlled, "El primer robot deberia quedar activo para jugador local.")
	_assert(robots[1].is_player_controlled, "El segundo robot deberia quedar activo para jugador local.")
	_assert(robots[0].player_index == 1, "El primer robot deberia usar el slot del jugador 1.")
	_assert(robots[1].player_index == 2, "El segundo robot deberia usar el slot del jugador 2.")

	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel")
	_assert(roster_label is Label, "El HUD deberia mostrar un roster compacto para leer el estado de los robots.")
	if roster_label is Label:
		var roster_text := (roster_label as Label).text
		_assert(roster_text.contains("Player 1"), "El roster deberia incluir a Player 1.")
		_assert(roster_text.contains("Player 2"), "El roster deberia incluir a Player 2.")

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
