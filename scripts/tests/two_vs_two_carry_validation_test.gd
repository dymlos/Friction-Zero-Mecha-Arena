extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "La escena 2v2 deberia exponer cuatro robots activos para laboratorio.")
	if robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return
	_assert(robots[0].is_ally_of(robots[1]), "Player 1 y Player 2 deberian compartir equipo.")
	_assert(not robots[0].is_ally_of(robots[2]), "Player 3 deberia seguir siendo rival de Player 1.")

	for robot in robots:
		robot.set_physics_process(false)
		robot.gravity = 0.0
		robot.void_fall_y = -100.0

	var owner := robots[0]
	var ally := robots[1]
	var enemy := robots[2]
	owner.apply_damage_to_part("left_arm", owner.max_part_health + 5.0, Vector3.LEFT)

	await process_frame

	var detached_part := _get_only_detached_part()
	_assert(detached_part != null, "La parte destruida deberia existir en escena.")
	if detached_part == null:
		await _cleanup_main(main)
		_finish()
		return

	await create_timer(detached_part.pickup_delay + 0.05).timeout

	ally.global_position = detached_part.global_position
	var picked_up := detached_part.try_pick_up(ally)
	_assert(picked_up, "El aliado deberia poder recoger la parte desprendida tras el pickup_delay.")
	_assert(ally.get_carried_part_name() == "left_arm", "El aliado deberia cargar la parte correcta.")
	_assert(not enemy.is_carrying_part(), "El rival no deberia recibir estado de carga por una captura ajena.")

	var ally_indicator := ally.get_node_or_null("CarryIndicator")
	_assert(ally_indicator is MeshInstance3D, "El robot aliado deberia exponer un indicador de carga en runtime.")
	if ally_indicator is MeshInstance3D:
		_assert((ally_indicator as MeshInstance3D).visible, "El indicador de carga deberia verse mientras el aliado transporta la parte.")
		var indicator_material := (ally_indicator as MeshInstance3D).material_override as StandardMaterial3D
		_assert(indicator_material != null, "El indicador deberia usar un material propio para teñirse segun la parte.")
		if indicator_material != null:
			var expected_color: Color = RobotBase.CARRY_PART_COLORS["left_arm"]
			_assert(
				indicator_material.albedo_color.is_equal_approx(expected_color),
				"El indicador deberia usar el color configurado para left_arm."
			)

	var carry_owner_indicator := ally.get_node_or_null("CarryOwnerIndicator")
	_assert(
		carry_owner_indicator is MeshInstance3D,
		"El portador deberia exponer un segundo marcador para conservar la identidad del dueño de la pieza."
	)
	if carry_owner_indicator is MeshInstance3D:
		_assert(
			(carry_owner_indicator as MeshInstance3D).visible,
			"La marca de dueño deberia verse mientras el aliado transporta la pieza."
		)
		var owner_indicator_material := (carry_owner_indicator as MeshInstance3D).material_override as StandardMaterial3D
		_assert(
			owner_indicator_material != null,
			"La marca de dueño deberia tener un material propio para teñirse con la identidad del robot original."
		)
		if owner_indicator_material != null:
			var expected_owner_color := owner.get_identity_color()
			_assert(
				owner_indicator_material.emission.is_equal_approx(expected_owner_color),
				"La marca de dueño deberia reutilizar el color de identidad del robot original."
			)
	var carry_return_indicator := ally.get_node_or_null("CarryReturnIndicator")
	_assert(
		carry_return_indicator is MeshInstance3D,
		"El portador deberia exponer una pista diegetica de retorno para leer adonde llevar la pieza."
	)
	var owner_return_floor_indicator := owner.get_node_or_null("RecoveryTargetFloorIndicator")
	_assert(
		owner_return_floor_indicator is MeshInstance3D,
		"El robot dueño deberia reforzar el retorno con una marca de piso tambien durante el transporte aliado."
	)
	if owner_return_floor_indicator is MeshInstance3D:
		_assert(
			owner.has_recoverable_detached_parts(),
			"El dueño deberia seguir considerando recuperable la pieza mientras un aliado la transporta."
		)
		await process_frame
		_assert(
			(owner_return_floor_indicator as MeshInstance3D).visible,
			"La marca de piso del dueño deberia seguir visible mientras la pieza viaja en manos aliadas."
		)
		_assert(
			(owner_return_floor_indicator as MeshInstance3D).global_position.distance_to(owner.global_position) < 0.2,
			"La marca de piso del dueño deberia seguir pegada a su robot durante el transporte."
		)
	if carry_return_indicator is MeshInstance3D:
		await process_frame
		_assert(
			(carry_return_indicator as MeshInstance3D).visible,
			"La pista de retorno deberia verse mientras el aliado transporta una parte ajena."
		)
		var return_direction := owner.global_position - ally.global_position
		return_direction.y = 0.0
		var indicator_forward := -((carry_return_indicator as MeshInstance3D).global_basis.z)
		indicator_forward.y = 0.0
		if return_direction.length_squared() > 0.0 and indicator_forward.length_squared() > 0.0:
			var expected_direction := return_direction.normalized()
			var actual_direction := indicator_forward.normalized()
			_assert(
				actual_direction.dot(expected_direction) > 0.9,
				"La pista de retorno deberia apuntar hacia el robot dueño de la pieza."
			)

	var thrown := ally.throw_carried_part(Vector2.RIGHT, 7.5)
	_assert(thrown, "El aliado deberia poder lanzar la parte para negar el rescate inmediato.")
	_assert(not ally.is_carrying_part(), "Tras lanzar la parte, el aliado no deberia seguir marcado como portador.")
	if ally_indicator is MeshInstance3D:
		_assert(not (ally_indicator as MeshInstance3D).visible, "El indicador deberia ocultarse al soltar la parte.")
	if carry_owner_indicator is MeshInstance3D:
		_assert(
			not (carry_owner_indicator as MeshInstance3D).visible,
			"La marca de dueño deberia ocultarse al soltar la pieza."
		)
	if carry_return_indicator is MeshInstance3D:
		_assert(
			not (carry_return_indicator as MeshInstance3D).visible,
			"La pista de retorno deberia ocultarse al soltar la pieza."
		)
	if owner_return_floor_indicator is MeshInstance3D:
		_assert(
			owner.has_recoverable_detached_parts(),
			"El dueño deberia seguir considerando recuperable la pieza despues de que vuelva al piso."
		)
		await process_frame
		_assert(
			(owner_return_floor_indicator as MeshInstance3D).visible,
			"La marca de piso del dueño deberia seguir visible mientras la pieza siga recuperable en el piso."
		)

	owner.global_position = detached_part.global_position
	var delivered_too_soon := detached_part.try_deliver_to_robot(owner)
	_assert(not delivered_too_soon, "El robot original no deberia recuperar la parte inmediatamente tras un lanzamiento.")

	await create_timer(detached_part.pickup_delay + 0.05).timeout

	var delivered_before_throw_window := detached_part.try_deliver_to_robot(owner)
	_assert(
		not delivered_before_throw_window,
		"La ventana de throw_pickup_delay deberia seguir bloqueando la recuperacion aunque pickup_delay ya haya pasado."
	)

	await create_timer(maxf(detached_part.throw_pickup_delay - detached_part.pickup_delay, 0.0) + 0.1).timeout

	var delivered_after_throw_window := detached_part.try_deliver_to_robot(owner, ally)
	_assert(delivered_after_throw_window, "La parte deberia poder volver al dueño una vez cumplido el throw_pickup_delay.")
	_assert(owner.get_part_health("left_arm") > 0.0, "La parte restaurada deberia devolver vida parcial al brazo.")

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _get_only_detached_part() -> DetachedPart:
	var detached_parts := get_nodes_in_group("detached_parts")
	_assert(detached_parts.size() == 1, "Se esperaba exactamente una parte desprendida para esta validacion.")
	if detached_parts.size() != 1:
		return null

	return detached_parts[0] as DetachedPart


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_main(main: Node) -> void:
	if not is_instance_valid(main):
		return

	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
