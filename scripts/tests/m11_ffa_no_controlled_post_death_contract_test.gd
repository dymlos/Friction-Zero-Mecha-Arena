extends SceneTree

const MAIN_FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MAIN_TEAMS_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")
const PilotSupportShip = preload("res://scripts/support/pilot_support_ship.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _assert_ffa_has_no_support_ship(MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE)
	await _assert_ffa_has_no_support_ship(MatchModeVariantCatalog.VARIANT_LAST_ALIVE)
	await _assert_teams_still_has_support_ship()
	_finish()


func _assert_ffa_has_no_support_ship(variant_id: String) -> void:
	var main := MAIN_FFA_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	match_controller.set_mode_variant_id(variant_id)
	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "FFA necesita cuatro robots para validar post-muerte.")
	for robot in robots:
		robot.void_fall_y = -100.0
	if robots.size() >= 1:
		robots[0].fall_into_void()
	await create_timer(0.1).timeout
	_assert(_count_owned_support_ships(main) == 0, "FFA no debe crear nave post-muerte controlable en %s." % variant_id)
	await _cleanup(main)


func _assert_teams_still_has_support_ship() -> void:
	var main := MAIN_TEAMS_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 2, "Teams necesita robots para validar soporte.")
	for robot in robots:
		robot.void_fall_y = -100.0
	if robots.size() >= 2:
		robots[1].fall_into_void()
	await create_timer(0.1).timeout
	_assert(_count_owned_support_ships(main) >= 1, "Teams debe conservar nave post-muerte controlable.")
	await _cleanup(main)


func _count_owned_support_ships(owner: Node) -> int:
	var count := 0
	for node in get_nodes_in_group("pilot_support_ships"):
		if node is PilotSupportShip and owner.is_ancestor_of(node):
			count += 1
	return count


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	for child in main.get_node("RobotRoot").get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _cleanup(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
