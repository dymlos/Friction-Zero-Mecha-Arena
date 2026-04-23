extends Node

const PlayerShellLoopValidationDriver = preload("res://scripts/qa/player_shell_loop_validation_driver.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")


func _ready() -> void:
	var driver := PlayerShellLoopValidationDriver.new()
	driver.configure(MatchController.MatchMode.TEAMS)
	call_deferred("add_child", driver)
