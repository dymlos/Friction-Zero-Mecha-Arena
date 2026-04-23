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
		await _assert_highlight_contract(scene_path)
	_finish()


func _assert_highlight_contract(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var scene_label := "La escena %s" % scene_path
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapScroll/RecapLabel") as Label
	var match_result_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultScroll/MatchResultLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % scene_label)
	_assert(recap_label != null, "%s deberia exponer texto legible para validar momentos clave en el recap." % scene_label)
	_assert(match_result_label != null, "%s deberia exponer texto legible para validar momentos clave en el cierre final." % scene_label)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para validar momentos clave." % scene_label)
	if match_controller == null or recap_label == null or match_result_label == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	_assert(match_controller.match_config != null, "%s deberia cargar una MatchConfig base." % scene_label)
	if match_controller.match_config == null:
		await _cleanup_main(main)
		return

	match_controller.match_config.rounds_to_win = 1
	match_controller.round_reset_delay = 0.45
	match_controller.match_restart_delay = 1.1
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[2].fall_into_void()
	await create_timer(0.05).timeout
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	_assert(
		_has_line(
			match_controller.get_round_recap_panel_lines(),
			"Resumen | Player 3 cayo al vacio -> Player 4 cayo al vacio"
		),
		"%s deberia incluir tambien el resumen compacto de bajas en el recap lateral." % scene_label
	)
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), "Momento inicial | Player 3 cayo al vacio"),
		"%s deberia destacar la primera baja como snippet compacto del cierre." % scene_label
	)
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), "Momento final | Player 4 cayo al vacio"),
		"%s deberia destacar tambien la baja que cerro la ronda/partida." % scene_label
	)
	_assert(
		recap_label.text.contains("Resumen | Player 3 cayo al vacio -> Player 4 cayo al vacio"),
		"%s deberia incluir el resumen compacto de bajas en el recap visible." % scene_label
	)
	_assert(
		recap_label.text.contains("Momento inicial | Player 3 cayo al vacio"),
		"%s deberia incluir el snippet del primer momento clave en el recap visible." % scene_label
	)
	_assert(
		recap_label.text.contains("Momento final | Player 4 cayo al vacio"),
		"%s deberia incluir el snippet del momento final en el recap visible." % scene_label
	)
	_assert(
		match_result_label.text.contains("Resumen | Player 3 cayo al vacio -> Player 4 cayo al vacio"),
		"%s deberia reutilizar el resumen compacto del cierre en el panel final." % scene_label
	)
	_assert(
		match_result_label.text.contains("Momento inicial | Player 3 cayo al vacio"),
		"%s deberia reutilizar el primer momento clave del cierre en el panel final." % scene_label
	)
	_assert(
		match_result_label.text.contains("Momento final | Player 4 cayo al vacio"),
		"%s deberia reutilizar el momento final del cierre en el panel final." % scene_label
	)

	await _cleanup_main(main)


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia seguir existiendo." % scene_path)
	if not (packed_scene is PackedScene):
		return null

	var main := (packed_scene as PackedScene).instantiate()
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
