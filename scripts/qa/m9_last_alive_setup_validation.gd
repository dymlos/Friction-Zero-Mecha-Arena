extends Node

const MatchController = preload("res://scripts/systems/match_controller.gd")

@onready var setup := $UI/LocalMatchSetup


func _ready() -> void:
	setup.set_match_mode(MatchController.MatchMode.FFA)
	setup.cycle_mode_variant()
