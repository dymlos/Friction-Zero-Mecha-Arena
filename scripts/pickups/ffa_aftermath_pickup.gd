extends Area3D
class_name FfaAftermathPickup

const FfaAftermathRules = preload("res://scripts/systems/ffa_aftermath_rules.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

signal collected(robot: RobotBase, payload_id: String, source_eliminated_label: String, arena_zone: String)

@export var payload_id := FfaAftermathRules.PAYLOAD_SURGE
@export var lifetime_seconds := FfaAftermathRules.PICKUP_LIFETIME_SECONDS
@export var source_eliminated_label := ""
@export var arena_zone := ""

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var visuals: Node3D = $Visuals
@onready var core: MeshInstance3D = $Visuals/Core

var _available := true
var _animation_time := 0.0


func _ready() -> void:
	set_meta("qa_id", "ffa_aftermath_pickup")
	add_to_group("ffa_aftermath_pickups")
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start(lifetime_seconds)
	_refresh_payload_visual()


func configure(next_payload_id: String, next_source_eliminated_label: String, next_arena_zone: String) -> void:
	payload_id = next_payload_id
	source_eliminated_label = next_source_eliminated_label
	arena_zone = next_arena_zone
	if is_inside_tree():
		_refresh_payload_visual()


func _process(delta: float) -> void:
	_animation_time += delta
	visuals.rotation.y = fmod(visuals.rotation.y + delta * 1.4, TAU)
	visuals.position.y = 0.08 + sin(_animation_time * 2.4) * 0.05


func try_collect(robot: RobotBase) -> bool:
	if not _available or robot == null:
		return false
	var applied := false
	match payload_id:
		FfaAftermathRules.PAYLOAD_SCRAP:
			applied = robot.repair_most_damaged_part(robot.max_part_health * FfaAftermathRules.SCRAP_REPAIR_RATIO) != ""
		FfaAftermathRules.PAYLOAD_CHARGE:
			applied = robot.restore_core_skill_charges(1)
		FfaAftermathRules.PAYLOAD_SURGE:
			applied = robot.apply_energy_surge(FfaAftermathRules.SURGE_DURATION_SECONDS)
	if not applied:
		return false
	_available = false
	collected.emit(robot, payload_id, source_eliminated_label, arena_zone)
	queue_free()
	return true


func _on_body_entered(body: Node) -> void:
	if body is RobotBase:
		try_collect(body as RobotBase)


func _refresh_payload_visual() -> void:
	if core == null:
		return
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	match payload_id:
		FfaAftermathRules.PAYLOAD_SCRAP:
			material.albedo_color = Color(0.48, 0.9, 0.58, 1.0)
		FfaAftermathRules.PAYLOAD_CHARGE:
			material.albedo_color = Color(0.42, 0.82, 1.0, 1.0)
		_:
			material.albedo_color = Color(1.0, 0.78, 0.24, 1.0)
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 0.9
	core.material_override = material
