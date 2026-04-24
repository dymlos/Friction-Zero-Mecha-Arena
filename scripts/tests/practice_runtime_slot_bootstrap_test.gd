extends SceneTree

const PRACTICE_SCENE := preload("res://scenes/practice/practice_mode.tscn")
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
	launch_config.configure_for_practice(
		"impacto",
		"res://scenes/practice/practice_mode.tscn",
		[
			{"slot": 1, "control_mode": RobotBase.ControlMode.EASY, "input_source": "keyboard", "keyboard_profile": RobotBase.KeyboardProfile.WASD_SPACE, "roster_entry_id": "aguja"},
			{"slot": 2, "control_mode": RobotBase.ControlMode.HARD, "input_source": "joypad", "device_id": 8, "device_connected": true, "roster_entry_id": "ancla"},
		]
	)
	shell_session.store_match_launch_config(launch_config)

	var practice = PRACTICE_SCENE.instantiate()
	root.add_child(practice)
	current_scene = practice
	await process_frame
	await process_frame

	_assert(String(practice.call("get_active_module_id")) == "impacto", "PracticeMode deberia conservar el modulo pedido.")
	_assert(
		int(practice.call("get_hud_detail_mode")) == MatchConfig.HudDetailMode.EXPLICIT,
		"PracticeMode debe arrancar en HUD explicito desde el contrato M8."
	)
	_assert(
		practice.has_method("get_active_module_hud_default"),
		"PracticeMode debe exponer el default HUD del modulo activo."
	)
	if practice.has_method("get_active_module_hud_default"):
		_assert(
			String(practice.call("get_active_module_hud_default")) == "explicito",
			"El modulo activo debe declarar HUD explicito por defecto."
		)
	_assert(practice.has_method("get_local_session"), "PracticeMode deberia exponer LocalSession para contratos runtime.")
	var session = practice.call("get_local_session") if practice.has_method("get_local_session") else null
	var robots := _get_scene_robots(practice)
	_assert(session != null, "PracticeMode deberia construir LocalSession desde launch_config.")
	_assert(robots.size() == 2, "PracticeMode deberia spawnear los slots activos de practica.")
	if session != null:
		_assert(String(session.get_slot_state(1)) == "keyboard", "P1 practica deberia quedar en teclado.")
		_assert(String(session.get_slot_roster_entry_id(1)) == "aguja", "P1 practica deberia conservar Aguja.")
		_assert(String(session.get_slot_state(2)) == "joypad", "P2 practica deberia quedar en joypad.")
		_assert(String(session.get_slot_roster_entry_id(2)) == "ancla", "P2 practica deberia conservar Ancla.")
		_assert(int(session.get_slot_device_id(2)) == 8, "P2 practica deberia conservar device_id.")
	if robots.size() == 2:
		_assert(robots[0].keyboard_profile == RobotBase.KeyboardProfile.WASD_SPACE, "Robot P1 practica deberia usar WASD.")
		_assert(robots[0].get_archetype_label() == "Aguja", "Robot P1 practica deberia recibir Aguja.")
		_assert(robots[1].joypad_device == 8, "Robot P2 practica deberia usar joypad.")
		_assert(robots[1].get_archetype_label() == "Ancla", "Robot P2 practica deberia recibir Ancla.")
		_assert(robots[1].keyboard_profile == RobotBase.KeyboardProfile.NONE, "Robot P2 practica no deberia leer teclado.")
		_assert(robots[1].control_mode == RobotBase.ControlMode.HARD, "Robot P2 practica deberia conservar Hard.")

	await _cleanup_current_scene()
	_finish()


func _get_scene_robots(practice: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := practice.get_node_or_null("RobotRoot")
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
