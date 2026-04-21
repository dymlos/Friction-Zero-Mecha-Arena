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
	await _verify_support_pickup_payloads_have_distinct_world_silhouettes()
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


func _verify_support_pickup_payloads_have_distinct_world_silhouettes() -> void:
	var payloads := [
		"stabilizer",
		"surge",
		"mobility",
		"interference",
	]
	var silhouette_signatures: Dictionary = {}
	var unique_signatures: Dictionary = {}
	var pickups: Array[Node3D] = []

	for payload_name in payloads:
		var pickup = PICKUP_SCENE.instantiate()
		pickup.set("payload_name", payload_name)
		root.add_child(pickup)
		pickup.call("set_support_active", true)
		pickups.append(pickup)

	await process_frame

	for pickup in pickups:
		var payload_name := str(pickup.get("payload_name"))
		var accent_visual := pickup.get_node_or_null("PayloadAccentVisual") as MeshInstance3D
		_assert(
			accent_visual != null,
			"Cada payload de soporte deberia exponer un acento/silueta propia en mundo, no solo color."
		)
		if accent_visual == null:
			continue

		var mesh := accent_visual.mesh
		var material := accent_visual.material_override as StandardMaterial3D
		var signature := "%s|%s|%s" % [
			mesh.get_class() if mesh != null else "null",
			accent_visual.scale,
			accent_visual.rotation_degrees,
		]
		silhouette_signatures[payload_name] = signature
		unique_signatures[signature] = true
		_assert(
			material != null,
			"El acento de payload deberia tener un material propio para sostener contraste sin pisar el nucleo."
		)
		if material != null:
			_assert(
				material.emission_enabled,
				"El acento de payload deberia seguir siendo legible a distancia con emision sobria."
			)

	_assert(
		silhouette_signatures.size() == payloads.size(),
		"Cada pickup probado deberia registrar su firma visual."
	)
	_assert(
		unique_signatures.size() == silhouette_signatures.size(),
		"Los payloads del soporte deberian diferenciarse por silueta, no compartir la misma firma visual."
	)

	for pickup in pickups:
		pickup.queue_free()
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
