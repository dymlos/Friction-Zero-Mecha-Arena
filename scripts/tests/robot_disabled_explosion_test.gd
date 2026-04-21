extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
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
	owner.disabled_explosion_radius = 4.0
	owner.disabled_explosion_damage = 18.0
	owner.disabled_explosion_impulse = 9.0
	other.global_position = owner.global_position + Vector3(1.2, 0.0, 0.0)

	var starting_total_health := _get_total_part_health(other)
	for part_name in owner.BODY_PARTS:
		owner.apply_damage_to_part(part_name, owner.max_part_health + 5.0, Vector3.RIGHT)

	await create_timer(0.25).timeout

	_assert(_get_total_part_health(other) < starting_total_health, "La explosion deberia daniar al robot cercano.")
	_assert(other.external_impulse.length() > 0.0, "La explosion deberia aplicar empuje radial.")

	await create_timer(1.1).timeout

	_assert(owner.visible, "El robot destruido deberia volver a aparecer tras la explosion.")
	_assert(not owner.is_fully_disabled(), "El robot destruido deberia resetearse al respawn.")

	_finish()


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
