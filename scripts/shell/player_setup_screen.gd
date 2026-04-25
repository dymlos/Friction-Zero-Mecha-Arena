extends Control
class_name PlayerSetupScreen

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const LocalSessionDraft = preload("res://scripts/systems/local_session_draft.gd")
const MapCatalog = preload("res://scripts/systems/map_catalog.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal back_requested
signal start_requested(launch_config: MatchLaunchConfig)

const DEFAULT_LOCAL_SLOTS := [1, 2, 3, 4, 5, 6, 7, 8]
const PANEL_MAX_WIDTH := 1080.0
const PANEL_MAX_HEIGHT := 760.0
const PANEL_MIN_SIDE_MARGIN := 36.0
const PANEL_TOP_MARGIN := 24.0
const PANEL_BOTTOM_RESERVED := 96.0
const PLAYER_SETUP_SEEN_META := &"player_setup_seen"
const TEAM_BLUE_COLOR := Color(0.36, 0.62, 1.0, 1.0)
const TEAM_RED_COLOR := Color(1.0, 0.38, 0.34, 1.0)

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: Control = $Panel
@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var control_hint_label: Label = %ControlHintLabel
@onready var slots_vbox: VBoxContainer = %SlotsVBox
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton
@onready var start_button: Button = %StartButton

var _session_draft := LocalSessionDraft.new()
var _slot_rows: Dictionary = {}
var _icon_cache: Dictionary = {}
var _blink_time := 0.0


func _ready() -> void:
	_install_qa_ids()
	_session_draft.configure(DEFAULT_LOCAL_SLOTS.size())
	backdrop.color = DEFAULT_PRESENTATION_PALETTE.surface_background_alt
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = "Jugadores y robots"
	control_hint_label.text = "Simple: mira hacia donde se mueve. Avanzado: stick izquierdo mueve y stick derecho apunta."
	control_hint_label.theme_type_variation = &"ShellBodyMuted"
	control_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	back_button.text = "Volver"
	start_button.text = "Iniciar"
	back_button.pressed.connect(func() -> void:
		back_requested.emit()
	)
	start_button.pressed.connect(_on_start_pressed)
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	resized.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")
	call_deferred("_move_control_hint_below_slots")
	_rebuild_slot_rows()
	_prepare_first_player_setup_open()
	_normalize_player_slots_for_joypad_ui()
	_refresh_view()
	call_deferred("focus_first_player_button")


func _process(delta: float) -> void:
	_blink_time += delta
	_refresh_join_button_blink()


func set_session_draft(session_draft: LocalSessionDraft) -> void:
	if session_draft == null:
		return
	_session_draft = session_draft
	_session_draft.configure(DEFAULT_LOCAL_SLOTS.size())
	_prepare_first_player_setup_open()
	_normalize_player_slots_for_joypad_ui()
	_refresh_view()


func is_start_enabled() -> bool:
	return _session_draft.can_launch(DEFAULT_LOCAL_SLOTS.size())


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


func focus_start_button() -> void:
	if start_button != null:
		start_button.grab_focus()


func focus_first_player_button() -> void:
	var row: Dictionary = _slot_rows.get(1, {})
	var button := row.get("state") as Button
	if button != null:
		button.grab_focus()


func get_status_line() -> String:
	return status_label.text


func get_control_hint_text() -> String:
	return control_hint_label.text


func _rebuild_slot_rows() -> void:
	if slots_vbox == null:
		return
	for child in slots_vbox.get_children():
		child.queue_free()
	_slot_rows.clear()

	for slot in DEFAULT_LOCAL_SLOTS:
		var row := VBoxContainer.new()
		row.name = "Slot%sRow" % slot
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 3)

		var top_row := HBoxContainer.new()
		top_row.name = "Slot%sTopRow" % slot
		top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_theme_constant_override("separation", 8)

		var state_button := Button.new()
		state_button.name = "Slot%sStateButton" % slot
		state_button.custom_minimum_size = Vector2(260, 40)
		state_button.focus_mode = Control.FOCUS_ALL
		state_button.theme_type_variation = &"ShellButtonSecondary"
		state_button.set_meta("qa_id", "shell_player_setup_slot_%s_state" % slot)
		state_button.pressed.connect(func() -> void:
			_toggle_slot_activation(slot)
		)
		state_button.gui_input.connect(func(event: InputEvent) -> void:
			_handle_slot_mode_input(event, slot)
		)
		top_row.add_child(state_button)

		var team_button := Button.new()
		team_button.name = "Slot%sTeamButton" % slot
		team_button.custom_minimum_size = Vector2(112, 40)
		team_button.focus_mode = Control.FOCUS_ALL
		team_button.theme_type_variation = &"ShellButtonSecondary"
		team_button.set_meta("qa_id", "shell_player_setup_slot_%s_team" % slot)
		team_button.gui_input.connect(func(event: InputEvent) -> void:
			_handle_team_option_input(event, slot)
		)
		top_row.add_child(team_button)

		var icon_rect := TextureRect.new()
		icon_rect.name = "Slot%sRobotIcon" % slot
		icon_rect.custom_minimum_size = Vector2(30, 30)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_row.add_child(icon_rect)

		var robot_button := Button.new()
		robot_button.name = "Slot%sRobotButton" % slot
		robot_button.custom_minimum_size = Vector2(154, 40)
		robot_button.focus_mode = Control.FOCUS_ALL
		robot_button.theme_type_variation = &"ShellButtonSecondary"
		robot_button.set_meta("qa_id", "shell_player_setup_slot_%s_robot" % slot)
		robot_button.gui_input.connect(func(event: InputEvent) -> void:
			_handle_robot_option_input(event, slot)
		)
		top_row.add_child(robot_button)

		var description_label := Label.new()
		description_label.name = "Slot%sDescriptionLabel" % slot
		description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description_label.theme_type_variation = &"ShellBodyMuted"
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.custom_minimum_size = Vector2(0, 30)
		row.add_child(top_row)
		row.add_child(description_label)

		slots_vbox.add_child(row)
		_slot_rows[slot] = {
			"row": row,
			"state": state_button,
			"team": team_button,
			"icon": icon_rect,
			"robot": robot_button,
			"description": description_label,
		}


