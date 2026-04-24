extends SceneTree

const LocalScaleContract = preload("res://scripts/systems/local_scale_contract.gd")
const SELF_PATH := "res://scripts/tools/m1_runtime_perf_probe.gd"
const DEFAULT_WARMUP_FRAMES := 30


func _init() -> void:
	if Engine.is_editor_hint():
		return
	if not OS.get_cmdline_args().has(SELF_PATH):
		return
	call_deferred("_run_cli")


func run_probe_for_test(scene_path: String, viewport_size: Vector2i, frames: int) -> Dictionary:
	return await _measure_scene(scene_path, viewport_size, frames, DEFAULT_WARMUP_FRAMES)


func build_milestone_result(
	result: Dictionary,
	milestone_id: String,
	visual_pass: bool,
	audio_pass: bool
) -> Dictionary:
	var tagged := result.duplicate(true)
	tagged["milestone"] = milestone_id
	tagged["visual_pass"] = visual_pass
	tagged["audio_pass"] = audio_pass
	return tagged


func _run_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print(JSON.stringify({
			"usage": "godot --headless --path . -s res://scripts/tools/m1_runtime_perf_probe.gd -- --scene res://scenes/main/main.tscn --viewport 1920x1080 --frames 600 --out user://m1_perf.json"
		}))
		quit(2)
		return

	var scene_path := _read_arg(args, "--scene", "res://scenes/main/main.tscn")
	var viewport_id := _read_arg(args, "--viewport", LocalScaleContract.PRIMARY_VIEWPORT)
	var frames := int(_read_arg(args, "--frames", "600"))
	var warmup_frames := int(_read_arg(args, "--warmup-frames", str(DEFAULT_WARMUP_FRAMES)))
	var out_path := _read_arg(args, "--out", "")
	var milestone_id := _read_arg(args, "--milestone", "")
	var visual_pass := args.has("--visual-pass")
	var audio_pass := args.has("--audio-pass")
	var viewport_size := _parse_viewport(viewport_id)

	var result := await _measure_scene(scene_path, viewport_size, frames, warmup_frames)
	if milestone_id != "":
		result = build_milestone_result(result, milestone_id, visual_pass, audio_pass)
	var json := JSON.stringify(result, "\t")
	if out_path != "":
		var file := FileAccess.open(out_path, FileAccess.WRITE)
		if file == null:
			push_error("No se pudo escribir %s" % out_path)
			quit(3)
			return
		file.store_string(json)
		file.close()
	print(json)
	quit(0)


func _measure_scene(scene_path: String, viewport_size: Vector2i, frames: int, warmup_frames: int = DEFAULT_WARMUP_FRAMES) -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return {
			"scene": scene_path,
			"viewport": _format_viewport(viewport_size),
			"frames": 0,
			"warmup_frames": 0,
			"error": "scene_tree_not_available",
			"budget": LocalScaleContract.get_performance_budget(_format_viewport(viewport_size)),
		}

	tree.root.size = viewport_size
	var packed_scene := load(scene_path)
	if not (packed_scene is PackedScene):
		return {
			"scene": scene_path,
			"viewport": _format_viewport(viewport_size),
			"frames": 0,
			"warmup_frames": 0,
			"error": "scene_not_found",
			"budget": LocalScaleContract.get_performance_budget(_format_viewport(viewport_size)),
		}

	var scene := (packed_scene as PackedScene).instantiate()
	tree.root.add_child(scene)
	tree.current_scene = scene
	await tree.process_frame
	await tree.process_frame
	var warmup_count := maxi(warmup_frames, 0)
	for _index in range(warmup_count):
		await tree.process_frame

	var measured_frames := maxi(frames, 1)
	var samples: Array[float] = []
	var previous_ticks := Time.get_ticks_usec()
	for _index in range(measured_frames):
		await tree.process_frame
		var now := Time.get_ticks_usec()
		samples.append(float(now - previous_ticks) / 1000.0)
		previous_ticks = now

	var avg_ms := _average(samples)
	var max_ms := _max(samples)
	var budget := LocalScaleContract.get_performance_budget(_format_viewport(viewport_size))
	var frame_budget := float(budget.get("frame_budget_ms", 16.7))
	var warning_budget := float(budget.get("warning_frame_ms", 20.0))

	if is_instance_valid(scene):
		tree.root.remove_child(scene)
		scene.free()
	tree.current_scene = null
	await tree.process_frame

	return {
		"scene": scene_path,
		"viewport": _format_viewport(viewport_size),
		"frames": measured_frames,
		"warmup_frames": warmup_count,
		"avg_frame_ms": snappedf(avg_ms, 0.001),
		"max_frame_ms": snappedf(max_ms, 0.001),
		"target_met_avg": avg_ms <= frame_budget,
		"warning_max_exceeded": max_ms > warning_budget,
		"budget": budget,
	}


func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _max(values: Array[float]) -> float:
	var result := 0.0
	for value in values:
		result = maxf(result, value)
	return result


func _read_arg(args: Array[String], key: String, fallback: String) -> String:
	var index := args.find(key)
	if index < 0 or index + 1 >= args.size():
		return fallback
	return String(args[index + 1])


func _parse_viewport(viewport_id: String) -> Vector2i:
	var parts := viewport_id.split("x", false)
	if parts.size() != 2:
		return Vector2i(1920, 1080)
	return Vector2i(int(parts[0]), int(parts[1]))


func _format_viewport(viewport_size: Vector2i) -> String:
	return "%sx%s" % [viewport_size.x, viewport_size.y]
