extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const CIZALLA_ARCHETYPE := preload("res://data/config/robots/cizalla_archetype.tres")
const ARIETE_ARCHETYPE := preload("res://data/config/robots/ariete_archetype.tres")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cizalla := _spawn_robot(CIZALLA_ARCHETYPE, 1, Vector3(-1.5, 0.0, 0.0))
	var victim := _spawn_robot(ARIETE_ARCHETYPE, 2, Vector3(1.5, 0.0, 0.0))
	await process_frame
	await physics_frame

	_assert(cizalla.has_core_skill(), "Cizalla debe tener una skill principal activa.")
	_assert(cizalla.get_core_skill_label() == "Corte", "La skill principal de Cizalla debe comunicarse como Corte.")
	_assert(cizalla.get_core_skill_charge_count() == 1, "Cizalla debe arrancar con una carga de Corte.")

	victim.apply_damage_to_part("right_arm", 12.0, Vector3.RIGHT)
	var health_before_passive_hit := victim.get_part_health("right_arm")
	victim.receive_attack_hit_from_robot(Vector3.RIGHT, 8.0, cizalla)
	var passive_damage := health_before_passive_hit - victim.get_part_health("right_arm")
	_assert(passive_damage <= 8.1, "Sin activar Corte, Cizalla no debe cobrar el bonus fuerte sobre parte tocada.")
	_assert(cizalla.get_passive_status_summary() == "", "Sin activar Corte no debe quedar cue de corte en roster.")

	_assert(cizalla.use_core_skill(), "Cizalla debe poder activar Corte con el boton de skill/carga.")
	_assert(cizalla.get_core_skill_charge_count() == 0, "Usar Corte debe gastar la carga.")
	_assert(cizalla.get_passive_status_summary().contains("corte"), "Al activar Corte, el roster debe mostrar ventana corta.")

	var health_before_skill_hit := victim.get_part_health("right_arm")
	victim.receive_attack_hit_from_robot(Vector3.RIGHT, 8.0, cizalla)
	var skill_damage := health_before_skill_hit - victim.get_part_health("right_arm")
	_assert(skill_damage > passive_damage + 1.5, "Corte activo debe amplificar el dano sobre parte ya tocada.")
	_assert(cizalla.get_passive_status_summary().contains("corte"), "Tras conectar Corte, el cue corto debe seguir legible.")

	var cue := victim.get_node_or_null("UpperBodyPivot/RightArm/DamageFeedback/DismantleCue") as MeshInstance3D
	_assert(cue != null and cue.visible, "La victima debe mostrar cue corporal cuando Corte conecta.")

	await _cleanup_robot(cizalla)
	await _cleanup_robot(victim)
	_finish()


func _spawn_robot(archetype: Resource, player_index: int, position: Vector3) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	robot.player_index = player_index
	robot.archetype_config = archetype
	robot.position = position
	root.add_child(robot)
	return robot


func _cleanup_robot(robot: Node) -> void:
	if not is_instance_valid(robot):
		return
	var parent := robot.get_parent()
	if parent != null:
		parent.remove_child(robot)
	robot.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
