extends "res://scripts/practice/practice_lane_base.gd"
class_name RecoveryLane

const DetachedPart = preload("res://scripts/robots/detached_part.gd")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")

const AllySpawn := Vector3(-4.0, 1.2, -3.75)
const RivalSpawn := Vector3(4.0, 1.2, -3.75)
const VoidPocketSpawn := Vector3(0.0, 1.2, 5.25)

var _ally_robot: RobotBase = null
var _rival_robot: RobotBase = null
var _ally_part_restored := false
var _enemy_part_denied := false
var _pending_ally_part_name := "left_arm"
var _pending_enemy_part_name := "right_leg"
var _void_pocket_area: Area3D = null


func configure_lane(module_spec: Dictionary, player_robots: Array) -> void:
	super.configure_lane(module_spec, player_robots)
	set_objective_lines([
		"Devuelve una parte aliada con vida parcial.",
		"Despues niega una parte rival en el vacio.",
	])
	set_callout_lines([
		"Cargar una parte bloquea otras acciones activas.",
	])
	call_deferred("_sync_lane_state")


func _ready() -> void:
	_ensure_auxiliary_robots()
	_ensure_void_pocket()
	_prime_detached_parts()
	_sync_lane_state()


func _physics_process(_delta: float) -> void:
	_sync_lane_state()


func _ensure_auxiliary_robots() -> void:
	if not is_instance_valid(_ally_robot):
		_ally_robot = _create_fixture_robot("Aliado", "grua", AllySpawn, 1)
	if not is_instance_valid(_rival_robot):
		_rival_robot = _create_fixture_robot("Rival", "ariete", RivalSpawn, 2)


func _create_fixture_robot(display_name: String, roster_entry_id: String, spawn_position: Vector3, team_identity: int) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate()
	if not (robot is RobotBase):
		return null

	var fixture_robot := robot as RobotBase
	add_child(fixture_robot)
	var roster_entry := RosterCatalog.get_shell_roster_entry(roster_entry_id)
	var archetype_config = roster_entry.get("config", null)
	fixture_robot.display_name = display_name
	fixture_robot.is_player_controlled = false
	fixture_robot.team_id = team_identity
	if archetype_config != null:
		fixture_robot.apply_runtime_loadout(archetype_config, RobotBase.ControlMode.EASY)
	fixture_robot.global_position = spawn_position
	fixture_robot.capture_spawn_transform()
	fixture_robot.reset_modular_state()
	return fixture_robot


func _ensure_void_pocket() -> void:
	if is_instance_valid(_void_pocket_area):
		return

	var area := Area3D.new()
	area.name = "VoidPocket"
	area.monitoring = true
	area.monitorable = true
	add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 1.0, 2.5)
	shape.shape = box
	area.add_child(shape)
	area.global_position = VoidPocketSpawn
	area.body_entered.connect(_on_void_pocket_body_entered)
	_void_pocket_area = area


func _prime_detached_parts() -> void:
	if is_instance_valid(_ally_robot):
		_ally_robot.apply_damage_to_part(_pending_ally_part_name, _ally_robot.max_part_health, Vector3.FORWARD, _rival_robot)
	if is_instance_valid(_rival_robot):
		_rival_robot.apply_damage_to_part(_pending_enemy_part_name, _rival_robot.max_part_health, Vector3.BACK, _ally_robot)


func _sync_lane_state() -> void:
	_ensure_auxiliary_robots()
	_ensure_void_pocket()

	_ally_part_restored = _ally_robot != null and is_instance_valid(_ally_robot) and _ally_robot.get_part_health(_pending_ally_part_name) > 0.0
	_enemy_part_denied = not _has_live_detached_part_for_robot(_rival_robot, _pending_enemy_part_name)

	set_progress_lines([
		"Aliado | %s" % ("recuperado" if _ally_part_restored else "pendiente"),
		"Rival | %s" % ("negado" if _enemy_part_denied else "pendiente"),
	])

	if _ally_part_restored and _enemy_part_denied and not _lane_completed:
		set_callout_lines([
			"Aprendiste: devolver ayuda al comeback y negar partes cierra espacio.",
			"Siguiente sugerido: modo libre.",
		])
		set_context_card_lines([
			"Aprendiste a convertir una parte caida en ventaja tactica.",
			"Siguiente sugerido: modo libre.",
		])
		complete_lane()


func _on_void_pocket_body_entered(body: Node) -> void:
	if not (body is DetachedPart):
		return

	var detached_part := body as DetachedPart
	if detached_part.get_original_robot() != _rival_robot:
		return
	detached_part.deny_to_void()


func _has_live_detached_part_for_robot(robot: RobotBase, part_name: String) -> bool:
	if robot == null or not is_instance_valid(robot):
		return false

	for node in get_tree().get_nodes_in_group("detached_parts"):
		if not (node is DetachedPart):
			continue
		var detached_part := node as DetachedPart
		if detached_part.get_original_robot() != robot:
			continue
		if detached_part.part_name != part_name:
			continue
		return is_instance_valid(detached_part)

	return false
