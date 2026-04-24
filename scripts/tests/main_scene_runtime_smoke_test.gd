extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const MatchHud = preload("res://scripts/ui/match_hud.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const SCENE_SPECS := [
	{
		"path": "res://scenes/main/main.tscn",
		"arena_name": "ArenaBlockout",
		"mode": MatchController.MatchMode.TEAMS,
		"expects_match_config": true,
		"requires_team_pairs": true,
		"requires_distinct_ffa": false,
	},
	{
		"path": "res://scenes/main/main_teams_validation.tscn",
		"arena_name": "ArenaTeamsValidation",
		"mode": MatchController.MatchMode.TEAMS,
		"expects_match_config": true,
		"requires_team_pairs": true,
		"requires_distinct_ffa": false,
	},
	{
		"path": "res://scenes/main/main_teams_large_validation.tscn",
		"arena_name": "ArenaTeamsLargeValidation",
		"mode": MatchController.MatchMode.TEAMS,
		"expects_match_config": true,
		"requires_team_pairs": true,
		"requires_distinct_ffa": false,
	},
	{
		"path": "res://scenes/main/main_teams_large.tscn",
		"arena_name": "ArenaTeamsLarge",
		"mode": MatchController.MatchMode.TEAMS,
		"expects_match_config": true,
		"expected_robot_count": 8,
		"requires_team_pairs": false,
		"requires_balanced_large_teams": true,
		"requires_distinct_ffa": false,
	},
	{
		"path": "res://scenes/main/main_ffa.tscn",
		"arena_name": "ArenaBlockout",
		"mode": MatchController.MatchMode.FFA,
		"expects_match_config": true,
		"requires_team_pairs": false,
		"requires_distinct_ffa": true,
	},
	{
		"path": "res://scenes/main/main_ffa_validation.tscn",
		"arena_name": "ArenaFFAValidation",
		"mode": MatchController.MatchMode.FFA,
		"expects_match_config": true,
		"requires_team_pairs": false,
		"requires_distinct_ffa": true,
	},
	{
		"path": "res://scenes/main/main_ffa_large_validation.tscn",
		"arena_name": "ArenaFFALargeValidation",
		"mode": MatchController.MatchMode.FFA,
		"expects_match_config": true,
		"requires_team_pairs": false,
		"requires_distinct_ffa": true,
	},
	{
		"path": "res://scenes/main/main_ffa_large.tscn",
		"arena_name": "ArenaFFALarge",
		"mode": MatchController.MatchMode.FFA,
		"expects_match_config": true,
		"expected_robot_count": 8,
		"requires_team_pairs": false,
		"requires_distinct_ffa": true,
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_spec in SCENE_SPECS:
		await _assert_main_scene_contract(scene_spec)

	_finish()


func _assert_main_scene_contract(scene_spec: Dictionary) -> void:
	var scene_path := String(scene_spec.get("path", ""))
	var packed_scene := load(scene_path)
	_assert(
		packed_scene is PackedScene,
		"La escena %s deberia cargarse como PackedScene." % scene_path
	)
	if not (packed_scene is PackedScene):
		return

	var main = (packed_scene as PackedScene).instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	_assert(main is Main, "La escena %s deberia instanciar Main para reutilizar el wiring comun." % scene_path)

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var hud := main.get_node_or_null("UI/MatchHud") as MatchHud
	var arena_name := String(scene_spec.get("arena_name", ""))
	var arena := main.get_node_or_null("ArenaRoot/%s" % arena_name) as ArenaBase
	var robots := _get_scene_robots(main)
	var expected_robot_count := int(scene_spec.get("expected_robot_count", 4))

	_assert(match_controller != null, "La escena %s deberia montar MatchController." % scene_path)
	_assert(hud != null, "La escena %s deberia montar MatchHud." % scene_path)
	_assert(arena != null, "La escena %s deberia usar el arena %s." % [scene_path, arena_name])
	_assert(robots.size() == expected_robot_count, "La escena %s deberia bootear con %s robots." % [scene_path, expected_robot_count])
	if match_controller == null or hud == null or arena == null or robots.size() != expected_robot_count:
		await _cleanup_main(main)
		return

	var expected_mode := int(scene_spec.get("mode", MatchController.MatchMode.TEAMS))
	_assert(
		match_controller.match_mode == expected_mode,
		"La escena %s deberia arrancar en el modo esperado." % scene_path
	)
	_assert(
		String(match_controller.get_round_status_line()).contains("Ronda 1"),
		"La escena %s deberia iniciar una partida real al bootear." % scene_path
	)
	_assert(
		not match_controller.get_round_state_lines().is_empty(),
		"La escena %s deberia publicar estado de ronda al iniciar." % scene_path
	)
	_assert(
		main.get_lab_scene_variant_summary_line().contains("Escena |"),
		"La escena %s deberia exponer el selector runtime de escenas del laboratorio." % scene_path
	)
	_assert(
		main.get_lab_selector_summary_line().contains("Lab |"),
		"La escena %s deberia exponer el selector runtime de slots/arquetipos." % scene_path
	)

	var match_config := match_controller.match_config
	var expects_match_config := bool(scene_spec.get("expects_match_config", false))
	_assert(
		(expects_match_config and match_config is MatchConfig) or (not expects_match_config and match_config == null),
		"La escena %s deberia respetar su contrato de MatchConfig." % scene_path
	)

	_assert(_all_robots_are_player_controlled(robots), "La escena %s deberia mantener control local en los cuatro slots." % scene_path)
	_assert(_has_unique_player_indices(robots), "La escena %s deberia mantener ownership unico por jugador." % scene_path)

	var requires_team_pairs := bool(scene_spec.get("requires_team_pairs", false))
	if requires_team_pairs:
		_assert(_uses_two_team_pairs(robots), "La escena %s deberia conservar las parejas 2v2 del laboratorio Teams." % scene_path)

	var requires_balanced_large_teams := bool(scene_spec.get("requires_balanced_large_teams", false))
	if requires_balanced_large_teams:
		_assert(_uses_balanced_large_teams(robots), "La escena %s deberia asignar P1/P3/P5/P7 vs P2/P4/P6/P8." % scene_path)

	var requires_distinct_ffa := bool(scene_spec.get("requires_distinct_ffa", false))
	if requires_distinct_ffa:
		_assert(_all_robots_are_ffa(robots), "La escena %s no deberia heredar alianzas del setup Teams." % scene_path)

	await _cleanup_main(main)


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _all_robots_are_player_controlled(robots: Array[RobotBase]) -> bool:
	for robot in robots:
		if not robot.is_player_controlled:
			return false

	return true


func _has_unique_player_indices(robots: Array[RobotBase]) -> bool:
	var seen_indices := {}
	for robot in robots:
		if robot.player_index <= 0:
			return false
		if seen_indices.has(robot.player_index):
			return false
		seen_indices[robot.player_index] = true

	return seen_indices.size() == robots.size()


func _uses_two_team_pairs(robots: Array[RobotBase]) -> bool:
	if robots.size() < 4:
		return false

	return (
		robots[0].team_id == robots[1].team_id
		and robots[2].team_id == robots[3].team_id
		and robots[0].team_id != robots[2].team_id
	)


func _uses_balanced_large_teams(robots: Array[RobotBase]) -> bool:
	if robots.size() != 8:
		return false
	for index in range(robots.size()):
		var expected_team := 1 if (index + 1) % 2 == 1 else 2
		if robots[index].team_id != expected_team:
			return false
	return true


func _all_robots_are_ffa(robots: Array[RobotBase]) -> bool:
	for robot in robots:
		if robot.team_id != 0:
			return false

	return true


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
