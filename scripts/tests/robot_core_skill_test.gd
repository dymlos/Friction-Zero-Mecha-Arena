extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")

const AGUJA_CONFIG_PATH := "res://data/config/robots/aguja_archetype.tres"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_poke_archetype_exposes_a_charge_skill()
	await _validate_charge_skill_spends_and_recovers_ammo()
	await _validate_ffa_lab_exposes_the_new_archetype_identity()
	await process_frame
	await process_frame
	_finish()


func _validate_poke_archetype_exposes_a_charge_skill() -> void:
	var config := load(AGUJA_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "El roster deberia incluir un recurso de arquetipo Poke/Skillshot dedicado.")
	if not (config is RobotArchetypeConfig):
		return

	var robot := await _spawn_robot(config as RobotArchetypeConfig)
	_assert(robot.has_method("has_core_skill"), "RobotBase deberia exponer si un arquetipo tiene una skill propia.")
	_assert(robot.has_method("get_core_skill_label"), "RobotBase deberia exponer el nombre corto de la skill propia para HUD/roster.")
	_assert(robot.has_method("get_core_skill_charge_count"), "RobotBase deberia exponer las cargas actuales de la skill propia.")
	_assert(robot.has_method("get_core_skill_max_charges"), "RobotBase deberia exponer el maximo de cargas de la skill propia.")
	if robot.has_method("has_core_skill"):
		_assert(bool(robot.call("has_core_skill")), "Aguja deberia arrancar con una skill propia activa.")
	if robot.has_method("get_core_skill_label"):
		_assert(String(robot.call("get_core_skill_label")) == "Pulso", "La primera skill propia de Aguja deberia leerse como Pulso.")
	if robot.has_method("get_core_skill_charge_count") and robot.has_method("get_core_skill_max_charges"):
		_assert(
			int(robot.call("get_core_skill_charge_count")) == int(robot.call("get_core_skill_max_charges")),
			"Aguja deberia arrancar con todas sus cargas disponibles."
		)

	await _cleanup_node(robot)


func _validate_charge_skill_spends_and_recovers_ammo() -> void:
	var config := load(AGUJA_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "La prueba de cargas necesita el recurso Aguja.")
	if not (config is RobotArchetypeConfig):
		return

	var tuned_config := (config as RobotArchetypeConfig).duplicate(true) as RobotArchetypeConfig
	tuned_config.set("core_skill_recharge_seconds", 0.15)
	var source := await _spawn_robot(tuned_config)
	var target := await _spawn_robot(null)

	source.global_position = Vector3.ZERO
	target.global_position = Vector3(0.0, 0.8, -2.1)

	_assert(source.has_method("use_core_skill"), "RobotBase deberia poder activar la skill propia del arquetipo.")
	if not source.has_method("use_core_skill"):
		await _cleanup_node(target)
		await _cleanup_node(source)
		return

	var baseline_impulse := target.external_impulse.length()
	var baseline_health := target.get_part_health("right_arm")
	var initial_charges := int(source.call("get_core_skill_charge_count"))
	var used := bool(source.call("use_core_skill"))
	_assert(used, "La skill propia de Aguja deberia poder dispararse sin depender de un pickup del mapa.")

	await _await_seconds(0.05)

	_assert(
		int(source.call("get_core_skill_charge_count")) == max(initial_charges - 1, 0),
		"Disparar la skill propia deberia consumir exactamente una carga."
	)

	await _await_seconds(0.35)

	_assert(
		target.external_impulse.length() > baseline_impulse,
		"El disparo propio de Aguja deberia empujar al robot rival alcanzado."
	)
	_assert(
		target.get_part_health("right_arm") < baseline_health,
		"El disparo propio de Aguja deberia castigar una parte del rival, no solo empujar."
	)

	await _await_seconds(0.2)

	_assert(
		int(source.call("get_core_skill_charge_count")) == initial_charges,
		"La skill propia deberia recargar una carga tras su timer configurado."
	)

	await _cleanup_group("temporary_projectiles")
	await _cleanup_node(target)
	await _cleanup_node(source)


func _validate_ffa_lab_exposes_the_new_archetype_identity() -> void:
	var main := FFA_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel")
	_assert(roster_label is Label, "La escena FFA deberia seguir exponiendo el roster compacto.")
	if roster_label is Label:
		var roster_text := (roster_label as Label).text
		_assert(roster_text.contains("Aguja"), "La escena FFA deberia exponer el nuevo arquetipo Poke/Skillshot.")
		_assert(
			roster_text.contains("skill Pulso") or roster_text.contains("skill pulso"),
			"El roster FFA deberia dejar visible la skill propia por cargas de Aguja."
		)

	await _cleanup_node(main)


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
		if not (node is Node):
			continue

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
