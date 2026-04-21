extends SceneTree

const PICKUP_SCENE := preload("res://scenes/support/pilot_support_pickup.tscn")

var _failed := false


class DummySupportShip:
	extends Node3D

	var stored_payloads: Array[String] = []

	func store_support_payload(payload_name: String) -> bool:
		stored_payloads.append(payload_name)
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_support_pickup_respawns_with_readable_timing()
	_finish()


func _verify_support_pickup_respawns_with_readable_timing() -> void:
	var pickup = PICKUP_SCENE.instantiate()
	root.add_child(pickup)
	pickup.set("respawn_delay", 0.25)

	var ship := DummySupportShip.new()
	root.add_child(ship)

	await process_frame

	_assert(
		pickup.has_method("get_time_until_respawn"),
		"El pickup de apoyo deberia exponer cuanto falta para reaparecer."
	)
	_assert(
		pickup.has_method("get_respawn_progress_ratio"),
		"El pickup de apoyo deberia exponer un ratio simple para telegraph de respawn."
	)
	_assert(
		pickup.get_node_or_null("RespawnVisual") != null,
		"El pickup de apoyo deberia incluir un telegraph diegetico de reaparicion."
	)

	pickup.call("set_support_active", true)
	pickup.global_position = Vector3.ZERO
	ship.global_position = Vector3.ZERO
	await process_frame

	_assert(
		pickup.visible,
		"Con soporte activo, el pickup deberia permanecer visible antes de ser recogido."
	)
	_assert(
		bool(pickup.call("try_collect", ship)),
		"El soporte deberia poder recoger el pickup cuando entra en radio."
	)
	_assert(
		pickup.visible,
		"Durante cooldown, el pedestal deberia seguir visible para marcar el punto de respawn."
	)
	var core_visual := pickup.get_node_or_null("CoreVisual") as MeshInstance3D
	var respawn_visual := pickup.get_node_or_null("RespawnVisual") as MeshInstance3D
	_assert(core_visual != null, "El pickup deberia seguir exponiendo su nucleo visible.")
	_assert(respawn_visual != null, "El pickup deberia seguir exponiendo su telegraph de respawn.")
	if core_visual != null:
		_assert(
			not core_visual.visible,
			"Durante cooldown, el nucleo del pickup deberia apagarse para dejar claro que ya fue consumido."
		)
	if respawn_visual != null:
		_assert(
			respawn_visual.visible,
			"Durante cooldown, el telegraph de respawn deberia volverse visible."
		)
	if pickup.has_method("get_time_until_respawn"):
		_assert(
			float(pickup.call("get_time_until_respawn")) > 0.0,
			"Tras recogerlo, el pickup deberia entrar en cooldown de respawn."
		)
	if pickup.has_method("get_respawn_progress_ratio"):
		_assert(
			float(pickup.call("get_respawn_progress_ratio")) < 1.0,
			"Durante cooldown, el telegraph de respawn no deberia marcarse como completo."
		)

	await _wait_seconds(0.35)

	_assert(
		core_visual != null and core_visual.visible,
		"Cuando termina el cooldown, el nucleo del pickup de apoyo deberia reaparecer para otra pasada del carril."
	)
	if respawn_visual != null:
		_assert(
			not respawn_visual.visible,
			"Al reaparecer, el telegraph temporal deberia apagarse otra vez."
		)
	if pickup.has_method("get_time_until_respawn"):
		_assert(
			is_zero_approx(float(pickup.call("get_time_until_respawn"))),
			"Una vez reaparecido, el cooldown pendiente deberia volver a cero."
		)
	if pickup.has_method("get_respawn_progress_ratio"):
		_assert(
			is_equal_approx(float(pickup.call("get_respawn_progress_ratio")), 1.0),
			"Al reaparecer, el telegraph de respawn deberia volver a completo."
		)

	pickup.queue_free()
	ship.queue_free()
	await process_frame


func _wait_seconds(duration: float) -> void:
	var timer: SceneTreeTimer = create_timer(maxf(duration, 0.0))
	await timer.timeout


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
