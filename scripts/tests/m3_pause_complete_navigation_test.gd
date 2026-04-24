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
			{"slot": 1, "control_mode": RobotBase.ControlMode.EASY, "input_source": "keyboard", "keyboard_profile": RobotBase.KeyboardProfile.WASD_SPACE, "roster_entry_id": "ariete"},
			{"slot": 2, "control_mode": RobotBase.ControlMode.HARD, "input_source": "keyboard", "keyboard_profile": RobotBase.KeyboardProfile.ARROWS_ENTER, "roster_entry_id": "aguja"},
		]
	)
	shell_session.store_match_launch_config(launch_config)

	var main = MAIN_FFA_SCENE.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	_assert(main.has_method("get_active_pause_surface_id"), "Main deberia exponer superficie de pausa activa.")
	_assert(main.has_method("close_active_pause_surface_for_slot"), "Main deberia cerrar superficies de pausa por owner.")
	if not (main.has_method("get_active_pause_surface_id") and main.has_method("close_active_pause_surface_for_slot")):
		await _cleanup_current_scene()
		_finish()
		return

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	_assert(match_controller != null, "Main deberia conservar MatchController.")
	if match_controller == null:
		await _cleanup_current_scene()
		_finish()
		return

	var initial_mode := match_controller.match_mode
	var initial_session_snapshot := _get_session_snapshot(main)
	_assert(
		initial_session_snapshot.size() == 2,
		"La fixture deberia arrancar con P1/P2 desde ShellSession."
	)

	_assert(bool(main.call("request_pause_for_slot", 1)), "P1 deberia poder abrir pausa completa.")
	_assert(paused, "Abrir pausa completa deberia congelar el arbol.")

	for surface_id in ["settings", "how_to_play", "characters"]:
		_assert(
			bool(main.call("select_pause_action_for_slot", 1, surface_id)),
			"P1 deberia poder seleccionar %s desde pausa." % surface_id
		)
		_assert(
			String(main.call("activate_pause_menu_selection_for_slot", 1)) == surface_id,
			"Activar %s deberia devolver su action id." % surface_id
		)
		await process_frame
		await process_frame
		_assert(
			String(main.call("get_active_pause_surface_id")) == surface_id,
			"%s deberia quedar montada como superficie activa." % surface_id
		)
		_assert(paused, "%s no deberia despausar el match." % surface_id)
		_assert(
			match_controller.match_mode == initial_mode,
			"%s no deberia cambiar el modo de match." % surface_id
		)
		_assert(
			_get_session_snapshot(main) == initial_session_snapshot,
			"%s no deberia cambiar control/input/roster de P1/P2." % surface_id
		)
		_assert(
			not bool(main.call("close_active_pause_surface_for_slot", 2)),
			"Un no-owner no deberia cerrar %s." % surface_id
		)
		_assert(
			bool(main.call("close_active_pause_surface_for_slot", 1)),
			"El owner deberia cerrar %s." % surface_id
		)
		await process_frame
		_assert(
			String(main.call("get_active_pause_surface_id")) == "",
			"Cerrar %s deberia limpiar la superficie activa." % surface_id
		)
		_assert(paused, "Cerrar %s deberia volver al menu de pausa sin reanudar." % surface_id)

	var pause_lines := "\n".join(PackedStringArray(main.call("get_pause_overlay_lines")))
	_assert(pause_lines.contains("Reanudar"), "Tras cerrar superficie, el overlay de pausa deberia volver a listar Reanudar.")
	_assert(bool(main.call("request_resume_for_slot", 1)), "El owner deberia poder reanudar tras cerrar superficies.")
	_assert(not paused, "Reanudar deberia limpiar pausa.")

	await _cleanup_current_scene()
	_finish()


func _get_session_snapshot(main: Node) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	var local_session = main.call("get_local_session")
	if local_session == null:
		return snapshot
	for slot in [1, 2]:
		snapshot.append({
			"slot": slot,
			"control_mode": int(local_session.call("get_slot_control_mode", slot)),
			"input_source": String(local_session.call("get_slot_state", slot)),
			"roster": String(local_session.call("get_slot_roster_entry_id", slot)),
		})
	return snapshot


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
