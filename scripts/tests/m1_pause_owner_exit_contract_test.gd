extends SceneTree

const MAIN_FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var shell_session := ShellSession.new()
	shell_session.store_match_launch_config(null)

	var launch_config := MatchLaunchConfig.new()
	launch_config.configure_for_local_match(
		MatchController.MatchMode.FFA,
		"res://scenes/main/main_ffa.tscn",
		[
			{"slot": 1, "control_mode": RobotBase.ControlMode.EASY, "input_source": "keyboard", "keyboard_profile": RobotBase.KeyboardProfile.WASD_SPACE},
			{"slot": 2, "control_mode": RobotBase.ControlMode.HARD, "input_source": "keyboard", "keyboard_profile": RobotBase.KeyboardProfile.ARROWS_ENTER}
		]
	)
	shell_session.store_match_launch_config(launch_config)

	var main := MAIN_FFA_SCENE.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController")
	_assert(match_controller != null, "MatchController debe existir.")
	_assert(bool(main.call("request_pause_for_slot", 2)), "P2 debe poder pausar si ocupa slot.")
	_assert(paused, "La pausa debe pausar el SceneTree.")
	_assert(int(match_controller.call("get_pause_owner_slot")) == 2, "P2 debe quedar como pause owner.")

	_assert(not bool(main.call("move_pause_menu_selection_for_slot", 1, 1)), "No-owner no debe mover la pausa.")
	_assert(not bool(main.call("select_pause_action_for_slot", 1, "return_to_menu")), "No-owner no debe elegir salida.")
	_assert(String(main.call("activate_pause_menu_selection_for_slot", 1)) == "", "No-owner no debe activar acciones.")
	_assert(not bool(main.call("request_resume_for_slot", 1)), "No-owner no debe reanudar.")
	_assert(paused, "La pausa debe seguir activa tras input no-owner.")

	var before_mode := int(match_controller.match_mode)
	var before_slot_1_mode := _get_robot_control_mode(main, 1)
	var before_slot_2_mode := _get_robot_control_mode(main, 2)

	_assert(bool(main.call("select_pause_action_for_slot", 2, "return_to_menu")), "Owner debe poder elegir salida.")
	var first_action := String(main.call("activate_pause_menu_selection_for_slot", 2))
	_assert(first_action == "confirm_return_to_menu", "Primera activacion debe pedir confirmacion.")
	_assert(paused, "Confirmacion no debe salir todavia.")
	_assert(int(match_controller.match_mode) == before_mode, "Confirmacion no debe cambiar modo.")
	_assert(_get_robot_control_mode(main, 1) == before_slot_1_mode, "Confirmacion no debe reasignar P1.")
	_assert(_get_robot_control_mode(main, 2) == before_slot_2_mode, "Confirmacion no debe reasignar P2.")

	var second_action := String(main.call("activate_pause_menu_selection_for_slot", 2))
	_assert(second_action == "return_to_menu", "Segunda activacion confirma salida inmediata.")
	await process_frame
	await process_frame
	_assert(current_scene != null, "La salida debe dejar una escena activa.")
	if current_scene != null:
		_assert(String(current_scene.scene_file_path) == "res://scenes/shell/game_shell.tscn", "Salida desde pausa debe volver a shell.")
		_assert(current_scene.has_method("get_active_screen_id") and String(current_scene.call("get_active_screen_id")) == "main_menu", "Shell debe abrir menu principal.")

	await _cleanup_current_scene()
	_finish()


func _get_robot_control_mode(main: Node, player_slot: int) -> int:
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return -1
	for child in robot_root.get_children():
		if child is RobotBase and int(child.player_index) == player_slot:
			return int(child.control_mode)
	return -1


func _cleanup_current_scene() -> void:
	if current_scene == null or not is_instance_valid(current_scene):
		paused = false
		return
	var scene := current_scene
	var parent := scene.get_parent()
	if parent != null:
		parent.remove_child(scene)
	scene.free()
	current_scene = null
	paused = false
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
