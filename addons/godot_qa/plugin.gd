@tool
extends EditorPlugin

const AUTOLOAD_NAME := "GodotQaBridge"
const AUTOLOAD_PATH := "res://addons/godot_qa/qa_bridge.gd"

func _enter_tree() -> void:
	var autoload_setting := "autoload/%s" % AUTOLOAD_NAME
	if not ProjectSettings.has_setting(autoload_setting):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _exit_tree() -> void:
	var autoload_setting := "autoload/%s" % AUTOLOAD_NAME
	if ProjectSettings.has_setting(autoload_setting):
		remove_autoload_singleton(AUTOLOAD_NAME)
