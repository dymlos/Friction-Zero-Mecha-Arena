extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "La escena 2v2 deberia seguir exponiendo cuatro robots jugables.")
	if robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	var owner := robots[0]
	var grua := robots[1]

	_assert(owner.is_ally_of(grua), "Grua deberia seguir compartiendo equipo con el robot de prueba en el laboratorio 2v2.")
	_assert(grua.has_method("has_core_skill"), "RobotBase deberia seguir exponiendo si un arquetipo tiene habilidad.")
	_assert(grua.has_method("get_core_skill_label"), "RobotBase deberia exponer la etiqueta corta de la habilidad.")
	_assert(grua.has_method("use_core_skill"), "RobotBase deberia permitir activar la habilidad del arquetipo de recuperacion.")
	if grua.has_method("has_core_skill"):
		_assert(bool(grua.call("has_core_skill")), "Grua deberia arrancar con una habilidad de recuperacion activa.")
	if grua.has_method("get_core_skill_label"):
		_assert(String(grua.call("get_core_skill_label")) == "Iman", "La habilidad de Grua deberia leerse como Iman.")

	var roster_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RosterLabel")
	_assert(roster_label is Label, "La escena 2v2 deberia seguir exponiendo el roster compacto.")
	if roster_label is Label:
		var roster_text := (roster_label as Label).text
		_assert(roster_text.contains("Grua"), "El roster 2v2 deberia seguir exponiendo el arquetipo de asistencia.")
		_assert(
			roster_text.contains("skill Iman") or roster_text.contains("skill iman"),
			"El roster 2v2 deberia dejar visible la nueva habilidad de Grua."
		)

	for robot in robots:
		robot.set_physics_process(false)
		robot.gravity = 0.0
		robot.void_fall_y = -100.0

	owner.apply_damage_to_part("left_arm", owner.max_part_health + 5.0, Vector3.LEFT)
	await process_frame

	var detached_part := _get_only_detached_part()
	_assert(detached_part != null, "La destruccion modular deberia seguir generando una parte desprendida para la skill de recuperacion.")
	if detached_part == null:
		await _cleanup_main(main)
		_finish()
		return

	await create_timer(detached_part.pickup_delay + 0.05).timeout

	grua.global_position = detached_part.global_position + Vector3(2.3, 0.0, 0.0)
	var base_pickup_range := grua.detached_part_pickup_range
	_assert(
		grua.global_position.distance_to(detached_part.global_position) > base_pickup_range,
		"La prueba de Iman necesita dejar a Grua fuera del pickup normal para demostrar el nuevo alcance."
	)
	if grua.global_position.distance_to(detached_part.global_position) <= base_pickup_range:
		await _cleanup_main(main)
		_finish()
		return

	var used := bool(grua.call("use_core_skill"))
	_assert(used, "Iman deberia poder activarse para capturar una parte aliada fuera del pickup normal.")
	_assert(grua.is_carrying_part(), "Grua deberia terminar cargando la parte capturada por Iman.")
	_assert(
		grua.get_carried_part_name() == "left_arm",
		"Iman deberia capturar la parte destruida correcta para integrarse con el loop de rescate."
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


func _get_only_detached_part() -> DetachedPart:
	var detached_parts := get_nodes_in_group("detached_parts")
	_assert(detached_parts.size() == 1, "Se esperaba exactamente una parte desprendida para validar Iman.")
	if detached_parts.size() != 1:
		return null

	return detached_parts[0] as DetachedPart


func _cleanup_main(main: Node) -> void:
	if not is_instance_valid(main):
		return

	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
