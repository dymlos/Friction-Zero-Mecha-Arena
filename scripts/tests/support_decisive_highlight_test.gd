extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const TEAMS_SCENES := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in TEAMS_SCENES:
		await _assert_support_highlight_contract(scene_path)
	_finish()


func _assert_support_highlight_contract(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var scene_label := "La escena %s" % scene_path
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % scene_label)
	_assert(support_root != null, "%s deberia exponer SupportRoot." % scene_label)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para validar apoyo decisivo." % scene_label)
	if match_controller == null or support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	_assert(match_controller.match_config != null, "%s deberia cargar una MatchConfig base." % scene_label)
	if match_controller.match_config == null:
		await _cleanup_main(main)
		return

	match_controller.match_config.rounds_to_win = 1
	match_controller.round_reset_delay = 0.15
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"%s deberia instanciar la nave de apoyo al caer un aliado en Teams." % scene_label
	)
	if support_root.get_child_count() != 1:
		await _cleanup_main(main)
		return

	var support_ship := support_root.get_child(0) as Node3D
	_assert(support_ship != null, "%s deberia instanciar la nave de apoyo para registrar el highlight." % scene_label)
	if support_ship == null:
		await _cleanup_main(main)
		return

	var surge_pickup: Node3D = null
	for pickup in get_nodes_in_group("pilot_support_pickups"):
		if not (pickup is Node3D):
			continue
		if str((pickup as Node3D).get("payload_name")) == "surge":
			surge_pickup = pickup as Node3D
			break

	_assert(
		surge_pickup != null,
		"%s deberia ofrecer una carga de energia en el carril de soporte para registrar el highlight." % scene_label
	)
	if surge_pickup == null:
		await _cleanup_main(main)
		return

	support_ship.global_position = surge_pickup.global_position
	await _wait_support_spawn_grace(support_ship)

	Input.action_press("p2_throw_part")
	await _wait_frames(2)
	Input.action_release("p2_throw_part")
	await _wait_frames(2)

	robots[2].fall_into_void()
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	var expected_highlight := "Apoyo decisivo | %s energia > %s" % [
		robots[1].get_roster_display_name(),
		robots[0].get_roster_display_name(),
	]
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), expected_highlight),
		"%s deberia explicar en el recap lateral que apoyo concreto acompano la ronda decisiva." % scene_label
	)
	_assert(
		_has_line(match_controller.get_match_result_lines(), expected_highlight),
		"%s deberia repetir el apoyo decisivo del cierre en el resultado final." % scene_label
	)

	await _cleanup_main(main)


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia seguir existiendo." % scene_path)
	if not (packed_scene is PackedScene):
		return null

	var main := (packed_scene as PackedScene).instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
	root.add_child(main)
	await process_frame
	await process_frame
	return main


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


func _wait_frames(count: int) -> void:
	for _step in range(count):
		await process_frame


func _wait_support_spawn_grace(support_ship: Node3D) -> void:
	var wait_seconds := 0.0
	if support_ship != null:
		wait_seconds = float(support_ship.get("spawn_pickup_grace_duration")) + 0.05
	if wait_seconds > 0.0:
		await create_timer(wait_seconds).timeout
	await _wait_frames(2)


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
