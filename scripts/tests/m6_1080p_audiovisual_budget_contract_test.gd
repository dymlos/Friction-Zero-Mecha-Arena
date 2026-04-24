extends SceneTree

const PROBE_SCRIPT := "res://scripts/tools/m1_runtime_perf_probe.gd"
const LocalScaleContract = preload("res://scripts/systems/local_scale_contract.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(LocalScaleContract.PRIMARY_VIEWPORT == "1920x1080", "M6 debe conservar 1080p como referencia primaria.")

	var script := load(PROBE_SCRIPT)
	_assert(script != null, "El perf probe compartido debe existir.")
	if script == null:
		_finish()
		return

	var probe = script.new()
	_assert(probe.has_method("run_probe_for_test"), "El probe debe mantener run_probe_for_test().")
	_assert(probe.has_method("build_milestone_result"), "El probe debe poder etiquetar resultados por milestone.")
	if not probe.has_method("run_probe_for_test") or not probe.has_method("build_milestone_result"):
		if probe is Object and is_instance_valid(probe):
			probe.free()
		_finish()
		return

	var result: Dictionary = await probe.call("run_probe_for_test", "res://scenes/main/main.tscn", Vector2i(1920, 1080), 24)
	var tagged: Dictionary = probe.call("build_milestone_result", result, "m6-pase-audiovisual-de-produccion", true, true)

	_assert(String(tagged.get("milestone", "")) == "m6-pase-audiovisual-de-produccion", "El JSON M6 debe declarar milestone.")
	_assert(bool(tagged.get("visual_pass", false)), "El JSON M6 debe declarar que el pase visual esta activo.")
	_assert(bool(tagged.get("audio_pass", false)), "El JSON M6 debe declarar que el pase de audio esta activo.")
	_assert(String(tagged.get("viewport", "")) == "1920x1080", "El checkpoint M6 debe correr a 1920x1080.")
	_assert(bool((tagged.get("budget", {}) as Dictionary).get("primary_reference", false)), "El budget 1080p debe ser primary_reference.")
	_assert(float(tagged.get("avg_frame_ms", 99.0)) <= float((tagged.get("budget", {}) as Dictionary).get("frame_budget_ms", 16.7)), "El promedio debe respetar budget 1080p.")

	if probe is Object and is_instance_valid(probe):
		probe.free()
	await process_frame
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
