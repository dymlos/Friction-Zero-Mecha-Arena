extends "res://scripts/practice/practice_lane_base.gd"
class_name ImpactLane

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")

const TARGET_SPAWN := Vector3(0.0, 1.2, -4.25)
const EDGE_LIMIT_Z := -10.5

var _target_robot: RobotBase = null
var _impact_seen := false


func configure_lane(module_spec: Dictionary, player_robots: Array) -> void:
	super.configure_lane(module_spec, player_robots)
	set_objective_lines([
		"Empuja el objetivo hacia el borde con un choque decidido.",
		"Lee angulo, timing y espacio antes de entrar.",
	])
	set_callout_lines([
		"El buen impacto no es solo dano: debe desplazar de verdad.",
	])
	call_deferred("_sync_lane_state")


func _ready() -> void:
	_ensure_target_robot()
	_sync_lane_state()


func _physics_process(_delta: float) -> void:
	_sync_lane_state()


func _ensure_target_robot() -> void:
	if is_instance_valid(_target_robot):
		return

	var robot := ROBOT_SCENE.instantiate()
	if not (robot is RobotBase):
		return

	_target_robot = robot as RobotBase
	add_child(_target_robot)
	var roster_entry := RosterCatalog.get_shell_roster_entry("patin")
	var archetype_config = roster_entry.get("config", null)
	_target_robot.display_name = "Objetivo"
	_target_robot.is_player_controlled = false
	_target_robot.team_id = -1
	if archetype_config != null:
		_target_robot.apply_runtime_loadout(archetype_config, RobotBase.ControlMode.EASY)
	_target_robot.global_position = TARGET_SPAWN
	_target_robot.global_rotation = Vector3.ZERO
	_target_robot.capture_spawn_transform()
	_target_robot.reset_modular_state()
	_target_robot.fell_into_void.connect(_on_target_fell_into_void)
	_target_robot.meaningful_collision.connect(_on_target_meaningful_collision)


func _on_target_fell_into_void(_robot: RobotBase) -> void:
	_impact_seen = true
	complete_lane()


func _on_target_meaningful_collision(_robot: RobotBase, _other_robot: RobotBase, _closing_speed: float) -> void:
	_impact_seen = true


func _sync_lane_state() -> void:
	_ensure_target_robot()
	if not is_instance_valid(_target_robot):
		return

	var progress_lines: Array[String] = []
	var distance_to_edge := maxf(0.0, _target_robot.global_position.z - EDGE_LIMIT_Z)
	progress_lines.append("Objetivo | %.1fm al borde" % distance_to_edge)
	progress_lines.append("Impacto | %s" % ("decisivo" if _impact_seen else "pendiente"))
	set_progress_lines(progress_lines)

	if _target_robot.global_position.z <= EDGE_LIMIT_Z and not _lane_completed:
		set_callout_lines([
			"Aprendiste: el angulo correcto convierte un choque en salida.",
			"Siguiente sugerido: Partes.",
		])
		complete_lane()
