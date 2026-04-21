extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var robot_a := ROBOT_SCENE.instantiate() as RobotBase
	robot_a.player_index = 1
	robot_a.team_id = 1
	root.add_child(robot_a)

	var robot_b := ROBOT_SCENE.instantiate() as RobotBase
	robot_b.player_index = 3
	robot_b.team_id = 2
	root.add_child(robot_b)

	await process_frame
	await physics_frame

	_assert(
		robot_a.has_method("get_identity_color"),
		"El robot deberia exponer un color de identidad reutilizable para lectura en pantalla compartida."
	)
	_assert(
		robot_b.has_method("get_identity_color"),
		"Cada robot deberia poder resolver su acento visual sin depender del HUD."
	)
	if not robot_a.has_method("get_identity_color") or not robot_b.has_method("get_identity_color"):
		await _cleanup_robot(robot_a)
		await _cleanup_robot(robot_b)
		_finish()
		return

	var color_a := robot_a.call("get_identity_color") as Color
	var color_b := robot_b.call("get_identity_color") as Color
	_assert(
		not color_a.is_equal_approx(color_b),
		"Dos robots de distinta identidad deberian resolver acentos distintos."
	)

	var facing_a := robot_a.get_node_or_null("UpperBodyPivot/FacingMarker") as MeshInstance3D
	var facing_b := robot_b.get_node_or_null("UpperBodyPivot/FacingMarker") as MeshInstance3D
	var core_a := robot_a.get_node_or_null("UpperBodyPivot/LeftCoreLight") as MeshInstance3D
	var core_b := robot_b.get_node_or_null("UpperBodyPivot/LeftCoreLight") as MeshInstance3D
	_assert(facing_a != null, "El robot deberia exponer un marcador frontal para orientar la lectura.")
	_assert(facing_b != null, "El segundo robot tambien deberia exponer el marcador frontal.")
	_assert(core_a != null, "El robot deberia exponer luces de core para reforzar identidad.")
	_assert(core_b != null, "El segundo robot tambien deberia exponer luces de core.")
	if facing_a == null or facing_b == null or core_a == null or core_b == null:
		await _cleanup_robot(robot_a)
		await _cleanup_robot(robot_b)
		_finish()
		return

	var facing_material_a := facing_a.material_override as StandardMaterial3D
	var facing_material_b := facing_b.material_override as StandardMaterial3D
	var core_material_a := core_a.material_override as StandardMaterial3D
	var core_material_b := core_b.material_override as StandardMaterial3D
	_assert(facing_material_a != null, "El marcador frontal deberia poder tintarse por identidad.")
	_assert(facing_material_b != null, "El segundo marcador frontal tambien deberia poder tintarse.")
	_assert(core_material_a != null, "La luz del core deberia poder tintarse por identidad.")
	_assert(core_material_b != null, "La segunda luz del core tambien deberia poder tintarse.")
	if facing_material_a == null or facing_material_b == null or core_material_a == null or core_material_b == null:
		await _cleanup_robot(robot_a)
		await _cleanup_robot(robot_b)
		_finish()
		return

	_assert(
		not facing_material_a.albedo_color.is_equal_approx(facing_material_b.albedo_color),
		"El marcador frontal deberia distinguir rapidamente dos robots distintos."
	)
	_assert(
		not core_material_a.emission.is_equal_approx(core_material_b.emission),
		"Las luces del core deberian reforzar esa identidad sin depender del roster."
	)

	await _cleanup_robot(robot_a)
	await _cleanup_robot(robot_b)
	_finish()


func _cleanup_robot(robot: RobotBase) -> void:
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
