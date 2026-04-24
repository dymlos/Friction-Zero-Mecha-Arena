extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const SCENE_SPECS := [
	{
		"label": "Teams base",
		"path": "res://scenes/main/main.tscn",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"label": "Teams validation",
		"path": "res://scenes/main/main_teams_validation.tscn",
		"mode": MatchController.MatchMode.TEAMS,
	},
	{
		"label": "FFA base",
		"path": "res://scenes/main/main_ffa.tscn",
		"mode": MatchController.MatchMode.FFA,
	},
	{
		"label": "FFA validation",
		"path": "res://scenes/main/main_ffa_validation.tscn",
		"mode": MatchController.MatchMode.FFA,
	},
]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_spec in SCENE_SPECS:
		await _assert_post_match_event_capture(scene_spec)
	_finish()


func _assert_post_match_event_capture(scene_spec: Dictionary) -> void:
	var label := String(scene_spec.get("label", "Escena"))
	var scene_path := String(scene_spec.get("path", ""))
	var test_mode := int(scene_spec.get("mode", MatchController.MatchMode.TEAMS))
	var main := await _instantiate_scene(scene_path)
	if main == null:
		return

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "%s deberia exponer MatchController." % label)
	_assert(robots.size() >= 4, "%s deberia ofrecer cuatro robots para cerrar el match." % label)
	if match_controller == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = test_mode
	_assert(match_controller.match_config != null, "%s deberia cargar MatchConfig." % label)
	if match_controller.match_config == null:
		await _cleanup_main(main)
		return

	match_controller.match_config.rounds_to_win = 1
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.match_config.round_intro_duration_teams = 0.0
	match_controller.round_intro_duration = 0.0
	match_controller.round_reset_delay = 0.1
	match_controller.match_restart_delay = 0.2
	match_controller.start_match()
	await process_frame

	for index in range(robots.size()):
		robots[index].void_fall_y = -100.0
		robots[index].global_position = Vector3(5.0 + float(index), 0.0, 0.0)

	if test_mode == MatchController.MatchMode.FFA:
		match_controller.record_support_payload_use(robots[0], "interference", robots[1])
		robots[1].fall_into_void()
		robots[2].fall_into_void()
		robots[3].fall_into_void()
	else:
		match_controller.record_ffa_aftermath_collection(robots[0], "impulso", robots[1].get_roster_display_name(), "borde oeste")
		robots[2].fall_into_void()
		robots[3].fall_into_void()

	await create_timer(0.08).timeout

	_assert(match_controller.is_match_over(), "%s deberia cerrar el match por void." % label)
	var story_lines := match_controller.call("get_post_match_review_lines") as Array
	var snippet_lines := match_controller.call("get_post_match_snippet_lines") as Array
	var summary := match_controller.call("get_post_match_review_summary") as Dictionary
	_assert(not story_lines.is_empty(), "%s deberia producir lectura post-match." % label)
	_assert(_has_line_containing(story_lines, "Lectura |"), "%s deberia incluir una linea Lectura." % label)
	_assert(not snippet_lines.is_empty(), "%s deberia producir snippets post-match." % label)
	_assert(_has_line_containing(snippet_lines, "Replay |"), "%s deberia incluir snippets Replay." % label)
	_assert(_has_line_containing(snippet_lines, "borde") or _has_line_containing(snippet_lines, "centro"), "%s deberia incluir zona de arena en el replay." % label)
	_assert(summary.has("story"), "%s deberia exponer resumen estructurado." % label)
	if test_mode == MatchController.MatchMode.FFA:
		_assert(
			_has_line_containing(story_lines, "FFA") or _has_line_containing(story_lines, "Posiciones") or _has_line_containing(story_lines, "desempate"),
			"%s deberia enfocar FFA en supervivencia, posiciones o desempate." % label
		)
		_assert(not _has_line_containing(snippet_lines, "apoyo"), "%s no deberia serializar eventos de soporte en FFA." % label)
		_assert(not _has_line_containing(story_lines, "Apoyo activo"), "%s no deberia mostrar apoyo activo en FFA." % label)
	else:
		_assert(_has_line_containing(story_lines, "Equipo"), "%s deberia enfocar Teams en equipos." % label)
		_assert(not _has_line_containing(snippet_lines, "botin"), "%s no deberia serializar aftermath FFA en Teams." % label)
		_assert(not _has_line_containing(story_lines, "Oportunidad |"), "%s no deberia mostrar oportunidad FFA en Teams." % label)

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


func _has_line_containing(lines: Array, expected_fragment: String) -> bool:
	for line in lines:
		if str(line).contains(expected_fragment):
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
