extends SceneTree

const MAIN_FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const LocalSessionDraft = preload("res://scripts/systems/local_session_draft.gd")
const LocalSessionBuilder = preload("res://scripts/systems/local_session_builder.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	ShellSession.new().store_match_launch_config(null)
	await _assert_draft_and_builder_modes()
	await _assert_runtime_launch_modes()
	_finish()


func _assert_draft_and_builder_modes() -> void:
	var draft := LocalSessionDraft.new()
	draft.configure(8)
	draft.set_slot_active(1, true)
	draft.set_slot_control_mode(1, RobotBase.ControlMode.EASY)
	draft.set_slot_active(2, true)
	draft.set_slot_control_mode(2, RobotBase.ControlMode.HARD)
	draft.set_slot_active(3, false)
	draft.reserve_joypad_for_slot(4, 44, true)
	draft.set_slot_control_mode(4, RobotBase.ControlMode.HARD)

	var specs := draft.build_active_slot_specs(4)
	_assert(specs.size() == 3, "El builder debe transportar solo slots activos launchables dentro del limite 4.")
	_assert(int(specs[0].get("control_mode", -1)) == RobotBase.ControlMode.EASY, "P1 debe salir Easy.")
	_assert(int(specs[1].get("control_mode", -1)) == RobotBase.ControlMode.HARD, "P2 debe salir Hard.")
	_assert(int(specs[2].get("slot", -1)) == 4, "P4 joypad debe conservar su slot.")
	_assert(int(specs[2].get("control_mode", -1)) == RobotBase.ControlMode.HARD, "P4 joypad debe conservar Hard.")

	var session := LocalSessionBuilder.build_from_slot_specs(specs)
	_assert(session.get_active_match_slots() == 3, "LocalSession debe reflejar los tres slots activos.")
	_assert(session.get_slot_control_mode(1) == RobotBase.ControlMode.EASY, "LocalSession P1 debe ser Easy.")
	_assert(session.get_slot_control_mode(2) == RobotBase.ControlMode.HARD, "LocalSession P2 debe ser Hard.")
	_assert(session.get_slot_control_mode(4) == RobotBase.ControlMode.HARD, "LocalSession P4 debe ser Hard.")
	_assert(session.get_slot_device_id(4) == 44, "LocalSession P4 debe conservar device_id.")


func _assert_runtime_launch_modes() -> void:
	var shell_session := ShellSession.new()
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

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 2, "La escena FFA base debe montar al menos dos robots.")
	if robots.size() >= 2:
		_assert(robots[0].control_mode == RobotBase.ControlMode.EASY, "P1 runtime debe quedar Easy.")
		_assert(robots[1].control_mode == RobotBase.ControlMode.HARD, "P2 runtime debe quedar Hard.")
		_assert(robots[0].get_control_reference_hint().contains("mueve"), "Easy debe tener hint operativo.")
		_assert(robots[1].get_control_reference_hint().contains("aim"), "Hard debe exponer aim separado.")

	await _cleanup_current_scene()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)
	return robots


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
