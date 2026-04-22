extends SceneTree

const TESTS_ROOT := "res://scripts/tests"
const TEST_SUFFIX := "_test.gd"
const SELF_PATH := "res://scripts/tests/test_runner.gd"

var _failed := false


static func collect_test_script_paths() -> PackedStringArray:
	var discovered: PackedStringArray = PackedStringArray()
	_collect_scripts_in_dir(TESTS_ROOT, discovered)
	discovered.sort()
	return discovered


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var discovered := collect_test_script_paths()
	if discovered.is_empty():
		push_error("No se encontraron scripts de test en %s." % TESTS_ROOT)
		quit(1)
		return

	var executable_path := OS.get_executable_path()
	var project_path := ProjectSettings.globalize_path("res://")

	print("Running %s tests from %s" % [discovered.size(), TESTS_ROOT])
	for test_path in discovered:
		var output: Array[String] = []
		var args := PackedStringArray([
			"--headless",
			"--path",
			project_path,
			"-s",
			test_path,
		])
		print("TEST %s" % test_path)
		var exit_code := OS.execute(executable_path, args, output, true)
		for line in output:
			if line == "":
				continue
			print(line)
		if exit_code != 0:
			_failed = true
			push_error("Fallo %s con exit code %s." % [test_path, exit_code])

	if _failed:
		quit(1)
		return

	print("Suite OK: %s tests" % discovered.size())
	quit(0)


static func _collect_scripts_in_dir(dir_path: String, discovered: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue

		var child_path := "%s/%s" % [dir_path, entry]
		if dir.current_is_dir():
			_collect_scripts_in_dir(child_path, discovered)
		elif entry.ends_with(TEST_SUFFIX) and child_path != SELF_PATH:
			discovered.append(child_path)
		entry = dir.get_next()

	dir.list_dir_end()
