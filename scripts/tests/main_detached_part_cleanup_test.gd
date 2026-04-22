extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia exponer MatchController.")
	_assert(robots.size() >= 4, "La escena principal deberia tener al menos cuatro robots para crear un escenario de limpieza.")
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	for robot in robots:
		robot.set_physics_process(false)
		robot.gravity = 0.0
		robot.void_fall_y = -1000.0

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	main.detached_part_cleanup_limit = 6

	# Generamos 3 partes separadas, y dejamos una para carga manual.
	robots[0].apply_damage_to_part("left_arm", robots[0].max_part_health + 5.0, Vector3.LEFT)
	robots[0].apply_damage_to_part("right_arm", robots[0].max_part_health + 5.0, Vector3.RIGHT)
	robots[1].apply_damage_to_part("left_leg", robots[1].max_part_health + 5.0, Vector3.BACK)

	await process_frame

	var detached_parts := _get_detached_parts()
	_assert(detached_parts.size() >= 3, "Se esperaban al menos tres partes desprendidas para activar el caso de limite.")
	if detached_parts.size() < 3:
		await _cleanup_main(main)
		_finish()
		return

	var pickup_delay := _get_max_pickup_delay(detached_parts)
	if pickup_delay > 0.0:
		await create_timer(pickup_delay + 0.05).timeout

	var carrier := robots[2]
	var carried_part := detached_parts[0]
	var picked_up := carried_part.try_pick_up(carrier)
	_assert(picked_up, "Una parte deveria poder ser recogida para validar su preservacion durante limpieza.")
	_assert(carrier.is_carrying_part(), "El portador deberia quedar marcado con parte en mano.")
	_assert(carried_part.is_carried(), "La parte seleccionada deberia marcarse como transportada.")

	main.detached_part_cleanup_limit = 1

	# Lanza limpieza de comienzo de ronda para validar el limite con 1 pieza en mano.
	main._on_round_started(1)
	await process_frame

	var after_round_parts := _get_detached_parts()
	var floor_parts_count := _count_floor_detached_parts(after_round_parts)
	_assert(is_instance_valid(carried_part), "La parte transportada no deberia ser eliminada por la limpieza proactiva.")
	_assert(carried_part.is_carried(), "La parte transportada sigue activa durante el ciclo de limpieza.")
	_assert(after_round_parts.size() <= 2, "Con limite 1 y una parte en mano no deberia quedar mas de una parte en piso.")
	_assert(floor_parts_count <= 1, "El limite 1 debe preservar solo una parte sin portar en el piso.")

	# Creamos otra parte para verificar la limpieza en un segundo ciclo de ronda.
	robots[2].apply_damage_to_part("right_leg", robots[2].max_part_health + 5.0, Vector3.FORWARD)
	await process_frame
	if _get_detached_parts().size() <= after_round_parts.size():
		# Si el daño no generara otra parte en este frame, aguardamos 1 tick para estabilidad del motor.
		await process_frame

	main._on_round_started(2)
	await process_frame

	after_round_parts = _get_detached_parts()
	floor_parts_count = _count_floor_detached_parts(after_round_parts)
	_assert(is_instance_valid(carried_part), "La parte transportada no debe romperse en rondas sucesivas de limpieza.")
	_assert(carried_part.is_carried(), "La parte transportada debe continuar intacta en rondas sucesivas.")
	_assert(after_round_parts.size() <= 2, "El ciclo reiterado de limpieza debe seguir el limite 1 sin exceder.")
	_assert(floor_parts_count <= 1, "Las rondas sucesivas no deben dejar acumuladas mas partes en piso del limite.")

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _get_detached_parts() -> Array[DetachedPart]:
	var parts: Array[DetachedPart] = []
	for node in root.get_tree().get_nodes_in_group("detached_parts"):
		if node is DetachedPart:
			parts.append(node as DetachedPart)

	return parts


func _count_floor_detached_parts(parts: Array[DetachedPart]) -> int:
	var count := 0
	for part in parts:
		if not part.is_carried():
			count += 1

	return count


func _get_max_pickup_delay(parts: Array[DetachedPart]) -> float:
	var max_delay := 0.0
	for part in parts:
		max_delay = maxf(max_delay, part.pickup_delay)

	return max_delay


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
