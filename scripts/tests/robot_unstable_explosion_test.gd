extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stable_result := await _measure_explosion_case(false)
	var unstable_result := await _measure_explosion_case(true)

	_assert(stable_result.get("ok", false), "La medicion base de explosion deberia completarse.")
	_assert(unstable_result.get("ok", false), "La medicion inestable deberia completarse.")
	if not stable_result.get("ok", false) or not unstable_result.get("ok", false):
		_finish()
		return

	_assert(
		bool(unstable_result.get("was_unstable", false)),
		"El robot destruido en overdrive deberia marcar su explosion como inestable."
	)
	_assert(
		float(unstable_result.get("damage_delta", 0.0)) > float(stable_result.get("damage_delta", 0.0)),
		"La explosion inestable deberia daniar mas que la explosion base a igual distancia."
	)
	_assert(
		float(unstable_result.get("impulse_delta", 0.0)) > float(stable_result.get("impulse_delta", 0.0)),
		"La explosion inestable deberia empujar mas que la explosion base a igual distancia."
	)

	_finish()


func _measure_explosion_case(use_overdrive: bool) -> Dictionary:
	var owner = ROBOT_SCENE.instantiate()
	var other = ROBOT_SCENE.instantiate()
	root.add_child(owner)
	root.add_child(other)

	await process_frame

	owner.set_physics_process(false)
	other.set_physics_process(false)
	owner.gravity = 0.0
	other.gravity = 0.0
	owner.void_fall_y = -100.0
	other.void_fall_y = -100.0
	owner.disabled_explosion_delay = 0.1
	owner.disabled_explosion_timer.wait_time = 0.1
	owner.disabled_explosion_radius = 4.0
	owner.disabled_explosion_damage = 18.0
	owner.disabled_explosion_impulse = 9.0
	other.global_position = owner.global_position + Vector3(1.2, 0.0, 0.0)

	if use_overdrive:
		owner.set_energy_focus("right_arm")
		owner.activate_overdrive()

	var starting_total_health: float = _get_total_part_health(other)
	var starting_impulse: float = other.external_impulse.length()
	for part_name in owner.BODY_PARTS:
		owner.apply_damage_to_part(part_name, owner.max_part_health + 5.0, Vector3.RIGHT)

	var was_unstable := false
	if owner.has_method("is_disabled_explosion_unstable"):
		was_unstable = bool(owner.call("is_disabled_explosion_unstable"))

	var result := {
		"ok": true,
		"was_unstable": was_unstable,
	}
	await create_timer(0.25).timeout
	result["damage_delta"] = starting_total_health - _get_total_part_health(other)
	result["impulse_delta"] = other.external_impulse.length() - starting_impulse

	owner.queue_free()
	other.queue_free()
	await process_frame
	return result


func _get_total_part_health(robot) -> float:
	var total := 0.0
	for part_name in robot.BODY_PARTS:
		total += robot.get_part_health(part_name)

	return total


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
