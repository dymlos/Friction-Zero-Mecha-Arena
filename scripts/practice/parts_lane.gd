extends "res://scripts/practice/practice_lane_base.gd"
class_name PartsLane

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")

const TARGET_SPAWN := Vector3(0.0, 1.2, -4.0)

var _target_robot: RobotBase = null
var _required_skill_label := "Corte"
var _saw_required_skill := false


func configure_lane(module_spec: Dictionary, player_robots: Array) -> void:
	super.configure_lane(module_spec, player_robots)
	_saw_required_skill = false
	set_objective_lines([
		"Activa Corte y castiga una parte ya tocada.",
		"Lee brazos al frente y piernas hacia la retaguardia.",
	])
	set_callout_lines([
		"Corte es una ventana corta: preparala antes del contacto.",
	])
	call_deferred("_sync_lane_state")


func get_required_skill_label() -> String:
	return _required_skill_label


func has_seen_required_skill() -> bool:
	return _saw_required_skill


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
	var roster_entry := RosterCatalog.get_shell_roster_entry("cizalla")
	var archetype_config = roster_entry.get("config", null)
	_target_robot.display_name = "Blanco"
	_target_robot.is_player_controlled = false
	_target_robot.team_id = -1
	if archetype_config != null:
		_target_robot.apply_runtime_loadout(archetype_config, RobotBase.ControlMode.EASY)
	_target_robot.global_position = TARGET_SPAWN
	_target_robot.capture_spawn_transform()
	_target_robot.reset_modular_state()


func _sync_lane_state() -> void:
	_ensure_target_robot()
	if not is_instance_valid(_target_robot):
		return

	for robot in get_player_robots():
		if robot != null and is_instance_valid(robot) and robot.has_method("get_core_skill_label"):
			if String(robot.call("get_core_skill_label")) == _required_skill_label:
				if robot.has_method("is_core_skill_active") and bool(robot.call("is_core_skill_active")):
					_saw_required_skill = true

	var active_parts := _target_robot.get_active_part_count()
	var damaged_part := ""
	for part_name in RobotBase.BODY_PARTS:
		if _target_robot.get_part_health(part_name) < _target_robot.max_part_health:
			damaged_part = RobotBase.get_part_display_name(part_name)
			break

	set_progress_lines([
		"Habilidad | %s" % ("Corte visto" if _saw_required_skill else "activa Corte"),
		"Partes vivas | %s/4" % active_parts,
		"Dano visible | %s" % (damaged_part if damaged_part != "" else "ninguno"),
	])

	if _saw_required_skill and active_parts < 4 and not _lane_completed:
		set_callout_lines([
			"Aprendiste: un golpe bueno cambia el cuerpo y la lectura del rival.",
			"Siguiente sugerido: modo libre.",
		])
		set_context_card_lines([
			"Aprendiste a mirar el cuerpo despues del golpe.",
			"Siguiente sugerido: modo libre.",
		])
		complete_lane()
