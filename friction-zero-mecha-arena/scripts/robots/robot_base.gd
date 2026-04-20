extends CharacterBody3D
class_name RobotBase

enum ControlMode { EASY, HARD }

const BODY_PARTS := [
	"left_arm",
	"right_arm",
	"left_leg",
	"right_leg",
]

@export var robot_id := 0
@export var display_name := "Prototype Robot"
@export var control_mode: ControlMode = ControlMode.EASY
@export var max_part_health := 100.0
@export var starting_energy_per_part := 25.0

var part_health: Dictionary = {}
var part_energy: Dictionary = {}


func _ready() -> void:
	reset_modular_state()


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
