extends Node

@onready var characters_screen: Control = $UI/CharactersScreen


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	characters_screen.set_filter("range_zone")
	characters_screen.select_character_by_id("ancla")
