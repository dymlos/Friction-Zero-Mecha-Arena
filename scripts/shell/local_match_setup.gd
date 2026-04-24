extends Control
class_name LocalMatchSetup

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const LocalSessionDraft = preload("res://scripts/systems/local_session_draft.gd")
const LocalScaleContract = preload("res://scripts/systems/local_scale_contract.gd")
const MapCatalog = preload("res://scripts/systems/map_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal back_requested
signal characters_requested
signal how_to_play_requested
signal practice_requested
signal start_requested(launch_config: MatchLaunchConfig)

const DEFAULT_LOCAL_SLOTS := [1, 2, 3, 4, 5, 6, 7, 8]

@onready var backdrop: ColorRect = $Backdrop
@onready var mode_value_label: Label = %ModeValueLabel
@onready var scale_status_label: Label = %ScaleStatusLabel
@onready var map_summary_label: Label = %MapSummaryLabel
@onready var map_focus_label: Label = %MapFocusLabel
@onready var map_cycle_button: Button = %MapCycleButton
@onready var slot_summary_label: Label = %SlotSummaryLabel
@onready var teams_button: Button = %TeamsButton
@onready var ffa_button: Button = %FFAButton
@onready var slot_buttons: Array[Button] = [
	%Slot1Button,
	%Slot2Button,
	%Slot3Button,
	%Slot4Button,
	%Slot5Button,
	%Slot6Button,
	%Slot7Button,
	%Slot8Button,
]
@onready var slot_roster_buttons: Array[Button] = [
	%Slot1RosterButton,
	%Slot2RosterButton,
	%Slot3RosterButton,
	%Slot4RosterButton,
	%Slot5RosterButton,
	%Slot6RosterButton,
	%Slot7RosterButton,
	%Slot8RosterButton,
]
@onready var start_button: Button = %StartButton
@onready var characters_button: Button = %CharactersButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var practice_button: Button = %PracticeButton
@onready var back_button: Button = %BackButton

var _session_draft := LocalSessionDraft.new()


func _ready() -> void:
	_install_qa_ids()
	_session_draft.configure(DEFAULT_LOCAL_SLOTS.size())
	backdrop.color = DEFAULT_PRESENTATION_PALETTE.surface_background_alt
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE

	teams_button.pressed.connect(func() -> void:
		set_match_mode(MatchController.MatchMode.TEAMS)
	)
	ffa_button.pressed.connect(func() -> void:
		set_match_mode(MatchController.MatchMode.FFA)
	)
	map_cycle_button.pressed.connect(func() -> void:
		cycle_selected_map()
	)
	for index in range(slot_buttons.size()):
		var slot := index + 1
		slot_buttons[index].pressed.connect(func() -> void:
			cycle_slot_state(slot)
		)
	for index in range(slot_roster_buttons.size()):
		var slot := index + 1
		slot_roster_buttons[index].pressed.connect(func() -> void:
			cycle_slot_roster_entry(slot)
		)
	characters_button.pressed.connect(_on_characters_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	practice_button.pressed.connect(_on_practice_pressed)
	start_button.text = "Iniciar"
	characters_button.text = "Characters"
	how_to_play_button.text = "How to Play"
	practice_button.text = "Practica"
	back_button.text = "Volver"
	_refresh_view()
	call_deferred("focus_start_button")


func set_session_draft(session_draft: LocalSessionDraft) -> void:
	if session_draft == null:
		return
	_session_draft = session_draft
	_session_draft.configure(DEFAULT_LOCAL_SLOTS.size())
	_refresh_view()


func set_match_mode(next_match_mode: MatchController.MatchMode) -> void:
	_session_draft.set_match_mode(next_match_mode)
	_refresh_view()


func set_slot_active(player_slot: int, active: bool) -> void:
	_session_draft.set_slot_active(player_slot, active)
	_refresh_view()


func set_slot_control_mode(player_slot: int, control_mode: int) -> void:
	_session_draft.set_slot_control_mode(player_slot, control_mode)
	_refresh_view()


func set_slot_input_source(player_slot: int, input_source: String) -> void:
	_session_draft.set_slot_input_source(player_slot, input_source)
	_refresh_view()


func reserve_joypad_for_slot(player_slot: int, device_id: int, connected: bool = true) -> void:
	_session_draft.reserve_joypad_for_slot(player_slot, device_id, connected)
	_refresh_view()


func cycle_slot_state(player_slot: int) -> void:
	_session_draft.cycle_slot_state(player_slot)
	_refresh_view()


func cycle_slot_roster_entry(player_slot: int) -> void:
	_session_draft.cycle_slot_roster_entry(player_slot)
	_refresh_view()


func cycle_selected_map(direction: int = 1) -> void:
	_session_draft.cycle_selected_map(_get_active_slot_count(), direction)
	_refresh_view()


func toggle_slot_control_mode(player_slot: int) -> void:
	_session_draft.toggle_slot_control_mode(player_slot)
	_refresh_view()


func is_start_enabled() -> bool:
	return _session_draft.can_launch(DEFAULT_LOCAL_SLOTS.size())


func build_launch_config() -> MatchLaunchConfig:
	var launch_config := MatchLaunchConfig.new()
	var active_slot_specs := _session_draft.build_active_slot_specs(DEFAULT_LOCAL_SLOTS.size())
	var active_slot_count := active_slot_specs.size()
	var map_id := _session_draft.get_selected_map_id(active_slot_count)
	launch_config.hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT
	launch_config.auto_restart_on_match_end = false
	launch_config.configure_for_local_match(
		_session_draft.match_mode,
		MapCatalog.resolve_scene_path(map_id, _session_draft.match_mode, active_slot_count),
		active_slot_specs,
		map_id
	)
	return launch_config


func get_slot_summary_lines() -> Array[String]:
	return _session_draft.get_slot_summary_lines(DEFAULT_LOCAL_SLOTS.size())


func get_scale_status_line() -> String:
	return LocalScaleContract.get_setup_status_line(
		_session_draft.build_active_slot_specs(DEFAULT_LOCAL_SLOTS.size()).size(),
		_session_draft.match_mode
	)


func get_map_summary_line() -> String:
	return MapCatalog.get_setup_summary_line(_get_selected_map_id(), _session_draft.match_mode, _get_active_slot_count())


func get_map_focus_line() -> String:
	return MapCatalog.get_setup_focus_line(_get_selected_map_id(), _session_draft.match_mode, _get_active_slot_count())


func _refresh_view() -> void:
	mode_value_label.text = "FFA" if _session_draft.match_mode == MatchController.MatchMode.FFA else "Equipos"
	teams_button.disabled = _session_draft.match_mode == MatchController.MatchMode.TEAMS
	ffa_button.disabled = _session_draft.match_mode == MatchController.MatchMode.FFA
	var slot_lines := get_slot_summary_lines()
	scale_status_label.text = get_scale_status_line()
	map_summary_label.text = get_map_summary_line()
	map_focus_label.text = get_map_focus_line()
	map_cycle_button.text = "Mapa"
	map_cycle_button.disabled = MapCatalog.get_maps_for(_session_draft.match_mode, _get_active_slot_count()).size() <= 1
	slot_summary_label.text = "\n".join(slot_lines)
	for index in range(slot_buttons.size()):
		var player_slot := index + 1
		slot_buttons[index].text = _build_slot_state_button_text(player_slot)
		slot_roster_buttons[index].text = _build_slot_roster_button_text(player_slot)
	start_button.disabled = not is_start_enabled()


func _get_active_slot_count() -> int:
	return _session_draft.build_active_slot_specs(DEFAULT_LOCAL_SLOTS.size()).size()


func _get_selected_map_id() -> String:
	return _session_draft.get_selected_map_id(_get_active_slot_count())


func _build_slot_state_button_text(player_slot: int) -> String:
	var slot_info := _session_draft.get_slot_info(player_slot)
	if not bool(slot_info.get("active", false)):
		return "P%s | activar" % player_slot
	var mode_label := "Hard" if int(slot_info.get("control_mode", RobotBase.ControlMode.EASY)) == RobotBase.ControlMode.HARD else "Easy"
	var input_source := String(slot_info.get("input_source", LocalSessionDraft.INPUT_SOURCE_KEYBOARD))
	if input_source == LocalSessionDraft.INPUT_SOURCE_JOYPAD:
		var connection_label := "ok" if bool(slot_info.get("device_connected", false)) else "sin joy"
		return "P%s | %s | %s" % [player_slot, mode_label, connection_label]
	return "P%s | %s | teclado" % [player_slot, mode_label]


func _build_slot_roster_button_text(player_slot: int) -> String:
	var slot_info := _session_draft.get_slot_info(player_slot)
	var roster_entry := RosterCatalog.get_competitive_entry(String(slot_info.get("roster_entry_id", "")))
	return String(roster_entry.get("label", slot_info.get("roster_entry_id", "")))


func _on_start_pressed() -> void:
	start_requested.emit(build_launch_config())


func _on_characters_pressed() -> void:
	characters_requested.emit()


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_how_to_play_pressed() -> void:
	how_to_play_requested.emit()


func _on_practice_pressed() -> void:
	practice_requested.emit()


func focus_characters_button() -> void:
	if characters_button != null:
		characters_button.grab_focus()


func focus_how_to_play_button() -> void:
	if how_to_play_button != null:
		how_to_play_button.grab_focus()


func focus_practice_button() -> void:
	if practice_button != null:
		practice_button.grab_focus()


func focus_start_button() -> void:
	if start_button != null:
		start_button.grab_focus()


func _install_qa_ids() -> void:
	mode_value_label.set_meta("qa_id", "shell_local_setup_mode")
	scale_status_label.set_meta("qa_id", "shell_local_setup_scale")
	map_summary_label.set_meta("qa_id", "shell_local_setup_map")
	map_focus_label.set_meta("qa_id", "shell_local_setup_map_focus")
	map_cycle_button.set_meta("qa_id", "shell_local_setup_map_cycle")
	slot_summary_label.set_meta("qa_id", "shell_local_setup_slots")
	teams_button.set_meta("qa_id", "shell_local_setup_teams")
	ffa_button.set_meta("qa_id", "shell_local_setup_ffa")
	start_button.set_meta("qa_id", "shell_local_setup_start")
	characters_button.set_meta("qa_id", "shell_local_setup_characters")
	how_to_play_button.set_meta("qa_id", "shell_local_setup_how_to_play")
	practice_button.set_meta("qa_id", "shell_local_setup_practice")
	back_button.set_meta("qa_id", "shell_local_setup_back")
	for index in range(slot_roster_buttons.size()):
		slot_roster_buttons[index].set_meta("qa_id", "shell_local_setup_slot_%s_robot" % (index + 1))
