extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(shell)
	await process_frame
	await process_frame
	shell.call("open_local_setup")
	await process_frame

	var setup = shell.call("get_active_screen")
	setup.call("set_match_mode", MatchController.MatchMode.FFA)
	setup.call("cycle_mode_variant")
	var launch_config = setup.call("build_launch_config")
	_assert(String(launch_config.mode_variant_id) == MatchModeVariantCatalog.VARIANT_LAST_ALIVE, "Shell debe lanzar last_alive desde variante FFA.")
	launch_config.hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT

	var main := shell.call("build_local_match_scene", launch_config) as Node
	root.add_child(main)
	await process_frame
	await process_frame

	var match_controller := main.get_node("Systems/MatchController") as MatchController
	_assert(match_controller.get_mode_variant_id() == MatchModeVariantCatalog.VARIANT_LAST_ALIVE, "Runtime debe recibir last_alive.")
	_assert(_has_line_with_fragment(match_controller.get_round_state_lines(), "Modo | FFA | Ultimo vivo"), "HUD debe leer variante.")

	await _cleanup_node(main)
	await _cleanup_node(shell)
	_finish()


func _has_line_with_fragment(lines: Array[String], fragment: String) -> bool:
	for line in lines:
		if line.contains(fragment):
			return true
	return false


func _cleanup_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
