extends Node
class_name PlayerShellLoopValidationDriver

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const GAME_SHELL_SCENE = preload("res://scenes/shell/game_shell.tscn")

var _match_mode: MatchController.MatchMode = MatchController.MatchMode.TEAMS
var _started := false
var _completed := false


func configure(next_match_mode: MatchController.MatchMode) -> void:
	_match_mode = next_match_mode


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	if _started or _completed:
		return

	_started = true
	var host := get_parent()
	if host == null:
		push_error("La validacion QA integrada necesita un nodo host persistente.")
		_completed = true
		return

	var game_shell := GAME_SHELL_SCENE.instantiate()
	host.add_child(game_shell)
	await _await_frames(1)

	if game_shell == null or not game_shell.has_method("open_local_setup"):
		push_error("La validacion QA integrada deberia abrir GameShell antes de navegar el loop.")
		_completed = true
		return

	game_shell.call("open_local_setup")
	await _await_frames(1)

	var setup: Variant = game_shell.call("get_active_screen")
	if setup == null or not setup.has_method("build_launch_config"):
		push_error("La validacion QA integrada deberia exponer el setup local real.")
		_completed = true
		return

	if _match_mode == MatchController.MatchMode.FFA and setup.has_method("set_match_mode"):
		setup.call("set_match_mode", MatchController.MatchMode.FFA)
		await _await_frames(1)

	var launch_config: Variant = setup.call("build_launch_config")
	if not (launch_config is MatchLaunchConfig):
		push_error("La validacion QA integrada deberia construir un MatchLaunchConfig real.")
		_completed = true
		return

	var typed_launch_config := launch_config as MatchLaunchConfig
	typed_launch_config.auto_restart_on_match_end = false
	var match_scene: Variant = game_shell.call("build_local_match_scene", typed_launch_config)
	if match_scene == null or not (match_scene is Node):
		push_error("La validacion QA integrada deberia poder instanciar el match usando el wiring comun de GameShell.")
		_completed = true
		return

	host.remove_child(game_shell)
	game_shell.queue_free()
	host.add_child(match_scene)
	await _await_frames(1)

	var main := match_scene as Node
	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	if main == null or match_controller == null or robots.size() < 4:
		push_error("La validacion QA integrada deberia llegar a un match real con cuatro robots.")
		_completed = true
		return

	if match_controller.match_config != null:
		match_controller.match_config.rounds_to_win = 1
		if _match_mode == MatchController.MatchMode.FFA:
			match_controller.match_config.round_intro_duration_ffa = 0.0
		else:
			match_controller.match_config.round_intro_duration_teams = 0.0

	match_controller.start_match()
	await _await_frames(1)

	for robot in robots:
		robot.void_fall_y = -100.0

	force_m6_audiovisual_readability_state(main)
	await _await_frames(1)

	if _match_mode == MatchController.MatchMode.FFA:
		robots[0].fall_into_void()
		await _await_frames(1)
		robots[1].fall_into_void()
		await _await_frames(1)
		robots[2].fall_into_void()
	else:
		robots[2].fall_into_void()
		robots[3].fall_into_void()

	await _await_frames(2)
	if not match_controller.is_match_over():
		push_error("La validacion QA integrada deberia quedar detenida en cierre de match estable.")

	_completed = true


func _await_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func force_m6_audiovisual_readability_state(main: Node = null) -> void:
	var robots := _get_scene_robots(main)
	if robots.size() >= 2:
		var first_robot := robots[0] as RobotBase
		var second_robot := robots[1] as RobotBase
		if first_robot != null:
			first_robot.apply_damage_to_part("left_arm", 45.0)
			first_robot.set_energy_focus("right_leg")
			first_robot.activate_overdrive()
		if second_robot != null:
			second_robot.apply_damage_to_part("left_leg", 70.0)

	var arena := _get_scene_arena(main)
	if arena != null:
		arena.set_pressure_warning_strength(0.65)


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	if main == null:
		return robots

	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _get_scene_arena(main: Node) -> ArenaBase:
	if main == null:
		return null

	var arena_root := main.get_node_or_null("ArenaRoot")
	if arena_root == null:
		return null

	for child in arena_root.get_children():
		if child is ArenaBase:
			return child as ArenaBase

	return null
