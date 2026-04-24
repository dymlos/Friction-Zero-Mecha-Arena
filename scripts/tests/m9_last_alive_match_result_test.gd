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
	match_controller.match_config.rounds_to_win = 1
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

	_assert(match_controller.is_match_over(), "First-to 1 debe cerrar partida.")
	var result_lines := match_controller.get_match_result_lines()
	_assert(_has_line_with_fragment(result_lines, "gana la partida con 1 ronda"), "Resultado debe hablar de ronda, no puntos.")
	_assert(not _has_line_with_fragment(result_lines, "Puntos cierre"), "Resultado last_alive no debe mostrar perfil de puntos por causa.")
	_assert(_has_line_with_fragment(result_lines, "Posiciones | 1."), "Resultado FFA debe conservar posiciones.")

	await _cleanup_node(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	for child in main.get_node("RobotRoot").get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


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
