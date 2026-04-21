extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")


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

	var detached_part = detached_parts[0]
	var restored: bool = detached_part.try_deliver_to_robot(robot)
	_assert(restored, "La parte desprendida deberia poder devolverse al robot original.")
	_assert(robot.get_part_health("left_arm") > 0.0, "La parte deberia volver con vida parcial.")

	quit()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	quit(1)
