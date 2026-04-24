extends Node

const MatchHud = preload("res://scripts/ui/match_hud.gd")

@onready var match_hud: MatchHud = $UI/MatchHud


func _ready() -> void:
	match_hud.show_status("Friction Zero | Validacion HUD 8P")
	match_hud.show_round_state([
		"Ronda 1 en juego",
		"Marcador | FFA 8P",
		"Posiciones | 1. Player 1 (2) | 2. Player 2 (0) | +6",
	])
	match_hud.show_roster([
		"P1 Ariete | vivo | embestida lista",
		"P2 Grua | vivo | iman lista",
		"P3 Cizalla | vivo | corte",
		"P4 Patin | vivo | derrape 2/2",
		"P5 Aguja | vivo | pulso 1/2",
		"P6 Ancla | vivo | baliza lista",
		"P7 Ariete | vivo | embestida lista",
		"P8 Patin | vivo | derrape 2/2",
	])
