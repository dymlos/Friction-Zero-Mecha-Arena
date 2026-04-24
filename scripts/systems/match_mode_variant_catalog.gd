extends RefCounted
class_name MatchModeVariantCatalog

const MatchController = preload("res://scripts/systems/match_controller.gd")

const VARIANT_SCORE_BY_CAUSE := "score_by_cause"
const VARIANT_LAST_ALIVE := "last_alive"
const PRESENTATION_ROLE_PRIMARY := "principal"
const PRESENTATION_ROLE_FFA_ALTERNATIVE := "alternativa_ffa"
const POST_DEATH_MODEL_FFA_AFTERMATH := "ffa_aftermath_neutral"
const POST_DEATH_MODEL_TEAMS_SUPPORT := "teams_support_ship"
const POST_DEATH_MODEL_NONE := "none"

const _VARIANTS := [
	{
		"id": VARIANT_SCORE_BY_CAUSE,
		"label": "Score por causa",
		"summary": "Puntos por causa: ring-out domina, destruccion total es via secundaria.",
		"score_label": "puntos",
		"presentation_role": PRESENTATION_ROLE_PRIMARY,
		"post_death_model": POST_DEATH_MODEL_FFA_AFTERMATH,
		"mode_identity": "ring-out dominante, destruccion modular secundaria",
		"supports_teams": true,
		"supports_ffa": true,
		"enabled": true,
	},
	{
		"id": VARIANT_LAST_ALIVE,
		"label": "Ultimo vivo",
		"summary": "FFA por rondas: gana quien queda en pie, sin puntos por causa.",
		"score_label": "rondas",
		"presentation_role": PRESENTATION_ROLE_FFA_ALTERNATIVE,
		"post_death_model": POST_DEATH_MODEL_FFA_AFTERMATH,
		"mode_identity": "supervivencia por rondas, sin score por causa",
		"supports_teams": false,
		"supports_ffa": true,
		"enabled": true,
	},
]


static func get_enabled_variants(match_mode: int) -> Array[Dictionary]:
	var variants: Array[Dictionary] = []
	for variant in _VARIANTS:
		if not bool(variant.get("enabled", false)):
			continue
		if not _variant_supports_match_mode(variant, match_mode):
			continue
		variants.append((variant as Dictionary).duplicate(true))
	return variants


static func get_default_variant_id(match_mode: int) -> String:
	var variants := get_enabled_variants(match_mode)
	if variants.is_empty():
		return VARIANT_SCORE_BY_CAUSE
	return String(variants[0].get("id", VARIANT_SCORE_BY_CAUSE))


static func get_primary_variant_id(match_mode: int) -> String:
	return VARIANT_SCORE_BY_CAUSE


static func get_variant(variant_id: String) -> Dictionary:
	for variant in _VARIANTS:
		if String(variant.get("id", "")) == variant_id:
			return (variant as Dictionary).duplicate(true)
	return {}


static func sanitize_variant_id(match_mode: int, variant_id: String) -> String:
	for variant in get_enabled_variants(match_mode):
		if String(variant.get("id", "")) == variant_id:
			return variant_id
	return get_default_variant_id(match_mode)


static func get_setup_summary_line(match_mode: int, variant_id: String) -> String:
	var sanitized_id := sanitize_variant_id(match_mode, variant_id)
	var variant := get_variant(sanitized_id)
	var label := String(variant.get("label", "Score por causa"))
	if match_mode == MatchController.MatchMode.FFA and is_subordinate_variant(match_mode, sanitized_id):
		return "Variante | %s (alternativa)" % label
	if match_mode == MatchController.MatchMode.FFA:
		return "Variante | %s (principal)" % label
	return "Variante | %s" % label


static func is_last_alive(variant_id: String) -> bool:
	return variant_id == VARIANT_LAST_ALIVE


static func is_subordinate_variant(match_mode: int, variant_id: String) -> bool:
	var sanitized_id := sanitize_variant_id(match_mode, variant_id)
	if match_mode != MatchController.MatchMode.FFA:
		return false
	return sanitized_id != get_primary_variant_id(match_mode)


static func get_variant_presentation_role(match_mode: int, variant_id: String) -> String:
	var variant := get_variant(sanitize_variant_id(match_mode, variant_id))
	return String(variant.get("presentation_role", PRESENTATION_ROLE_PRIMARY))


static func get_post_death_model(match_mode: int, variant_id: String = "") -> String:
	if match_mode == MatchController.MatchMode.TEAMS:
		return POST_DEATH_MODEL_TEAMS_SUPPORT
	var sanitized_id := sanitize_variant_id(match_mode, variant_id)
	var variant := get_variant(sanitized_id)
	return String(variant.get("post_death_model", POST_DEATH_MODEL_FFA_AFTERMATH))


static func get_variant_label(match_mode: int, variant_id: String) -> String:
	var variant := get_variant(sanitize_variant_id(match_mode, variant_id))
	return String(variant.get("label", "Score por causa"))


static func _variant_supports_match_mode(variant: Dictionary, match_mode: int) -> bool:
	if match_mode == MatchController.MatchMode.FFA:
		return bool(variant.get("supports_ffa", false))
	return bool(variant.get("supports_teams", false))
