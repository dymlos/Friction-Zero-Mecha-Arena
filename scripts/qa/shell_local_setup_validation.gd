extends Node

const LocalMatchSetup = preload("res://scripts/shell/local_match_setup.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")

@onready var local_match_setup: LocalMatchSetup = $UI/LocalMatchSetup


func _ready() -> void:
	local_match_setup.set_match_mode(MatchController.MatchMode.FFA)
	local_match_setup.toggle_slot_control_mode(2)
	local_match_setup.toggle_slot_control_mode(4)
	local_match_setup.focus_characters_button()
