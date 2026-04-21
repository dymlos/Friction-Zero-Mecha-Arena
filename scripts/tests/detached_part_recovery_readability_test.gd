extends SceneTree

const DETACHED_PART_SCENE := preload("res://scenes/robots/detached_part.tscn")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false
var _recovery_loss_reason := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var owner := ROBOT_SCENE.instantiate() as RobotBase
	owner.player_index = 2
	owner.team_id = 2
	owner.position = Vector3(6.0, 0.0, 0.0)
	owner.set_physics_process(false)
	root.add_child(owner)

	var detached_part := DETACHED_PART_SCENE.instantiate() as DetachedPart
	detached_part.cleanup_time = 0.5
	detached_part.pickup_delay = 0.0
	detached_part.configure_from_visuals(owner, "left_arm", [], Vector3.ZERO)
	root.add_child(detached_part)

	await process_frame
	await physics_frame

	_assert(
		detached_part.has_signal("recovery_lost"),
		"La parte desprendida deberia avisar cuando su ventana de recuperacion se pierde."
	)
	if detached_part.has_signal("recovery_lost"):
		detached_part.recovery_lost.connect(_on_recovery_lost)

	_assert(
		detached_part.has_method("get_cleanup_progress_ratio"),
		"La parte desprendida deberia exponer el progreso de su ventana de recuperacion."
	)

	var indicator := detached_part.get_node_or_null("RecoveryIndicator")
	_assert(
		indicator is MeshInstance3D,
		"La parte desprendida deberia mostrar un indicador diegetico de recuperacion sobre el suelo."
	)
	var ownership_indicator := detached_part.get_node_or_null("OwnershipIndicator")
	_assert(
		ownership_indicator is MeshInstance3D,
		"La parte desprendida deberia dejar visible a quien pertenece sin abrir otra banda de HUD."
	)
	if not detached_part.has_method("get_cleanup_progress_ratio"):
		await _cleanup_owner(owner)
		_finish()
		return
	if not owner.has_method("get_identity_color"):
		await _cleanup_owner(owner)
		_finish()
		return
	if ownership_indicator is MeshInstance3D:
		var ownership_material := (ownership_indicator as MeshInstance3D).material_override as StandardMaterial3D
		_assert(
			ownership_material != null,
			"El indicador de pertenencia deberia poder tintarse con la identidad del robot original."
		)
		if ownership_material != null:
			var owner_color := owner.call("get_identity_color") as Color
			_assert(
				ownership_material.albedo_color.is_equal_approx(owner_color),
				"La parte desprendida deberia reutilizar el color de identidad del robot dueño."
			)
			_assert(
				(ownership_indicator as MeshInstance3D).visible,
				"La marca de pertenencia deberia verse mientras la parte siga tirada en el piso."
			)

	var initial_ratio := float(detached_part.call("get_cleanup_progress_ratio"))
	_assert(
		initial_ratio > 0.75,
		"La ventana de recuperacion deberia arrancar practicamente completa."
	)

	await create_timer(0.2).timeout

	var reduced_ratio := float(detached_part.call("get_cleanup_progress_ratio"))
	_assert(
		reduced_ratio < initial_ratio,
		"El progreso de recuperacion deberia reducirse mientras la pieza sigue tirada."
	)

	await create_timer(0.35).timeout
	await process_frame

	_assert(
		_recovery_loss_reason == "timeout",
		"Al agotarse la ventana, la parte deberia reportar perdida por timeout."
	)
	_assert(
		not is_instance_valid(detached_part),
		"La parte desprendida deberia limpiarse al terminar la ventana de recuperacion."
	)

	await _cleanup_owner(owner)
	_finish()


func _on_recovery_lost(_detached_part: DetachedPart, reason: String) -> void:
	_recovery_loss_reason = reason


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
