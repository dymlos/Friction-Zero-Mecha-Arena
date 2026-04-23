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
		await _assert_elimination_readability_contract(scene_path)
	_finish()


func _assert_elimination_readability_contract(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var scene_label := "La escena %s" % scene_path
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapScroll/RecapLabel") as Label
	var match_result_label := main.get_node_or_null("UI/MatchHud/Root/MatchResultPanel/Margin/MatchResultVBox/MatchResultScroll/MatchResultLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % scene_label)
	_assert(recap_label != null, "%s deberia exponer el detalle del recap para validar atribucion." % scene_label)
	_assert(match_result_label != null, "%s deberia exponer el detalle del resultado final para validar atribucion." % scene_label)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para validar lectura de eliminacion." % scene_label)
	if match_controller == null or recap_label == null or match_result_label == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.rounds_to_win = 1
	match_controller.round_reset_delay = 0.45
	match_controller.match_restart_delay = 1.1

	for robot in robots:
		robot.void_fall_y = -100.0

	var explosion_attacker := robots[0]
	robots[2].disabled_explosion_delay = 0.35
	robots[2].disabled_explosion_timer.wait_time = 0.35
	for part_name in robots[2].BODY_PARTS:
		robots[2].apply_damage_to_part(
			part_name,
			robots[2].max_part_health + 10.0,
			Vector3.LEFT,
			explosion_attacker
		)

	await create_timer(0.05).timeout

	var disabled_line := _find_robot_status_line(match_controller, robots[2])
	_assert(
		disabled_line.contains("Inutilizado"),
		"%s deberia seguir marcando al robot sin partes como inutilizado antes de la explosion." % scene_label
	)
	_assert(
		disabled_line.contains("explota"),
		"%s deberia avisar que el cuerpo inutilizado va a explotar pronto." % scene_label
	)

	await create_timer(0.4).timeout

	var exploded_line := _find_robot_status_line(match_controller, robots[2])
	_assert(
		exploded_line.contains("Fuera") or exploded_line.contains("Apoyo activo"),
		"%s deberia dejar claro que el robot ya salio del combate principal tras explotar." % scene_label
	)
	_assert(
		exploded_line.contains("explosion"),
		"%s deberia conservar la causa breve de eliminacion por explosion." % scene_label
	)
	_assert(
		_has_line_with_fragment(
			match_controller.get_round_state_lines(),
			"Ultima baja | Player 3 explosiono tras quedar inutilizado por Player 1"
		),
		"%s deberia dejar visible la ultima baja por explosion junto con el rival que la forzo." % scene_label
	)

	var void_attacker := robots[1]
	robots[3].apply_damage_to_part("left_leg", 6.0, Vector3.LEFT, void_attacker)
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	var void_line := _find_robot_status_line(match_controller, robots[3])
	_assert(
		void_line.contains("Fuera"),
		"%s deberia marcar como fuera al robot que cae al vacio." % scene_label
	)
	_assert(
		void_line.contains("vacio"),
		"%s deberia conservar la causa breve de eliminacion por vacio." % scene_label
	)
	_assert(
		_has_line_with_fragment(
			match_controller.get_round_state_lines(),
			"Ultima baja | Player 4 cayo al vacio por Player 2"
		),
		"%s deberia exponer tambien la ultima baja por vacio junto con el rival responsable." % scene_label
	)
	_assert(
		recap_label.text.contains("Player 3 / Cizalla | baja 1 | explosion por Player 1"),
		"%s deberia conservar en el recap lateral la atribucion del rival que forzo la explosion." % scene_label
	)
	_assert(
		recap_label.text.contains("Player 4 / Patin | baja 2 | vacio por Player 2"),
		"%s deberia conservar en el recap lateral la atribucion del rival que forzo la caida al vacio." % scene_label
	)
	_assert(
		_has_line_with_fragment(
			match_controller.get_round_recap_panel_lines(),
			"Cierre | Player 4 cayo al vacio por Player 2"
		),
		"%s deberia reutilizar tambien la ultima baja con atribucion del rival responsable en el recap lateral del cierre final." % scene_label
	)
	_assert(
		recap_label.text.contains("Cierre | Player 4 cayo al vacio por Player 2"),
		"%s deberia dejar explicita tambien la ultima baja decisiva en el recap visible." % scene_label
	)
	_assert(
		match_result_label.text.contains("Cierre | Player 4 cayo al vacio por Player 2"),
		"%s deberia reutilizar la ultima baja con atribucion del rival responsable en el resultado final." % scene_label
	)

	await create_timer(maxf(match_controller.round_reset_delay + 0.2, 0.95)).timeout
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


func _find_robot_status_line(match_controller: MatchController, robot: RobotBase) -> String:
	var lookup := "P%s %s" % [robot.player_index, robot.display_name]
	for line in match_controller.get_robot_status_lines():
		if line.begins_with(lookup):
			return line

	return ""


func _has_line_with_fragment(lines: Array[String], fragment: String) -> bool:
	for line in lines:
		if line.contains(fragment):
			return true

	return false


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


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
