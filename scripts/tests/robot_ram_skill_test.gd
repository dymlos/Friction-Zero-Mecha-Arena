extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")

const ARIETE_CONFIG_PATH := "res://data/config/robots/ariete_archetype.tres"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_ariete_exposes_a_core_ram_skill()
	await _validate_ram_skill_creates_a_short_impact_window()
	await _validate_teams_lab_roster_reads_the_ram_state()
	await process_frame
	await process_frame
	_finish()


func _validate_ariete_exposes_a_core_ram_skill() -> void:
	var config := load(ARIETE_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "La prueba necesita el recurso de arquetipo Ariete.")
	if not (config is RobotArchetypeConfig):
		return

	var robot := await _spawn_robot(config as RobotArchetypeConfig)
	_assert(robot.has_method("has_core_skill"), "RobotBase deberia exponer si un arquetipo tiene una skill propia.")
	_assert(robot.has_method("get_core_skill_label"), "RobotBase deberia exponer el nombre corto de la skill propia.")
	if robot.has_method("has_core_skill"):
		_assert(bool(robot.call("has_core_skill")), "Ariete ya no deberia depender solo de pasivas; deberia tener una skill propia de impacto.")
	if robot.has_method("get_core_skill_label"):
		_assert(
			String(robot.call("get_core_skill_label")) == "Embestida",
			"La skill propia de Ariete deberia leerse como Embestida."
		)

	await _cleanup_node(robot)


func _validate_ram_skill_creates_a_short_impact_window() -> void:
	var config := load(ARIETE_CONFIG_PATH)
	_assert(config is RobotArchetypeConfig, "La prueba de Embestida necesita el recurso Ariete.")
	if not (config is RobotArchetypeConfig):
		return

	var source := await _spawn_robot(config as RobotArchetypeConfig)
	var baseline_arm_power := source.get_effective_arm_power_multiplier()
	var baseline_received_impulse := source.get_received_impulse_multiplier()

	_assert(source.has_method("use_core_skill"), "RobotBase deberia poder activar la skill propia de Ariete.")
	if not source.has_method("use_core_skill"):
		await _cleanup_node(source)
		return

	var used := bool(source.call("use_core_skill"))
	_assert(used, "Ariete deberia poder activar Embestida sin pickups del mapa.")
	if used:
		await process_frame
		_assert(
			source.get_effective_arm_power_multiplier() > baseline_arm_power,
			"Embestida deberia aumentar por un instante la fuerza de impacto de Ariete."
		)
		_assert(
			source.get_received_impulse_multiplier() < baseline_received_impulse,
			"Embestida deberia volver a Ariete mas estable frente al impulso externo mientras dura la ventana."
		)

		await _await_seconds(0.9)

		_assert(
			is_equal_approx(source.get_effective_arm_power_multiplier(), baseline_arm_power),
			"Al terminar Embestida, Ariete deberia volver a su potencia de impacto base."
		)
		_assert(
			is_equal_approx(source.get_received_impulse_multiplier(), baseline_received_impulse),
			"Al terminar Embestida, Ariete deberia volver a su resistencia base."
		)

	await _cleanup_node(source)


func _validate_teams_lab_roster_reads_the_ram_state() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var ariete := _find_robot_by_archetype(main, "Ariete")
	_assert(ariete != null, "La escena principal deberia seguir incluyendo a Ariete en el laboratorio Teams.")
	if ariete == null:
		await _cleanup_node(main)
		return

	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel")
	_assert(roster_label is Label, "El laboratorio Teams deberia seguir exponiendo el roster compacto.")
	if not (roster_label is Label):
		await _cleanup_node(main)
		return

	var roster_text := (roster_label as Label).text
	_assert(
		roster_text.contains("skill Embestida") or roster_text.contains("skill embestida"),
		"El roster de Teams deberia dejar visible la skill propia de Ariete."
	)

	var used := ariete.use_core_skill()
	_assert(used, "La prueba de HUD necesita activar Embestida desde Ariete.")
	if used:
		await process_frame
		await process_frame
		roster_text = (roster_label as Label).text
		_assert(
			roster_text.contains("embestida"),
			"El roster compacto deberia marcar cuando Ariete esta dentro de su ventana corta de Embestida."
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
