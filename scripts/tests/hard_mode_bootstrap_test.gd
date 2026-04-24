extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	main.hard_mode_player_slots = PackedInt32Array([1, 4])
	root.add_child(main)

	await process_frame
	await process_frame

	var robots := _get_scene_robots(main)
	_assert(robots.size() >= 4, "La escena principal deberia ofrecer cuatro robots para probar slots Hard.")
	if robots.size() < 4:
		await _cleanup_main(main)
		_finish()
		return

	_assert(robots[0].control_mode == RobotBase.ControlMode.HARD, "P1 deberia quedar en Hard segun la configuracion de slots.")
	_assert(robots[1].control_mode == RobotBase.ControlMode.EASY, "P2 deberia permanecer en Easy si no esta listado.")
	_assert(robots[2].control_mode == RobotBase.ControlMode.EASY, "P3 deberia permanecer en Easy si no esta listado.")
	_assert(robots[3].control_mode == RobotBase.ControlMode.HARD, "P4 deberia quedar en Hard segun la configuracion de slots.")
	_assert(main.hard_mode_player_slots.has(1), "El array global debe conservar P1 en modo Hard.")
	_assert(main.hard_mode_player_slots.has(4), "El array global debe conservar P4 en modo Hard.")

	var status_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/StatusLabel")
	_assert(status_label is Label, "El HUD deberia exponer el estado inicial del laboratorio.")
	if status_label is Label:
		var startup_status_text := (status_label as Label).text
		_assert(
			startup_status_text.contains("TFGX"),
			"El estado inicial deberia dejar visible el aim por teclado para el slot Hard del laboratorio."
		)

	main.toggle_lab_control_mode_for_player_slot(2)
	await process_frame
	await process_frame
	_assert(main.hard_mode_player_slots.has(2), "El selector por slot debe habilitar Hard en el jugador elegido.")
	_assert(robots[1].control_mode == RobotBase.ControlMode.HARD, "P2 debe pasar a Hard desde el selector de slot.")
	var roster_label := main.get_node_or_null("UI/MatchHud/Root/TopLeftStack/RosterLabel")
	_assert(roster_label is Label, "El HUD deberia seguir mostrando el roster compacto.")
	if roster_label is Label:
		var roster_text_hard_p2 := (roster_label as Label).text
		_assert(
			roster_text_hard_p2.contains("flechas + aim Ins/Del/PgUp/PgDn"),
			"El roster deberia volver visible el nuevo aim Hard por teclado del perfil flechas."
		)

	main.toggle_lab_control_mode_for_player_slot(2)
	await process_frame
	await process_frame
	_assert(not main.hard_mode_player_slots.has(2), "El selector por slot debe revertir a Easy si se vuelve a activar.")
	_assert(robots[1].control_mode == RobotBase.ControlMode.EASY, "P2 debe volver a Easy tras otro toggle de mismo slot.")

	if roster_label is Label:
		var roster_text := (roster_label as Label).text
		_assert(roster_text.contains("Player 1"), "El roster deberia seguir incluyendo al jugador Hard.")
		_assert(roster_text.contains("Avanzado"), "El roster deberia hacer visible que un robot usa Control Hard.")
		_assert(
			roster_text.contains("WASD + aim TFGX"),
			"El roster deberia mantener visible el perfil Hard local que ya usa aim por teclado."
		)
		_assert(
			roster_text.contains("IJKL + aim stick derecho"),
			"El roster deberia dejar explicito cuando un slot Hard local sigue siendo joypad-first para el aim."
		)
	if status_label is Label:
		var status_text := (status_label as Label).text
		_assert(
			status_text.contains("Lab: P2"),
			"Tras alternar un slot, el estado deberia pasar a resumir el selector runtime del laboratorio."
		)

	await _cleanup_main(main)
	_finish()


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
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
