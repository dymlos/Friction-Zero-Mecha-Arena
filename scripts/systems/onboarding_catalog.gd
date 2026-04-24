extends RefCounted
class_name OnboardingCatalog


static func get_sections() -> Array:
	return [
		{
			"id": "controls",
			"label": "Movimiento y control",
			"summary": "Aprende a arrancar con peso, deslizar, frenar y elegir entre control simple o avanzado.",
			"bullets": [
				"Simple: el robot mira hacia donde lo mueves.",
				"Avanzado: mueves con el stick izquierdo y apuntas el torso con el derecho.",
				"Controlar el deslizamiento importa mas que acelerar sin plan.",
			],
			"callout": "Primero siente el patinaje; despues busca el choque.",
			"practice_module_id": "movimiento",
		},
		{
			"id": "victory",
			"label": "Como ganar",
			"summary": "Ganas empujando rivales fuera, destruyendo sus cuatro partes o sobreviviendo al cierre.",
			"bullets": [
				"Empujar al borde es la forma principal de eliminar.",
				"Destruir todas las partes tambien elimina, pero suele llevar mas trabajo.",
				"El cuerpo inutilizado explota despues de unos segundos y puede cambiar el cierre.",
			],
			"callout": "Mira el borde antes de perseguir dano.",
			"practice_module_id": "impacto",
		},
		{
			"id": "combat",
			"label": "Combate e impacto",
			"summary": "El duelo ideal es leer, reposicionarse y convertir un choque preciso en ventaja clara.",
			"bullets": [
				"Un impacto bueno desplaza, abre borde o expone una parte concreta.",
				"El timing y el angulo importan mas que chocar todo el tiempo.",
				"Las habilidades sirven para abrir ventanas, no para llenar la pantalla.",
			],
			"callout": "El golpe decisivo empieza antes del contacto.",
			"practice_module_id": "impacto",
		},
		{
			"id": "parts",
			"label": "Partes y desgaste",
			"summary": "Brazos y piernas tienen vida propia; perder piezas te vuelve mas torpe, pero no te deja sin chances.",
			"bullets": [
				"Piernas: velocidad, control del deslizamiento e inercia.",
				"Brazos: empuje y dominio de corto alcance.",
				"Sin las cuatro partes, el robot queda inutilizado y pasa a ser un peligro empujable.",
			],
			"callout": "Lee que parte queda antes de entrar.",
			"practice_module_id": "partes",
		},
		{
			"id": "energy",
			"label": "Energia y Overdrive",
			"summary": "La energia por extremidad decide si priorizas traccion, empuje o una apuesta corta de poder.",
			"bullets": [
				"Mas energia en piernas mejora control y entrada.",
				"Mas energia en brazos mejora presion frontal.",
				"Overdrive concentra poder temporal y luego castiga con penalidad.",
			],
			"callout": "Cambia energia para un plan visible, no por reflejo.",
			"practice_module_id": "energia",
		},
		{
			"id": "recovery",
			"label": "Recuperar o negar partes",
			"summary": "Las partes destruidas caen en la arena: puedes devolver las aliadas o tirar las rivales al vacio.",
			"bullets": [
				"Recuperar una parte devuelve vida parcial y mantiene comeback.",
				"Negar una parte rival tambien gana espacio tactico.",
				"Cargar una parte bloquea otras habilidades activas.",
			],
			"callout": "Una parte caida puede valer tanto como una baja.",
			"practice_module_id": "recuperacion",
		},
	]


static func get_section(section_id: String) -> Dictionary:
	for section in get_sections():
		if String(section.get("id", "")) == section_id:
			return section

	return {}


static func get_practice_module_id_for_section(section_id: String) -> String:
	return String(get_section(section_id).get("practice_module_id", ""))
