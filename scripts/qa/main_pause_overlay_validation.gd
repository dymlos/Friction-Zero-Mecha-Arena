extends Node

const MatchHud = preload("res://scripts/ui/match_hud.gd")

@onready var match_hud: MatchHud = $UI/MatchHud


func _ready() -> void:
	match_hud.show_status("Friction Zero | Validacion overlay pausa")
	match_hud.show_round_state([
		"Ronda 2 en juego",
		"Pausa | P2 al mando",
	])
	match_hud.show_roster([
		"Easy | Player 1 / Ariete | Activo | 4/4 partes | WASD",
		"Easy | Player 2 / Grua | Activo | 3/4 partes | joy 21",
		"Easy | Player 3 / Cizalla | Activo | 4/4 partes | numpad",
		"Easy | Player 4 / Patin | Activo | 4/4 partes | IJKL",
	])
	match_hud.show_pause_overlay("Pausa", [
		"Owner | P2",
		"Navegacion | arriba/abajo mueve | ataque confirma | pausa reanuda",
		"Acciones",
		"> Reanudar",
		"  Reiniciar",
		"  Volver al menu",
		"Informacion",
		"  Settings",
		"  How to Play",
		"  Characters",
		"Quick settings",
		"  HUD | Contextual",
		"  Master | 80%",
		"  Musica | 70%",
		"  SFX | 90%",
	])
