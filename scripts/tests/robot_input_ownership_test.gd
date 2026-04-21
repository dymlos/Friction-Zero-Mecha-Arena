extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var player_one = ROBOT_SCENE.instantiate()
	var player_two = ROBOT_SCENE.instantiate()
	player_one.is_player_controlled = true
	player_one.player_index = 1
	player_one.keyboard_profile = RobotBase.KeyboardProfile.WASD_SPACE
	player_two.is_player_controlled = true
	player_two.player_index = 2
	player_two.keyboard_profile = RobotBase.KeyboardProfile.ARROWS_ENTER

	root.add_child(player_one)
	root.add_child(player_two)

	await process_frame

	var p1_left := _get_action_keycodes("p1_move_left")
	var p2_left := _get_action_keycodes("p2_move_left")
	var p1_attack := _get_action_keycodes("p1_attack")
	var p2_attack := _get_action_keycodes("p2_attack")

	_assert(p1_left.has(KEY_A), "El jugador 1 deberia conservar el perfil WASD.")
	_assert(not p1_left.has(KEY_LEFT), "El jugador 1 no deberia compartir flechas con el jugador 2.")
	_assert(p2_left.has(KEY_LEFT), "El jugador 2 deberia tener un perfil propio con flechas.")
	_assert(not p2_left.has(KEY_A), "El jugador 2 no deberia reutilizar la tecla A del jugador 1.")
	_assert(p1_attack.has(KEY_SPACE), "El jugador 1 deberia atacar con Space.")
	_assert(p2_attack.has(KEY_ENTER), "El jugador 2 deberia atacar con Enter.")

	quit()


func _get_action_keycodes(action_name: StringName) -> Array[int]:
	var keycodes: Array[int] = []
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			keycodes.append((event as InputEventKey).physical_keycode)

	return keycodes


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	quit(1)
