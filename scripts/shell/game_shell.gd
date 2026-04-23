extends Control
class_name GameShell

const CHARACTERS_SCENE := preload("res://scenes/shell/characters_screen.tscn")
const HOW_TO_PLAY_SCENE := preload("res://scenes/shell/how_to_play_screen.tscn")
const LOCAL_MATCH_SETUP_SCENE := preload("res://scenes/shell/local_match_setup.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/shell/main_menu.tscn")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

@onready var screen_root: Control = %ScreenRoot

var _active_screen: Control = null
var _active_screen_id := ""
var _characters_return_screen_id := "main_menu"
var _how_to_play_return_screen_id := "main_menu"
var _shell_session := ShellSession.new()


func _ready() -> void:
	open_main_menu()


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


func return_to_main_menu() -> void:
	open_main_menu()


func launch_local_match(launch_config: MatchLaunchConfig) -> void:
	if launch_config == null:
		return

	_shell_session.store_match_launch_config(launch_config)
	get_tree().change_scene_to_file(launch_config.target_scene_path)


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


func _wire_screen(screen: Control) -> void:
	if screen == null:
		return

	if screen.has_signal("play_local_requested"):
		screen.play_local_requested.connect(open_local_setup)
	if screen.has_signal("characters_requested"):
		screen.characters_requested.connect(open_characters)
	if screen.has_signal("how_to_play_requested"):
		screen.how_to_play_requested.connect(open_how_to_play)
	if screen.has_signal("exit_requested"):
		screen.exit_requested.connect(func() -> void:
			get_tree().quit()
		)
	if screen.has_signal("back_requested"):
		screen.back_requested.connect(_on_back_requested)
	if screen.has_signal("start_requested"):
		screen.start_requested.connect(launch_local_match)


func _on_back_requested() -> void:
	if _active_screen_id == "characters":
		_return_from_characters()
		return
	if _active_screen_id == "how_to_play":
		_return_from_how_to_play()
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
