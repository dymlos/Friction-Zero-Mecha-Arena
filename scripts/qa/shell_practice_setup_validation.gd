extends Node

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")


func _ready() -> void:
	var game_shell := GAME_SHELL_SCENE.instantiate()
	add_child(game_shell)
	await get_tree().process_frame
	await get_tree().process_frame
	game_shell.call("open_practice_setup")
