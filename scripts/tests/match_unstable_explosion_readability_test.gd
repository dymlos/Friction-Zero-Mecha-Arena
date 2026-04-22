extends SceneTree

const SCENE_PATHS := [
	"res://scenes/main/main.tscn",
	"res://scenes/main/main_teams_validation.tscn",
]
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in SCENE_PATHS:
		var scene_resource := load(scene_path) as PackedScene
		var main = scene_resource.instantiate()
		root.add_child(main)

		await process_frame
		await process_frame

		var match_controller := main.get_node("Systems/MatchController") as MatchController
		var robots := _get_scene_robots(main)
		_assert(match_controller != null, "%s deberia exponer MatchController." % scene_path)
		_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para validar lectura de explosion inestable." % scene_path)
		if match_controller == null or robots.size() < 4:
			await _cleanup_main(main)
			_finish()
			return

		match_controller.match_mode = MatchController.MatchMode.TEAMS
		match_controller.round_reset_delay = 0.45

		for robot in robots:
			robot.void_fall_y = -100.0

		var unstable_robot := robots[2]
		unstable_robot.set_energy_focus("right_arm")
		unstable_robot.activate_overdrive()
		unstable_robot.disabled_explosion_delay = 0.35
		unstable_robot.disabled_explosion_timer.wait_time = 0.35
		for part_name in unstable_robot.BODY_PARTS:
			unstable_robot.apply_damage_to_part(part_name, unstable_robot.max_part_health + 10.0, Vector3.LEFT)

		await create_timer(0.05).timeout

		var disabled_line := _find_robot_status_line(match_controller, unstable_robot)
		_assert(
			disabled_line.contains("Inutilizado"),
			"%s deberia seguir marcando al robot inutilizado antes de la explosion." % scene_path
		)
		_assert(
			disabled_line.contains("inestable"),
			"%s deberia avisar cuando la explosion pendiente nace de un overdrive." % scene_path
		)

		await create_timer(0.4).timeout

		var exploded_line := _find_robot_status_line(match_controller, unstable_robot)
		_assert(
			exploded_line.contains("Fuera") or exploded_line.contains("Apoyo activo"),
			"%s deberia dejar claro que el robot ya salio del combate principal tras explotar." % scene_path
		)
		_assert(
			exploded_line.contains("explosion inestable"),
			"%s deberia conservar la causa breve de eliminacion por explosion inestable." % scene_path
		)
		_assert(
			_has_line_with_fragment(match_controller.get_round_state_lines(), "Ultima baja | Player 3 exploto en sobrecarga"),
			"%s deberia dejar visible la ultima baja por explosion inestable." % scene_path
		)

		await create_timer(1.0).timeout
		await _cleanup_main(main)
	_finish()


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
