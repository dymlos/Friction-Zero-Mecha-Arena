extends SceneTree

const MAIN_FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var shell_session := ShellSession.new()
	var launch_config := MatchLaunchConfig.new()
	launch_config.configure_for_local_match(
		MatchController.MatchMode.FFA,
		"res://scenes/main/main_ffa.tscn",
		[
			{"slot": 1, "control_mode": 0},
			{"slot": 2, "control_mode": 1},
		]
	)
	shell_session.store_match_launch_config(launch_config)

	var main = MAIN_FFA_SCENE.instantiate()
	root.add_child(main)
	current_scene = main

	await process_frame
	await process_frame

	_assert(main.has_method("move_pause_menu_selection_for_slot"), "Main deberia exponer navegacion del menu de pausa.")
	_assert(main.has_method("activate_pause_menu_selection_for_slot"), "Main deberia exponer activacion del menu de pausa.")
	_assert(main.has_method("get_pause_overlay_lines"), "Main deberia exponer el contenido actual del overlay de pausa.")
	if not (
		main.has_method("move_pause_menu_selection_for_slot")
		and main.has_method("activate_pause_menu_selection_for_slot")
		and main.has_method("get_pause_overlay_lines")
	):
		await _cleanup_current_scene()
		_finish()
		return

	var pause_requested := bool(main.call("request_pause_for_slot", 2))
	_assert(pause_requested, "El owner local deberia poder abrir la pausa en un match lanzado desde shell.")
	_assert(paused, "La pausa deberia congelar el arbol principal.")

	var pause_lines := PackedStringArray(main.call("get_pause_overlay_lines"))
	_assert(
		"\n".join(pause_lines).contains("Reanudar"),
		"El overlay de pausa deberia listar la accion Reanudar."
	)
	_assert(
		"\n".join(pause_lines).contains("Volver al menu"),
		"El overlay de pausa de shell deberia listar la salida al menu."
	)

	var selected_return := bool(main.call("select_pause_action_for_slot", 2, "return_to_menu"))
	_assert(selected_return, "El owner deberia poder seleccionar `Volver al menu` aunque haya mas acciones de pausa.")

	var first_activation := String(main.call("activate_pause_menu_selection_for_slot", 2))
	_assert(
		first_activation == "confirm_return_to_menu",
		"Activar `Volver al menu` por primera vez deberia abrir una confirmacion y no salir directo."
	)
	pause_lines = PackedStringArray(main.call("get_pause_overlay_lines"))
	_assert(
		"\n".join(pause_lines).contains("Confirmar salida"),
		"La confirmacion de salida deberia quedar visible en el overlay."
	)
	_assert(paused, "La partida deberia seguir pausada mientras la salida espera confirmacion.")

	var second_activation := String(main.call("activate_pause_menu_selection_for_slot", 2))
	_assert(
		second_activation == "return_to_menu",
		"La segunda activacion sobre `Volver al menu` deberia confirmar la salida."
	)

	await process_frame
	await process_frame
	await process_frame

	_assert(current_scene != null, "Volver al menu deberia dejar una escena activa.")
	if current_scene != null:
		_assert(
			String(current_scene.scene_file_path) == "res://scenes/shell/game_shell.tscn",
			"Confirmar salida desde pausa deberia volver a la shell raiz."
		)
		_assert(
			current_scene.has_method("get_active_screen_id")
			and String(current_scene.call("get_active_screen_id")) == "main_menu",
			"Al volver desde pausa, la shell deberia reabrir su menu principal."
		)

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
	paused = false
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
