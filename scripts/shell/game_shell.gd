extends Control
class_name GameShell

const CHARACTERS_SCENE := preload("res://scenes/shell/characters_screen.tscn")
const HOW_TO_PLAY_SCENE := preload("res://scenes/shell/how_to_play_screen.tscn")
const LOCAL_MATCH_SETUP_SCENE := preload("res://scenes/shell/local_match_setup.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/shell/main_menu.tscn")
const PRACTICE_SETUP_SCENE := preload("res://scenes/shell/practice_setup.tscn")
const SETTINGS_SCENE := preload("res://scenes/shell/settings_screen.tscn")
const InputPromptCatalog = preload("res://scripts/systems/input_prompt_catalog.gd")
const LocalSessionDraft = preload("res://scripts/systems/local_session_draft.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")
const STICK_NAV_DEADZONE := 0.55
const STICK_NAV_FIRST_REPEAT_SECONDS := 0.28
const STICK_NAV_HELD_REPEAT_SECONDS := 0.16

@onready var screen_root: Control = %ScreenRoot

var _active_screen: Control = null
var _active_screen_id := ""
var _help_label: Label = null
var _stick_nav_direction := Vector2i.ZERO
var _stick_nav_cooldown := 0.0
var _characters_return_screen_id := "main_menu"
var _how_to_play_return_screen_id := "main_menu"
var _practice_return_screen_id := "main_menu"
var _settings_return_screen_id := "main_menu"
var _shell_session := ShellSession.new()
var _local_session_draft := LocalSessionDraft.new()


func _ready() -> void:
	InputPromptCatalog.ensure_menu_input_actions()
	_create_help_label()
	_set_shell_music_state()
	open_main_menu()


