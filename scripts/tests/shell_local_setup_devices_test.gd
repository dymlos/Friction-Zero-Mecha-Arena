extends SceneTree

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_shell := GAME_SHELL_SCENE.instantiate()
	root.add_child(game_shell)
	current_scene = game_shell
	await process_frame
	await process_frame

	game_shell.call("open_local_setup")
	await process_frame
	await process_frame

	var setup: Variant = game_shell.call("get_active_screen")
	_assert(setup != null, "GameShell deberia montar LocalMatchSetup.")
	if setup == null:
		await _cleanup_current_scene()
		_finish()
		return

	_assert(setup.has_method("set_slot_active"), "LocalMatchSetup deberia exponer activo/inactivo por slot.")
	_assert(setup.has_method("set_slot_input_source"), "LocalMatchSetup deberia exponer fuente keyboard/joypad.")
	_assert(setup.has_method("reserve_joypad_for_slot"), "LocalMatchSetup deberia poder reclamar un joypad para un slot.")
	_assert(setup.has_method("cycle_slot_roster_entry"), "LocalMatchSetup deberia permitir ciclar robot por slot.")
	_assert(setup.has_method("is_start_enabled"), "LocalMatchSetup deberia exponer si Iniciar esta habilitado.")
	_assert(setup.has_method("get_slot_summary_lines"), "LocalMatchSetup deberia exponer resumen legible de slots.")
	if _failed:
		await _cleanup_current_scene()
		_finish()
		return

	setup.call("set_slot_active", 3, false)
	setup.call("set_slot_active", 4, false)
	setup.call("set_slot_active", 5, true)
	setup.call("set_slot_input_source", 5, "joypad")
	setup.call("reserve_joypad_for_slot", 5, 15, true)
	setup.call("set_slot_control_mode", 2, RobotBase.ControlMode.HARD)
	setup.call("set_slot_input_source", 2, "joypad")
	setup.call("reserve_joypad_for_slot", 2, 12, true)
	await process_frame

	var lines: Array = setup.call("get_slot_summary_lines")
	_assert(lines.size() == 8, "Setup local deberia mantener P1-P8 visibles.")
	_assert(String(lines[0]).contains("P1") and String(lines[0]).contains("teclado"), "P1 deberia leerse como teclado.")
	_assert(String(lines[1]).contains("P2") and String(lines[1]).contains("joypad 12"), "P2 deberia mostrar joypad reclamado.")
	_assert(String(lines[1]).contains("Hard"), "P2 deberia conservar modo Hard visible.")
	_assert(String(lines[2]).contains("inactivo"), "P3 deberia quedar visible como inactivo.")
	_assert(String(lines[4]).contains("P5") and String(lines[4]).contains("Aguja"), "P5 deberia quedar visible con Aguja.")
	_assert(bool(setup.call("is_start_enabled")), "Iniciar deberia quedar habilitado con slots activos validos.")

	var launch_config = setup.call("build_launch_config")
	_assert(launch_config.local_slots.size() == 3, "Launch config deberia transportar solo slots activos.")
	_assert(String(launch_config.local_slots[1].get("input_source", "")) == "joypad", "Launch config deberia conservar input_source.")
	_assert(int(launch_config.local_slots[1].get("device_id", -1)) == 12, "Launch config deberia conservar device_id.")
	_assert(int(launch_config.local_slots[1].get("keyboard_profile", -2)) == RobotBase.KeyboardProfile.NONE, "Joypad no deberia arrastrar perfil de teclado.")
	_assert(String(launch_config.local_slots[2].get("roster_entry_id", "")) == "aguja", "Launch config deberia conservar robot de P5.")

	setup.call("reserve_joypad_for_slot", 2, 12, false)
	await process_frame
	_assert(not bool(setup.call("is_start_enabled")), "Iniciar deberia deshabilitarse con joypad reservado/desconectado.")
	lines = setup.call("get_slot_summary_lines")
	_assert(String(lines[1]).contains("desconectado"), "El slot reservado deberia exponer desconexion visible.")

	await _cleanup_current_scene()
	_finish()


func _cleanup_current_scene() -> void:
	if current_scene == null or not is_instance_valid(current_scene):
		return

	var scene := current_scene
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
