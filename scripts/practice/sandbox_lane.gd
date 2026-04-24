extends "res://scripts/practice/practice_lane_base.gd"
class_name SandboxLane

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")

var _fixture_robot: RobotBase = null


func configure_lane(module_spec: Dictionary, player_robots: Array) -> void:
	super.configure_lane(module_spec, player_robots)
	set_objective_lines([
		"Combina movimiento, impacto, energia, partes y recuperacion.",
		"No hay fallo: prueba sin presion competitiva.",
	])
	set_callout_lines([
		"Experimenta sin perder lectura de cuerpo y borde.",
	])
	call_deferred("_sync_lane_state")


func _ready() -> void:
	_ensure_fixture_robot()
	_sync_lane_state()


func _physics_process(_delta: float) -> void:
	_sync_lane_state()


func _ensure_fixture_robot() -> void:
	if is_instance_valid(_fixture_robot):
		return

	var robot := ROBOT_SCENE.instantiate()
	if not (robot is RobotBase):
		return

	_fixture_robot = robot as RobotBase
	add_child(_fixture_robot)
	var roster_entry := RosterCatalog.get_shell_roster_entry("patin")
	var archetype_config = roster_entry.get("config", null)
	_fixture_robot.display_name = "Sandbox"
	_fixture_robot.is_player_controlled = false
	_fixture_robot.team_id = -1
	if archetype_config != null:
		_fixture_robot.apply_runtime_loadout(archetype_config, RobotBase.ControlMode.EASY)
	_fixture_robot.global_position = Vector3(0.0, 1.2, -5.0)
	_fixture_robot.capture_spawn_transform()
	_fixture_robot.reset_modular_state()


func _sync_lane_state() -> void:
	var player_count := 0
	for robot in get_player_robots():
		if robot != null and is_instance_valid(robot):
			player_count += 1

	set_progress_lines([
		"Jugadores activos | %s" % player_count,
		"Fixture | %s" % ("listo" if is_instance_valid(_fixture_robot) else "pendiente"),
	])
