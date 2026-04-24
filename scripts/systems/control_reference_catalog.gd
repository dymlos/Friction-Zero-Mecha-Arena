extends RefCounted
class_name ControlReferenceCatalog

const DEFAULT_BUTTON_REFERENCE := "Habilidad o soltar: C / X | Choque: Space / A | Energia: Q/E o LB/RB | Overdrive: R / Y"
const UNIVERSAL_ACTION_LABELS := [
	"Choque / ataque",
	"Energia",
	"Overdrive",
	"Partes / item",
]


static func get_default_button_reference() -> String:
	return DEFAULT_BUTTON_REFERENCE


static func get_universal_action_labels() -> Array:
	return UNIVERSAL_ACTION_LABELS.duplicate()
