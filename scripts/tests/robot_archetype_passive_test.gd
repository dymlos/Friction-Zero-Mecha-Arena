extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const ARIETE_CONFIG := preload("res://data/config/robots/ariete_archetype.tres")
const GRUA_CONFIG := preload("res://data/config/robots/grua_archetype.tres")
const CIZALLA_CONFIG := preload("res://data/config/robots/cizalla_archetype.tres")
const PATIN_CONFIG := preload("res://data/config/robots/patin_archetype.tres")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_ariete_resists_more_impulse_than_patins()
	await _validate_grua_stabilizes_another_part_after_a_return()
	await _validate_cizalla_punishes_parts_that_are_already_damaged()
	await _validate_patin_keeps_mobility_boosts_longer()
	_finish()


func _validate_ariete_resists_more_impulse_than_patins() -> void:
	var ariete := await _spawn_robot(ARIETE_CONFIG)
	var patin := await _spawn_robot(PATIN_CONFIG)

	ariete.apply_impulse(Vector3.RIGHT * 10.0)
	patin.apply_impulse(Vector3.RIGHT * 10.0)

	_assert(
		ariete.external_impulse.length() < patin.external_impulse.length(),
		"Ariete deberia resistir mas impulso externo que Patin para sentirse mas tanque."
	)

	await _cleanup_node(ariete)
	await _cleanup_node(patin)


func _validate_grua_stabilizes_another_part_after_a_return() -> void:
	var owner := await _spawn_robot(ARIETE_CONFIG)
	var grua := await _spawn_robot(GRUA_CONFIG)

	owner.apply_damage_to_part("left_arm", owner.max_part_health, Vector3.LEFT)
	owner.apply_damage_to_part("right_leg", 22.0, Vector3.BACK)
	var right_leg_before := owner.get_part_health("right_leg")
	var restored := owner.restore_part_from_return("left_arm", grua)

	_assert(restored, "El retorno de parte deberia seguir funcionando con Grua.")
	_assert(
		owner.get_part_health("right_leg") > right_leg_before,
		"Grua deberia estabilizar otra parte dañada al devolver una pieza."
	)

	await _cleanup_node(owner)
	await _cleanup_node(grua)


func _validate_cizalla_punishes_parts_that_are_already_damaged() -> void:
	var victim_against_ariete := await _spawn_robot(ARIETE_CONFIG)
	var victim_against_cizalla := await _spawn_robot(ARIETE_CONFIG)
	var ariete := await _spawn_robot(ARIETE_CONFIG)
	var cizalla := await _spawn_robot(CIZALLA_CONFIG)

	victim_against_ariete.apply_damage_to_part("right_arm", 12.0, Vector3.RIGHT)
	victim_against_cizalla.apply_damage_to_part("right_arm", 12.0, Vector3.RIGHT)

	var has_attacker_aware_attack := victim_against_cizalla.has_method("receive_attack_hit_from_robot")
	_assert(
		has_attacker_aware_attack,
		"RobotBase deberia exponer un hook de daño con atacante para que Cizalla pueda castigar piezas ya dañadas."
	)
	if has_attacker_aware_attack:
		victim_against_ariete.call("receive_attack_hit_from_robot", Vector3.RIGHT, 18.0, ariete)
		_assert(
			cizalla.use_core_skill(),
			"Cizalla deberia activar Corte antes de castigar fuerte una parte ya tocada."
		)
		victim_against_cizalla.call("receive_attack_hit_from_robot", Vector3.RIGHT, 18.0, cizalla)

		_assert(
			victim_against_cizalla.get_part_health("right_arm") < victim_against_ariete.get_part_health("right_arm"),
			"Cizalla deberia castigar mas fuerte una parte ya tocada que un arquetipo base de empuje."
		)

	await _cleanup_node(victim_against_ariete)
	await _cleanup_node(victim_against_cizalla)
	await _cleanup_node(ariete)
	await _cleanup_node(cizalla)


func _validate_patin_keeps_mobility_boosts_longer() -> void:
	var ariete := await _spawn_robot(ARIETE_CONFIG)
	var patin := await _spawn_robot(PATIN_CONFIG)

	var ariete_applied := ariete.apply_mobility_boost(0.2)
	var patin_applied := patin.apply_mobility_boost(0.2)

	_assert(ariete_applied, "El boost de movilidad base deberia seguir aplicandose en Ariete.")
	_assert(patin_applied, "El boost de movilidad base deberia seguir aplicandose en Patin.")
	_assert(
		patin.get_mobility_boost_time_left() > ariete.get_mobility_boost_time_left(),
		"Patin deberia convertir el mismo pickup de movilidad en una ventana mas larga de reposicion."
	)

	await _cleanup_node(ariete)
	await _cleanup_node(patin)


func _spawn_robot(config: Resource) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	robot.archetype_config = config
	root.add_child(robot)
	await process_frame
	await process_frame
	return robot


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
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
