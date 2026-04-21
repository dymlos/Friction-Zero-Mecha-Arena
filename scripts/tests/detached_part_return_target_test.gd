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
	owner.set_physics_process(false)
	root.add_child(owner)

	var detached_part := DETACHED_PART_SCENE.instantiate() as DetachedPart
	detached_part.cleanup_time = 0.4
	detached_part.pickup_delay = 0.0
	detached_part.configure_from_visuals(owner, "left_leg", [], Vector3.ZERO)
	root.add_child(detached_part)

	await process_frame
	await physics_frame

	var return_indicator := owner.get_node_or_null("RecoveryTargetIndicator")
	_assert(
		return_indicator is MeshInstance3D,
		"El robot con una pieza recuperable deberia marcarse como objetivo de retorno."
	)
	if return_indicator is MeshInstance3D:
		_assert(
			(return_indicator as MeshInstance3D).visible,
			"La marca de retorno deberia verse mientras exista una pieza propia recuperable."
		)

	detached_part.deny_to_void()
	await process_frame
	await process_frame

	if return_indicator is MeshInstance3D:
		_assert(
			not (return_indicator as MeshInstance3D).visible,
			"La marca de retorno deberia ocultarse cuando la pieza ya no puede recuperarse."
		)

	await _cleanup_owner(owner)
	_finish()


func _cleanup_owner(owner: Node3D) -> void:
	if not is_instance_valid(owner):
		return

	var parent := owner.get_parent()
	if parent != null:
		parent.remove_child(owner)
	owner.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
