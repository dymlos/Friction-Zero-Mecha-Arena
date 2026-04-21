extends CharacterBody3D
class_name RobotBase

signal fell_into_void(robot: RobotBase)
signal respawned(robot: RobotBase)
signal prototype_attack_used(robot: RobotBase)

enum ControlMode { EASY, HARD }

const BODY_PARTS := [
	"left_arm",
	"right_arm",
	"left_leg",
	"right_leg",
]

const KEYBOARD_INPUT_BINDINGS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"attack": [KEY_SPACE],
}

@export var robot_id := 0
@export var display_name := "Prototype Robot"
@export var control_mode: ControlMode = ControlMode.EASY
@export var max_part_health := 100.0
@export var starting_energy_per_part := 25.0

@export_group("Prototype Controls")
@export var is_player_controlled := false
@export_range(1, 8) var player_index := 1
@export var joypad_device := -1
@export_range(0.0, 0.8, 0.05) var joystick_deadzone := 0.25

@export_group("Prototype Movement")
@export var max_move_speed := 7.5
@export var move_acceleration := 20.0
@export var glide_damping := 4.0
@export var turn_speed := 10.0
@export var gravity := 28.0

@export_group("Prototype Combat")
@export var passive_push_strength := 3.5
@export var attack_impulse_strength := 10.0
@export var attack_range := 2.2
@export var attack_cooldown := 0.4

@export_group("Prototype Void")
@export var void_fall_y := -6.0

var part_health: Dictionary = {}
var part_energy: Dictionary = {}
var external_impulse := Vector3.ZERO

var _spawn_transform := Transform3D.IDENTITY
var _planar_velocity := Vector3.ZERO
var _attack_cooldown_remaining := 0.0
var _is_respawning := false
var _starting_collision_layer := 1
var _starting_collision_mask := 1
var _was_joypad_attack_pressed := false


func _ready() -> void:
	_spawn_transform = global_transform
	_starting_collision_layer = collision_layer
	_starting_collision_mask = collision_mask
	add_to_group("robots")
	reset_modular_state()
	if is_player_controlled:
		_ensure_default_input_actions()
		_report_joypad_status()


func _physics_process(delta: float) -> void:
	if _is_respawning:
		return

	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	_update_prototype_movement(delta)
	_update_prototype_attack()

	if global_position.y <= void_fall_y:
		fall_into_void()


func reset_modular_state() -> void:
	# Cada extremidad tiene vida y energia propia. Todavia no aplica movimiento ni combate.
	for part_name in BODY_PARTS:
		part_health[part_name] = max_part_health
		part_energy[part_name] = starting_energy_per_part


func get_part_health(part_name: String) -> float:
	return float(part_health.get(part_name, 0.0))


func set_part_energy(part_name: String, value: float) -> void:
	if not BODY_PARTS.has(part_name):
		push_warning("Parte desconocida: %s" % part_name)
		return

	part_energy[part_name] = maxf(value, 0.0)


func is_fully_disabled() -> bool:
	for part_name in BODY_PARTS:
		if get_part_health(part_name) > 0.0:
			return false

	return true


func apply_impulse(impulse: Vector3) -> void:
	impulse.y = 0.0
	external_impulse += impulse


func fall_into_void() -> void:
	if _is_respawning:
		return

	_is_respawning = true
	fell_into_void.emit(self)
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

	await get_tree().create_timer(0.75).timeout
	reset_to_spawn()


func reset_to_spawn() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	_planar_velocity = Vector3.ZERO
	external_impulse = Vector3.ZERO
	_attack_cooldown_remaining = 0.0
	visible = true
	collision_layer = _starting_collision_layer
	collision_mask = _starting_collision_mask
	_is_respawning = false
	set_physics_process(true)
	respawned.emit(self)


func _update_prototype_movement(delta: float) -> void:
	var input_vector := _get_move_input_vector()
	var move_direction := Vector3(input_vector.x, 0.0, input_vector.y)

	if move_direction.length_squared() > 0.0:
		var input_strength := clampf(input_vector.length(), 0.0, 1.0)
		move_direction = move_direction.normalized()
		var target_velocity := move_direction * max_move_speed * input_strength
		_planar_velocity = _planar_velocity.move_toward(target_velocity, move_acceleration * delta)
		_face_direction(move_direction, delta)
	else:
		_planar_velocity = _planar_velocity.move_toward(Vector3.ZERO, glide_damping * delta)

	external_impulse = external_impulse.move_toward(Vector3.ZERO, glide_damping * 0.75 * delta)

	velocity.x = _planar_velocity.x + external_impulse.x
	velocity.z = _planar_velocity.z + external_impulse.z
	velocity.y -= gravity * delta

	move_and_slide()

	if is_on_floor() and velocity.y < 0.0:
		velocity.y = 0.0

	_planar_velocity = Vector3(velocity.x, 0.0, velocity.z) - external_impulse
	_apply_passive_collision_pushes()


