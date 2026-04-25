extends Control
class_name LocalMatchSetup

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const LocalSessionDraft = preload("res://scripts/systems/local_session_draft.gd")
const LocalScaleContract = preload("res://scripts/systems/local_scale_contract.gd")
const MapCatalog = preload("res://scripts/systems/map_catalog.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal back_requested
signal characters_requested
signal how_to_play_requested
signal practice_requested
signal players_requested
signal start_requested(launch_config: MatchLaunchConfig)

const DEFAULT_LOCAL_SLOTS := [1, 2, 3, 4, 5, 6, 7, 8]

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: Control = $Panel
@onready var mode_value_label: Label = %ModeValueLabel
@onready var scale_status_label: Label = %ScaleStatusLabel
@onready var map_summary_label: Label = %MapSummaryLabel
@onready var map_focus_label: Label = %MapFocusLabel
@onready var map_cycle_button: Button = %MapCycleButton
@onready var variant_summary_label: Label = %VariantSummaryLabel
@onready var variant_cycle_button: Button = %VariantCycleButton
@onready var slots_title_label: Label = $Panel/Margin/VBox/SlotsTitleLabel
@onready var slot_summary_label: Label = %SlotSummaryLabel
@onready var slot_buttons_grid: GridContainer = $Panel/Margin/VBox/SlotButtons
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

const PANEL_MAX_WIDTH := 920.0
const PANEL_MAX_HEIGHT := 760.0
const PANEL_MIN_SIDE_MARGIN := 40.0
const PANEL_TOP_MARGIN := 24.0
const PANEL_BOTTOM_RESERVED := 96.0


func _ready() -> void:
	_install_qa_ids()
	_session_draft.configure(DEFAULT_LOCAL_SLOTS.size())
	backdrop.color = DEFAULT_PRESENTATION_PALETTE.surface_background_alt
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")
	mode_value_label.visible = false
	teams_button.toggle_mode = false
	ffa_button.visible = false
	slots_title_label.visible = false
	slot_buttons_grid.visible = false
	characters_button.visible = false

	_connect_horizontal_option(teams_button, _cycle_match_mode_from_axis)
	_connect_horizontal_option(map_cycle_button, cycle_selected_map)
	_connect_horizontal_option(variant_cycle_button, cycle_mode_variant)
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
	start_button.text = "Continuar"
	characters_button.text = "Robots"
	how_to_play_button.text = "Como jugar"
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


func cycle_match_mode(direction: int = 1) -> void:
	var next_mode := MatchController.MatchMode.FFA
	if _session_draft.match_mode == MatchController.MatchMode.FFA:
		next_mode = MatchController.MatchMode.TEAMS
	set_match_mode(next_mode)


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


func cycle_mode_variant(direction: int = 1) -> void:
	_session_draft.cycle_mode_variant(direction)
	_refresh_view()


func toggle_slot_control_mode(player_slot: int) -> void:
	_session_draft.toggle_slot_control_mode(player_slot)
	_refresh_view()


func is_start_enabled() -> bool:
	return true


func request_start_from_shortcut() -> bool:
	if not is_start_enabled():
		return false

	_on_start_pressed()
	return true


func build_launch_config() -> MatchLaunchConfig:
	var launch_config := MatchLaunchConfig.new()
	var active_slot_specs := _session_draft.build_active_slot_specs(DEFAULT_LOCAL_SLOTS.size())
	var active_slot_count := active_slot_specs.size()
	var map_id := _session_draft.get_selected_map_id(active_slot_count)
	launch_config.auto_restart_on_match_end = false
	launch_config.configure_for_local_match(
		_session_draft.match_mode,
		MapCatalog.resolve_scene_path(map_id, _session_draft.match_mode, active_slot_count),
		active_slot_specs,
		map_id,
		_session_draft.get_selected_mode_variant_id()
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
	var base_line := MapCatalog.get_setup_summary_line(_get_selected_map_id(), _session_draft.match_mode, _get_active_slot_count())
	var map_count := MapCatalog.get_maps_for(_session_draft.match_mode, _get_active_slot_count()).size()
	if map_count <= 0:
		return "Mapa | no disponible"
	if map_count == 1:
		return "%s | sin mas mapas por ahora" % base_line
	return "%s | %s opciones" % [base_line, map_count]


func get_map_focus_line() -> String:
	return MapCatalog.get_setup_focus_line(_get_selected_map_id(), _session_draft.match_mode, _get_active_slot_count())


func get_variant_summary_line() -> String:
	return _session_draft.get_mode_variant_summary_line()


func _refresh_view() -> void:
	mode_value_label.text = "Todos contra todos" if _session_draft.match_mode == MatchController.MatchMode.FFA else "Equipos"
	teams_button.disabled = false
	ffa_button.disabled = false
	teams_button.text = "< %s >" % mode_value_label.text
	teams_button.theme_type_variation = &"ShellButtonSecondary"
	var slot_lines := get_slot_summary_lines()
	scale_status_label.text = get_scale_status_line()
	map_summary_label.text = get_map_summary_line()
	map_focus_label.text = get_map_focus_line()
	var map_count := MapCatalog.get_maps_for(_session_draft.match_mode, _get_active_slot_count()).size()
	map_cycle_button.text = "< Mapa >" if map_count > 1 else "Sin mas mapas"
	map_cycle_button.theme_type_variation = &"ShellButtonSecondary" if map_count > 1 else &"ShellButtonUnavailable"
	map_cycle_button.disabled = false
	variant_summary_label.text = get_variant_summary_line()
	var variant_count := MatchModeVariantCatalog.get_enabled_variants(_session_draft.match_mode).size()
	variant_cycle_button.text = "< Reglas >" if variant_count > 1 else "Sin variantes"
	variant_cycle_button.theme_type_variation = &"ShellButtonSecondary" if variant_count > 1 else &"ShellButtonUnavailable"
	variant_cycle_button.disabled = false
	slot_summary_label.text = _build_compact_slot_summary_text(slot_lines)
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
		return "P%s activar" % player_slot
	var mode_label := "Avanzado" if int(slot_info.get("control_mode", RobotBase.ControlMode.EASY)) == RobotBase.ControlMode.HARD else "Simple"
	var input_source := String(slot_info.get("input_source", LocalSessionDraft.INPUT_SOURCE_KEYBOARD))
	if input_source == LocalSessionDraft.INPUT_SOURCE_JOYPAD:
		var connected := bool(slot_info.get("device_connected", false))
		var device_id := int(slot_info.get("device_id", -1))
		if connected and device_id >= 0:
			return "P%s %s | joy %s" % [player_slot, mode_label, device_id]
		return "P%s %s | sin joy" % [player_slot, mode_label]

	return "P%s activar joystick" % player_slot


func _apply_responsive_layout() -> void:
	if panel == null:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var desired_side := maxf((viewport_size.x - PANEL_MAX_WIDTH) * 0.5, PANEL_MIN_SIDE_MARGIN)
	var max_side := maxf(PANEL_MIN_SIDE_MARGIN, (viewport_size.x - 560.0) * 0.5)
	var side_margin := clampf(desired_side, PANEL_MIN_SIDE_MARGIN, max_side)

	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.offset_left = side_margin
	panel.offset_right = -side_margin

	var available_height := viewport_size.y - PANEL_TOP_MARGIN - PANEL_BOTTOM_RESERVED
	var target_height := minf(available_height, PANEL_MAX_HEIGHT)
	var slack := maxf(available_height - target_height, 0.0)
	var top_margin := PANEL_TOP_MARGIN + (slack * 0.5)
	var bottom_margin := PANEL_BOTTOM_RESERVED + (slack * 0.5)

	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_top = top_margin
	panel.offset_bottom = -bottom_margin


func _build_slot_roster_button_text(player_slot: int) -> String:
	var slot_info := _session_draft.get_slot_info(player_slot)
	var roster_entry := RosterCatalog.get_competitive_entry(String(slot_info.get("roster_entry_id", "")))
	return String(roster_entry.get("label", slot_info.get("roster_entry_id", "")))


func _build_compact_slot_summary_text(slot_lines: Array[String]) -> String:
	var rows: Array[String] = []
	var half := ceili(float(slot_lines.size()) / 2.0)
	for index in range(half):
		var left := _compact_slot_summary_line(slot_lines[index])
		var right := ""
		var right_index := index + half
		if right_index < slot_lines.size():
			right = _compact_slot_summary_line(slot_lines[right_index])
		rows.append("%s    %s" % [left, right])
	return "\n".join(rows)


func _compact_slot_summary_line(line: String) -> String:
	return line.replace("teclado ", "").replace("joypad ", "joy ")


func _cycle_match_mode_from_axis(_direction: int = 1) -> void:
	cycle_match_mode()


func _connect_horizontal_option(button: Button, handler: Callable) -> void:
	if button == null:
		return
	button.gui_input.connect(func(event: InputEvent) -> void:
		_handle_horizontal_option_input(event, handler)
	)


func _handle_horizontal_option_input(event: InputEvent, handler: Callable) -> void:
	var direction := 0
	if _is_pressed_action(event, "ui_left"):
		direction = -1
	elif _is_pressed_action(event, "ui_right"):
		direction = 1
	if direction == 0:
		return

	handler.call(direction)
	accept_event()


func _is_pressed_action(event: InputEvent, action_name: String) -> bool:
	if event is InputEventKey and (event as InputEventKey).echo:
		return false
	return event.is_action_pressed(StringName(action_name))


func _on_start_pressed() -> void:
	players_requested.emit()


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
	variant_summary_label.set_meta("qa_id", "shell_local_setup_variant")
	variant_cycle_button.set_meta("qa_id", "shell_local_setup_variant_cycle")
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
