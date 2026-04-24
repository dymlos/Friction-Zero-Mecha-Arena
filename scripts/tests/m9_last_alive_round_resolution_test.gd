extends SceneTree

const FFA_SCENE := preload("res://scenes/main/main_ffa_validation.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := FFA_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "Escena FFA debe exponer MatchController.")
	_assert(robots.size() >= 4, "Escena FFA debe tener cuatro robots.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_node(main)
		_finish()
		return

	match_controller.set_mode_variant_id(MatchModeVariantCatalog.VARIANT_LAST_ALIVE)
	match_controller.match_config.rounds_to_win = 2
	match_controller.round_reset_delay = 0.2
	match_controller.request_pause_restart()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[0].fall_into_void()
	await create_timer(0.05).timeout
	robots[1].fall_into_void()
	await create_timer(0.05).timeout
	robots[2].fall_into_void()
	await create_timer(0.05).timeout

	_assert(not match_controller.is_round_active(), "Ultimo vivo debe cerrar ronda al quedar un robot.")
	_assert(match_controller.get_round_status_line().contains(robots[3].display_name), "Ganador debe ser ultimo robot en pie.")
	_assert(_has_line(match_controller.get_round_recap_panel_lines(), "Objetivo | Primero a 2 rondas"), "Objetivo debe hablar de rondas.")
	_assert(_has_line_with_fragment(match_controller.get_round_recap_panel_lines(), "Cierre ronda | ultimo vivo (+1 ronda)"), "Cierre debe sumar una ronda plana.")
	_assert(not _has_line_with_fragment(match_controller.get_round_recap_panel_lines(), "Puntos cierre"), "Ultimo vivo no debe mostrar perfil de puntos por causa.")

	await create_timer(match_controller.round_reset_delay + 0.25).timeout
	_assert(match_controller.is_round_active(), "Si no llego a first-to, debe iniciar otra ronda.")

	await _cleanup_node(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	for child in main.get_node("RobotRoot").get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _has_line(lines: Array[String], expected: String) -> bool:
	return lines.has(expected)


func _has_line_with_fragment(lines: Array[String], fragment: String) -> bool:
	for line in lines:
		if line.contains(fragment):
			return true
	return false


func _cleanup_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
