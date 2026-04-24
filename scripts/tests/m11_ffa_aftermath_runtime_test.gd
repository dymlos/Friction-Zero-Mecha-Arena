extends SceneTree

const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const TEAMS_SCENE := preload("res://scenes/main/main.tscn")
const FfaAftermathPickup = preload("res://scripts/pickups/ffa_aftermath_pickup.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _assert_ffa_aftermath()
	await _assert_teams_has_no_aftermath()
	_finish()


func _assert_ffa_aftermath() -> void:
	var main := FFA_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "FFA runtime deberia exponer cuatro robots.")
	if robots.size() < 4:
		await _cleanup_node(main)
		return
	robots[0].fall_into_void()
	await process_frame
	await process_frame

	var pickups := get_nodes_in_group("ffa_aftermath_pickups")
	_assert(pickups.size() == 1, "La primera baja FFA deberia crear un pickup de aftermath.")
	if pickups.size() == 1:
		var pickup := pickups[0] as FfaAftermathPickup
		robots[3].use_core_skill()
		_assert(pickup.try_collect(robots[3]), "Un robot vivo deberia poder tomar botin aplicable.")
		await process_frame
		_assert(get_nodes_in_group("ffa_aftermath_pickups").is_empty(), "El pickup recogido deberia desaparecer.")

	robots[1].fall_into_void()
	await process_frame
	robots[2].fall_into_void()
	await process_frame
	var count_after_close := get_nodes_in_group("ffa_aftermath_pickups").size()
	_assert(count_after_close <= 1, "La baja que cierra ronda no deberia crear un nuevo pickup.")
	await _cleanup_node(main)


func _assert_teams_has_no_aftermath() -> void:
	var main := TEAMS_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var robots := _get_scene_robots(main)
	if robots.size() >= 2:
		robots[1].fall_into_void()
		await process_frame
		await process_frame
	_assert(get_nodes_in_group("ffa_aftermath_pickups").is_empty(), "Teams no deberia crear aftermath FFA.")
	await _cleanup_node(main)


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
