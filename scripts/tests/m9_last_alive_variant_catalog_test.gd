extends SceneTree

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var teams_variants := MatchModeVariantCatalog.get_enabled_variants(MatchController.MatchMode.TEAMS)
	var ffa_variants := MatchModeVariantCatalog.get_enabled_variants(MatchController.MatchMode.FFA)
	_assert(teams_variants.size() == 1, "Teams debe conservar una sola variante.")
	_assert(String(teams_variants[0].get("id", "")) == MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE, "Teams debe usar score_by_cause.")
	_assert(ffa_variants.size() == 2, "FFA debe exponer Score por causa y Ultimo vivo.")
	_assert(String(ffa_variants[0].get("id", "")) == MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE, "Score por causa debe seguir default.")
	_assert(String(ffa_variants[1].get("id", "")) == MatchModeVariantCatalog.VARIANT_LAST_ALIVE, "Ultimo vivo debe ser segunda variante FFA.")
	_assert(MatchModeVariantCatalog.sanitize_variant_id(MatchController.MatchMode.TEAMS, MatchModeVariantCatalog.VARIANT_LAST_ALIVE) == MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE, "Ultimo vivo no debe sanear como Teams.")
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
