extends Control
class_name SettingsScreen

const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")
const ShellSettingsCatalog = preload("res://scripts/systems/shell_settings_catalog.gd")
const UserSettings = preload("res://scripts/systems/user_settings.gd")

signal back_requested

const SURFACE_SCOPE_GLOBAL := "global"
const SURFACE_SCOPE_PAUSE := "pause"
const PAUSE_SECTION_IDS := ["audio", "hud"]

@onready var backdrop: ColorRect = $Backdrop
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var audio_button: Button = %AudioButton
@onready var video_button: Button = %VideoButton
@onready var hud_button: Button = %HudButton
@onready var controls_button: Button = %ControlsButton
@onready var section_summary_label: Label = %SectionSummaryLabel
@onready var audio_content: VBoxContainer = %AudioContent
@onready var master_slider: HSlider = %MasterSlider
@onready var master_value_label: Label = %MasterValueLabel
@onready var music_row: HBoxContainer = $CenterPanel/Margin/VBox/ContentPanel/Margin/ContentScroll/VBox/AudioContent/MusicRow
@onready var music_slider: HSlider = %MusicSlider
@onready var music_value_label: Label = %MusicValueLabel
@onready var sfx_slider: HSlider = %SFXSlider
@onready var sfx_value_label: Label = %SFXValueLabel
@onready var video_content: VBoxContainer = %VideoContent
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var vsync_check: CheckButton = %VSyncCheck
@onready var hud_content: VBoxContainer = %HudContent
@onready var hud_mode_option: OptionButton = %HudModeOption
@onready var controls_content: VBoxContainer = %ControlsContent
@onready var controls_summary_label: Label = %ControlsSummaryLabel
@onready var back_button: Button = %BackButton

var _store: Node = null
var _settings: UserSettings = null
var _active_section_id := "audio"
var _surface_scope := SURFACE_SCOPE_GLOBAL


func _ready() -> void:
	_install_qa_ids()
	backdrop.color = DEFAULT_PRESENTATION_PALETTE.surface_background_alt
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = "Opciones"
	subtitle_label.text = "Ajusta audio, video, ayudas en pantalla y revisa los controles."
	music_row.visible = false
	back_button.text = "Volver"
	back_button.pressed.connect(go_back)
	_store = get_node_or_null("/root/UserSettingsStore")
	_settings = _store.call("get_settings") if _store != null and _store.has_method("get_settings") else UserSettings.new()
	_populate_catalog()
	_bind_controls()
	_configure_section_buttons()
	_apply_surface_scope()
	_apply_settings_to_controls()
	_select_section("audio")
	call_deferred("focus_back_button")


func set_surface_scope(scope_id: String) -> void:
	if not [SURFACE_SCOPE_GLOBAL, SURFACE_SCOPE_PAUSE].has(scope_id):
		scope_id = SURFACE_SCOPE_GLOBAL
	_surface_scope = scope_id
	_apply_surface_scope()


func get_section_ids() -> Array[String]:
	var ids: Array[String] = []
	for section in ShellSettingsCatalog.get_sections():
		var section_id := String(section.get("id", ""))
		if _surface_scope == SURFACE_SCOPE_PAUSE and not PAUSE_SECTION_IDS.has(section_id):
			continue
		ids.append(section_id)
	return ids


func get_settings_snapshot() -> Dictionary:
	return {
		"audio_master_volume": float(_settings.audio_master_volume),
		"audio_music_volume": float(_settings.audio_music_volume),
		"audio_sfx_volume": float(_settings.audio_sfx_volume),
		"window_mode": String(_settings.window_mode),
		"vsync_enabled": bool(_settings.vsync_enabled),
		"default_hud_detail_mode": int(_settings.default_hud_detail_mode),
	}


func set_master_volume(value: float) -> bool:
	_settings.audio_master_volume = value
	_persist_settings()
	return true


func set_music_volume(value: float) -> bool:
	_settings.audio_music_volume = value
	_persist_settings()
	return true