func _update_prototype_attack() -> void:
	if not is_player_controlled:
		return

	if not _is_attack_just_pressed():
		return

	if _attack_cooldown_remaining > 0.0:
		return

	_attack_cooldown_remaining = attack_cooldown
	prototype_attack_used.emit(self)

	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	apply_impulse(forward * attack_impulse_strength * 0.25)

	for node in get_tree().get_nodes_in_group("robots"):
		if node == self or not (node is RobotBase):
			continue

		var other := node as RobotBase
		var offset := other.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance <= 0.0 or distance > attack_range:
			continue

		var direction_to_other := offset / distance
		if forward.dot(direction_to_other) < 0.25:
			continue

		other.apply_impulse(direction_to_other * attack_impulse_strength)


func _apply_passive_collision_pushes() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var other := collision.get_collider()
		if not (other is RobotBase):
			continue

		var push_direction := global_position.direction_to(other.global_position)
		push_direction.y = 0.0
		if push_direction.length_squared() == 0.0:
			push_direction = -global_transform.basis.z

		(other as RobotBase).apply_impulse(push_direction.normalized() * passive_push_strength)


func _get_move_input_vector() -> Vector2:
	if not is_player_controlled:
		return Vector2.ZERO

	var keyboard_vector := Input.get_vector(
		_player_action_name("move_left"),
		_player_action_name("move_right"),
		_player_action_name("move_forward"),
		_player_action_name("move_back")
	)
	var joypad_vector := _get_joypad_move_vector()
	if joypad_vector.length_squared() > keyboard_vector.length_squared():
		return joypad_vector

	return keyboard_vector


func _face_direction(direction: Vector3, delta: float) -> void:
	var target_basis := Basis.looking_at(direction, Vector3.UP)
	var new_transform := global_transform
	new_transform.basis = new_transform.basis.slerp(target_basis, 1.0 - exp(-turn_speed * delta)).orthonormalized()
	global_transform = new_transform


func _player_action_name(action_suffix: String) -> StringName:
	return StringName("p%s_%s" % [player_index, action_suffix])


func _ensure_default_input_actions() -> void:
	for action_suffix in KEYBOARD_INPUT_BINDINGS:
		var action_name := _player_action_name(action_suffix)
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, joystick_deadzone)
		else:
			InputMap.action_set_deadzone(action_name, joystick_deadzone)

		for keycode in KEYBOARD_INPUT_BINDINGS[action_suffix]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			_add_input_event_if_missing(action_name, event)


func _add_input_event_if_missing(action_name: StringName, event: InputEvent) -> void:
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)


func _get_joypad_move_vector() -> Vector2:
	var best_vector := Vector2.ZERO
	for device in _get_joypad_devices_to_read():
		var raw_vector := Vector2(
			Input.get_joy_axis(device, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		)
		var filtered_vector := _apply_radial_deadzone(raw_vector)
		var dpad_vector := _get_dpad_move_vector(device)
		var device_vector := filtered_vector
		if dpad_vector.length_squared() > device_vector.length_squared():
			device_vector = dpad_vector

		if device_vector.length_squared() > best_vector.length_squared():
			best_vector = device_vector

	return best_vector


func _is_attack_just_pressed() -> bool:
	var keyboard_pressed := Input.is_action_just_pressed(_player_action_name("attack"))
	var joypad_pressed := _is_joypad_attack_pressed()
	var joypad_just_pressed := joypad_pressed and not _was_joypad_attack_pressed
	_was_joypad_attack_pressed = joypad_pressed
	return keyboard_pressed or joypad_just_pressed


func _is_joypad_attack_pressed() -> bool:
	for device in _get_joypad_devices_to_read():
		if Input.is_joy_button_pressed(device, JOY_BUTTON_A):
			return true

	return false


func _get_joypad_devices_to_read() -> Array[int]:
	var connected_devices := Input.get_connected_joypads()
	var devices: Array[int] = []
	if joypad_device >= 0:
		if connected_devices.has(joypad_device):
			devices.append(joypad_device)
		return devices

	for device in connected_devices:
		devices.append(int(device))

	return devices


func _apply_radial_deadzone(raw_vector: Vector2) -> Vector2:
	var length := raw_vector.length()
	if length <= joystick_deadzone:
		return Vector2.ZERO

	var scaled_length := inverse_lerp(joystick_deadzone, 1.0, minf(length, 1.0))
	return raw_vector.normalized() * scaled_length


func _get_dpad_move_vector(device: int) -> Vector2:
	var dpad_vector := Vector2.ZERO
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT):
		dpad_vector.x -= 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT):
		dpad_vector.x += 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP):
		dpad_vector.y -= 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN):
		dpad_vector.y += 1.0

	return dpad_vector.normalized()


func _report_joypad_status() -> void:
	var connected_devices := Input.get_connected_joypads()
	if connected_devices.is_empty():
		print("%s: no hay joystick conectado; queda teclado como fallback." % display_name)
		return

	var device_names: Array[String] = []
	for device in connected_devices:
		device_names.append("%s:%s" % [device, Input.get_joy_name(int(device))])

	print("%s: joysticks detectados -> %s" % [display_name, device_names])
