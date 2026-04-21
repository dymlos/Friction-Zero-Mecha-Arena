extends Node3D
class_name Main

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchHud = preload("res://scripts/ui/match_hud.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const EdgeRepairPickup = preload("res://scripts/pickups/edge_repair_pickup.gd")
const EdgeMobilityPickup = preload("res://scripts/pickups/edge_mobility_pickup.gd")
const EdgeEnergyPickup = preload("res://scripts/pickups/edge_energy_pickup.gd")
const EdgePulsePickup = preload("res://scripts/pickups/edge_pulse_pickup.gd")

@export var hard_mode_player_slots: PackedInt32Array = PackedInt32Array()

@onready var arena_root: Node3D = $ArenaRoot
@onready var robot_root: Node3D = $RobotRoot
@onready var systems: Node = $Systems
@onready var match_controller: MatchController = $Systems/MatchController
@onready var ui: MatchHud = $UI/MatchHud

var _arena: ArenaBase = null


func _ready() -> void:
	# Esta escena solo conecta piezas grandes: arena, robots, UI y sistemas.
	# La logica concreta vive en scripts mas chicos para que el proyecto crezca ordenado.
	_arena = _get_active_arena()
	_configure_playable_prototype()
	_connect_arena_pickups()
	_register_existing_robots()
	match_controller.start_match()
	_apply_match_pressure_to_arena()
	_report_startup_structure()
	ui.show_status(_build_startup_status())
	_refresh_hud()


func _process(_delta: float) -> void:
	_apply_match_pressure_to_arena()
	_refresh_hud()


func _register_existing_robots() -> void:
	# Por ahora los robots estan puestos a mano en la escena.
	# Cuando haya seleccion de jugadores, este punto puede pasar a usar spawns y datos.
	for child in robot_root.get_children():
		if child is RobotBase:
			match_controller.register_robot(child)
			child.fell_into_void.connect(_on_robot_fell_into_void)
			child.respawned.connect(_on_robot_respawned)
			child.part_destroyed.connect(_on_robot_part_destroyed)
			child.part_restored.connect(_on_robot_part_restored)
			child.robot_disabled.connect(_on_robot_disabled)
			child.robot_exploded.connect(_on_robot_exploded)


func _configure_playable_prototype() -> void:
	var robots := _get_scene_robots()
	_apply_match_mode_bootstrap(robots)
	var spawn_points := _get_arena_spawn_points()
	var local_player_count: int = min(match_controller.get_local_player_count(), robots.size())

	for index in range(robots.size()):
		var robot: RobotBase = robots[index]
		robot.player_index = index + 1
		robot.is_player_controlled = index < local_player_count
		robot.control_mode = _resolve_control_mode_for_slot(robot.player_index)
		_assign_default_local_inputs(robot, index)
		if index < spawn_points.size():
			var spawn_point: Marker3D = spawn_points[index]
			robot.global_position = spawn_point.global_position
			robot.global_basis = spawn_point.global_basis
		robot.capture_spawn_transform()
		if robot.is_player_controlled:
			robot.refresh_input_setup()


func _apply_match_mode_bootstrap(robots: Array[RobotBase]) -> void:
	if match_controller == null:
		return
	if match_controller.match_mode != MatchController.MatchMode.FFA:
		return

	# El laboratorio 2v2 deja team_id en la escena; en FFA se neutralizan para que
	# rescate/negacion y scoring traten a cada robot como competidor individual.
	for robot in robots:
		robot.team_id = 0


func _assign_default_local_inputs(robot: RobotBase, index: int) -> void:
	if not robot.is_player_controlled:
		return

	if index == 0:
		robot.keyboard_profile = RobotBase.KeyboardProfile.WASD_SPACE
		robot.joypad_device = -1
		return

	if index == 1:
		robot.keyboard_profile = RobotBase.KeyboardProfile.ARROWS_ENTER
		robot.joypad_device = -1
		return

	if index == 2:
		robot.keyboard_profile = RobotBase.KeyboardProfile.NUMPAD
		robot.joypad_device = -1
		return

	if index == 3:
		robot.keyboard_profile = RobotBase.KeyboardProfile.IJKL
		robot.joypad_device = -1
		return

	robot.keyboard_profile = RobotBase.KeyboardProfile.NONE


func _get_scene_robots() -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _get_arena_spawn_points() -> Array[Marker3D]:
	if _arena != null:
		return _arena.get_spawn_points()

	return []


func _get_active_arena() -> ArenaBase:
	for child in arena_root.get_children():
		if child is ArenaBase:
			return child as ArenaBase

	return null


func _resolve_control_mode_for_slot(player_slot: int) -> RobotBase.ControlMode:
	if hard_mode_player_slots.has(player_slot):
		return RobotBase.ControlMode.HARD

	return RobotBase.ControlMode.EASY


func _apply_match_pressure_to_arena() -> void:
	if _arena == null:
		return

	_arena.set_play_area_scale(match_controller.get_current_play_area_scale())


func _refresh_hud() -> void:
	ui.show_round_state(match_controller.get_round_state_lines())
	ui.show_roster(match_controller.get_robot_status_lines())


func _report_startup_structure() -> void:
	var arena_count := arena_root.get_child_count()
	var robot_count := robot_root.get_child_count()
	var system_count := systems.get_child_count()

	print("Friction Zero base cargada.")
	print("Arenas: %s | Robots: %s | Sistemas: %s" % [arena_count, robot_count, system_count])


func _connect_arena_pickups() -> void:
	for node in get_tree().get_nodes_in_group("edge_repair_pickups"):
		if not (node is EdgeRepairPickup):
			continue

		var pickup := node as EdgeRepairPickup
		if pickup.pickup_collected.is_connected(_on_edge_repair_pickup_collected):
			continue

		pickup.pickup_collected.connect(_on_edge_repair_pickup_collected)

	for node in get_tree().get_nodes_in_group("edge_mobility_pickups"):
		if not (node is EdgeMobilityPickup):
			continue

		var mobility_pickup := node as EdgeMobilityPickup
		if mobility_pickup.pickup_collected.is_connected(_on_edge_mobility_pickup_collected):
			continue

		mobility_pickup.pickup_collected.connect(_on_edge_mobility_pickup_collected)

	for node in get_tree().get_nodes_in_group("edge_energy_pickups"):
		if not (node is EdgeEnergyPickup):
			continue

		var energy_pickup := node as EdgeEnergyPickup
		if energy_pickup.pickup_collected.is_connected(_on_edge_energy_pickup_collected):
			continue

		energy_pickup.pickup_collected.connect(_on_edge_energy_pickup_collected)

	for node in get_tree().get_nodes_in_group("edge_pulse_pickups"):
		if not (node is EdgePulsePickup):
			continue

		var pulse_pickup := node as EdgePulsePickup
		if pulse_pickup.pickup_collected.is_connected(_on_edge_pulse_pickup_collected):
			continue

		pulse_pickup.pickup_collected.connect(_on_edge_pulse_pickup_collected)


func _build_startup_status() -> String:
	var control_segments: Array[String] = []
	for robot in match_controller.registered_robots:
		if not is_instance_valid(robot) or not robot.is_player_controlled:
			continue

		control_segments.append("P%s %s" % [robot.player_index, robot.get_input_hint()])

	var control_summary := ", ".join(control_segments)
	if control_summary == "":
		control_summary = "sin jugadores locales"

	return "Friction Zero: %s robots en arena | %s" % [
		match_controller.registered_robots.size(),
		control_summary,
	]


func _on_robot_fell_into_void(robot: RobotBase) -> void:
	var message := match_controller.record_robot_elimination(robot, MatchController.EliminationCause.VOID)
	if message != "":
		ui.show_status(message)


func _on_robot_respawned(robot: RobotBase) -> void:
	if match_controller.is_round_reset_pending():
		return

	ui.show_status("%s volvio al punto de prueba" % robot.display_name)


func _on_robot_part_destroyed(robot: RobotBase, part_name: String, _detached_part: DetachedPart) -> void:
	ui.show_status("%s perdio %s" % [robot.display_name, RobotBase.get_part_display_name(part_name)])


func _on_robot_part_restored(robot: RobotBase, part_name: String, restored_by: RobotBase) -> void:
	if restored_by == robot:
		ui.show_status("%s recupero %s" % [robot.display_name, RobotBase.get_part_display_name(part_name)])
		return

	ui.show_status("%s devolvio %s a %s" % [
		restored_by.display_name,
		RobotBase.get_part_display_name(part_name),
		robot.display_name,
	])


func _on_robot_disabled(robot: RobotBase) -> void:
	ui.show_status("%s quedo inutilizado" % robot.display_name)


func _on_robot_exploded(robot: RobotBase) -> void:
	var message := match_controller.record_robot_elimination(robot, MatchController.EliminationCause.EXPLOSION)
	if message != "":
		ui.show_status(message)


func _on_edge_repair_pickup_collected(robot: RobotBase, repaired_part_name: String) -> void:
	ui.show_status("%s estabilizo %s en borde" % [
		robot.display_name,
		RobotBase.get_part_display_name(repaired_part_name),
	])


func _on_edge_mobility_pickup_collected(robot: RobotBase, boost_duration: float) -> void:
	ui.show_status("%s activo impulso de borde (%.1fs)" % [
		robot.display_name,
		boost_duration,
	])


func _on_edge_energy_pickup_collected(robot: RobotBase, surge_duration: float) -> void:
	ui.show_status("%s recargo energia de borde (%.1fs)" % [
		robot.display_name,
		surge_duration,
	])


func _on_edge_pulse_pickup_collected(robot: RobotBase, item_name: String) -> void:
	var item_label := robot.get_carried_item_display_name()
	if item_label == "":
		item_label = item_name

	ui.show_status("%s aseguro %s de borde" % [
		robot.display_name,
		item_label,
	])
