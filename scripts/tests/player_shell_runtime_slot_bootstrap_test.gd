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
			{"slot": 1, "control_mode": RobotBase.ControlMode.EASY, "input_source": "keyboard", "keyboard_profile": RobotBase.KeyboardProfile.WASD_SPACE, "roster_entry_id": "ancla"},
			{"slot": 2, "control_mode": RobotBase.ControlMode.HARD, "input_source": "joypad", "device_id": 45, "device_connected": true, "roster_entry_id": "aguja"},
			{"slot": 4, "control_mode": RobotBase.ControlMode.EASY, "input_source": "keyboard", "keyboard_profile": RobotBase.KeyboardProfile.IJKL},
		]
	)
	shell_session.store_match_launch_config(launch_config)

	var main = MAIN_FFA_SCENE.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var session = main.call("get_local_session")
	var robots := _get_scene_robots(main)
	_assert(session != null, "Main deberia construir LocalSession desde launch_config.")
	_assert(robots.size() >= 4, "La escena FFA deberia exponer robots suficientes para mapear slots.")
	if session != null:
		_assert(int(session.get_active_match_slots()) == 3, "Runtime deberia respetar la cantidad de slots activos de shell.")
		_assert(String(session.get_slot_state(1)) == "keyboard", "P1 deberia quedar como teclado.")
		_assert(String(session.get_slot_roster_entry_id(1)) == "ancla", "P1 deberia conservar Ancla desde shell.")
		_assert(String(session.get_slot_state(2)) == "joypad", "P2 deberia quedar como joypad.")
		_assert(String(session.get_slot_roster_entry_id(2)) == "aguja", "P2 deberia conservar Aguja desde shell.")
		_assert(int(session.get_slot_device_id(2)) == 45, "P2 deberia conservar el device_id de shell.")
		_assert(String(session.get_slot_state(4)) == "keyboard", "P4 deberia conservar su slot real aunque P3 no participe.")
	if robots.size() >= 4:
		_assert(robots[0].keyboard_profile == RobotBase.KeyboardProfile.WASD_SPACE, "Robot P1 deberia usar el teclado de P1.")
		_assert(robots[0].get_archetype_label() == "Ancla", "Robot P1 deberia recibir el arquetipo elegido en shell.")
		_assert(robots[1].joypad_device == 45, "Robot P2 deberia consumir el joypad de shell.")
		_assert(robots[1].get_archetype_label() == "Aguja", "Robot P2 deberia recibir el arquetipo elegido en shell.")
		_assert(robots[1].keyboard_profile == RobotBase.KeyboardProfile.NONE, "Robot P2 joypad no deberia leer teclado.")
		_assert(robots[1].control_mode == RobotBase.ControlMode.HARD, "Robot P2 deberia conservar Hard.")
		_assert(robots[2].is_player_controlled == false, "P3 no deberia quedar activo si shell no lo lanzo.")
		_assert(robots[3].is_player_controlled and robots[3].keyboard_profile == RobotBase.KeyboardProfile.IJKL, "P4 deberia poder participar sin depender de P3.")

	var disconnected_slot := int(main.call("sync_local_joypad_connection", 45, false))
	_assert(disconnected_slot == 2, "Hot-plug deberia seguir reconociendo el joypad reservado por shell.")
	var reconnect_slot := int(main.call("sync_local_joypad_connection", 45, true))
	_assert(reconnect_slot == 2, "El mismo device_id deberia recuperar P2 en runtime.")

	await _cleanup_current_scene()
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


func _cleanup_current_scene() -> void:
	if current_scene == null or not is_instance_valid(current_scene):
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
