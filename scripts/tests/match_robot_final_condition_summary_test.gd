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
		await _assert_final_condition_contract(scene_path)
	_finish()


func _assert_final_condition_contract(scene_path: String) -> void:
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var scene_label := "La escena %s" % scene_path
	var match_controller := main.get_node("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % scene_label)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para validar el resumen final por robot." % scene_label)
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.TEAMS
	match_controller.match_config.rounds_to_win = 1
	match_controller.round_reset_delay = 0.15
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame

	for robot in robots:
		robot.void_fall_y = -100.0

	robots[0].apply_damage_to_part("left_arm", robots[0].max_part_health + 5.0)
	robots[2].apply_damage_to_part("left_leg", robots[2].max_part_health + 5.0)
	robots[2].apply_damage_to_part("right_leg", robots[2].max_part_health + 5.0)
	robots[3].apply_damage_to_part("right_arm", robots[3].max_part_health + 5.0)
	await process_frame

	robots[2].fall_into_void()
	robots[3].fall_into_void()
	await create_timer(0.05).timeout

	_assert(match_controller.is_match_over(), "%s deberia cerrar la partida cuando el objetivo es 1." % scene_label)
	_assert(
		_has_line_containing(
			match_controller.get_round_recap_panel_lines(),
			"Player 1 / Ariete | sigue en pie | 3/4 partes | sin brazo izquierdo"
		),
		"%s deberia conservar tambien el arquetipo del robot superviviente en el recap lateral." % scene_label
	)
	_assert(
		_has_line_containing(
			match_controller.get_round_recap_panel_lines(),
			"Player 3 / Cizalla | baja 1 | vacio | 2/4 partes | sin pierna izquierda, pierna derecha"
		),
		"%s deberia conservar tambien el arquetipo al explicar que extremidades le faltaban al robot eliminado." % scene_label
	)
	_assert(
		_has_line_containing(
			match_controller.get_match_result_lines(),
			"Player 4 / Patin | baja 2 | vacio | 3/4 partes | sin brazo derecho"
		),
		"%s deberia repetir el estado final de extremidades sin perder la identidad de arquetipo del robot derrotado." % scene_label
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


func _has_line_containing(lines: Array[String], expected_fragment: String) -> bool:
	for line in lines:
		if line.contains(expected_fragment):
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
