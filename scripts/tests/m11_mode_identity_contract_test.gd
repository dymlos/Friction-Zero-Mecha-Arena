extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ffa_variants := MatchModeVariantCatalog.get_enabled_variants(MatchController.MatchMode.FFA)
	var teams_variants := MatchModeVariantCatalog.get_enabled_variants(MatchController.MatchMode.TEAMS)
	_assert(_variant_ids(ffa_variants) == [MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE, MatchModeVariantCatalog.VARIANT_LAST_ALIVE], "FFA debe exponer score_by_cause y last_alive en ese orden.")
	_assert(_variant_ids(teams_variants) == [MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE], "Teams debe exponer solo score_by_cause.")
	_assert(MatchModeVariantCatalog.sanitize_variant_id(MatchController.MatchMode.TEAMS, MatchModeVariantCatalog.VARIANT_LAST_ALIVE) == MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE, "last_alive saneado en Teams debe volver a score_by_cause.")
	for variant in ffa_variants:
		_assert(String(variant.get("post_death_model", "")) != MatchModeVariantCatalog.POST_DEATH_MODEL_TEAMS_SUPPORT, "Ninguna variante FFA debe declarar teams_support_ship.")
	_assert(MatchModeVariantCatalog.get_setup_summary_line(MatchController.MatchMode.FFA, MatchModeVariantCatalog.VARIANT_LAST_ALIVE).contains("alternativa"), "La linea de setup de last_alive debe comunicar alternativa.")
	_assert(MatchModeVariantCatalog.get_setup_summary_line(MatchController.MatchMode.FFA, MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE).contains("principal"), "La linea de setup default FFA debe comunicar principal.")
	_finish()


func _variant_ids(variants: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for variant in variants:
		ids.append(String(variant.get("id", "")))
	return ids


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