func _refresh_view() -> void:
	if not is_node_ready():
		return
	_sync_joypad_connection_flags()
	_refresh_summary()

	for slot in DEFAULT_LOCAL_SLOTS:
		var row: Dictionary = _slot_rows.get(slot, {})
		if row.is_empty():
			continue
		var slot_info := _session_draft.get_slot_info(slot)
		var active := bool(slot_info.get("active", false))
		var entry := RosterCatalog.get_competitive_entry(String(slot_info.get("roster_entry_id", "")))
		var team_id := int(slot_info.get("team_id", LocalSessionDraft.TEAM_BLUE))
		var team_color := _get_team_color(team_id)
		var robot_color := entry.get("accent_color", Color.WHITE) as Color
		var state_button := row.get("state") as Button
		var team_button := row.get("team") as Button
		var icon_rect := row.get("icon") as TextureRect
		var robot_button := row.get("robot") as Button
		var description_label := row.get("description") as Label

		state_button.text = _build_slot_state_text(slot, slot_info)
		state_button.tooltip_text = "A activa o desactiva. Izquierda/derecha cambia Simple o Avanzado cuando esta activo."
		state_button.add_theme_color_override("font_color", team_color.lightened(0.18) if active else DEFAULT_PRESENTATION_PALETTE.accent_focus)
		state_button.add_theme_color_override("font_focus_color", team_color.lightened(0.24) if active else DEFAULT_PRESENTATION_PALETTE.accent_focus)
		team_button.visible = _session_draft.match_mode == MatchController.MatchMode.TEAMS
		team_button.text = _build_team_button_text(slot_info)
		team_button.tooltip_text = "Izquierda/derecha cambia el lado de este jugador."
		team_button.add_theme_color_override("font_color", team_color.lightened(0.18))
		team_button.add_theme_color_override("font_focus_color", team_color.lightened(0.24))
		robot_button.text = "< %s >" % String(entry.get("label", "Robot"))
		robot_button.disabled = false
		robot_button.tooltip_text = "Izquierda/derecha cambia el robot de este jugador."
		robot_button.add_theme_color_override("font_color", robot_color.lightened(0.22))
		robot_button.add_theme_color_override("font_focus_color", robot_color.lightened(0.28))
		icon_rect.texture = _get_robot_icon(entry, team_id, active)
		description_label.text = _build_roster_description(entry) if active else "Inactivo. Presiona A para sumar este jugador con joystick."
		description_label.add_theme_color_override("font_color", robot_color.lightened(0.12) if active else DEFAULT_PRESENTATION_PALETTE.text_secondary)

	start_button.disabled = not is_start_enabled()
	status_label.text = _build_status_line()
	_refresh_join_button_blink()


