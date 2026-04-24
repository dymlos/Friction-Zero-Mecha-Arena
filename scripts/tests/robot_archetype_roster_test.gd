extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_competitive_roster_exists()
	await _validate_archetype_configs_exist_and_drive_stats()
	await _validate_lab_hud_surfaces_the_roster_identity()
	await _validate_cizalla_passive_reaches_the_roster()
	_finish()


func _validate_competitive_roster_exists() -> void:
	var expected_ids := ["ariete", "grua", "cizalla", "patin", "aguja", "ancla"]
	_assert(
		RosterCatalog.get_competitive_entry_ids() == expected_ids,
		"El roster competitivo completo deberia existir sin cambiar todavia los defaults de escenas 4P."
	)


func _validate_archetype_configs_exist_and_drive_stats() -> void:
	var required_configs := [
		"res://data/config/robots/ariete_archetype.tres",
		"res://data/config/robots/grua_archetype.tres",
		"res://data/config/robots/cizalla_archetype.tres",
		"res://data/config/robots/patin_archetype.tres",
		"res://data/config/robots/aguja_archetype.tres",
		"res://data/config/robots/ancla_archetype.tres",
	]
	for config_path in required_configs:
		_assert(load(config_path) is Resource, "Falta el recurso de arquetipo %s para el roster base." % config_path)

	var main := MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "La escena principal deberia seguir exponiendo cuatro robots para validar arquetipos.")
	if robots.size() < 4:
		await _cleanup_node(main)
		return

	var labels_by_slot := {}
	for robot in robots:
		_assert(robot.has_method("get_archetype_label"), "RobotBase deberia exponer el arquetipo asignado al HUD y a los tests.")
		if robot.has_method("get_archetype_label"):
			var label := String(robot.call("get_archetype_label"))
			_assert(label != "", "Cada robot del laboratorio deberia tener un arquetipo visible.")
			labels_by_slot[robot.player_index] = label

	_assert(labels_by_slot.get(1, "") == "Ariete", "P1 deberia arrancar como Ariete para cubrir el rol de empuje/tanque.")
	_assert(labels_by_slot.get(2, "") == "Grua", "P2 deberia arrancar como Grua para validar rescate/recuperacion.")
	_assert(labels_by_slot.get(3, "") == "Cizalla", "P3 deberia arrancar como Cizalla para cubrir dano modular/dismantle.")
	_assert(labels_by_slot.get(4, "") == "Patin", "P4 deberia arrancar como Patin para validar movilidad/reposicion.")

	var p1 := robots[0]
	var p2 := robots[1]
	var p3 := robots[2]
	var p4 := robots[3]
	_assert(p1.max_part_health > p4.max_part_health, "Ariete deberia sacrificar movilidad a cambio de mayor aguante.")
	_assert(p1.passive_push_strength > p4.passive_push_strength, "Ariete deberia empujar mas que Patin.")
	_assert(p4.max_move_speed > p1.max_move_speed, "Patin deberia ser el arquetipo mas movil del laboratorio.")
	_assert(p3.attack_damage > p1.attack_damage, "Cizalla deberia castigar partes con mas dano base que Ariete.")
	_assert(p3.collision_damage_scale > p4.collision_damage_scale, "Cizalla deberia tensar la ruta de dano modular.")
	_assert(
		p2.restored_part_health_ratio > p1.restored_part_health_ratio,
		"Grua deberia devolver partes con mas vida que Ariete."
	)
	_assert(
		p2.carried_part_return_range > p1.carried_part_return_range,
		"Grua deberia facilitar el rescate con un rango de retorno mayor."
	)

	await _cleanup_node(main)


func _validate_lab_hud_surfaces_the_roster_identity() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var roster_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RosterLabel")
	_assert(roster_label is Label, "El HUD deberia seguir exponiendo el roster compacto.")
	if roster_label is Label:
		var roster_text := (roster_label as Label).text
		_assert(roster_text.contains("Ariete"), "El roster compacto deberia dejar visible el arquetipo Ariete.")
		_assert(roster_text.contains("Grua"), "El roster compacto deberia dejar visible el arquetipo Grua.")
		_assert(roster_text.contains("Cizalla"), "El roster compacto deberia dejar visible el arquetipo Cizalla.")
		_assert(roster_text.contains("Patin"), "El roster compacto deberia dejar visible el arquetipo Patin.")

	await _cleanup_node(main)

	var ffa := FFA_SCENE.instantiate()
	root.add_child(ffa)

	await process_frame
	await process_frame

	var match_controller := ffa.get_node_or_null("Systems/MatchController") as MatchController
	_assert(match_controller != null, "La escena FFA deberia seguir exponiendo MatchController para el marcador.")
	if match_controller != null:
		var score_line := _find_line_with_prefix(match_controller.get_round_state_lines(), "Marcador |")
		_assert(
			score_line == "",
			"El opening neutral FFA no deberia reintroducir `Marcador | ...` solo para mostrar arquetipos."
		)
	var ffa_roster_label := ffa.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RosterLabel")
	_assert(ffa_roster_label is Label, "La escena FFA deberia conservar el roster compacto como lectura de identidad.")
	if ffa_roster_label is Label:
		var ffa_roster_text := (ffa_roster_label as Label).text
		_assert(ffa_roster_text.contains("Ariete"), "El roster FFA deberia seguir exponiendo la identidad Ariete.")
		_assert(ffa_roster_text.contains("Patin"), "El roster FFA deberia seguir exponiendo la identidad Patin.")

	await _cleanup_node(ffa)


func _validate_cizalla_passive_reaches_the_roster() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var robots := _get_scene_robots(main)
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(robots.size() >= 3, "La escena principal deberia seguir exponiendo a Cizalla en el slot 3.")
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController para el roster.")
	if robots.size() < 3 or match_controller == null:
		await _cleanup_node(main)
		return

	var cizalla := robots[2]
	var victim := robots[0]
	victim.apply_damage_to_part("right_arm", 12.0, Vector3.RIGHT)
	victim.receive_attack_hit_from_robot(Vector3.RIGHT, 18.0, cizalla)
	await process_frame
	await physics_frame

	var roster_lines := match_controller.get_robot_status_lines()
	var cizalla_line := ""
	for line in roster_lines:
		if line.contains("Cizalla"):
			cizalla_line = line
			break

	_assert(cizalla_line != "", "El roster deberia seguir exponiendo una linea para Cizalla.")
	_assert(
		cizalla_line.contains("corte"),
		"Cuando Cizalla castiga una parte ya tocada, el roster compacto deberia mostrar ese cue sin abrir otra UI."
	)

	await _cleanup_node(main)


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


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
