extends SceneTree

const FFA_SCENE_PATHS := [
	"res://scenes/main/main_ffa.tscn",
	"res://scenes/main/main_ffa_validation.tscn",
]
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in FFA_SCENE_PATHS:
		await _assert_draw_recap_contract(scene_path)

	_finish()


func _assert_draw_recap_contract(scene_path: String) -> void:
	var packed_scene := load(scene_path)
	_assert(packed_scene is PackedScene, "La escena %s deberia seguir existiendo." % scene_path)
	if not (packed_scene is PackedScene):
		return

	var main := (packed_scene as PackedScene).instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var recap_panel := main.get_node_or_null("UI/MatchHud/Root/RecapPanel") as Control
	var recap_label := main.get_node_or_null("UI/MatchHud/Root/RecapPanel/Margin/RecapVBox/RecapScroll/RecapLabel") as Label
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena %s deberia exponer MatchController." % scene_path)
	_assert(recap_panel != null, "La escena %s deberia exponer el recap de ronda." % scene_path)
	_assert(recap_label != null, "La escena %s deberia exponer un bloque de detalle legible." % scene_path)
	_assert(robots.size() >= 4, "La escena %s deberia ofrecer cuatro robots para forzar una ronda sin ganador." % scene_path)
	if match_controller == null or recap_panel == null or recap_label == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	match_controller.match_mode = MatchController.MatchMode.FFA
	match_controller.round_reset_delay = 0.3
	match_controller.round_intro_duration = 0.0
	if match_controller.match_config != null:
		match_controller.match_config.round_intro_duration_ffa = 0.0

	match_controller._finish_round_draw()

	await create_timer(0.08).timeout

	_assert(not match_controller.is_round_active(), "La ronda deberia cerrarse si todos los robots caen al vacio.")
	_assert(
		match_controller.get_round_status_line().contains("sin ganador"),
		"El estado visible deberia dejar claro que la ronda termino sin ganador."
	)
	_assert(recap_panel.visible, "Incluso una ronda sin ganador deberia seguir mostrando recap entre rondas.")
	_assert(
		_has_line(match_controller.get_round_recap_panel_lines(), "Cierre ronda | sin ganador (+0)"),
		"El recap entre rondas deberia explicar explicitamente que un empate no otorgo puntos ni cerro por causa."
	)
	_assert(
		recap_label.text.contains("Cierre ronda | sin ganador (+0)"),
		"El recap visible deberia repetir que la ronda termino sin puntos."
	)

	await _cleanup_main(main)


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
