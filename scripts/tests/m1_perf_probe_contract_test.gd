extends SceneTree

const PROBE_SCRIPT := "res://scripts/tools/m1_runtime_perf_probe.gd"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var script := load(PROBE_SCRIPT)
	_assert(script != null, "El probe M1 debe existir en scripts/tools/m1_runtime_perf_probe.gd.")
	if script == null:
		_finish()
		return

	var probe = script.new()
	_assert(probe.has_method("run_probe_for_test"), "El probe debe exponer run_probe_for_test().")
	if not probe.has_method("run_probe_for_test"):
		_finish()
		return

	var result: Dictionary = await probe.call("run_probe_for_test", "res://scenes/main/main_ffa.tscn", Vector2i(1920, 1080), 24)
	_assert(String(result.get("scene", "")) == "res://scenes/main/main_ffa.tscn", "El JSON debe conservar la escena.")
	_assert(String(result.get("viewport", "")) == "1920x1080", "El JSON debe conservar viewport.")
	_assert(int(result.get("frames", 0)) == 24, "El JSON debe conservar frame count.")
	_assert(float(result.get("avg_frame_ms", -1.0)) >= 0.0, "avg_frame_ms debe ser numerico.")
	_assert(float(result.get("max_frame_ms", -1.0)) >= 0.0, "max_frame_ms debe ser numerico.")
	_assert(result.has("budget"), "El JSON debe incluir budget.")
	var budget: Dictionary = result.get("budget", {})
	_assert(bool(budget.get("primary_reference", false)), "1920x1080 debe ser primary_reference.")
	_assert(float(budget.get("frame_budget_ms", 0.0)) <= 16.7, "Budget 1080p debe apuntar a 60 fps.")
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
