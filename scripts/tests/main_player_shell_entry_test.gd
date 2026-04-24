extends SceneTree

const MAIN_FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var shell_session := ShellSession.new()
	var launch_config := MatchLaunchConfig.new()
	_assert(
		_has_property(launch_config, "hud_detail_mode"),
		"MatchLaunchConfig deberia transportar tambien el modo HUD elegido para el match."
	)
	if not _has_property(launch_config, "hud_detail_mode"):
		_finish()
		return

	launch_config.configure_for_local_match(
		MatchController.MatchMode.FFA,
		"res://scenes/main/main_ffa.tscn",
		[
			{"slot": 1, "control_mode": RobotBase.ControlMode.EASY},
			{"slot": 2, "control_mode": RobotBase.ControlMode.HARD},
		]
	)
	launch_config.set("hud_detail_mode", MatchConfig.HudDetailMode.CONTEXTUAL)
	shell_session.store_match_launch_config(launch_config)

	var main = MAIN_FFA_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var status_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/StatusLabel") as Label
	var round_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	var robots := _get_scene_robots(main)

	_assert(match_controller != null, "La escena FFA deberia seguir exponiendo MatchController.")
	_assert(status_label != null, "La escena FFA deberia seguir exponiendo StatusLabel.")
	_assert(round_label != null, "La escena FFA deberia seguir exponiendo RoundLabel.")
	_assert(robots.size() >= 4, "La escena FFA deberia seguir teniendo suficientes robots para validar el arranque desde shell.")
	if match_controller == null or status_label == null or round_label == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	_assert(
		String(main.get("entry_context")) == MatchLaunchConfig.ENTRY_CONTEXT_PLAYER_SHELL,
		"`Main` deberia entrar en contexto `player_shell` al consumir un launch config pendiente."
	)
	_assert(
		not bool(main.get("lab_runtime_selector_enabled")),
		"Al arrancar desde shell, `Main` no deberia dejar activo el selector runtime del laboratorio."
	)
	_assert(
		match_controller.match_mode == MatchController.MatchMode.FFA,
		"El launch config pendiente deberia poder fijar el modo FFA antes de arrancar el match."
	)
	_assert(
		match_controller.get_runtime_hud_detail_mode() == MatchConfig.HudDetailMode.CONTEXTUAL,
		"El launch config pendiente deberia poder fijar el HUD runtime antes de poblar el HUD."
	)
	_assert(
		not status_label.text.contains("F1"),
		"El status HUD de player shell no deberia anunciar toggles de laboratorio."
	)
	_assert(
		not round_label.text.contains("Lab |"),
		"El HUD de player shell no deberia mostrar metadata del selector runtime."
	)
	_assert(
		not round_label.text.contains("Escena |"),
		"El HUD de player shell no deberia exponer el ciclo de escenas del laboratorio."
	)
	_assert(
		not round_label.text.contains("HUD |"),
		"El HUD de player shell no deberia mostrar prompts de F1 propios del laboratorio."
	)
	_assert(
		not round_label.text.contains("Control P"),
		"El HUD de player shell no deberia mostrar el selector interno del laboratorio."
	)

	_assert(robots[0].is_player_controlled, "P1 deberia seguir ocupado al arrancar desde shell.")
	_assert(robots[1].is_player_controlled, "P2 deberia seguir ocupado al arrancar desde shell.")
	_assert(
		not robots[2].is_player_controlled and not robots[3].is_player_controlled,
		"Los slots no configurados en shell no deberian activarse por default al entrar al match."
	)
	_assert(
		robots[0].control_mode == RobotBase.ControlMode.EASY,
		"El slot 1 deberia conservar el modo Easy elegido en setup."
	)
	_assert(
		robots[1].control_mode == RobotBase.ControlMode.HARD,
		"El slot 2 deberia conservar el modo Hard elegido en setup."
	)

	await _cleanup_main(main)

	var default_shell_session := ShellSession.new()
	var default_launch_config := MatchLaunchConfig.new()
	default_launch_config.configure_for_local_match(
		MatchController.MatchMode.FFA,
		"res://scenes/main/main_ffa.tscn",
		[
			{"slot": 1, "control_mode": RobotBase.ControlMode.EASY},
			{"slot": 2, "control_mode": RobotBase.ControlMode.HARD},
		]
	)
	default_shell_session.store_match_launch_config(default_launch_config)

	var default_main = MAIN_FFA_SCENE.instantiate()
	root.add_child(default_main)
	await process_frame
	await process_frame

	var default_match_controller := default_main.get_node_or_null("Systems/MatchController") as MatchController
	var default_round_label := default_main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RoundLabel") as Label
	_assert(default_match_controller != null, "La escena FFA deberia exponer MatchController en arranque default.")
	_assert(default_round_label != null, "La escena FFA deberia exponer RoundLabel en arranque default.")
	if default_match_controller != null and default_round_label != null:
		_assert(
			default_match_controller.get_runtime_hud_detail_mode() == MatchConfig.HudDetailMode.CONTEXTUAL,
			"Un match local lanzado desde shell sin override deberia arrancar con HUD contextual."
		)
		_assert(
			not default_round_label.text.contains("Modo |"),
			"El HUD contextual competitivo no deberia mostrar la linea explicita de modo."
		)
		_assert(
			not default_round_label.text.contains("HUD |"),
			"El HUD contextual competitivo no deberia mostrar prompts explicitos de HUD."
		)
		_assert(
			not default_round_label.text.contains("Lab |"),
			"El HUD contextual competitivo no deberia mostrar metadata de laboratorio."
		)
		_assert(
			not default_round_label.text.contains("Control P"),
			"El HUD contextual competitivo no deberia mostrar selector interno de laboratorio."
		)

	await _cleanup_main(default_main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false

	for property_info in target.get_property_list():
		if String(property_info.get("name", "")) == property_name:
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
