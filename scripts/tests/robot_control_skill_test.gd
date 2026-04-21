extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")

const ANCLA_CONFIG_PATH := "res://data/config/robots/ancla_archetype.tres"
const CONTROL_BEACON_GROUP := "temporary_control_beacons"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_control_archetype_exposes_zone_skill()
	await _validate_zone_skill_spawns_single_beacon_and_suppresses_enemy()
	await _validate_ffa_lab_exposes_control_archetype_identity()
	await process_frame
	await process_frame
	_finish()


func _validate_control_archetype_exposes_zone_skill() -> void:
	var config := load(ANCLA_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "El roster deberia incluir un recurso dedicado para el arquetipo Control/Zona.")
	if not (config is RobotArchetypeConfig):
		return

	var robot := await _spawn_robot(config as RobotArchetypeConfig)
	_assert(robot.has_method("has_core_skill"), "RobotBase deberia seguir exponiendo si un arquetipo tiene skill propia.")
	_assert(robot.has_method("get_core_skill_label"), "RobotBase deberia exponer la etiqueta corta de la skill propia.")
	if robot.has_method("has_core_skill"):
		_assert(bool(robot.call("has_core_skill")), "El arquetipo Control/Zona deberia arrancar con una skill propia activa.")
	if robot.has_method("get_core_skill_label"):
		_assert(String(robot.call("get_core_skill_label")) == "Baliza", "La skill propia del arquetipo Control/Zona deberia leerse como Baliza.")

	await _cleanup_node(robot)


func _validate_zone_skill_spawns_single_beacon_and_suppresses_enemy() -> void:
	var config := load(ANCLA_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "La prueba de Baliza necesita el recurso del arquetipo Control/Zona.")
	if not (config is RobotArchetypeConfig):
		return

	var tuned_config := (config as RobotArchetypeConfig).duplicate(true) as RobotArchetypeConfig
	tuned_config.set("core_skill_max_charges", 2)
	tuned_config.set("core_skill_recharge_seconds", 0.15)

	var source := await _spawn_robot(tuned_config)
	var target := await _spawn_robot(null)

	source.global_position = Vector3.ZERO
	target.global_position = Vector3(0.0, 0.8, -1.1)

	_assert(source.has_method("use_core_skill"), "RobotBase deberia poder activar la skill propia de Control/Zona.")
	_assert(target.has_method("is_control_zone_suppressed"), "RobotBase deberia exponer si una zona de control esta afectando al robot.")
	_assert(
		target.has_method("get_control_zone_suppression_time_left"),
		"RobotBase deberia exponer el tiempo restante de supresion para tests y HUD."
	)
	if not source.has_method("use_core_skill"):
		await _cleanup_node(target)
		await _cleanup_node(source)
		return

	var initial_charges := int(source.call("get_core_skill_charge_count"))
	var used := bool(source.call("use_core_skill"))
	_assert(used, "Baliza deberia poder desplegarse sin depender de pickups del mapa.")

	await _await_seconds(0.05)

	_assert(
		_count_group_nodes(CONTROL_BEACON_GROUP) == 1,
		"Baliza deberia dejar una sola baliza activa en escena para mantener la lectura limpia."
	)
	if target.has_method("is_control_zone_suppressed"):
		_assert(
			bool(target.call("is_control_zone_suppressed")),
			"Un rival dentro del area de Baliza deberia entrar en estado de zona de control."
		)
	if target.has_method("get_control_zone_suppression_time_left"):
		_assert(
			float(target.call("get_control_zone_suppression_time_left")) > 0.0,
			"La zona de control deberia dejar una ventana temporal legible, no solo un tick instantaneo."
		)
	_assert(
		int(source.call("get_core_skill_charge_count")) == max(initial_charges - 1, 0),
		"Desplegar Baliza deberia consumir una carga."
	)

	await _await_seconds(0.25)

	var used_again := bool(source.call("use_core_skill"))
	_assert(used_again, "Baliza deberia poder redeplegarse tras recargar una carga.")

	await _await_seconds(0.05)

	_assert(
		_count_group_nodes(CONTROL_BEACON_GROUP) == 1,
		"Redeplegar Baliza deberia reemplazar la baliza anterior en vez de apilar zonas."
	)

	await _cleanup_group(CONTROL_BEACON_GROUP)
	await _cleanup_node(target)
	await _cleanup_node(source)


func _validate_ffa_lab_exposes_control_archetype_identity() -> void:
	var main := FFA_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel")
	_assert(roster_label is Label, "La escena FFA deberia seguir exponiendo el roster compacto.")
	if roster_label is Label:
		var roster_text := (roster_label as Label).text
		_assert(roster_text.contains("Ancla"), "La escena FFA deberia exponer el arquetipo Control/Zona en el roster jugable.")
		_assert(
			roster_text.contains("skill Baliza") or roster_text.contains("skill baliza"),
			"El roster FFA deberia dejar visible la skill propia Baliza."
		)

	await _cleanup_node(main)


func _count_group_nodes(group_name: String) -> int:
	var count := 0
	for node in get_nodes_in_group(group_name):
		if node is Node:
			count += 1

	return count


func _spawn_robot(config: RobotArchetypeConfig) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	if config != null:
		robot.archetype_config = config

	root.add_child(robot)
	await process_frame
	await process_frame
	return robot


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _cleanup_group(group_name: String) -> void:
	for node in get_nodes_in_group(group_name):
		if node is Node:
			await _cleanup_node(node as Node)


func _await_seconds(seconds: float) -> void:
	var physics_fps := float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60))
	var frame_count := maxi(int(ceil(seconds * physics_fps)), 1)
	for _frame in range(frame_count):
		await physics_frame

	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
