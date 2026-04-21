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
	var recap_panel := main.get_node_or_null("UI/MatchHud/Root/RecapPanel") as Control
	var recap_title_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapTitleLabel") as Label
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia exponer MatchController.")
	_assert(recap_panel != null, "El HUD deberia exponer un panel de recap de ronda.")
	_assert(recap_title_label != null, "El recap deberia exponer un titulo legible.")
	_assert(recap_label != null, "El recap deberia exponer un bloque de detalle legible.")
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para validar el resumen de ronda.")
	if match_controller == null or recap_panel == null or recap_title_label == null or recap_label == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.round_reset_delay = 0.45
	_assert(not recap_panel.visible, "Durante la ronda activa el recap no deberia tapar el combate.")
	for robot in robots:
		robot.void_fall_y = -100.0

	robots[2].fall_into_void()
	await create_timer(0.05).timeout
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	var expected_recap := "Resumen | %s vacio -> %s vacio" % [robots[2].display_name, robots[3].display_name]
	_assert(
		_has_line(match_controller.get_round_state_lines(), expected_recap),
		"Al cerrar la ronda, el HUD deberia conservar un resumen compacto del orden de bajas."
	)
	_assert(recap_panel.visible, "Al cerrar la ronda deberia aparecer un recap dedicado.")
	_assert(
		recap_title_label.text.contains("Cierre de ronda"),
		"El panel deberia distinguir un cierre de ronda de un resultado de partida."
	)
	_assert(
		recap_label.text.contains("Equipo 1 gana la ronda 1"),
		"El recap deberia reiterar la decision de la ronda."
	)
	_assert(
		recap_label.text.contains("Player 3 | baja 1 | vacio"),
		"El recap deberia explicar la primera baja con orden y causa."
	)
	_assert(
		recap_label.text.contains("Player 4 | baja 2 | vacio"),
		"El recap deberia explicar la segunda baja con orden y causa."
	)

	await create_timer(maxf(match_controller.round_reset_delay + 0.2, 0.95)).timeout

	_assert(
		not _has_line_prefix(match_controller.get_round_state_lines(), "Resumen | "),
		"El resumen compacto de la ronda anterior deberia limpiarse al iniciar la siguiente."
	)
	_assert(not recap_panel.visible, "Al iniciar la siguiente ronda el recap deberia ocultarse otra vez.")

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _has_line(lines: Array[String], expected: String) -> bool:
	for line in lines:
		if line == expected:
			return true

	return false


func _has_line_prefix(lines: Array[String], prefix: String) -> bool:
	for line in lines:
		if line.begins_with(prefix):
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
