extends Node3D
class_name PracticeMode

const LocalSession = preload("res://scripts/systems/local_session.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const PauseController = preload("res://scripts/systems/pause_controller.gd")
const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const PracticeDirector = preload("res://scripts/practice/practice_director.gd")
const PracticeHud = preload("res://scripts/ui/practice_hud.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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


func request_module_restart() -> void:
	_pause_controller.reset()
	get_tree().paused = false
	_reset_robot_spawns()
	practice_director.restart_lane(fixture_root, _player_robots)
	_refresh_hud()


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
	var session := DEFAULT_LOCAL_SESSION_CONFIG.duplicate(true) as LocalSession
	if session == null:
		session = LocalSession.new()

	var slot_count: int = maxi(1, _get_active_slot_specs().size())
	session.configure(max(session.max_local_slots, slot_count), slot_count)
	for slot_spec in _get_active_slot_specs():
		var slot := int(slot_spec.get("slot", 0))
		if slot <= 0:
			continue

		session.assign_keyboard_slot(
			slot,
			_get_default_keyboard_profile_for_slot(slot),
			int(slot_spec.get("control_mode", RobotBase.ControlMode.EASY))
		)

	return session


func _spawn_player_robots() -> void:
	_player_robots.clear()
	var module_spec := PracticeCatalog.get_module(_get_requested_module_id())
	var roster_entry := RosterCatalog.get_shell_roster_entry(String(module_spec.get("recommended_roster_entry_id", "")))
	var archetype_config = roster_entry.get("config", null)
	var slot_specs := _get_active_slot_specs()
	for index in range(slot_specs.size()):
		var slot_spec: Dictionary = slot_specs[index]
		var robot := ROBOT_SCENE.instantiate() as RobotBase
		if robot == null:
			continue

		robot_root.add_child(robot)
		robot.display_name = "Player %s" % int(slot_spec.get("slot", index + 1))
		if archetype_config != null:
			robot.apply_runtime_loadout(
				archetype_config,
				int(slot_spec.get("control_mode", RobotBase.ControlMode.EASY))
			)
		_local_session.apply_to_robot(robot, int(slot_spec.get("slot", index + 1)))
		robot.refresh_input_setup()
		robot.global_position = Vector3((index * 2.4) - ((slot_specs.size() - 1) * 1.2), 1.2, 0.0)
		_player_robots.append(robot)


func _setup_module() -> void:
	practice_director.setup(_get_requested_module_id(), fixture_root, _player_robots)


func _refresh_hud() -> void:
	var module_spec := practice_director.get_active_module_spec()
	practice_hud.set_module_title(String(module_spec.get("label", "Practica")))
	practice_hud.set_objective_lines(practice_director.get_objective_lines())
	var progress_lines := practice_director.get_progress_lines()
	if progress_lines.is_empty():
		progress_lines = ["%s jugador(es) activos" % _player_robots.size()]
	practice_hud.set_progress_lines(progress_lines)
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
	if not (event is InputEventKey):
		return false

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
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
	if event.is_action_pressed("ui_up"):
		_pause_controller.move_selection(owner_slot, -1)
		_refresh_hud()
		return true
	if event.is_action_pressed("ui_down"):
		_pause_controller.move_selection(owner_slot, 1)
		_refresh_hud()
		return true
	if event.is_action_pressed("ui_accept"):
		var action := _pause_controller.activate_selected_action(owner_slot)
		match action:
			"resume":
				request_resume_for_slot(owner_slot)
			"restart":
				request_module_restart()
			"confirm_return_to_menu":
				_refresh_hud()
			"return_to_menu":
				return_to_menu()
		return action != ""
	if event.is_action_pressed("ui_cancel"):
		if _pause_controller.cancel_return_to_menu_confirmation(owner_slot):
			_refresh_hud()
			return true

	return false


func request_pause_for_slot(player_slot: int) -> bool:
	if not _pause_controller.request_pause(player_slot, _local_session, true):
		return false

	get_tree().paused = true
	_refresh_hud()
	return true


func request_resume_for_slot(player_slot: int) -> bool:
	if not _pause_controller.request_resume(player_slot):
		return false

	get_tree().paused = false
	_refresh_hud()
	return true


func _build_pause_lines() -> Array[String]:
	if not _pause_controller.is_paused():
		return ["Sin pausa | usa la tecla de pausa del slot activo."]

	var lines: Array[String] = [
		"P%s pausa" % _pause_controller.get_pause_owner_slot(),
	]
	lines.append_array(_pause_controller.get_action_labels())
	if _pause_controller.is_return_to_menu_confirmation_active():
		lines.append("Confirmar volver al menu")

	return lines


func _get_active_slot_specs() -> Array[Dictionary]:
	var slot_specs: Array[Dictionary] = []
	if _pending_match_launch_config == null or _pending_match_launch_config.local_slots.is_empty():
		return [{"slot": 1, "control_mode": RobotBase.ControlMode.EASY}]

	for slot_spec in _pending_match_launch_config.local_slots:
		if slot_spec is Dictionary:
			slot_specs.append(slot_spec)

	return slot_specs


func _on_lane_completed() -> void:
	_refresh_hud()


func _get_default_keyboard_profile_for_slot(player_slot: int) -> int:
	match player_slot:
		1:
			return RobotBase.KeyboardProfile.WASD_SPACE
		2:
			return RobotBase.KeyboardProfile.ARROWS_ENTER
		3:
			return RobotBase.KeyboardProfile.NUMPAD
		4:
			return RobotBase.KeyboardProfile.IJKL
		_:
			return RobotBase.KeyboardProfile.NONE
