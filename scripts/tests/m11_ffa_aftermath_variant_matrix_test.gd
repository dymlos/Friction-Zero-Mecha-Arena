extends SceneTree

const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _assert_variant_spawns_neutral_aftermath(MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE)
	await _assert_variant_spawns_neutral_aftermath(MatchModeVariantCatalog.VARIANT_LAST_ALIVE)
	_finish()


func _assert_variant_spawns_neutral_aftermath(variant_id: String) -> void:
	var main := FFA_SCENE.instantiate()
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller != null:
		match_controller.mode_variant_id = variant_id
		if match_controller.match_config != null:
			match_controller.match_config.round_intro_duration_ffa = 0.0
	root.add_child(main)
	await process_frame
	await process_frame
	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "FFA necesita cuatro robots para validar aftermath en %s." % variant_id)
	if robots.size() < 4:
		await _cleanup(main)
		return

	robots[0].fall_into_void()
	await create_timer(0.1).timeout
	_assert(_count_owned_group(main, "ffa_aftermath_pickups") == 1, "La baja no final debe crear un pickup de aftermath en %s." % variant_id)
	_assert(_count_owned_group(main, "pilot_support_ships") == 0, "La baja FFA no debe crear naves de soporte en %s." % variant_id)
	var state_text := "\n".join(PackedStringArray(match_controller.get_round_state_lines()))
	_assert(state_text.contains("Botin |"), "El HUD debe mostrar Botin mientras el pickup esta activo en %s." % variant_id)
	for node in get_nodes_in_group("ffa_aftermath_pickups"):
		if node is Node and main.is_ancestor_of(node):
			(node as Node).queue_free()
	await process_frame
	await process_frame
	var cleared_state_text := "\n".join(PackedStringArray(match_controller.get_round_state_lines()))
	_assert(not cleared_state_text.contains("Botin |"), "El HUD debe limpiar Botin cuando el pickup ya no esta activo en %s." % variant_id)
	await _cleanup(main)


func _count_owned_group(owner: Node, group_name: String) -> int:
	var count := 0
	for node in get_nodes_in_group(group_name):
		if node is Node and owner.is_ancestor_of(node):
			count += 1
	return count


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _cleanup(node: Node) -> void:
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
