extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")

const PATIN_CONFIG_PATH := "res://data/config/robots/patin_archetype.tres"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_patin_exposes_a_core_mobility_skill()
	await _validate_mobility_skill_creates_a_short_reposition_window()
	await _validate_teams_lab_roster_reads_the_mobility_skill_state()
	await process_frame
	await process_frame
	_finish()


func _validate_patin_exposes_a_core_mobility_skill() -> void:
	var config := load(PATIN_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "La prueba necesita el recurso de arquetipo Patin.")
	if not (config is RobotArchetypeConfig):
		return

	var robot := await _spawn_robot(config as RobotArchetypeConfig)
	_assert(robot.has_method("has_core_skill"), "RobotBase deberia seguir exponiendo si un arquetipo tiene skill propia.")
	_assert(robot.has_method("get_core_skill_label"), "RobotBase deberia exponer la etiqueta corta de la skill propia.")
	if robot.has_method("has_core_skill"):
		_assert(bool(robot.call("has_core_skill")), "Patin deberia dejar de depender solo de tuning pasivo y exponer una skill propia.")
	if robot.has_method("get_core_skill_label"):
		_assert(
			String(robot.call("get_core_skill_label")) == "Derrape",
			"La skill propia de Patin deberia leerse como Derrape."
		)

	await _cleanup_node(robot)


func _validate_mobility_skill_creates_a_short_reposition_window() -> void:
	var config := load(PATIN_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "La prueba de Derrape necesita el recurso Patin.")
	if not (config is RobotArchetypeConfig):
		return

	var tuned_config := (config as RobotArchetypeConfig).duplicate(true) as RobotArchetypeConfig
	tuned_config.set("core_skill_recharge_seconds", 0.15)
	var patin := await _spawn_robot(tuned_config)
	var baseline_drive := patin.get_effective_leg_drive_multiplier()

	_assert(patin.has_method("use_core_skill"), "RobotBase deberia poder activar la skill propia de Patin.")
	_assert(patin.has_method("is_mobility_skill_active"), "RobotBase deberia exponer si la ventana de Derrape esta activa.")
	if not patin.has_method("use_core_skill"):
		await _cleanup_node(patin)
		return

	var used := bool(patin.call("use_core_skill"))
	_assert(used, "Patin deberia poder activar Derrape sin depender de pickups de borde.")
	if used:
		await physics_frame
		await process_frame

		_assert(
			patin.global_position.length() > 0.05,
			"Derrape deberia reposicionar a Patin de inmediato y no quedarse solo en un contador."
		)
		_assert(
			patin.get_effective_leg_drive_multiplier() > baseline_drive,
			"Derrape deberia abrir una ventana corta de mayor movilidad real para Patin."
		)
		if patin.has_method("is_mobility_skill_active"):
			_assert(
				bool(patin.call("is_mobility_skill_active")),
				"Patin deberia marcar la ventana activa de Derrape mientras dura el desplazamiento."
			)

		await _await_seconds(0.9)

		_assert(
			int(patin.get_core_skill_charge_count()) == int(patin.get_core_skill_max_charges()),
			"Derrape deberia recuperar su carga tras el tiempo de recarga configurado."
		)
		_assert(
			is_equal_approx(patin.get_effective_leg_drive_multiplier(), baseline_drive),
			"Al terminar Derrape, Patin deberia volver a su movilidad base."
		)
		if patin.has_method("is_mobility_skill_active"):
			_assert(
				not bool(patin.call("is_mobility_skill_active")),
				"Al terminar Derrape, la ventana activa deberia apagarse."
			)

	await _cleanup_node(patin)


func _validate_teams_lab_roster_reads_the_mobility_skill_state() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var patin := _find_robot_by_archetype(main, "Patin")
	_assert(patin != null, "La escena principal deberia seguir incluyendo a Patin en el laboratorio Teams.")
	if patin == null:
		await _cleanup_node(main)
		return

	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel")
	_assert(roster_label is Label, "El laboratorio Teams deberia seguir exponiendo el roster compacto.")
	if not (roster_label is Label):
		await _cleanup_node(main)
		return

	var roster_text := (roster_label as Label).text
	_assert(
		roster_text.contains("skill Derrape") or roster_text.contains("skill derrape"),
		"El roster de Teams deberia dejar visible la skill propia de Patin."
	)

	var used := patin.use_core_skill()
	_assert(used, "La prueba de HUD necesita activar Derrape desde Patin.")
	if used:
		await process_frame
		await process_frame
		roster_text = (roster_label as Label).text
		_assert(
			roster_text.contains("derrape"),
			"El roster compacto deberia marcar cuando Patin entra en su ventana de reposicion."
		)

	await _cleanup_node(main)


func _find_robot_by_archetype(root_node: Node, archetype_label: String) -> RobotBase:
	for node in root_node.get_tree().get_nodes_in_group("robots"):
		if not (node is RobotBase):
			continue

		var robot := node as RobotBase
		if robot.get_archetype_label() == archetype_label:
			return robot

	return null


func _spawn_robot(config: RobotArchetypeConfig) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	if config != null:
		robot.archetype_config = config
	robot.gravity = 0.0
	robot.void_fall_y = -100.0
	root.add_child(robot)
	await process_frame
	await process_frame
	return robot


func _await_seconds(duration: float) -> void:
	if duration <= 0.0:
		return

	await create_timer(duration).timeout
	await physics_frame
	await process_frame


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