func set_sfx_volume(value: float) -> bool:
	_settings.audio_sfx_volume = value
	_persist_settings()
	return true


func set_window_mode(value: String) -> bool:
	if _surface_scope == SURFACE_SCOPE_PAUSE:
		return false
	_settings.window_mode = value
	_persist_settings()
	return true


func set_vsync_enabled(is_enabled: bool) -> bool:
	if _surface_scope == SURFACE_SCOPE_PAUSE:
		return false
	_settings.vsync_enabled = is_enabled
	_persist_settings()
	return true


func set_hud_detail_mode(mode: int) -> bool:
	_settings.default_hud_detail_mode = mode
	_persist_settings()
	return true


func get_controls_summary_text() -> String:
	return controls_summary_label.text


func focus_back_button() -> void:
	if back_button != null:
		back_button.grab_focus()


func go_back() -> void:
	back_requested.emit()


func _populate_catalog() -> void:
	var sections := ShellSettingsCatalog.get_sections()
	audio_button.text = String(sections[0].get("title", "Audio"))
	video_button.text = String(sections[1].get("title", "Video"))
	hud_button.text = String(sections[2].get("title", "HUD"))
	controls_button.text = String(sections[3].get("title", "Controles"))
	_rebuild_window_mode_options()
	_rebuild_hud_mode_options()
	controls_summary_label.text = _build_controls_summary()


func _configure_section_buttons() -> void:
	for button in [audio_button, video_button, hud_button, controls_button]:
		button.toggle_mode = true


func _apply_surface_scope() -> void:
	if not is_node_ready():
		return
	var pause_scope := _surface_scope == SURFACE_SCOPE_PAUSE
	video_button.visible = not pause_scope
	controls_button.visible = not pause_scope
	video_button.disabled = pause_scope
	controls_button.disabled = pause_scope
	subtitle_label.text = (
		"Ajustes rapidos de pausa: audio y ayudas en pantalla."
		if pause_scope
		else "Ajusta audio, video, ayudas en pantalla y revisa los controles."
	)
	if pause_scope and not PAUSE_SECTION_IDS.has(_active_section_id):
		_select_section("audio")


func _bind_controls() -> void:
	audio_button.pressed.connect(func() -> void:
		_select_section("audio")
	)
	video_button.pressed.connect(func() -> void:
		_select_section("video")
	)
	hud_button.pressed.connect(func() -> void:
		_select_section("hud")
	)
	controls_button.pressed.connect(func() -> void:
		_select_section("controls")
	)
	master_slider.value_changed.connect(func(value: float) -> void:
		set_master_volume(value)
	)
	music_slider.value_changed.connect(func(value: float) -> void:
		set_music_volume(value)
	)
	sfx_slider.value_changed.connect(func(value: float) -> void:
		set_sfx_volume(value)
	)
	window_mode_option.item_selected.connect(_on_window_mode_selected)
	vsync_check.toggled.connect(func(is_pressed: bool) -> void:
		set_vsync_enabled(is_pressed)
	)
	hud_mode_option.item_selected.connect(_on_hud_mode_selected)


func _apply_settings_to_controls() -> void:
	master_slider.set_value_no_signal(float(_settings.audio_master_volume))
	music_slider.set_value_no_signal(float(_settings.audio_music_volume))
	sfx_slider.set_value_no_signal(float(_settings.audio_sfx_volume))
	master_value_label.text = _format_percent(_settings.audio_master_volume)
	music_value_label.text = _format_percent(_settings.audio_music_volume)
	sfx_value_label.text = _format_percent(_settings.audio_sfx_volume)
	_select_option_by_metadata(window_mode_option, String(_settings.window_mode))
	vsync_check.set_pressed_no_signal(bool(_settings.vsync_enabled))
	_select_option_by_metadata(hud_mode_option, int(_settings.default_hud_detail_mode))
	controls_summary_label.text = _build_controls_summary()
	_refresh_section_summary()


