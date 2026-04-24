extends RefCounted
class_name MatchModeVariantCatalog

const MatchController = preload("res://scripts/systems/match_controller.gd")

const VARIANT_SCORE_BY_CAUSE := "score_by_cause"

const _VARIANTS := [
	{
		"id": VARIANT_SCORE_BY_CAUSE,
		"label": "Score por causa",
		"summary": "Puntos por causa: ring-out domina, destruccion total es via secundaria.",
		"supports_teams": true,
		"supports_ffa": true,
		"enabled": true,
	},
	# Ultimo vivo necesita reglas de match propias antes de exponerse en runtime.
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
	return "Variante | %s" % String(variant.get("label", "Score por causa"))


static func _variant_supports_match_mode(variant: Dictionary, match_mode: int) -> bool:
	if match_mode == MatchController.MatchMode.FFA:
		return bool(variant.get("supports_ffa", false))
	return bool(variant.get("supports_teams", false))
