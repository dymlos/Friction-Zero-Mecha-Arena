extends SceneTree

const PRACTICE_MODE_SCENE := preload("res://scenes/practice/practice_mode.tscn")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _assert_practice_bootstrap(
		[
			{"slot": 1, "control_mode": RobotBase.ControlMode.EASY},
		],
		1
	)
	await _assert_practice_bootstrap(
		[
			{"slot": 1, "control_mode": RobotBase.ControlMode.EASY},
			{"slot": 2, "control_mode": RobotBase.ControlMode.HARD},
		],
		2
	)
	await _assert_practice_bootstrap(
		[
			{"slot": 1, "control_mode": RobotBase.ControlMode.EASY},
			{"slot": 2, "control_mode": RobotBase.ControlMode.HARD},
			{"slot": 3, "control_mode": RobotBase.ControlMode.EASY},
		],
		2
	)
	_finish()


func _assert_practice_bootstrap(slot_specs: Array, expected_players: int) -> void:
	var shell_session := ShellSession.new()
	var launch_config := MatchLaunchConfig.new()
	launch_config.configure_for_practice(
		"movimiento",
		"res://scenes/practice/practice_mode.tscn",
		slot_specs
	)
	shell_session.store_match_launch_config(launch_config)

	var practice_mode := PRACTICE_MODE_SCENE.instantiate()
	root.add_child(practice_mode)
	current_scene = practice_mode

	await process_frame
	await process_frame

	var robot_root := practice_mode.get_node_or_null("RobotRoot")
	var fixture_root := practice_mode.get_node_or_null("FixtureRoot")
	var practice_hud := practice_mode.get_node_or_null("UI/PracticeHud")
	var robots := _get_scene_robots(robot_root)

	_assert(
		str(practice_mode.get("entry_context")) == MatchLaunchConfig.ENTRY_CONTEXT_PRACTICE,
		"PracticeMode deberia entrar en contexto `practice`."
	)
	_assert(
		practice_mode.has_method("get_active_module_id"),
		"PracticeMode deberia exponer el modulo activo."
	)
	_assert(
		practice_mode.has_method("request_module_restart"),
		"PracticeMode deberia exponer reinicio rapido del modulo."
	)
	_assert(
		practice_mode.has_method("return_to_menu"),
		"PracticeMode deberia poder volver a la shell sin pasar por el laboratorio."
	)
	_assert(
		practice_mode.has_method("get_hud_detail_mode"),
		"PracticeMode deberia exponer modo de HUD para contrato de practica."
	)
	if practice_mode.has_method("get_hud_detail_mode"):
		_assert(
			int(practice_mode.call("get_hud_detail_mode")) == MatchConfig.HudDetailMode.EXPLICIT,
			"PracticeMode deberia quedar en ayuda visible por defecto."
		)
	_assert(
		String(practice_mode.call("get_active_module_id")) == "movimiento",
		"PracticeMode deberia consumir `practice_module_id` desde ShellSession."
	)
	_assert(robot_root != null, "PracticeMode deberia exponer RobotRoot.")
	_assert(fixture_root != null, "PracticeMode deberia exponer FixtureRoot separado.")
	_assert(practice_hud != null, "PracticeMode deberia exponer PracticeHud.")
	if practice_hud != null:
		_assert(
			practice_hud.has_method("is_explicit_layout") and bool(practice_hud.call("is_explicit_layout")),
			"PracticeHud deberia declararse explicito en practica."
		)
	_assert(
		robots.size() == expected_players,
		"PracticeMode deberia instanciar solo los robots jugables pedidos por launch config."
	)

	for index in range(robots.size()):
		var robot := robots[index]
		_assert(robot.is_player_controlled, "Los robots de practica deberian quedar controlados localmente.")
		_assert(
			robot.player_index == index + 1,
			"PracticeMode deberia conservar indices de jugador estables."
		)

	_assert(
		practice_mode.get_node_or_null("UI/MatchHud") == null,
		"PracticeMode no deberia instanciar MatchHud competitivo."
	)
	_assert(
		not practice_mode.has_method("cycle_lab_scene_variant"),
		"PracticeMode no deberia filtrar APIs del laboratorio."
	)

	await _cleanup_scene(practice_mode)


func _get_scene_robots(robot_root: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _cleanup_scene(scene: Node) -> void:
	if not is_instance_valid(scene):
		return

	var parent := scene.get_parent()
	if parent != null:
		parent.remove_child(scene)
	scene.free()
	current_scene = null
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
