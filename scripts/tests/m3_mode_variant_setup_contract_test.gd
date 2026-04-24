extends SceneTree

const LOCAL_MATCH_SETUP_SCENE := preload("res://scenes/shell/local_match_setup.tscn")
const LocalSessionDraft = preload("res://scripts/systems/local_session_draft.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")

const MATCH_MODE_VARIANT_CATALOG_SCRIPT := "res://scripts/systems/match_mode_variant_catalog.gd"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog_script := load(MATCH_MODE_VARIANT_CATALOG_SCRIPT)
	_assert(catalog_script != null, "MatchModeVariantCatalog deberia vivir en scripts/systems.")
	if catalog_script != null:
		var teams_variants: Array = catalog_script.get_enabled_variants(MatchController.MatchMode.TEAMS)
		var ffa_variants: Array = catalog_script.get_enabled_variants(MatchController.MatchMode.FFA)
		_assert(
			teams_variants.size() == 1 and String(teams_variants[0].get("id", "")) == "score_by_cause",
			"Teams deberia exponer una sola variante activa: score_by_cause."
		)
		_assert(
			ffa_variants.size() == 2
			and String(ffa_variants[0].get("id", "")) == "score_by_cause"
			and String(ffa_variants[1].get("id", "")) == "last_alive",
			"FFA deberia exponer Score por causa y Ultimo vivo."
		)
		_assert(
			String(catalog_script.get_variant("score_by_cause").get("label", "")) == "Score por causa",
			"La variante score_by_cause deberia mostrar label legible."
		)

	var draft := LocalSessionDraft.new()
	_assert(draft.has_method("get_selected_mode_variant_id"), "LocalSessionDraft deberia exponer variante seleccionada.")
	_assert(draft.has_method("set_selected_mode_variant_id"), "LocalSessionDraft deberia permitir setear variante.")
	_assert(draft.has_method("cycle_mode_variant"), "LocalSessionDraft deberia permitir ciclar variante.")
	if draft.has_method("set_selected_mode_variant_id") and draft.has_method("get_selected_mode_variant_id"):
		draft.call("set_selected_mode_variant_id", "desconocida")
		_assert(
			String(draft.call("get_selected_mode_variant_id")) == "score_by_cause",
			"LocalSessionDraft deberia sanitizar variantes desconocidas a score_by_cause."
		)
	if draft.has_method("cycle_mode_variant") and draft.has_method("get_selected_mode_variant_id"):
		draft.call("set_match_mode", MatchController.MatchMode.FFA)
		draft.call("cycle_mode_variant")
		_assert(
			String(draft.call("get_selected_mode_variant_id")) == "last_alive",
			"Ciclar FFA debe llegar a Ultimo vivo."
		)
		draft.call("set_match_mode", MatchController.MatchMode.TEAMS)
		_assert(
			String(draft.call("get_selected_mode_variant_id")) == "score_by_cause",
			"Teams debe sanear Ultimo vivo a Score por causa."
		)

	var setup := LOCAL_MATCH_SETUP_SCENE.instantiate()
	root.add_child(setup)
	await process_frame
	await process_frame

	_assert(setup.has_method("get_variant_summary_line"), "LocalMatchSetup deberia exponer resumen de variante.")
	if setup.has_method("get_variant_summary_line"):
		_assert(
			String(setup.call("get_variant_summary_line")).contains("Variante | Score por causa"),
			"LocalMatchSetup deberia mostrar `Variante | Score por causa`."
		)
	if setup.has_method("build_launch_config"):
		var launch_config: Variant = setup.call("build_launch_config")
		var mode_variant_id := ""
		if launch_config != null:
			var raw_variant: Variant = launch_config.get("mode_variant_id")
			mode_variant_id = "" if raw_variant == null else String(raw_variant)
		_assert(
			launch_config != null and mode_variant_id == "score_by_cause",
			"LocalMatchSetup deberia transportar mode_variant_id en el launch config."
		)

	setup.queue_free()
	await process_frame
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
