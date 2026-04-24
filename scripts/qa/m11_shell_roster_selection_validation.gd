extends Node

const MatchController = preload("res://scripts/systems/match_controller.gd")
const LocalMatchSetup = preload("res://scripts/shell/local_match_setup.gd")

@onready var local_match_setup: LocalMatchSetup = $UI/LocalMatchSetup


func _ready() -> void:
	local_match_setup.set_match_mode(MatchController.MatchMode.FFA)
	for _index in range(5):
		local_match_setup.cycle_slot_roster_entry(1)
	local_match_setup.focus_characters_button()
