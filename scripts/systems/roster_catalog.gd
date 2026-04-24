extends RefCounted
class_name RosterCatalog

const ARIETE_CONFIG := preload("res://data/config/robots/ariete_archetype.tres")
const GRUA_CONFIG := preload("res://data/config/robots/grua_archetype.tres")
const CIZALLA_CONFIG := preload("res://data/config/robots/cizalla_archetype.tres")
const PATIN_CONFIG := preload("res://data/config/robots/patin_archetype.tres")
const AGUJA_CONFIG := preload("res://data/config/robots/aguja_archetype.tres")
const ANCLA_CONFIG := preload("res://data/config/robots/ancla_archetype.tres")
const ControlReferenceCatalog = preload("res://scripts/systems/control_reference_catalog.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")

const COMPETITIVE_ENTRY_IDS := ["ariete", "grua", "cizalla", "patin", "aguja", "ancla"]
const DEFAULT_SLOT_ENTRY_IDS := ["ariete", "grua", "cizalla", "patin", "aguja", "ancla", "ariete", "patin"]
const TEACHING_FOCUS_ENTRY_IDS := ["ariete", "patin", "cizalla"]
const VISUAL_DIFFERENTIATION_SCOPE := "moderada"
const VISUAL_IDENTITY_RULES := [
	"misma familia robotica industrial",
	"silueta/acento moderado",
	"lectura primaria desde el cuerpo",
	"HUD como refuerzo, no como unica lectura",
]
const CONFIG_BY_ID := {
	"ariete": ARIETE_CONFIG,
	"grua": GRUA_CONFIG,
	"cizalla": CIZALLA_CONFIG,
	"patin": PATIN_CONFIG,
	"aguja": AGUJA_CONFIG,
	"ancla": ANCLA_CONFIG,
}
const ARCHETYPE_FAMILIES := {
	"ariete": "Empuje / tanque",
	"grua": "Asistencia / rescate",
	"cizalla": "Dismantler",
	"patin": "Movilidad / reposicion",
	"aguja": "Poke / skillshot",
	"ancla": "Control / zona",
}
const MODE_NOTES := {
	"ariete": {
		"ffa": "Controla cruces cortos y amenaza bordes sin depender de terceros.",
		"teams": "Abre espacio frontal para que un aliado remate o rescate.",
	},
	"grua": {
		"ffa": "Sobrevive mejor alrededor de piezas sueltas y castiga persecuciones largas.",
		"teams": "Convierte rescates dificiles en rotaciones seguras para sostener al equipo.",
	},
	"cizalla": {
		"ffa": "Persigue robots tocados y decide cuando robar una baja ajena.",
		"teams": "Marca una pieza debil para que el equipo concentre el siguiente choque.",
	},
	"patin": {
		"ffa": "Roba angulos, evita encierros y vuelve al cierre cuando otros se exponen.",
		"teams": "Reposiciona rapido para cubrir rescates o rematar rutas abiertas.",
	},
	"aguja": {
		"ffa": "Presiona desde angulos y castiga rutas de escape sin dominar el centro.",
		"teams": "Abre objetivos para que un aliado cierre el choque.",
	},
	"ancla": {
		"ffa": "Corta rutas valiosas y obliga a elegir entre botin, borde o choque malo.",
		"teams": "Fija zonas de presion para que el equipo empuje hacia una salida concreta.",
	},
}


static func get_shell_roster() -> Array:
	return get_competitive_roster()


static func get_competitive_roster() -> Array:
	var roster: Array = []
	for entry_id in COMPETITIVE_ENTRY_IDS:
		roster.append(_build_entry(entry_id, CONFIG_BY_ID[entry_id]))

	return roster


static func get_competitive_entry(entry_id: String) -> Dictionary:
	for entry in get_competitive_roster():
		if String(entry.get("id", "")) == entry_id:
			return entry

	return {}


static func get_competitive_entry_ids() -> Array:
	return COMPETITIVE_ENTRY_IDS.duplicate()


static func get_teaching_focus_entry_ids() -> Array:
	return TEACHING_FOCUS_ENTRY_IDS.duplicate()


static func get_teaching_focus_roster() -> Array:
	var focus_roster: Array = []
	for entry_id in TEACHING_FOCUS_ENTRY_IDS:
		focus_roster.append(get_competitive_entry(entry_id))

	return focus_roster


static func get_universal_action_labels() -> Array:
	return ControlReferenceCatalog.get_universal_action_labels()


static func get_visual_identity_rules() -> Array:
	return VISUAL_IDENTITY_RULES.duplicate()


static func get_default_entry_id_for_slot(player_slot: int) -> String:
	var index := wrapi(player_slot - 1, 0, DEFAULT_SLOT_ENTRY_IDS.size())
	return DEFAULT_SLOT_ENTRY_IDS[index]


static func get_entry_id_for_archetype_path(resource_path: String) -> String:
	for entry in get_competitive_roster():
		if String(entry.get("config_path", "")) == resource_path:
			return String(entry.get("id", ""))

	return ""


static func get_shell_roster_entry(entry_id: String) -> Dictionary:
	return get_competitive_entry(entry_id)


static func get_shell_roster_entry_label(entry_id: String) -> String:
	return String(get_shell_roster_entry(entry_id).get("label", ""))


static func _build_entry(entry_id: String, config: RobotArchetypeConfig) -> Dictionary:
	return {
		"id": entry_id,
		"label": config.archetype_label,
		"role": config.role_label,
		"archetype_family": String(ARCHETYPE_FAMILIES.get(entry_id, config.role_label)),
		"mode_notes": MODE_NOTES.get(entry_id, {}),
		"fantasy": config.fantasy_line,
		"strength": config.strength_line,
		"risk": config.risk_line,
		"signature": config.signature_line,
		"primary_skill": config.core_skill_label if config.core_skill_label != "" else config.signature_line,
		"button_reference": ControlReferenceCatalog.get_default_button_reference(),
		"visual_differentiation_scope": VISUAL_DIFFERENTIATION_SCOPE,
		"teaching_focus": TEACHING_FOCUS_ENTRY_IDS.has(entry_id),
		"extra_skill_labels": "",
		"universal_actions": ControlReferenceCatalog.get_universal_action_labels(),
		"body_read": config.body_read_line,
		"easy": config.easy_line,
		"hard": config.hard_line,
		"accent_color": config.accent_color,
		"core_skill_label": config.core_skill_label,
		"config": config,
		"config_path": config.resource_path,
	}
