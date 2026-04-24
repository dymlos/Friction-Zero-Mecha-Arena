extends SceneTree

const CueBank = preload("res://scripts/audio/procedural_cue_bank.gd")
const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const DETACHED_PART_SCENE := preload("res://scenes/robots/detached_part.tscn")
const Main = preload("res://scripts/main/main.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cue_bank := CueBank.new()
	_assert(cue_bank.has_method("get_cue_profile"), "ProceduralCueBank debe exponer perfiles funcionales por cue.")
	_assert(cue_bank.has_method("get_available_cue_ids"), "ProceduralCueBank debe listar cues disponibles.")
	if not cue_bank.has_method("get_cue_profile"):
		_finish()
		return

	var required_cues := [
		"impact_heavy",
		"part_destroyed",
		"part_recovered",
		"part_denied",
		"robot_disabled",
		"robot_exploded",
		"pickup_taken",
		"pressure_warning",
	]
	for cue_id in required_cues:
		var profile: Dictionary = cue_bank.call("get_cue_profile", cue_id)
		_assert(not profile.is_empty(), "El cue funcional %s debe tener perfil." % cue_id)
		_assert(String(profile.get("bus", "")) == "SFX", "%s debe ir por SFX." % cue_id)
		_assert(float(profile.get("functional_priority", 0.0)) >= 0.7, "%s debe ser funcionalmente prioritario." % cue_id)
		_assert(bool(profile.get("industrial_weight", false)), "%s debe declararse como feedback industrial." % cue_id)

	var audio_director := root.get_node_or_null("AudioDirector")
	_assert(audio_director != null, "El proyecto debe registrar AudioDirector como autoload para ruteo M6.")
	if audio_director == null:
		_finish()
		return
	audio_director.call("reset_debug_history")

	var main := MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var robots := main.get_tree().get_nodes_in_group("robots")
	var robot := robots[0] as RobotBase if not robots.is_empty() else null
	var enemy := robots[1] as RobotBase if robots.size() > 1 else null
	_assert(robot != null, "La escena principal debe exponer robots para ruteo M6.")
	_assert(enemy != null, "La escena principal debe exponer un rival para validar negacion de partes.")
	if robot != null and enemy != null:
		enemy.team_id = robot.team_id + 10
		main.call("_on_robot_part_restored", robot, "left_arm", robot)
		main.call("_on_detached_part_recovery_lost", _make_denied_part(robot, enemy), "void")
		main.call("_on_robot_disabled", robot)
		main.call("_on_robot_exploded", robot)
		await process_frame
		await process_frame

	var history := audio_director.call("get_debug_history") as Array
	_assert(_history_contains(history, "cue", "part_recovered"), "Restaurar parte debe rutear cue propio.")
	_assert(_history_contains(history, "cue", "part_denied"), "Negar parte debe rutear cue propio.")
	_assert(_history_contains(history, "cue", "robot_disabled"), "Inutilizacion debe rutear cue propio.")
	_assert(_history_contains(history, "cue", "robot_exploded"), "Explosion debe rutear cue propio.")

	await _cleanup_scene(main)
	_finish()


func _make_denied_part(original_robot: RobotBase, denied_by: RobotBase) -> DetachedPart:
	var detached := DETACHED_PART_SCENE.instantiate() as DetachedPart
	root.add_child(detached)
	detached.original_robot = original_robot
	detached.part_name = "left_arm"
	detached.set("_last_recovery_loss_source", denied_by)
	return detached


func _history_contains(history: Array, entry_type: String, value: String) -> bool:
	for entry in history:
		if not (entry is Dictionary):
			continue
		if String(entry.get("type", "")) == entry_type and String(entry.get("value", "")) == value:
			return true
	return false


func _cleanup_scene(scene: Node) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	var parent := scene.get_parent()
	if parent != null:
		parent.remove_child(scene)
	scene.free()
	current_scene = null
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
