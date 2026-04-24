extends Node

const MatchHud = preload("res://scripts/ui/match_hud.gd")
const SETTINGS_SCREEN_SCENE = preload("res://scenes/shell/settings_screen.tscn")
const HOW_TO_PLAY_SCREEN_SCENE = preload("res://scenes/shell/how_to_play_screen.tscn")
const CHARACTERS_SCREEN_SCENE = preload("res://scenes/shell/characters_screen.tscn")

@export var surface_id := "settings"

@onready var match_hud: MatchHud = $UI/MatchHud


func _ready() -> void:
	match_hud.show_status("Friction Zero | Validacion pausa completa")
	match_hud.show_round_state([
		"Ronda 2 en juego",
		"Pausa | P1 al mando",
	])
	match_hud.show_pause_overlay("Pausa", [
		"Pausa | jugador P1 al mando",
		"Ayuda",
		"> %s" % _get_surface_label(),
	])
	var surface_scene := _get_surface_scene()
	if surface_scene == null:
		return
	var surface := surface_scene.instantiate() as Control
	if surface == null:
		return
	if surface.has_method("set_surface_scope"):
		surface.call("set_surface_scope", "pause")
	_set_process_mode_when_paused(surface)
	match_hud.get_pause_surface_root().add_child(surface)
	match_hud.set_pause_surface_visible(true)


func _get_surface_scene() -> PackedScene:
	match surface_id:
		"settings":
			return SETTINGS_SCREEN_SCENE
		"how_to_play":
			return HOW_TO_PLAY_SCREEN_SCENE
		"characters":
			return CHARACTERS_SCREEN_SCENE
	return null


func _get_surface_label() -> String:
	match surface_id:
		"settings":
			return "Opciones"
		"how_to_play":
			return "Como jugar"
		"characters":
			return "Robots"
	return surface_id


func _set_process_mode_when_paused(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	for child in node.get_children():
		_set_process_mode_when_paused(child)