func _refresh_summary() -> void:
	var active_count := maxi(_get_active_slot_count(), 1)
	var mode_label := "Todos contra todos" if _session_draft.match_mode == MatchController.MatchMode.FFA else "Equipos"
	var map_id := _session_draft.get_selected_map_id(active_count)
	var map_entry := MapCatalog.get_map(map_id)
	var map_label := String(map_entry.get("label", "Mapa"))
	var map_count := MapCatalog.get_maps_for(_session_draft.match_mode, active_count).size()
	var map_note := "sin mas mapas por ahora"
	if map_count > 1:
		map_note = "%s mapas disponibles" % map_count
	var variant_label := MatchModeVariantCatalog.get_variant_label(_session_draft.match_mode, _session_draft.get_selected_mode_variant_id())
	summary_label.text = "Modo: %s | Mapa final: %s (%s) | Reglas: %s" % [mode_label, map_label, map_note, variant_label]


func _toggle_slot_activation(player_slot: int) -> void:
	var slot_info := _session_draft.get_slot_info(player_slot)
	if not bool(slot_info.get("active", false)):
		_activate_joypad_slot(player_slot, RobotBase.ControlMode.EASY)
		_refresh_view()
		return

	_session_draft.set_slot_active(player_slot, false)
	_refresh_view()


func _set_slot_control_mode_from_axis(player_slot: int, direction: int) -> void:
	var slot_info := _session_draft.get_slot_info(player_slot)
	if not bool(slot_info.get("active", false)):
		return
	_session_draft.set_slot_control_mode(
		player_slot,
		RobotBase.ControlMode.HARD if direction > 0 else RobotBase.ControlMode.EASY
	)
	_refresh_view()


func _set_slot_team_from_axis(player_slot: int, direction: int) -> void:
	_session_draft.set_slot_team_id(
		player_slot,
		LocalSessionDraft.TEAM_RED if direction > 0 else LocalSessionDraft.TEAM_BLUE
	)
	_refresh_view()


func _activate_joypad_slot(player_slot: int, control_mode: int) -> void:
	var device_id := _pick_device_for_slot(player_slot)
	var connected_devices := Input.get_connected_joypads()
	_session_draft.reserve_joypad_for_slot(player_slot, device_id, connected_devices.has(device_id))
	_session_draft.set_slot_control_mode(player_slot, control_mode)


func _normalize_player_slots_for_joypad_ui() -> void:
	if _session_draft == null:
		return
	for slot in DEFAULT_LOCAL_SLOTS:
		var slot_info := _session_draft.get_slot_info(slot)
		if not bool(slot_info.get("active", false)):
			continue
		if String(slot_info.get("input_source", LocalSessionDraft.INPUT_SOURCE_KEYBOARD)) == LocalSessionDraft.INPUT_SOURCE_JOYPAD:
			continue
		_activate_joypad_slot(slot, int(slot_info.get("control_mode", RobotBase.ControlMode.EASY)))
	_sync_joypad_connection_flags()


func _prepare_first_player_setup_open() -> void:
	if _session_draft == null or _session_draft.has_meta(PLAYER_SETUP_SEEN_META):
		return
	for slot in DEFAULT_LOCAL_SLOTS:
		var slot_info := _session_draft.get_slot_info(slot)
		if String(slot_info.get("input_source", LocalSessionDraft.INPUT_SOURCE_KEYBOARD)) == LocalSessionDraft.INPUT_SOURCE_KEYBOARD:
			_session_draft.set_slot_active(slot, false)
	_session_draft.set_meta(PLAYER_SETUP_SEEN_META, true)


func _move_control_hint_below_slots() -> void:
	var parent := control_hint_label.get_parent()
	if parent == null:
		return
	var status_index := status_label.get_index()
	parent.move_child(control_hint_label, maxi(status_index, 0))


func _sync_joypad_connection_flags() -> void:
	var connected_devices := Input.get_connected_joypads()
	for slot in DEFAULT_LOCAL_SLOTS:
		var slot_info := _session_draft.get_slot_info(slot)
		if not bool(slot_info.get("active", false)):
			continue
		if String(slot_info.get("input_source", LocalSessionDraft.INPUT_SOURCE_KEYBOARD)) != LocalSessionDraft.INPUT_SOURCE_JOYPAD:
			continue
		var control_mode := int(slot_info.get("control_mode", RobotBase.ControlMode.EASY))
		var device_id := int(slot_info.get("device_id", -1))
		if device_id < 0:
			device_id = _pick_device_for_slot(slot)
		_session_draft.reserve_joypad_for_slot(slot, device_id, connected_devices.has(device_id))
		_session_draft.set_slot_control_mode(slot, control_mode)


