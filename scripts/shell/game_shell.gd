extends Control
class_name GameShell

const LOCAL_MATCH_SETUP_SCENE := preload("res://scenes/shell/local_match_setup.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/shell/main_menu.tscn")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")

@onready var screen_root: Control = %ScreenRoot

var _active_screen: Control = null
var _active_screen_id := ""
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
	if screen.has_signal("exit_requested"):
		screen.exit_requested.connect(func() -> void:
			get_tree().quit()
		)
	if screen.has_signal("back_requested"):
		screen.back_requested.connect(return_to_main_menu)
	if screen.has_signal("start_requested"):
		screen.start_requested.connect(launch_local_match)
