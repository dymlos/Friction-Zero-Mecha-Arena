extends SceneTree

const MAIN_FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio_director := root.get_node_or_null("/root/AudioDirector")
	_assert(audio_director != null, "AudioDirector deberia estar disponible para quick settings.")
	if audio_director == null:
		_finish()
		return
	audio_director.call("set_master_volume", 0.5)
	audio_director.call("set_music_volume", 0.5)
	audio_director.call("set_sfx_volume", 0.5)

	var shell_session := ShellSession.new()
	shell_session.store_match_launch_config(null)
	var launch_config := MatchLaunchConfig.new()
	launch_config.configure_for_local_match(
		MatchController.MatchMode.FFA,
		"res://scenes/main/main_ffa.tscn",
		[{"slot": 1, "control_mode": 0, "input_source": "keyboard", "keyboard_profile": 1}]
	)
	shell_session.store_match_launch_config(launch_config)

	var main = MAIN_FFA_SCENE.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	_assert(bool(main.call("request_pause_for_slot", 1)), "P1 deberia poder abrir pausa operacional.")
	var overlay_text := "\n".join(PackedStringArray(main.call("get_pause_overlay_lines")))
	_assert(overlay_text.contains("Acciones"), "La pausa deberia separar acciones de match.")
	_assert(overlay_text.contains("Quick settings"), "La pausa deberia mostrar quick settings.")
	_assert(overlay_text.contains("Dispositivos"), "La pausa deberia mostrar resumen corto de dispositivos.")

	var match_controller := main.get_node_or_null("Systems/MatchController")
	var initial_hud_mode := int(match_controller.call("get_runtime_hud_detail_mode")) if match_controller != null else -1
	_assert(bool(main.call("select_pause_action_for_slot", 1, "toggle_hud")), "El owner deberia poder seleccionar HUD.")
	var hud_action := String(main.call("activate_pause_menu_selection_for_slot", 1))
	_assert(hud_action == "toggle_hud", "Activar HUD deberia devolver la accion de quick setting.")
	_assert(
		match_controller != null
		and int(match_controller.call("get_runtime_hud_detail_mode")) != initial_hud_mode,
		"El quick setting de HUD deberia aplicarse en runtime."
	)

	_assert(bool(main.call("select_pause_action_for_slot", 1, "audio_master")), "El owner deberia poder seleccionar master.")
	var audio_action := String(main.call("activate_pause_menu_selection_for_slot", 1))
	_assert(audio_action == "audio_master", "Activar master deberia devolver accion de audio.")
	_assert(
		float(audio_director.call("get_master_volume")) > 0.5,
		"El quick setting master deberia reflejarse en AudioDirector."
	)

	_assert(not bool(main.call("select_pause_action_for_slot", 2, "audio_sfx")), "Un no-owner no deberia seleccionar quick settings.")

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
