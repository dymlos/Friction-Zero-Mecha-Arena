extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const SCENE_SPECS := [
	{
		"path": "res://scenes/main/main.tscn",
		"arena_path": "ArenaRoot/ArenaBlockout",
		"label": "Teams base",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"path": "res://scenes/main/main_teams_validation.tscn",
		"arena_path": "ArenaRoot/ArenaTeamsValidation",
		"label": "Teams rapido",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"path": "res://scenes/main/main_ffa.tscn",
		"arena_path": "ArenaRoot/ArenaBlockout",
		"label": "FFA base",
		"mode": MatchController.MatchMode.FFA,
	},
	{
		"path": "res://scenes/main/main_ffa_validation.tscn",
		"arena_path": "ArenaRoot/ArenaFFAValidation",
		"label": "FFA rapido",
		"mode": MatchController.MatchMode.FFA,
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_spec in SCENE_SPECS:
		await _assert_space_reduction_scene_contract(scene_spec)
	_finish()


func _assert_space_reduction_scene_contract(scene_spec: Dictionary) -> void:
	var scene_path := String(scene_spec.get("path", ""))
	var label := String(scene_spec.get("label", scene_path))
	var arena_path := String(scene_spec.get("arena_path", ""))
	var expected_mode := int(scene_spec.get("mode", MatchController.MatchMode.TEAMS))
	var packed_scene := load(scene_path)
	_assert(
		packed_scene is PackedScene,
		"La escena %s deberia cargarse para validar la presion de arena." % label
	)
	if not (packed_scene is PackedScene):
		return

	var main := (packed_scene as PackedScene).instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
		if match_controller_preload.match_config != null:
			match_controller_preload.match_config.round_intro_duration_teams = 0.0
			match_controller_preload.match_config.round_intro_duration_ffa = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var arena := main.get_node_or_null(arena_path) as ArenaBase
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena %s deberia exponer MatchController." % label)
	_assert(arena != null, "La escena %s deberia exponer su arena activa." % label)
	_assert(robots.size() >= 4, "La escena %s deberia ofrecer cuatro robots para validar la presion de arena." % label)
	if match_controller == null or arena == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	_assert(
		match_controller.match_mode == expected_mode,
		"La escena %s deberia mantener el modo esperado durante la prueba de presion." % label
	)
	match_controller.round_reset_delay = 0.15
	match_controller.match_config.rounds_to_win = 3
	match_controller.match_config.round_time_seconds = 1.0
	match_controller.match_config.progressive_space_reduction = true
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.space_reduction_warning_seconds = 0.2
	match_controller.space_reduction_start_ratio = 0.25
	match_controller.space_reduction_min_scale = 0.5
	match_controller.start_match()

	for robot in robots:
		robot.void_fall_y = -100.0

	var initial_size := arena.get_safe_play_area_size()
	await create_timer(0.12).timeout
	await process_frame

	_assert(
		match_controller.get_round_state_lines().any(func(line: String) -> bool: return line.contains("Arena se cierra en")),
		"La escena %s deberia avisar en HUD un instante antes de que empiece la contraccion real." % label
	)
	await create_timer(0.45).timeout
	await process_frame

	var shrunken_size := arena.get_safe_play_area_size()
	_assert(
		shrunken_size.x < initial_size.x and shrunken_size.y < initial_size.y,
		"La escena %s deberia reducir el area segura cuando la presion progresiva esta activa." % label
	)
	_assert(
		match_controller.get_round_state_lines().any(func(line: String) -> bool: return line.contains("Arena")),
		"La escena %s deberia informar en HUD cuando la arena empieza a cerrarse." % label
	)

	await _force_round_reset_closure(match_controller, robots)
	await create_timer(match_controller.round_reset_delay + 0.15).timeout
	await process_frame

	var reset_size := arena.get_safe_play_area_size()
	_assert(
		reset_size.is_equal_approx(initial_size),
		"La escena %s deberia restaurar el tamano completo del arena tras el reset comun de ronda." % label
	)

	await create_timer(0.8).timeout
	await _cleanup_main(main)


func _force_round_reset_closure(match_controller: MatchController, robots: Array[RobotBase]) -> void:
	if match_controller == null:
		return

	var elimination_count := 2
	if match_controller.match_mode == MatchController.MatchMode.FFA:
		elimination_count = max(robots.size() - 1, 0)

	for index in range(min(elimination_count, robots.size())):
		robots[robots.size() - 1 - index].fall_into_void()
		await create_timer(0.05).timeout


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