func _pick_device_for_slot(player_slot: int) -> int:
	var connected_devices := Input.get_connected_joypads()
	var slot_info := _session_draft.get_slot_info(player_slot)
	var current_device := int(slot_info.get("device_id", -1))
	if current_device >= 0 and connected_devices.has(current_device):
		return current_device

	var used_devices := {}
	for slot in DEFAULT_LOCAL_SLOTS:
		if slot == player_slot:
			continue
		var other_info := _session_draft.get_slot_info(slot)
		if not bool(other_info.get("active", false)):
			continue
		if String(other_info.get("input_source", "")) != LocalSessionDraft.INPUT_SOURCE_JOYPAD:
			continue
		var other_device := int(other_info.get("device_id", -1))
		if other_device >= 0:
			used_devices[other_device] = true

	for device_id in connected_devices:
		if not used_devices.has(int(device_id)):
			return int(device_id)
	if current_device >= 0:
		return current_device
	return player_slot - 1


func _build_slot_state_text(player_slot: int, slot_info: Dictionary) -> String:
	if not bool(slot_info.get("active", false)):
		return "P%s Activar" % player_slot
	var mode_label := "Avanzado" if int(slot_info.get("control_mode", RobotBase.ControlMode.EASY)) == RobotBase.ControlMode.HARD else "Simple"
	var device_id := int(slot_info.get("device_id", player_slot - 1))
	var connected := bool(slot_info.get("device_connected", false))
	var connection_label := "Joystick %s" % (device_id + 1)
	if not connected:
		connection_label = "%s sin conectar" % connection_label
	return "P%s | %s | < %s >" % [player_slot, connection_label, mode_label]


func _build_team_button_text(slot_info: Dictionary) -> String:
	var team_id := int(slot_info.get("team_id", LocalSessionDraft.TEAM_BLUE))
	return "< Rojo >" if team_id == LocalSessionDraft.TEAM_RED else "< Azul >"


func _build_roster_description(entry: Dictionary) -> String:
	var role := String(entry.get("role", "Rol"))
	var skill := String(entry.get("primary_skill", entry.get("signature", "")))
	var fantasy := String(entry.get("fantasy", ""))
	return "%s | Habilidad: %s | %s" % [role, skill, fantasy]


func _build_status_line() -> String:
	if is_start_enabled():
		return "Listo. Start inicia la partida."
	if _get_active_slot_count() <= 0:
		return "Activa al menos un jugador."
	return "Conecta un joystick por cada jugador activo."


func _get_active_slot_count() -> int:
	return _session_draft.build_active_slot_specs(DEFAULT_LOCAL_SLOTS.size()).size()


func _handle_slot_mode_input(event: InputEvent, player_slot: int) -> void:
	var direction := _get_horizontal_input_direction(event)
	if direction == 0:
		return
	_set_slot_control_mode_from_axis(player_slot, direction)
	accept_event()


func _handle_team_option_input(event: InputEvent, player_slot: int) -> void:
	var direction := _get_horizontal_input_direction(event)
	if direction == 0:
		return
	_set_slot_team_from_axis(player_slot, direction)
	accept_event()


func _handle_robot_option_input(event: InputEvent, player_slot: int) -> void:
	var direction := _get_horizontal_input_direction(event)
	if direction == 0:
		return
	_session_draft.cycle_slot_roster_entry(player_slot, direction)
	_refresh_view()
	accept_event()


func _get_horizontal_input_direction(event: InputEvent) -> int:
	if event is InputEventKey and (event as InputEventKey).echo:
		return 0
	if event.is_action_pressed(&"ui_left"):
		return -1
	if event.is_action_pressed(&"ui_right"):
		return 1
	return 0


func _refresh_join_button_blink() -> void:
	var alpha := 0.64 + sin(_blink_time * 5.6) * 0.24
	for slot in DEFAULT_LOCAL_SLOTS:
		var row: Dictionary = _slot_rows.get(slot, {})
		var state_button := row.get("state") as Button
		if state_button == null:
			continue
		var slot_info := _session_draft.get_slot_info(slot)
		if bool(slot_info.get("active", false)):
			state_button.modulate = Color.WHITE
		else:
			state_button.modulate = Color(1.0, 1.0, 1.0, alpha)


