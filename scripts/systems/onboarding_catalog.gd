extends RefCounted
class_name OnboardingCatalog


static func get_sections() -> Array:
	return [
		{
			"id": "victory",
			"label": "Como ganar",
			"summary": "Ganas empujando rivales al vacio o destruyendo sus cuatro partes antes de quedarte sin arena.",
			"bullets": [
				"Cada ronda termina por ring-out, destruccion total o presion final del borde.",
				"El cuerpo inutilizado sigue en la arena unos segundos y explota antes de limpiarse.",
				"Shared-screen: leer posicion y espacio libre importa tanto como pegar primero.",
			],
			"callout": "Busca el primer choque serio, pero no regales el borde por perseguir una baja.",
			"practice_module_id": "impacto",
		},
		{
			"id": "parts",
			"label": "Partes y desgaste",
			"summary": "Brazos y piernas tienen vida propia; perder piezas vuelve al robot mas torpe, no necesariamente fuera del match.",
			"bullets": [
				"Las piernas sostienen velocidad, control del deslizamiento e inercia.",
				"Los brazos sostienen empuje y dominio de corto alcance.",
				"Sin las cuatro partes, el robot queda inutilizado y pasa a ser un peligro empujable.",
			],
			"callout": "Un robot roto todavia puede generar caos: lee que parte le queda antes de entrar.",
			"practice_module_id": "partes",
		},
		{
			"id": "energy",
			"label": "Energia y Overdrive",
			"summary": "La energia se reparte por extremidad y decide si priorizas traccion, empuje o una apuesta corta de poder.",
			"bullets": [
				"Mas energia en piernas mejora arranque, control y capacidad de sostener el deslizamiento.",
				"Mas energia en brazos mejora impacto frontal y dominio al trabarse.",
				"Overdrive concentra poder temporal en una parte y despues deja penalidad u overheating.",
			],
			"callout": "No hace falta microgestionar cada segundo: cambia energia para un plan claro y visible.",
			"practice_module_id": "energia",
		},
		{
			"id": "recovery",
			"label": "Recuperar o negar partes",
			"summary": "Las partes destruidas caen en la arena; tus aliados pueden devolverlas y los rivales pueden tirarlas al vacio.",
			"bullets": [
				"Recuperar una parte devuelve vida parcial y mantiene el comeback abierto.",
				"Negar una parte enemiga vale tanto como cerrar una linea de escape cerca del borde.",
				"Al cargar una parte, tu robot deja de usar otras habilidades activas.",
			],
			"callout": "Si el centro esta limpio, mirar una parte caida puede abrir la jugada decisiva del equipo.",
			"practice_module_id": "recuperacion",
		},
		{
			"id": "controls",
			"label": "Easy, Hard y lectura",
			"summary": "Easy apunta con el movimiento; Hard separa locomocion y torso para ataques mas precisos.",
			"bullets": [
				"Easy: mover tambien orienta el robot. Es la opcion mas directa para party play.",
				"Hard: el stick izquierdo mueve y el derecho rota el torso para apuntar distinto al desplazamiento.",
				"En shared-screen importa que todos entiendan rapido que esta haciendo cada robot, no solo quien tiene mas inputs.",
			],
			"callout": "Si estas aprendiendo, empieza en Easy y cambia a Hard cuando ya leas bien rebotes, bordes y ventanas de choque.",
			"practice_module_id": "movimiento",
		},
	]


static func get_section(section_id: String) -> Dictionary:
	for section in get_sections():
		if String(section.get("id", "")) == section_id:
			return section

	return {}


static func get_practice_module_id_for_section(section_id: String) -> String:
	return String(get_section(section_id).get("practice_module_id", ""))
