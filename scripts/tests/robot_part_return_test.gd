extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var robot = ROBOT_SCENE.instantiate()
	root.add_child(robot)

	await process_frame

	robot.apply_damage_to_part("left_arm", robot.max_part_health + 5.0, Vector3.LEFT)
	robot.set_physics_process(false)
	await create_timer(0.4).timeout
	await process_frame

	var detached_parts := get_nodes_in_group("detached_parts")
	_assert(
		detached_parts.size() == 1,
		"Se esperaba exactamente una parte desprendida."
	)
	if detached_parts.size() != 1:
		return

	var detached_part = detached_parts[0]
	_assert(detached_part is DetachedPart, "La parte desprendida deberia instanciar DetachedPart.")
	if not (detached_part is DetachedPart):
		return

	await create_timer((detached_part as DetachedPart).pickup_delay + 0.05).timeout
	var restored: bool = detached_part.try_deliver_to_robot(robot)
	_assert(restored, "La parte desprendida deberia poder devolverse al robot original.")
	_assert(robot.get_part_health("left_arm") > 0.0, "La parte deberia volver con vida parcial.")

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
