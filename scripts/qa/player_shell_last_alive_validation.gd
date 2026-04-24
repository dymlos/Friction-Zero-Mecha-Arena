extends Node

const GAME_SHELL_SCENE := preload("res://scenes/shell/game_shell.tscn")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")


func _ready() -> void:
	var shell := GAME_SHELL_SCENE.instantiate()
	add_child(shell)
	await get_tree().process_frame
	await get_tree().process_frame
	shell.open_local_setup()
	await get_tree().process_frame
	var setup = shell.get_active_screen()
	setup.set_match_mode(MatchController.MatchMode.FFA)
	setup.cycle_mode_variant()
	var launch_config = setup.build_launch_config()
	launch_config.hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT
	var main = shell.build_local_match_scene(launch_config)
	add_child(main)
