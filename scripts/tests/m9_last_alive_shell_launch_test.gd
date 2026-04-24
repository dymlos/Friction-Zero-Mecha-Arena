extends SceneTree

const LOCAL_MATCH_SETUP_SCENE := preload("res://scenes/shell/local_match_setup.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchModeVariantCatalog = preload("res://scripts/systems/match_mode_variant_catalog.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var setup := LOCAL_MATCH_SETUP_SCENE.instantiate()
	root.add_child(setup)
	await process_frame
	await process_frame

	setup.call("set_match_mode", MatchController.MatchMode.FFA)
	var default_variant_line := String(setup.call("get_variant_summary_line"))
	_assert(default_variant_line.contains("Puntos por eliminacion"), "FFA debe arrancar en Puntos por eliminacion.")
	_assert(default_variant_line.contains("principal"), "Puntos por eliminacion debe comunicarse como variante principal.")
	setup.call("cycle_mode_variant")
	var cycled_variant_line := String(setup.call("get_variant_summary_line"))
	_assert(cycled_variant_line.contains("Ultimo en pie"), "Setup FFA debe poder ciclar a Ultimo en pie.")
	_assert(cycled_variant_line.contains("alternativa"), "Ultimo en pie debe comunicarse como variante alternativa.")

	var launch_config = setup.call("build_launch_config")
	_assert(String(launch_config.mode_variant_id) == MatchModeVariantCatalog.VARIANT_LAST_ALIVE, "Launch config debe transportar last_alive.")

	setup.call("set_match_mode", MatchController.MatchMode.TEAMS)
	launch_config = setup.call("build_launch_config")
	_assert(String(launch_config.mode_variant_id) == MatchModeVariantCatalog.VARIANT_SCORE_BY_CAUSE, "Teams debe lanzar score_by_cause aunque FFA tuviera last_alive seleccionado.")
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
