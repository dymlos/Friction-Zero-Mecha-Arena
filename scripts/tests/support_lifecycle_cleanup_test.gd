extends SceneTree

const TEAM_SCENES := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
]
const MatchController = preload("res://scripts/systems/match_controller.gd")
const PilotSupportPickup = preload("res://scripts/support/pilot_support_pickup.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const SupportLaneGate = preload("res://scripts/support/support_lane_gate.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in TEAM_SCENES:
		await _verify_support_cleanup_after_round_reset(scene_path)
		await _verify_support_cleanup_after_manual_match_restart(scene_path)
	_finish()


func _verify_support_cleanup_after_round_reset(scene_path: String) -> void:
	var main := await _instantiate_main_scene(scene_path)
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController para validar cleanup del soporte." % scene_path)
	_assert(support_root != null, "%s deberia seguir exponiendo SupportRoot." % scene_path)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para cerrar una ronda Teams." % scene_path)
	if match_controller == null or support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.rounds_to_win = 2
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.match_config.void_elimination_round_points = 1
	match_controller.match_config.destruction_elimination_round_points = 1
	match_controller.match_config.unstable_elimination_round_points = 1
	match_controller.round_reset_delay = 0.15
	match_controller.start_match()
	await _wait_frames(2)

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Al caer un aliado en Teams deberia aparecer la nave de apoyo antes del reset de ronda."
	)
	_assert(
		match_controller.get_robot_support_state(robots[1]) != "",
		"El owner del soporte deberia publicar `support_state` mientras la nave sigue activa."
	)
	_assert(
		_are_support_lane_nodes_active(),
		"Con una nave de apoyo viva, el carril externo deberia seguir activo."
	)

	robots[2].fall_into_void()
	robots[3].fall_into_void()
	await create_timer(match_controller.round_reset_delay + 0.2).timeout
	await _wait_frames(2)

	_assert(
		match_controller.is_round_active(),
		"Tras cerrar una ronda no final, el match deberia volver a una ronda activa."
	)
	_assert(
		match_controller.get_round_status_line().contains("Ronda 2"),
		"El reset de ronda deberia avanzar al siguiente numero de ronda."
	)
	_assert(
		support_root.get_child_count() == 0,
		"Tras el reset de ronda no deberian quedar naves de apoyo stale en SupportRoot."
	)
	_assert(
		match_controller.get_robot_support_state(robots[1]) == "",
		"Tras el reset de ronda deberia limpiarse el `support_state` del jugador eliminado."
	)
	_assert(
		not _are_support_lane_nodes_active(),
		"Tras el reset de ronda el carril externo deberia volver a quedar apagado."
	)

	await _cleanup_main(main)


func _verify_support_cleanup_after_manual_match_restart(scene_path: String) -> void:
	var main := await _instantiate_main_scene(scene_path)
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController para validar restart manual." % scene_path)
	_assert(support_root != null, "%s deberia seguir exponiendo SupportRoot." % scene_path)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para cerrar una partida Teams." % scene_path)
	if match_controller == null or support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.rounds_to_win = 1
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.round_reset_delay = 0.15
	match_controller.match_restart_delay = 0.25
	match_controller.start_match()
	await _wait_frames(2)

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Antes de reiniciar manualmente deberia existir una nave de apoyo activa."
	)
	_assert(
		match_controller.get_robot_support_state(robots[1]) != "",
		"Antes del restart manual, el owner del soporte deberia seguir marcado como `Apoyo activo`."
	)

	robots[2].fall_into_void()
	robots[3].fall_into_void()
	await _wait_frames(3)

	_assert(match_controller.is_match_over(), "La partida deberia quedar cerrada antes de probar `F5`.")

	var restart_event := InputEventKey.new()
	restart_event.pressed = true
	restart_event.keycode = KEY_F5
	main._unhandled_input(restart_event)
	await _wait_frames(2)

	_assert(
		not match_controller.is_match_over(),
		"F5 deberia reiniciar el match sin esperar al timer automatico."
	)
	_assert(
		match_controller.get_round_status_line().contains("Ronda 1"),
		"El restart manual deberia volver a un match limpio desde la ronda 1."
	)
	_assert(
		support_root.get_child_count() == 0,
		"Tras `F5` no deberian quedar naves de apoyo stale del match anterior."
	)
	_assert(
		match_controller.get_robot_support_state(robots[1]) == "",
		"Tras `F5` deberia limpiarse el `support_state` del match anterior."
	)
	_assert(
		not _are_support_lane_nodes_active(),
		"Tras `F5` el carril externo deberia reiniciarse apagado."
	)

	await _cleanup_main(main)


func _instantiate_main_scene(scene_path: String) -> Node:
	var scene := load(scene_path) as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	return main


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _are_support_lane_nodes_active() -> bool:
	for node in get_nodes_in_group("pilot_support_pickups"):
		if not (node is PilotSupportPickup):
			continue

		var pickup := node as PilotSupportPickup
		if pickup.visible:
			return true

	for node in get_nodes_in_group("support_lane_gates"):
		if not (node is SupportLaneGate):
			continue

		var gate := node as SupportLaneGate
		if gate.is_support_active():
			return true

	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


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