func _get_team_color(team_id: int) -> Color:
	return TEAM_RED_COLOR if team_id == LocalSessionDraft.TEAM_RED else TEAM_BLUE_COLOR


func _on_start_pressed() -> void:
	if not is_start_enabled():
		return
	start_requested.emit(build_launch_config())


func _on_joy_connection_changed(_device_id: int, _connected: bool) -> void:
	_refresh_view()


func _apply_responsive_layout() -> void:
	if panel == null:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var desired_side := maxf((viewport_size.x - PANEL_MAX_WIDTH) * 0.5, PANEL_MIN_SIDE_MARGIN)
	var max_side := maxf(PANEL_MIN_SIDE_MARGIN, (viewport_size.x - 640.0) * 0.5)
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


func _get_robot_icon(entry: Dictionary, team_id: int, active: bool) -> Texture2D:
	var entry_id := String(entry.get("id", "robot"))
	var cache_key := "%s_%s_%s" % [entry_id, team_id, active]
	if _icon_cache.has(cache_key):
		return _icon_cache[cache_key]

	var accent := entry.get("accent_color", Color.WHITE) as Color
	var team_color := _get_team_color(team_id)
	if active:
		accent = accent.lerp(team_color, 0.28)
	else:
		accent = accent.darkened(0.35)
	var image := Image.create(28, 28, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var dark := accent.darkened(0.45)
	var light := accent.lightened(0.2)
	_fill_rect(image, Rect2i(0, 24, 28, 4), team_color.darkened(0.08))
	_fill_rect(image, Rect2i(11, 5, 6, 4), light)
	_fill_rect(image, Rect2i(8, 9, 12, 10), accent)
	_fill_rect(image, Rect2i(6, 12, 4, 5), dark)
	_fill_rect(image, Rect2i(18, 12, 4, 5), dark)
	_fill_rect(image, Rect2i(9, 19, 4, 5), dark)
	_fill_rect(image, Rect2i(15, 19, 4, 5), dark)

	match entry_id:
		"ariete":
			_fill_rect(image, Rect2i(4, 10, 20, 3), light)
			_fill_rect(image, Rect2i(10, 3, 8, 3), accent)
		"grua":
			_fill_rect(image, Rect2i(18, 4, 3, 11), light)
			_fill_rect(image, Rect2i(20, 4, 4, 3), light)
		"cizalla":
			_fill_rect(image, Rect2i(3, 11, 5, 3), light)
			_fill_rect(image, Rect2i(20, 11, 5, 3), light)
			_fill_rect(image, Rect2i(4, 8, 3, 3), accent)
			_fill_rect(image, Rect2i(21, 8, 3, 3), accent)
		"patin":
			_fill_rect(image, Rect2i(5, 23, 8, 2), light)
			_fill_rect(image, Rect2i(15, 23, 8, 2), light)
		"aguja":
			_fill_rect(image, Rect2i(13, 1, 2, 8), light)
			_fill_rect(image, Rect2i(12, 2, 4, 2), accent)
		"ancla":
			_fill_rect(image, Rect2i(5, 20, 18, 4), dark)
			_fill_rect(image, Rect2i(3, 17, 4, 4), light)
			_fill_rect(image, Rect2i(21, 17, 4, 4), light)

	var texture := ImageTexture.create_from_image(image)
	_icon_cache[cache_key] = texture
	return texture


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var start_x := clampi(rect.position.x, 0, image.get_width())
	var start_y := clampi(rect.position.y, 0, image.get_height())
	var end_x := clampi(rect.position.x + rect.size.x, 0, image.get_width())
	var end_y := clampi(rect.position.y + rect.size.y, 0, image.get_height())
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			image.set_pixel(x, y, color)


func _install_qa_ids() -> void:
	title_label.set_meta("qa_id", "shell_player_setup_title")
	summary_label.set_meta("qa_id", "shell_player_setup_summary")
	control_hint_label.set_meta("qa_id", "shell_player_setup_controls_hint")
	slots_vbox.set_meta("qa_id", "shell_player_setup_slots")
	status_label.set_meta("qa_id", "shell_player_setup_status")
	back_button.set_meta("qa_id", "shell_player_setup_back")
	start_button.set_meta("qa_id", "shell_player_setup_start")
