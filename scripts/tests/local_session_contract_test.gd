extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

const LOCAL_SESSION_SCRIPT := "res://scripts/systems/local_session.gd"
const DEFAULT_LOCAL_SESSION_RESOURCE := "res://data/config/local/default_local_session_config.tres"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var local_session_script := load(LOCAL_SESSION_SCRIPT)
	_assert(local_session_script != null, "La sesion local deberia vivir en scripts/systems/local_session.gd.")

	var default_local_session = load(DEFAULT_LOCAL_SESSION_RESOURCE)
	_assert(default_local_session != null, "La sesion local deberia exponer un recurso default para el contrato del laboratorio.")

	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	_assert(main.has_method("get_local_session"), "Main deberia exponer la sesion local activa.")
	if not main.has_method("get_local_session"):
		await _cleanup_main(main)
		_finish()
		return

	var session = main.call("get_local_session")
	_assert(session != null, "Main deberia bootear una sesion local valida.")
	if session == null:
		await _cleanup_main(main)
		_finish()
		return

	_assert(
		session.has_method("get_max_local_slots"),
		"La sesion local deberia exponer cuantos slots soporta el laboratorio."
	)
	_assert(
		session.has_method("get_active_match_slots"),
		"La sesion local deberia exponer cuantos slots estan activos en la partida."
	)
	_assert(
		session.has_method("get_slot_state"),
		"La sesion local deberia permitir inspeccionar el estado de cada slot."
	)
	_assert(
		session.has_method("get_slot_keyboard_profile"),
		"La sesion local deberia permitir inspeccionar el perfil de teclado por slot."
	)
	_assert(
		session.has_method("has_unique_slot_ownership"),
		"La sesion local deberia poder validar ownership unico entre slots."
	)
	_assert(
		session.has_method("assign_joypad_slot")
			and session.has_method("mark_slot_disconnected")
			and session.has_method("restore_joypad_slot"),
		"La sesion local deberia cubrir el contrato base de joypad conectado/desconectado."
	)

	_assert(
		int(session.call("get_max_local_slots")) == 8,
		"La sesion local deberia soportar ocho slots logicos aunque el laboratorio mantenga cuatro robots."
	)
	_assert(
		int(session.call("get_active_match_slots")) == 4,
		"La sesion local deberia arrancar con cuatro slots activos en escena."
	)
	_assert(
		bool(session.call("has_unique_slot_ownership")),
		"La sesion local no deberia duplicar ownership entre slots activos."
	)

	var robots := _get_scene_robots(main)
	_assert(robots.size() == 4, "La escena principal deberia seguir exponiendo cuatro robots del laboratorio.")
	for robot in robots:
		var slot_state := String(session.call("get_slot_state", robot.player_index))
		_assert(
			slot_state == "keyboard",
			"Los slots activos del laboratorio deberian seguir arrancando en modo teclado."
		)
		_assert(
			int(session.call("get_slot_keyboard_profile", robot.player_index)) == int(robot.keyboard_profile),
			"La sesion local deberia reflejar el mismo perfil de teclado que consume cada robot."
		)

	var recovery_slot := 5
	session.call("assign_joypad_slot", recovery_slot, 77)
	_assert(
		String(session.call("get_slot_state", recovery_slot)) == "joypad",
		"Un slot reservado para joypad deberia quedar marcado como conectado."
	)
	session.call("mark_slot_disconnected", recovery_slot)
	_assert(
		String(session.call("get_slot_state", recovery_slot)) == "disconnected",
		"Al desconectarse, el slot deberia quedar reservado como disconnected."
	)
	_assert(
		int(session.call("get_slot_device_id", recovery_slot)) == 77,
		"El slot desconectado deberia conservar el mismo device_id reservado."
	)
	_assert(
		int(session.call("restore_joypad_slot", 77)) == recovery_slot,
		"Cuando vuelve el mismo device_id, deberia recuperar su slot original."
	)
	_assert(
		String(session.call("get_slot_state", recovery_slot)) == "joypad",
		"Al reconectar el mismo device_id, el slot deberia volver a estado joypad."
	)

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node_or_null("RobotRoot")
	if robot_root == null:
		return robots

	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


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
