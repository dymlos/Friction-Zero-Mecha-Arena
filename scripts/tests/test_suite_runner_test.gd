extends SceneTree

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner_script := load("res://scripts/tests/test_runner.gd")
	_assert(runner_script != null, "La suite headless deberia exponer un entrypoint comun en scripts/tests/test_runner.gd.")
	if runner_script == null:
		_finish()
		return

	_assert(runner_script.has_method("collect_test_script_paths"), "El runner comun deberia exponer collect_test_script_paths() para discovery automatico.")
	if not runner_script.has_method("collect_test_script_paths"):
		_finish()
		return

	var discovered = runner_script.collect_test_script_paths()
	_assert(discovered is PackedStringArray, "El discovery deberia devolver un PackedStringArray estable.")
	_assert(
		discovered.has("res://scripts/tests/robot_disabled_warning_indicator_test.gd"),
		"El runner comun deberia incluir tests existentes del proyecto."
	)
	_assert(
		not discovered.has("res://scripts/tests/test_runner.gd"),
		"El runner comun no deberia ejecutarse a si mismo dentro de la suite."
	)
	_assert(
		discovered.has("res://scripts/tests/test_suite_runner_test.gd"),
		"El smoke test del runner tambien deberia formar parte del discovery automatico."
	)

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
