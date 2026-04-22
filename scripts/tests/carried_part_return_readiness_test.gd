extends SceneTree

const DETACHED_PART_SCENE := preload("res://scenes/robots/detached_part.tscn")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var owner := ROBOT_SCENE.instantiate() as RobotBase
	owner.player_index = 1
	owner.team_id = 1
	owner.position = Vector3.ZERO
	owner.set_physics_process(false)
	root.add_child(owner)

	var carrier := ROBOT_SCENE.instantiate() as RobotBase
	carrier.player_index = 2
	carrier.team_id = 1
	carrier.position = Vector3(5.0, 0.0, 0.0)
	carrier.set_physics_process(false)
	root.add_child(carrier)

	var detached_part := DETACHED_PART_SCENE.instantiate() as DetachedPart
	detached_part.cleanup_time = 1.2
	detached_part.pickup_delay = 0.0
	detached_part.configure_from_visuals(owner, "left_leg", [], Vector3.ZERO)
	root.add_child(detached_part)

	await process_frame
	await physics_frame
	await create_timer(0.05).timeout

	var picked_up := carrier.try_pick_up_detached_part(detached_part)
	_assert(
		picked_up,
		"El aliado deberia poder cargar una parte propia para llevarla de regreso."
	)
	if not picked_up:
		await _cleanup_nodes([owner, carrier, detached_part])
		_finish()
		return

	detached_part.carrier_robot = carrier
	detached_part.freeze = true
	detached_part.collision_layer = 0
	detached_part.collision_mask = 0

	await process_frame

	var carry_return_indicator := carrier.get_node_or_null("CarryReturnIndicator") as MeshInstance3D
	var owner_floor_indicator := owner.get_node_or_null("RecoveryTargetFloorIndicator") as MeshInstance3D
	_assert(
		carrier.has_method("is_carried_part_return_ready"),
		"El robot portador deberia exponer si la parte cargada ya esta en rango real de retorno."
	)
	_assert(
		carry_return_indicator != null,
		"El portador deberia seguir exponiendo el indicador diegetico de retorno."
	)
	_assert(
		owner_floor_indicator != null,
		"El robot dueño deberia seguir exponiendo la marca de retorno a nivel piso."
	)
	if not carrier.has_method("is_carried_part_return_ready") or carry_return_indicator == null or owner_floor_indicator == null:
		await _cleanup_nodes([owner, carrier, detached_part])
		_finish()
		return

	var carry_material := carry_return_indicator.material_override as StandardMaterial3D
	var owner_floor_material := owner_floor_indicator.material_override as StandardMaterial3D
	_assert(carry_material != null, "El indicador de retorno del portador deberia tener material propio.")
	_assert(owner_floor_material != null, "La marca de retorno del dueño deberia tener material propio.")
	if carry_material == null or owner_floor_material == null:
		await _cleanup_nodes([owner, carrier, detached_part])
		_finish()
		return

	var far_ready := bool(carrier.call("is_carried_part_return_ready"))
	var far_emission := carry_material.emission_energy_multiplier
	var far_floor_emission := owner_floor_material.emission_energy_multiplier
	_assert(
		not far_ready,
		"Mientras el portador siga lejos, la entrega no deberia marcarse como lista."
	)

	carrier.global_position = owner.global_position + Vector3(carrier.carried_part_return_range - 0.1, 0.0, 0.0)
	await process_frame
	await physics_frame
	await process_frame

	var near_ready := bool(carrier.call("is_carried_part_return_ready"))
	_assert(
		near_ready,
		"Al entrar en el radio real de retorno, el portador deberia marcar la entrega como lista."
	)
	_assert(
		carry_material.emission_energy_multiplier > far_emission,
		"El indicador de retorno del portador deberia intensificarse cuando la entrega ya esta lista."
	)
	_assert(
		owner_floor_material.emission_energy_multiplier > far_floor_emission,
		"La marca de retorno del dueño deberia intensificarse cuando un aliado ya puede devolver la pieza."
	)

	await _cleanup_nodes([owner, carrier, detached_part])
	_finish()


func _cleanup_nodes(nodes: Array) -> void:
	for node in nodes:
		if node == null or not is_instance_valid(node):
			continue
		var parent: Node = node.get_parent()
		if parent != null:
			parent.remove_child(node)
		node.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
