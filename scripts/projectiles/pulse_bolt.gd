extends Area3D
class_name PulseBolt

const RobotBase = preload("res://scripts/robots/robot_base.gd")

@export var speed := 14.0
@export var max_lifetime := 1.0
@export var impact_impulse := 8.5
@export var damage_amount := 18.0

var _source_robot: RobotBase = null
var _travel_direction := Vector3.FORWARD
var _lifetime_remaining := 0.0


func _ready() -> void:
	add_to_group("temporary_projectiles")
	_lifetime_remaining = maxf(_lifetime_remaining, max_lifetime)
	_face_travel_direction()


func _physics_process(delta: float) -> void:
	global_position += _travel_direction * speed * delta
	_lifetime_remaining = maxf(_lifetime_remaining - delta, 0.0)
	if _lifetime_remaining == 0.0:
		queue_free()


func configure(
	source_robot: RobotBase,
	world_position: Vector3,
	world_direction: Vector3,
	projectile_speed: float,
	lifetime: float,
	push_impulse: float,
	damage: float
) -> void:
	_source_robot = source_robot
	global_position = world_position
	_travel_direction = world_direction
	_travel_direction.y = 0.0
	if _travel_direction.length_squared() <= 0.0001:
		_travel_direction = Vector3.FORWARD

	_travel_direction = _travel_direction.normalized()
	speed = projectile_speed
	max_lifetime = lifetime
	_lifetime_remaining = lifetime
	impact_impulse = push_impulse
	damage_amount = damage
	_face_travel_direction()


func _face_travel_direction() -> void:
	var planar_direction := _travel_direction
	planar_direction.y = 0.0
	if planar_direction.length_squared() <= 0.0001:
		return

	global_basis = Basis.looking_at(planar_direction.normalized(), Vector3.UP)


func _on_body_entered(body: Node) -> void:
	if body == _source_robot:
		return

	if body is RobotBase:
		var robot := body as RobotBase
		robot.apply_impulse(_travel_direction * impact_impulse)
		robot.receive_attack_hit_from_robot(_travel_direction, damage_amount, _source_robot)
		queue_free()
		return

	if body is PhysicsBody3D:
		queue_free()
