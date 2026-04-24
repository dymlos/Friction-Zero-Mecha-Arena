extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	root.add_child(robot)

	await process_frame
	await physics_frame

	var smoke := robot.get_node_or_null("UpperBodyPivot/LeftArm/DamageFeedback/Smoke")
	var spark := robot.get_node_or_null("UpperBodyPivot/LeftArm/DamageFeedback/Spark")
	_assert(smoke is MeshInstance3D, "Cada parte deberia exponer un marcador visual de daño leve.")
	_assert(spark is MeshInstance3D, "Cada parte deberia exponer un marcador visual de daño crítico.")
	if not (smoke is MeshInstance3D) or not (spark is MeshInstance3D):
		await _cleanup_robot(robot)
		_finish()
		return

	var smoke_mesh := smoke as MeshInstance3D
	var spark_mesh := spark as MeshInstance3D
	_assert(not smoke_mesh.visible, "El marcador de daño no deberia arrancar visible en una parte sana.")
	_assert(not spark_mesh.visible, "El marcador crítico no deberia arrancar visible en una parte sana.")

	robot.apply_damage_to_part("left_arm", 30.0)
	await process_frame

	_assert(smoke_mesh.visible, "Una parte dañada deberia mostrar un marcador diegético legible.")
	_assert(not spark_mesh.visible, "El marcador crítico no deberia activarse con daño moderado.")

	var snapshot: Dictionary = robot.call("get_diegetic_readability_snapshot")
	var left_arm: Dictionary = (snapshot.get("parts", {}) as Dictionary).get("left_arm", {})
	_assert(
		String(left_arm.get("damage_feedback_anchor", "")) == "UpperBodyPivot/LeftArm",
		"El feedback M6 de dano debe estar montado sobre el brazo danado."
	)
	_assert(
		bool(snapshot.get("hud_is_secondary", false)),
		"El contrato M6 debe dejar explicito que HUD refuerza, no reemplaza, la lectura del robot."
	)

	robot.apply_damage_to_part("left_arm", 40.0)
	await process_frame

	_assert(spark_mesh.visible, "El marcador crítico deberia activarse cuando la parte queda muy castigada.")

	robot.repair_part("left_arm", 100.0)
	await process_frame

	_assert(not smoke_mesh.visible, "Reparar una parte deberia limpiar el feedback de daño leve.")
	_assert(not spark_mesh.visible, "Reparar una parte deberia limpiar el feedback crítico.")

	robot.apply_damage_to_part("left_arm", 100.0)
	await process_frame

	_assert(not smoke_mesh.visible, "Una parte desprendida no deberia dejar el marcador flotando en el robot.")
	_assert(not spark_mesh.visible, "El feedback crítico deberia apagarse al desprenderse la parte.")

	await _cleanup_robot(robot)
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
