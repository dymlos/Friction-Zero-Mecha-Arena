extends SceneTree

const LocalScaleContract = preload("res://scripts/systems/local_scale_contract.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(LocalScaleContract.get_scale_tier(1) == LocalScaleContract.ScaleTier.POLISHED_2_4, "1P practica/smoke debe usar tier pulido.")
	_assert(LocalScaleContract.get_scale_tier(2) == LocalScaleContract.ScaleTier.POLISHED_2_4, "2P debe estar en el rango pulido.")
	_assert(LocalScaleContract.get_scale_tier(4) == LocalScaleContract.ScaleTier.POLISHED_2_4, "4P debe estar en el rango pulido.")
	_assert(LocalScaleContract.get_scale_tier(5) == LocalScaleContract.ScaleTier.VALIDATION_5_8, "5P abre el rango de validacion.")
	_assert(LocalScaleContract.get_scale_tier(8) == LocalScaleContract.ScaleTier.VALIDATION_5_8, "8P debe seguir siendo meta soportada, no pulida.")
	_assert(LocalScaleContract.is_polished_scale(4), "4P debe quedar marcado como pulido.")
	_assert(not LocalScaleContract.is_polished_scale(8), "8P no debe prometer la misma calidad que 2-4 sin playtest.")

	var polished_line := LocalScaleContract.get_setup_status_line(4, MatchController.MatchMode.FFA)
	_assert(polished_line.contains("2-4 pulido"), "El setup debe comunicar que 2-4 es el foco pulido.")
	_assert(polished_line.contains("FFA"), "El status debe conservar el modo actual.")

	var validation_line := LocalScaleContract.get_setup_status_line(8, MatchController.MatchMode.TEAMS)
	_assert(validation_line.contains("5-8 validacion"), "El setup debe marcar 5-8 como validacion.")
	_assert(validation_line.contains("4v4"), "Teams 8P debe comunicar 4v4.")

	var budget_4p := LocalScaleContract.get_shared_screen_budget(4)
	_assert(int(budget_4p.get("visible_rosters", 0)) == 4, "4P debe permitir roster visible por jugador.")
	_assert(int(budget_4p.get("max_hud_line_chars", 0)) >= 72, "4P puede tener lineas algo mas informativas.")

	var budget_8p := LocalScaleContract.get_shared_screen_budget(8)
	_assert(int(budget_8p.get("visible_rosters", 0)) == 8, "8P debe mantener una linea compacta por slot en HUD explicito.")
	_assert(int(budget_8p.get("max_hud_line_chars", 0)) <= 72, "8P debe mantener lineas compactas.")
	_assert(bool(budget_8p.get("compact_standings", false)), "8P debe compactar standings con +N.")

	var perf_1080 := LocalScaleContract.get_performance_budget("1920x1080")
	_assert(float(perf_1080.get("target_fps", 0.0)) == 60.0, "1080p debe apuntar a 60 fps.")
	_assert(float(perf_1080.get("frame_budget_ms", 0.0)) <= 16.7, "1080p debe usar presupuesto de frame de 60 fps.")
	_assert(bool(perf_1080.get("primary_reference", false)), "1080p debe quedar como referencia primaria.")

	var perf_720 := LocalScaleContract.get_performance_budget("1280x720")
	_assert(not bool(perf_720.get("primary_reference", true)), "720p debe ser comparacion secundaria.")

	var setup_scene := load("res://scenes/shell/local_match_setup.tscn") as PackedScene
	_assert(setup_scene != null, "Setup local debe existir.")
	var setup := setup_scene.instantiate()
	root.add_child(setup)
	await process_frame
	await process_frame
	_assert(setup.has_method("get_scale_status_line"), "Setup local debe exponer get_scale_status_line().")
	if setup.has_method("get_scale_status_line"):
		_assert(String(setup.call("get_scale_status_line")).contains("2-4 pulido"), "Setup default 4P debe comunicar el foco pulido.")
		for slot in range(5, 9):
			setup.call("set_slot_active", slot, true)
			setup.call("set_slot_input_source", slot, "joypad")
			setup.call("reserve_joypad_for_slot", slot, 40 + slot, true)
		_assert(String(setup.call("get_scale_status_line")).contains("5-8 validacion"), "Setup 8P debe comunicar validacion.")
	root.remove_child(setup)
	setup.free()
	await process_frame

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
