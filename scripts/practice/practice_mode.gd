extends Node3D
class_name PracticeMode

const LocalSession = preload("res://scripts/systems/local_session.gd")
const LocalSessionBuilder = preload("res://scripts/systems/local_session_builder.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const PauseController = preload("res://scripts/systems/pause_controller.gd")
const InputPromptCatalog = preload("res://scripts/systems/input_prompt_catalog.gd")
const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const PracticeDirector = preload("res://scripts/practice/practice_director.gd")
const PracticeHud = preload("res://scripts/ui/practice_hud.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const DEFAULT_LOCAL_SESSION_CONFIG := preload("res://data/config/local/default_local_session_config.tres")

@export var entry_context := MatchLaunchConfig.ENTRY_CONTEXT_PRACTICE

@onready var robot_root: Node3D = $RobotRoot
@onready var fixture_root: Node3D = $FixtureRoot
@onready var practice_director: PracticeDirector = $Systems/PracticeDirector
@onready var practice_hud: PracticeHud = $UI/PracticeHud

var _pending_match_launch_config: MatchLaunchConfig = null
var _local_session: LocalSession = null
var _player_robots: Array[RobotBase] = []
var _pause_controller := PauseController.new()
var _hud_detail_mode: MatchConfig.HudDetailMode = MatchConfig.HudDetailMode.EXPLICIT


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputPromptCatalog.ensure_menu_input_actions()
	_pending_match_launch_config = _consume_match_launch_config()
	_apply_pending_entry_context()
	_local_session = _build_local_session()
	_spawn_player_robots()
	_setup_module()
	practice_director.lane_status_changed.connect(_refresh_hud)
	practice_director.lane_completed.connect(_on_lane_completed)
	_refresh_hud()


func get_active_module_id() -> String:
	return practice_director.get_active_module_id()


func get_local_session() -> LocalSession:
	return _local_session


func get_hud_detail_mode() -> int:
	return _hud_detail_mode


func get_active_module_hud_default() -> String:
	var module_spec := practice_director.get_active_module_spec()
	return String(module_spec.get("hud_default", "explicito"))


func request_module_restart() -> void:
	_pause_controller.reset()
	get_tree().paused = false
	_reset_robot_spawns()
	practice_director.restart_lane(fixture_root, _player_robots)
	_refresh_hud()


func get_pause_lines() -> Array[String]:
	return _build_pause_lines()


func return_to_menu() -> void:
	_pause_controller.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/shell/game_shell.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if _try_handle_pause_input(event):
		get_viewport().set_input_as_handled()


func _consume_match_launch_config() -> MatchLaunchConfig:
	var shell_session := ShellSession.new()
	return shell_session.consume_match_launch_config()


func _apply_pending_entry_context() -> void:
	entry_context = MatchLaunchConfig.ENTRY_CONTEXT_PRACTICE
	if _pending_match_launch_config == null:
		return

	if String(_pending_match_launch_config.entry_context) != "":
		entry_context = String(_pending_match_launch_config.entry_context)


func _build_local_session() -> LocalSession:
	var default_session := DEFAULT_LOCAL_SESSION_CONFIG.duplicate(true) as LocalSession
	if default_session == null:
		default_session = LocalSession.new()
	return LocalSessionBuilder.build_from_slot_specs(_get_active_slot_specs(), default_session)


func _spawn_player_robots() -> void:
	_player_robots.clear()
	var slot_specs := _get_active_slot_specs()
	for index in range(slot_specs.size()):
		var slot_spec: Dictionary = slot_specs[index]
		var robot := ROBOT_SCENE.instantiate() as RobotBase
		if robot == null:
			continue

		robot_root.add_child(robot)
		robot.display_name = "Player %s" % int(slot_spec.get("slot", index + 1))
		_local_session.apply_to_robot(robot, int(slot_spec.get("slot", index + 1)))
		robot.refresh_input_setup()
		robot.global_position = Vector3((index * 2.4) - ((slot_specs.size() - 1) * 1.2), 1.2, 0.0)
		_player_robots.append(robot)


func _setup_module() -> void:
	practice_director.setup(_get_requested_module_id(), fixture_root, _player_robots)
	_apply_module_hud_default()


func _refresh_hud() -> void:
	var module_spec := practice_director.get_active_module_spec()
	practice_hud.set_module_title(String(module_spec.get("label", "Practica")))
	practice_hud.set_objective_lines(practice_director.get_objective_lines())
	var progress_lines := practice_director.get_progress_lines()
	if progress_lines.is_empty():
		progress_lines = ["%s jugador(es) activos" % _player_robots.size()]
	practice_hud.set_progress_lines(progress_lines)
	practice_hud.set_context_card_title(practice_director.get_context_card_title())
	practice_hud.set_context_card_lines(practice_director.get_context_card_lines())
	practice_hud.set_controls_lines(_build_control_lines())
	practice_hud.set_callout_lines(practice_director.get_callout_lines())
	practice_hud.set_pause_lines(_build_pause_lines())


func _build_control_lines() -> Array[String]:
	var lines: Array[String] = []
	for robot in _player_robots:
		lines.append("P%s | %s" % [robot.player_index, robot.get_control_reference_hint()])

	return lines


func _reset_robot_spawns() -> void:
	for index in range(_player_robots.size()):
		var robot := _player_robots[index]
		if robot == null:
			continue

		robot.velocity = Vector3.ZERO
		robot.global_position = Vector3((index * 2.4) - ((_player_robots.size() - 1) * 1.2), 1.2, 0.0)


func _get_requested_module_id() -> String:
	if _pending_match_launch_config == null:
		return "movimiento"

	var module_id := String(_pending_match_launch_config.practice_module_id)
	if module_id.is_empty():
		return "movimiento"

	return module_id


func _try_handle_pause_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.echo:
			return false

	for slot_spec in _get_active_slot_specs():
		var slot := int(slot_spec.get("slot", 0))
		if slot <= 0:
			continue
		if not event.is_action_pressed("p%s_pause" % slot):
			continue
		if _pause_controller.is_paused():
			if _pause_controller.get_pause_owner_slot() == slot:
				request_resume_for_slot(slot)
				return true
			return false
		request_pause_for_slot(slot)
		return true

	if not _pause_controller.is_paused():
		return false

	var owner_slot := _pause_controller.get_pause_owner_slot()
	if event.is_action_pressed("p%s_move_forward" % owner_slot) or event.is_action_pressed("ui_up"):
		_pause_controller.move_selection(owner_slot, -1)
		_refresh_hud()
		return true
	if event.is_action_pressed("p%s_move_back" % owner_slot) or event.is_action_pressed("ui_down"):
		_pause_controller.move_selection(owner_slot, 1)
		_refresh_hud()
		return true
	if event.is_action_pressed("p%s_attack" % owner_slot) or event.is_action_pressed("ui_accept"):
		var action := activate_pause_menu_selection_for_slot(owner_slot)
		return action != ""
	if event.is_action_pressed("p%s_menu_back" % owner_slot):
		if _pause_controller.cancel_return_to_menu_confirmation(owner_slot):
			_refresh_hud()
			return true
		return request_resume_for_slot(owner_slot)

	return false


func request_pause_for_slot(player_slot: int) -> bool:
	if not _pause_controller.request_pause(player_slot, _local_session, true):
		return false

	get_tree().paused = true
	_refresh_hud()
	return true


func select_pause_action_for_slot(player_slot: int, action_id: String) -> bool:
	if not _pause_controller.select_action(player_slot, action_id):
		return false
	_refresh_hud()
	return true


func activate_pause_menu_selection_for_slot(player_slot: int) -> String:
	var action := _pause_controller.activate_selected_action(player_slot)
	match action:
		"resume":
			request_resume_for_slot(player_slot)
		"restart":
			request_module_restart()
		"toggle_hud":
			_toggle_pause_hud_setting()
		"audio_master":
			_step_pause_audio_volume("master")
		"audio_music":
			_step_pause_audio_volume("music")
		"audio_sfx":
			_step_pause_audio_volume("sfx")
		"confirm_return_to_menu":
			_refresh_hud()
		"return_to_menu":
			return_to_menu()
	return action


func request_resume_for_slot(player_slot: int) -> bool:
	if not _pause_controller.request_resume(player_slot):
		return false

	get_tree().paused = false
	_refresh_hud()
	return true


func _build_pause_lines() -> Array[String]:
	if not _pause_controller.is_paused():
		return ["Sin pausa | Select pausa | teclado usa pausa del slot activo."]

	var lines: Array[String] = [
		"P%s pausa" % _pause_controller.get_pause_owner_slot(),
		"Navegacion | %s" % InputPromptCatalog.get_pause_navigation_help_line(),
	]
	lines.append("Acciones")
	lines.append_array(_build_pause_action_lines(["resume", "restart", "return_to_menu"]))
	lines.append("Quick settings")
	lines.append_array(_build_pause_quick_setting_lines())
	lines.append("Dispositivos")
	lines.append_array(_build_pause_device_lines())
	if _pause_controller.is_return_to_menu_confirmation_active():
		lines.append("Confirmar volver al menu | A confirma | B cancela")

	return lines


func _build_pause_action_lines(action_ids: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	var selected_action_id := _pause_controller.get_selected_action_id()
	for action_label in _pause_controller.get_action_labels():
		var trimmed := action_label.strip_edges().trim_prefix(">").strip_edges()
		var action_id := _action_label_to_id(trimmed)
		if not action_ids.has(action_id):
			continue
		var prefix := "> " if action_id == selected_action_id else "  "
		lines.append("%s%s" % [prefix, trimmed])
	return lines


func _build_pause_quick_setting_lines() -> Array[String]:
	var selected_action_id := _pause_controller.get_selected_action_id()
	var hud_label := "contextual" if _hud_detail_mode == MatchConfig.HudDetailMode.CONTEXTUAL else "explicito"
	var specs := [
		{"id": "toggle_hud", "label": "HUD", "value": hud_label},
		{"id": "audio_master", "label": "Master", "value": "%d%%" % roundi(_get_audio_volume("master") * 100.0)},
		{"id": "audio_music", "label": "Musica", "value": "%d%%" % roundi(_get_audio_volume("music") * 100.0)},
		{"id": "audio_sfx", "label": "SFX", "value": "%d%%" % roundi(_get_audio_volume("sfx") * 100.0)},
	]
	var lines: Array[String] = []
	for spec in specs:
		var action_id := String(spec.get("id", ""))
		var prefix := "> " if action_id == selected_action_id else "  "
		lines.append("%s%s | %s" % [prefix, String(spec.get("label", "")), String(spec.get("value", ""))])
	return lines


func _build_pause_device_lines() -> Array[String]:
	var segments: Array[String] = []
	for robot in _player_robots:
		segments.append("P%s %s" % [robot.player_index, robot.get_input_hint()])
	var lines: Array[String] = []
	if segments.is_empty():
		lines.append("sin slots activos")
	else:
		lines.append(", ".join(segments))
	return lines


func _toggle_pause_hud_setting() -> void:
	_hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT if _hud_detail_mode == MatchConfig.HudDetailMode.CONTEXTUAL else MatchConfig.HudDetailMode.CONTEXTUAL
	if practice_hud != null and practice_hud.has_method("set_explicit_mode"):
		practice_hud.call("set_explicit_mode", _hud_detail_mode == MatchConfig.HudDetailMode.EXPLICIT)
	_refresh_hud()


func _step_pause_audio_volume(volume_id: String) -> void:
	var current_volume := _get_audio_volume(volume_id)
	var next_volume := snappedf(current_volume + 0.1, 0.1)
	if next_volume > 1.0:
		next_volume = 0.0
	_set_audio_volume(volume_id, next_volume)
	_refresh_hud()


func _get_audio_volume(volume_id: String) -> float:
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director == null:
		return 1.0
	match volume_id:
		"master":
			return float(audio_director.call("get_master_volume"))
		"music":
			return float(audio_director.call("get_music_volume"))
		"sfx":
			return float(audio_director.call("get_sfx_volume"))
	return 1.0


func _set_audio_volume(volume_id: String, value: float) -> void:
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director == null:
		return
	match volume_id:
		"master":
			audio_director.call("set_master_volume", value)
		"music":
			audio_director.call("set_music_volume", value)
		"sfx":
			audio_director.call("set_sfx_volume", value)


func _apply_module_hud_default() -> void:
	_hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT
	var hud_default := get_active_module_hud_default()
	if hud_default == "contextual":
		_hud_detail_mode = MatchConfig.HudDetailMode.CONTEXTUAL
	if practice_hud != null and practice_hud.has_method("set_explicit_mode"):
		practice_hud.call("set_explicit_mode", _hud_detail_mode == MatchConfig.HudDetailMode.EXPLICIT)


func _action_label_to_id(label: String) -> String:
	match label:
		"Reanudar":
			return "resume"
		"Reiniciar":
			return "restart"
		"Volver al menu":
			return "return_to_menu"
		"HUD":
			return "toggle_hud"
		"Master":
			return "audio_master"
		"Musica":
			return "audio_music"
		"SFX":
			return "audio_sfx"
	return ""


func _get_active_slot_specs() -> Array[Dictionary]:
	var slot_specs: Array[Dictionary] = []
	if _pending_match_launch_config == null or _pending_match_launch_config.local_slots.is_empty():
		var module_spec := PracticeCatalog.get_module(_get_requested_module_id())
		return LocalSessionBuilder.sanitize_slot_specs([{
			"slot": 1,
			"control_mode": RobotBase.ControlMode.EASY,
			"roster_entry_id": String(module_spec.get("recommended_roster_entry_id", "")),
		}])

	for slot_spec in _pending_match_launch_config.local_slots:
		if slot_spec is Dictionary:
			slot_specs.append(slot_spec)

	var sanitized := LocalSessionBuilder.sanitize_slot_specs(slot_specs)
	var capped: Array[Dictionary] = []
	for spec in sanitized:
		if int(spec.get("slot", 0)) > 2:
			continue
		capped.append(spec)
		if capped.size() >= 2:
			break
	return capped


func _on_lane_completed() -> void:
	_refresh_hud()


func _get_default_keyboard_profile_for_slot(player_slot: int) -> int:
	return LocalSessionBuilder.get_default_keyboard_profile_for_slot(player_slot)
