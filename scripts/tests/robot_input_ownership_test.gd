extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var player_one = ROBOT_SCENE.instantiate()
	var player_two = ROBOT_SCENE.instantiate()
	var player_three = ROBOT_SCENE.instantiate()
	var player_four = ROBOT_SCENE.instantiate()
	player_one.is_player_controlled = true
	player_one.player_index = 1
	player_one.keyboard_profile = RobotBase.KeyboardProfile.WASD_SPACE
	player_two.is_player_controlled = true
	player_two.player_index = 2
	player_two.keyboard_profile = RobotBase.KeyboardProfile.ARROWS_ENTER
	player_three.is_player_controlled = true
	player_three.player_index = 3
	player_three.keyboard_profile = RobotBase.KeyboardProfile.NUMPAD
	player_four.is_player_controlled = true
	player_four.player_index = 4
	player_four.keyboard_profile = RobotBase.KeyboardProfile.IJKL

	root.add_child(player_one)
	root.add_child(player_two)
	root.add_child(player_three)
	root.add_child(player_four)

	await process_frame

	var p1_left := _get_action_keycodes("p1_move_left")
	var p2_left := _get_action_keycodes("p2_move_left")
	var p2_aim := _merge_keycodes([
		"p2_aim_left",
		"p2_aim_right",
		"p2_aim_forward",
		"p2_aim_back",
	])
	var p3_aim := _merge_keycodes([
		"p3_aim_left",
		"p3_aim_right",
		"p3_aim_forward",
		"p3_aim_back",
	])
	var p1_attack := _get_action_keycodes("p1_attack")
	var p2_attack := _get_action_keycodes("p2_attack")
	var p1_throw := _get_action_keycodes("p1_throw_part")
	var p1_aim := _merge_keycodes([
		"p1_aim_left",
		"p1_aim_right",
		"p1_aim_forward",
		"p1_aim_back",
	])
	var p4_profile_keys := _merge_keycodes([
		"p4_move_left",
		"p4_move_right",
		"p4_move_forward",
		"p4_move_back",
		"p4_attack",
		"p4_energy_prev",
		"p4_energy_next",
		"p4_throw_part",
		"p4_overdrive",
	])

	_assert(p1_left.has(KEY_A), "El jugador 1 deberia conservar el perfil WASD.")
	_assert(not p1_left.has(KEY_LEFT), "El jugador 1 no deberia compartir flechas con el jugador 2.")
	_assert(p2_left.has(KEY_LEFT), "El jugador 2 deberia tener un perfil propio con flechas.")
	_assert(not p2_left.has(KEY_A), "El jugador 2 no deberia reutilizar la tecla A del jugador 1.")
	_assert(p1_attack.has(KEY_SPACE), "El jugador 1 deberia atacar con Space.")
	_assert(p2_attack.has(KEY_ENTER), "El jugador 2 deberia atacar con Enter.")
	_assert(p1_throw.has(KEY_C), "El jugador 1 deberia poder lanzar partes con una tecla dedicada.")
	_assert(
		p2_aim.has(KEY_INSERT)
			and p2_aim.has(KEY_DELETE)
			and p2_aim.has(KEY_PAGEUP)
			and p2_aim.has(KEY_PAGEDOWN),
		"El perfil flechas deberia exponer aim Hard por teclado con el cluster Insert/Delete/PgUp/PgDn."
	)
	_assert(
		p3_aim.has(KEY_KP_7)
			and p3_aim.has(KEY_KP_9)
			and p3_aim.has(KEY_KP_DIVIDE)
			and p3_aim.has(KEY_KP_MULTIPLY),
		"El perfil numpad deberia exponer aim Hard por teclado con el cluster superior del pad."
	)
	_assert(
		not _arrays_intersect(p1_aim, p4_profile_keys),
		"El aim Hard del jugador 1 no deberia pisar teclas del perfil IJKL del jugador 4."
	)
	_assert(
		not _arrays_intersect(p2_aim, p4_profile_keys),
		"El aim Hard del jugador 2 no deberia pisar teclas del perfil IJKL del jugador 4."
	)
	_assert(
		not _arrays_intersect(p2_aim, p3_aim),
		"Los perfiles Hard de flechas y numpad no deberian compartir teclas."
	)

	_finish()


func _get_action_keycodes(action_name: StringName) -> Array[int]:
	var keycodes: Array[int] = []
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			keycodes.append((event as InputEventKey).physical_keycode)

	return keycodes


func _merge_keycodes(action_names: Array[StringName]) -> Array[int]:
	var keycodes: Array[int] = []
	for action_name in action_names:
		for keycode in _get_action_keycodes(action_name):
			if not keycodes.has(keycode):
				keycodes.append(keycode)

	return keycodes


func _arrays_intersect(left: Array[int], right: Array[int]) -> bool:
	for value in left:
		if right.has(value):
			return true

	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