func _process(delta: float) -> void:
	_update_stick_navigation(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _is_pressed_action(event, InputPromptCatalog.MENU_START_ACTION):
		if _try_handle_start_shortcut():
			get_viewport().set_input_as_handled()
		return

	if _is_pressed_action(event, "ui_cancel"):
		if _try_handle_back_shortcut():
			get_viewport().set_input_as_handled()


func get_active_screen_id() -> String:
	return _active_screen_id


func get_active_screen() -> Control:
	return _active_screen


func open_main_menu() -> void:
	_mount_screen(MAIN_MENU_SCENE, "main_menu")


func open_local_setup() -> void:
	_mount_screen(LOCAL_MATCH_SETUP_SCENE, "local_match_setup")


func open_characters(return_screen_id: String = "") -> void:
	var resolved_return_screen_id := return_screen_id
	if resolved_return_screen_id == "":
		resolved_return_screen_id = _active_screen_id
	if resolved_return_screen_id == "" or resolved_return_screen_id == "characters":
		resolved_return_screen_id = "main_menu"

	_characters_return_screen_id = resolved_return_screen_id
	_mount_screen(CHARACTERS_SCENE, "characters")


func open_how_to_play(return_screen_id: String = "") -> void:
	var resolved_return_screen_id := return_screen_id
	if resolved_return_screen_id == "":
		resolved_return_screen_id = _active_screen_id
	if resolved_return_screen_id == "" or resolved_return_screen_id == "how_to_play":
		resolved_return_screen_id = "main_menu"

	_how_to_play_return_screen_id = resolved_return_screen_id
	_mount_screen(HOW_TO_PLAY_SCENE, "how_to_play")


func open_practice_setup(return_screen_id: String = "", module_id: String = "") -> void:
	var resolved_return_screen_id := return_screen_id
	if resolved_return_screen_id == "":
		resolved_return_screen_id = _active_screen_id
	if resolved_return_screen_id == "" or resolved_return_screen_id == "practice_setup":
		resolved_return_screen_id = "main_menu"

	_practice_return_screen_id = resolved_return_screen_id
	_mount_screen(PRACTICE_SETUP_SCENE, "practice_setup")
	if is_instance_valid(_active_screen) and _active_screen.has_method("set_preserve_existing_roster"):
		_active_screen.call("set_preserve_existing_roster", resolved_return_screen_id == "local_match_setup")
	if is_instance_valid(_active_screen) and _active_screen.has_method("set_selected_module"):
		_active_screen.call_deferred("set_selected_module", module_id)


func open_settings(return_screen_id: String = "") -> void:
	var resolved_return_screen_id := return_screen_id
	if resolved_return_screen_id == "":
		resolved_return_screen_id = _active_screen_id
	if resolved_return_screen_id == "" or resolved_return_screen_id == "settings":
		resolved_return_screen_id = "main_menu"

	_settings_return_screen_id = resolved_return_screen_id
	_mount_screen(SETTINGS_SCENE, "settings")


func return_to_main_menu() -> void:
	open_main_menu()


func launch_local_match(launch_config: MatchLaunchConfig) -> void:
	if launch_config == null:
		return

	_shell_session.store_match_launch_config(launch_config)
	get_tree().change_scene_to_file(launch_config.target_scene_path)


func build_local_match_scene(launch_config: MatchLaunchConfig) -> Node:
	if launch_config == null:
		return null

	var packed_scene := load(launch_config.target_scene_path)
	if not (packed_scene is PackedScene):
		return null

	_shell_session.store_match_launch_config(launch_config)
	return (packed_scene as PackedScene).instantiate()


func _mount_screen(screen_scene: PackedScene, screen_id: String) -> void:
	if screen_root == null or screen_scene == null:
		return

	if is_instance_valid(_active_screen):
		screen_root.remove_child(_active_screen)
		_active_screen.queue_free()

	var screen_instance := screen_scene.instantiate()
	if not (screen_instance is Control):
		return

	_active_screen = screen_instance as Control
	_active_screen_id = screen_id
	screen_root.add_child(_active_screen)
	_wire_screen(_active_screen)
	_refresh_help_label()


func _wire_screen(screen: Control) -> void:
	if screen == null:
		return
	if screen.has_method("set_session_draft"):
		screen.call("set_session_draft", _local_session_draft)

	if screen.has_signal("play_local_requested"):
		screen.play_local_requested.connect(func() -> void:
			_play_audio_cue("ui_confirm")
			open_local_setup()
		)
	if screen.has_signal("characters_requested"):
		screen.characters_requested.connect(func() -> void:
			_play_audio_cue("ui_confirm")
			open_characters()
		)
	if screen.has_signal("how_to_play_requested"):
		screen.how_to_play_requested.connect(func() -> void:
			_play_audio_cue("ui_confirm")
			open_how_to_play()
		)
	if screen.has_signal("settings_requested"):
		screen.settings_requested.connect(func() -> void:
			_play_audio_cue("ui_confirm")
			open_settings()
		)
	if screen.has_signal("practice_requested"):
		screen.practice_requested.connect(func(module_id: String = "") -> void:
			_play_audio_cue("ui_confirm")
			open_practice_setup("", module_id)
		)
	if screen.has_signal("exit_requested"):
		screen.exit_requested.connect(func() -> void:
			_play_audio_cue("ui_back")
			get_tree().quit()
		)
	if screen.has_signal("back_requested"):
		screen.back_requested.connect(func() -> void:
			_play_audio_cue("ui_back")
			_on_back_requested()
		)
	if screen.has_signal("start_requested"):
		screen.start_requested.connect(func(launch_config: MatchLaunchConfig) -> void:
			_play_audio_cue("ui_confirm")
			launch_local_match(launch_config)
		)


func _on_back_requested() -> void:
	if _active_screen_id == "characters":
		_return_from_characters()
		return
	if _active_screen_id == "how_to_play":
		_return_from_how_to_play()
		return
	if _active_screen_id == "practice_setup":
		_return_from_practice_setup()
		return
	if _active_screen_id == "settings":
		_return_from_settings()
		return

	return_to_main_menu()


func _return_from_characters() -> void:
	var target_screen_id := _characters_return_screen_id
	if target_screen_id == "local_match_setup":
		open_local_setup()
	else:
		target_screen_id = "main_menu"
		open_main_menu()

	call_deferred("_restore_focus_after_characters_return", target_screen_id)


func _restore_focus_after_characters_return(target_screen_id: String) -> void:
	if not is_instance_valid(_active_screen):
		return

	if target_screen_id in ["main_menu", "local_match_setup"] and _active_screen.has_method("focus_characters_button"):
		_active_screen.call_deferred("focus_characters_button")


func _return_from_how_to_play() -> void:
	var target_screen_id := _how_to_play_return_screen_id
	if target_screen_id == "local_match_setup":
		open_local_setup()
	else:
		target_screen_id = "main_menu"
		open_main_menu()

	call_deferred("_restore_focus_after_how_to_play_return", target_screen_id)


func _restore_focus_after_how_to_play_return(target_screen_id: String) -> void:
	if not is_instance_valid(_active_screen):
		return

	if target_screen_id in ["main_menu", "local_match_setup"] and _active_screen.has_method("focus_how_to_play_button"):
		_active_screen.call_deferred("focus_how_to_play_button")


func _return_from_practice_setup() -> void:
	var target_screen_id := _practice_return_screen_id
	if target_screen_id == "local_match_setup":
		open_local_setup()
	elif target_screen_id == "how_to_play":
		open_how_to_play("local_match_setup" if _how_to_play_return_screen_id == "local_match_setup" else "main_menu")
	else:
		target_screen_id = "main_menu"
		open_main_menu()

	call_deferred("_restore_focus_after_practice_return", target_screen_id)


func _restore_focus_after_practice_return(target_screen_id: String) -> void:
	if not is_instance_valid(_active_screen):
		return

	if target_screen_id in ["main_menu", "local_match_setup", "how_to_play"] and _active_screen.has_method("focus_practice_button"):
		_active_screen.call_deferred("focus_practice_button")


func _return_from_settings() -> void:
	var target_screen_id := _settings_return_screen_id
	if target_screen_id != "main_menu":
		target_screen_id = "main_menu"
	open_main_menu()
	call_deferred("_restore_focus_after_settings_return", target_screen_id)


func _restore_focus_after_settings_return(target_screen_id: String) -> void:
	if not is_instance_valid(_active_screen):
		return
	if target_screen_id == "main_menu" and _active_screen.has_method("focus_settings_button"):
		_active_screen.call_deferred("focus_settings_button")


func _play_audio_cue(cue_id: String) -> void:
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director == null or not audio_director.has_method("play_cue"):
		return

	audio_director.call("play_cue", cue_id)


func _set_shell_music_state() -> void:
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director == null or not audio_director.has_method("set_music_state"):
		return

	audio_director.call("set_music_state", "shell")


func _try_handle_start_shortcut() -> bool:
	if is_instance_valid(_active_screen) and _active_screen.has_method("request_start_from_shortcut"):
		return bool(_active_screen.call("request_start_from_shortcut"))

	return false


func _try_handle_back_shortcut() -> bool:
	if _active_screen_id == "" or _active_screen_id == "main_menu":
		return false

	_play_audio_cue("ui_back")
	_on_back_requested()
	return true


func _is_pressed_action(event: InputEvent, action_name: String) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.echo:
			return false

	return event.is_action_pressed(StringName(action_name))


func _create_help_label() -> void:
	if _help_label != null:
		return

	_help_label = Label.new()
	_help_label.name = "GamepadHelpLabel"
	_help_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_help_label.theme_type_variation = &"ShellSubtitle"
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help_label.anchor_left = 0.0
	_help_label.anchor_right = 1.0
	_help_label.anchor_top = 1.0
	_help_label.anchor_bottom = 1.0
	_help_label.offset_left = 24.0
	_help_label.offset_right = -24.0
	_help_label.offset_top = -48.0
	_help_label.offset_bottom = -12.0
	_help_label.set_meta("qa_id", "shell_gamepad_help")
	add_child(_help_label)


func _refresh_help_label() -> void:
	if _help_label == null:
		return

	var start_enabled := is_instance_valid(_active_screen) and _active_screen.has_method("request_start_from_shortcut")
	_help_label.text = InputPromptCatalog.get_menu_navigation_help_line(start_enabled, true)


func _update_stick_navigation(delta: float) -> void:
	var next_direction := _get_left_stick_navigation_direction()
	if next_direction == Vector2i.ZERO:
		_stick_nav_direction = Vector2i.ZERO
		_stick_nav_cooldown = 0.0
		return

	_stick_nav_cooldown = maxf(_stick_nav_cooldown - delta, 0.0)
	if next_direction == _stick_nav_direction and _stick_nav_cooldown > 0.0:
		return

	_dispatch_navigation_action(next_direction)
	if next_direction != _stick_nav_direction:
		_stick_nav_cooldown = STICK_NAV_FIRST_REPEAT_SECONDS
	else:
		_stick_nav_cooldown = STICK_NAV_HELD_REPEAT_SECONDS
	_stick_nav_direction = next_direction


func _get_left_stick_navigation_direction() -> Vector2i:
	var strongest_vector := Vector2.ZERO
	for device_id in Input.get_connected_joypads():
		var raw_vector := Vector2(
			Input.get_joy_axis(int(device_id), JOY_AXIS_LEFT_X),
			Input.get_joy_axis(int(device_id), JOY_AXIS_LEFT_Y)
		)
		if raw_vector.length_squared() > strongest_vector.length_squared():
			strongest_vector = raw_vector

	if strongest_vector.length() < STICK_NAV_DEADZONE:
		return Vector2i.ZERO
	if absf(strongest_vector.y) >= absf(strongest_vector.x):
		return Vector2i(0, 1 if strongest_vector.y > 0.0 else -1)
	return Vector2i(1 if strongest_vector.x > 0.0 else -1, 0)


func _dispatch_navigation_action(direction: Vector2i) -> void:
	var action_name := ""
	if direction.y < 0:
		action_name = "ui_up"
	elif direction.y > 0:
		action_name = "ui_down"
	elif direction.x < 0:
		action_name = "ui_left"
	elif direction.x > 0:
		action_name = "ui_right"
	if action_name == "":
		return

	var press_event := InputEventAction.new()
	press_event.action = StringName(action_name)
	press_event.pressed = true
	Input.parse_input_event(press_event)

	var release_event := InputEventAction.new()
	release_event.action = StringName(action_name)
	release_event.pressed = false
	Input.parse_input_event(release_event)