func _persist_settings() -> void:
	if _store != null and _store.has_method("save_settings"):
		_store.call("save_settings")
		_settings = _store.call("get_settings")
	else:
		_settings = _settings.duplicate_sanitized()
	_apply_settings_to_controls()


func _select_section(section_id: String) -> void:
	if _surface_scope == SURFACE_SCOPE_PAUSE and not PAUSE_SECTION_IDS.has(section_id):
		section_id = "audio"
	_active_section_id = section_id
	audio_content.visible = section_id == "audio"
	video_content.visible = section_id == "video"
	hud_content.visible = section_id == "hud"
	controls_content.visible = section_id == "controls"
	audio_button.disabled = false
	video_button.disabled = _surface_scope == SURFACE_SCOPE_PAUSE
	hud_button.disabled = false
	controls_button.disabled = _surface_scope == SURFACE_SCOPE_PAUSE
	audio_button.button_pressed = section_id == "audio"
	video_button.button_pressed = section_id == "video"
	hud_button.button_pressed = section_id == "hud"
	controls_button.button_pressed = section_id == "controls"
	audio_button.text = "< Audio >" if audio_button.button_pressed else "Audio"
	video_button.text = "< Video >" if video_button.button_pressed else "Video"
	hud_button.text = "< Ayudas >" if hud_button.button_pressed else "Ayudas"
	controls_button.text = "< Controles >" if controls_button.button_pressed else "Controles"
	_refresh_section_summary()


func _refresh_section_summary() -> void:
	for section in ShellSettingsCatalog.get_sections():
		if String(section.get("id", "")) != _active_section_id:
			continue
		section_summary_label.text = String(section.get("summary", ""))
		return
	section_summary_label.text = ""


func _build_controls_summary() -> String:
	var lines: Array[String] = []
	lines.append("Modos | %s" % ", ".join(ShellSettingsCatalog.get_control_mode_lines()))
	lines.append("Joysticks | %s" % ", ".join(ShellSettingsCatalog.get_connected_joypad_lines()))
	lines.append(ShellSettingsCatalog.get_controls_note())
	return "\n".join(lines)


func _rebuild_window_mode_options() -> void:
	window_mode_option.clear()
	for option in ShellSettingsCatalog.get_window_mode_options():
		window_mode_option.add_item(String(option.get("label", "")))
		window_mode_option.set_item_metadata(
			window_mode_option.item_count - 1,
			String(option.get("value", UserSettings.WINDOW_MODE_WINDOWED))
		)


func _rebuild_hud_mode_options() -> void:
	hud_mode_option.clear()
	for option in ShellSettingsCatalog.get_hud_mode_options():
		hud_mode_option.add_item(String(option.get("label", "")))
		hud_mode_option.set_item_metadata(
			hud_mode_option.item_count - 1,
			int(option.get("value", 0))
		)


func _on_window_mode_selected(index: int) -> void:
	set_window_mode(String(window_mode_option.get_item_metadata(index)))


func _on_hud_mode_selected(index: int) -> void:
	set_hud_detail_mode(int(hud_mode_option.get_item_metadata(index)))


func _select_option_by_metadata(button: OptionButton, expected_value: Variant) -> void:
	for index in range(button.item_count):
		if button.get_item_metadata(index) != expected_value:
			continue
		button.select(index)
		return
	button.select(0)


func _format_percent(value: float) -> String:
	return "%s%%" % int(round(clampf(value, 0.0, 1.0) * 100.0))


func _install_qa_ids() -> void:
	title_label.set_meta("qa_id", "shell_settings_title")
	audio_button.set_meta("qa_id", "shell_settings_audio")
	video_button.set_meta("qa_id", "shell_settings_video")
	hud_button.set_meta("qa_id", "shell_settings_hud")
	controls_button.set_meta("qa_id", "shell_settings_controls")
	back_button.set_meta("qa_id", "shell_settings_back")
