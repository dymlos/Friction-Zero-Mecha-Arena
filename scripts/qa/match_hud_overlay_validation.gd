extends Node

const MatchHud = preload("res://scripts/ui/match_hud.gd")

@onready var match_hud: MatchHud = $UI/MatchHud


func _ready() -> void:
	match_hud.show_status(
		"Estado del match | Pantalla compartida | HUD contextual con mensajes persistentes de validacion."
	)
	match_hud.show_round_state([
		"Ronda 3 | Presion progresiva activa en 00:18",
		"Objetivo | Equipo 1 2 puntos | Equipo 2 1 punto",
		"Advertencia | El borde norte vuelve a abrirse tras la cuenta regresiva.",
	])
	match_hud.show_roster([
		"Avanzado | P1 / Ariete | Apoyo activo | estabilizador > P2 / Grua | usa / | objetivo ,/. | vacio",
		"Avanzado | P2 / Grua | en pie | 3/4 partes | energia 2/1/4",
		"Avanzado | P3 / Cizalla | interferido por gate | 4/4 partes | energia 2/2/2",
		"Avanzado | P4 / Patin | fuera de rango | 4/4 partes | energia 1/3/2",
	])
