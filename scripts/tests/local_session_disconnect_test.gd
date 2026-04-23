extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	_assert(main.has_method("sync_local_joypad_connection"), "Main deberia exponer sync_local_joypad_connection para el contrato runtime de hot-plug.")
	_assert(main.has_method("get_local_session_summary_line"), "Main deberia exponer una linea compacta de sesion/hot-plug para el HUD.")
	if not main.has_method("sync_local_joypad_connection") or not main.has_method("get_local_session"):
		await _cleanup_main(main)
		_finish()
		return

	var session = main.call("get_local_session")
	var robots := _get_scene_robots(main)
	_assert(session != null, "Main deberia bootear una sesion local para el contrato de hot-plug.")
	_assert(robots.size() >= 4, "La escena principal deberia seguir exponiendo cuatro robots del laboratorio.")
	if session == null or robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	var claimed_slot := int(main.call("sync_local_joypad_connection", 21, true, 2))
	_assert(claimed_slot == 2, "Al registrar un joypad en un slot elegido, la sesion deberia respetar ese ownership.")
	_assert(String(session.call("get_slot_state", 2)) == "joypad", "El slot 2 deberia quedar marcado como joypad.")
	_assert(int(session.call("get_slot_device_id", 2)) == 21, "El slot 2 deberia conservar el device_id asignado.")
	_assert(robots[1].joypad_device == 21, "El robot del slot 2 deberia consumir el ownership joypad resuelto por la sesion.")
	_assert(
		robots[1].keyboard_profile == RobotBase.KeyboardProfile.NONE,
		"El slot 2 no deberia seguir leyendo teclado despues de pasar a joypad."
	)

	var disconnected_slot := int(main.call("sync_local_joypad_connection", 21, false))
	_assert(disconnected_slot == 2, "La desconexion deberia seguir apuntando al mismo slot reservado.")
	_assert(
		String(session.call("get_slot_state", 2)) == "disconnected",
		"Cuando el joypad se desconecta, el slot deberia quedar reservado como disconnected."
	)
	_assert(
		int(session.call("get_slot_device_id", 2)) == 21,
		"El slot desconectado deberia conservar el mismo device_id reservado."
	)
	_assert(
		String(main.call("get_local_session_summary_line")).contains("P2 desconectado"),
		"El HUD deberia exponer una linea compacta cuando un slot queda desconectado pero reservado."
	)

	var reconnect_slot := int(main.call("sync_local_joypad_connection", 21, true))
	_assert(reconnect_slot == 2, "Cuando vuelve el mismo device_id, deberia recuperar automaticamente su slot.")
	_assert(String(session.call("get_slot_state", 2)) == "joypad", "El slot 2 deberia volver a estado joypad al reconectar.")
	_assert(
		String(main.call("get_local_session_summary_line")) == "",
		"Sin slots reservados/desconectados, la linea compacta de sesion no deberia ensuciar el HUD."
	)

	var ignored_slot := int(main.call("sync_local_joypad_connection", 22, true))
	_assert(
		ignored_slot == -1,
		"Un device_id nuevo no deberia robar ownership automaticamente cuando no existe slot reservado."
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

	paused = false
	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
