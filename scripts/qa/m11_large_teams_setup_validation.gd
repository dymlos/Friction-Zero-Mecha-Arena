extends Node

const MatchController = preload("res://scripts/systems/match_controller.gd")
const LocalMatchSetup = preload("res://scripts/shell/local_match_setup.gd")
const LocalSessionDraft = preload("res://scripts/systems/local_session_draft.gd")

@onready var local_match_setup: LocalMatchSetup = $UI/LocalMatchSetup


func _ready() -> void:
	local_match_setup.set_match_mode(MatchController.MatchMode.TEAMS)
	for slot in range(5, 9):
		local_match_setup.set_slot_active(slot, true)
		local_match_setup.set_slot_input_source(slot, LocalSessionDraft.INPUT_SOURCE_JOYPAD)
		local_match_setup.reserve_joypad_for_slot(slot, slot + 20, true)
