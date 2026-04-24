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
		"Simple | P1 / Ariete | activo | 4/4 partes | WASD",
		"Simple | P2 / Grua | activo | 3/4 partes | joy 21",
		"Simple | P3 / Cizalla | activo | 4/4 partes | numpad",
		"Simple | P4 / Patin | activo | 4/4 partes | IJKL",
	])
	match_hud.show_pause_overlay("Pausa", [
		"Pausa | jugador P2 al mando",
		"Navegacion | stick izq. mueve | stick der. desplaza texto | A acepta | B vuelve",
		"Acciones",
		"> Reanudar",
		"  Reiniciar",
		"  Volver al menu",
		"Ayuda",
		"  Opciones",
		"  Como jugar",
		"  Robots",
		"Ajustes rapidos",
		"  Ayuda | Contextual",
		"  General | 80%",
		"  Musica | 70%",
		"  Efectos | 90%",
	])
