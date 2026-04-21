extends Node3D
class_name Main

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchHud = preload("res://scripts/ui/match_hud.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const EdgeRepairPickup = preload("res://scripts/pickups/edge_repair_pickup.gd")
const EdgeMobilityPickup = preload("res://scripts/pickups/edge_mobility_pickup.gd")
const EdgeEnergyPickup = preload("res://scripts/pickups/edge_energy_pickup.gd")
const EdgePulsePickup = preload("res://scripts/pickups/edge_pulse_pickup.gd")
const ARIETE_ARCHETYPE = preload("res://data/config/robots/ariete_archetype.tres")
const GRUA_ARCHETYPE = preload("res://data/config/robots/grua_archetype.tres")
const CIZALLA_ARCHETYPE = preload("res://data/config/robots/cizalla_archetype.tres")
const PATIN_ARCHETYPE = preload("res://data/config/robots/patin_archetype.tres")
const AGUJA_ARCHETYPE = preload("res://data/config/robots/aguja_archetype.tres")
const ANCLA_ARCHETYPE = preload("res://data/config/robots/ancla_archetype.tres")
const HUD_DETAIL_TOGGLE_KEY := KEY_F1
const LAB_SELECTOR_SLOT_KEY := KEY_F2
const LAB_SELECTOR_ARCHETYPE_KEY := KEY_F3
const LAB_SELECTOR_CONTROL_KEY := KEY_F4
const MATCH_RESTART_KEY := KEY_F5
const DEFAULT_LAB_ARCHETYPES := [
	ARIETE_ARCHETYPE,
	GRUA_ARCHETYPE,
	CIZALLA_ARCHETYPE,
	PATIN_ARCHETYPE,
	AGUJA_ARCHETYPE,
	ANCLA_ARCHETYPE,
]

@export var hard_mode_player_slots: PackedInt32Array = PackedInt32Array()
@export var lab_runtime_selector_enabled := true
@export var lab_runtime_archetypes: Array[RobotArchetypeConfig] = []

@onready var arena_root: Node3D = $ArenaRoot
@onready var robot_root: Node3D = $RobotRoot
@onready var systems: Node = $Systems
@onready var match_controller: MatchController = $Systems/MatchController
@onready var ui: MatchHud = $UI/MatchHud

var _arena: ArenaBase = null
var _lab_selected_player_slot := 1
var _applying_lab_selector_reset := false


func _ready() -> void:
	# Esta escena solo conecta piezas grandes: arena, robots, UI y sistemas.
	# La logica concreta vive en scripts mas chicos para que el proyecto crezca ordenado.
	_arena = _get_active_arena()
	_configure_playable_prototype()
	_configure_edge_pickup_layout_profile()
	_connect_arena_pickups()
	_connect_match_flow()
	_register_existing_robots()
	match_controller.start_match()
	_apply_match_pressure_to_arena()
	_report_startup_structure()
	ui.show_status(_build_hud_toggle_status())
	_refresh_hud()


func _process(_delta: float) -> void:
	_apply_match_pressure_to_arena()
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == MATCH_RESTART_KEY and match_controller.request_match_restart():
		ui.show_status(_build_hud_toggle_status())
		_refresh_hud()
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode != HUD_DETAIL_TOGGLE_KEY:
		if key_event.keycode == LAB_SELECTOR_SLOT_KEY:
			cycle_lab_selector_slot()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == LAB_SELECTOR_ARCHETYPE_KEY:
			cycle_selected_lab_archetype()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == LAB_SELECTOR_CONTROL_KEY:
			toggle_selected_lab_control_mode()
			get_viewport().set_input_as_handled()
		return

	cycle_hud_detail_mode()
	get_viewport().set_input_as_handled()


func cycle_hud_detail_mode() -> void:
	match_controller.cycle_hud_detail_mode()
	ui.show_status(_build_hud_toggle_status())
	_refresh_hud()


func cycle_lab_selector_slot() -> void:
	if not lab_runtime_selector_enabled:
		return

	var robots := _get_scene_robots()
	if robots.is_empty():
		return

	var selected_index := _get_selected_lab_robot_index(robots)
	selected_index = wrapi(selected_index + 1, 0, robots.size())
	_lab_selected_player_slot = robots[selected_index].player_index
	ui.show_status("Lab: %s" % _get_selected_lab_robot_brief())
	_refresh_hud()


func cycle_selected_lab_archetype() -> void:
	if not lab_runtime_selector_enabled:
		return

	var robot := _get_selected_lab_robot()
	if robot == null:
		return

	var archetype_pool := _get_lab_runtime_archetypes()
	if archetype_pool.is_empty():
		return

	var next_index := _get_next_lab_archetype_index(archetype_pool, robot.archetype_config)
	_apply_lab_runtime_loadout(
		robot,
		archetype_pool[next_index],
		robot.control_mode
	)


func toggle_selected_lab_control_mode() -> void:
	if not lab_runtime_selector_enabled:
		return

	var robot := _get_selected_lab_robot()
	if robot == null:
		return

	var next_mode := RobotBase.ControlMode.HARD
	if robot.control_mode == RobotBase.ControlMode.HARD:
		next_mode = RobotBase.ControlMode.EASY

	_apply_lab_runtime_loadout(robot, robot.archetype_config, next_mode)


func get_lab_selector_summary_line() -> String:
	if not lab_runtime_selector_enabled:
		return ""

	var robot := _get_selected_lab_robot()
	if robot == null:
		return ""

	return "Lab | %s | F2 slot | F3 arquetipo | F4 modo" % _get_lab_robot_brief(robot)


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
	ui.show_round_state(_build_round_state_lines())
	ui.show_roster(match_controller.get_robot_status_lines())
	ui.show_recap(
		match_controller.get_round_recap_panel_title(),
		match_controller.get_round_recap_panel_lines()
	)
	ui.show_match_result(
		match_controller.get_match_result_title(),
		match_controller.get_match_result_lines()
	)


func _connect_match_flow() -> void:
	if match_controller.round_started.is_connected(_on_round_started):
		return

	match_controller.round_started.connect(_on_round_started)


func _configure_edge_pickup_layout_profile() -> void:
	if _arena == null:
		return

	var layout_profile := ArenaBase.EDGE_PICKUP_LAYOUT_PROFILE_FFA if match_controller.match_mode == MatchController.MatchMode.FFA else ArenaBase.EDGE_PICKUP_LAYOUT_PROFILE_TEAMS
	_arena.set_edge_pickup_layout_profile(layout_profile)


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


func _build_hud_toggle_status() -> String:
	return "%s | %s con F1" % [
		_build_startup_status(),
		match_controller.get_hud_detail_mode_label(),
	]


func _build_round_state_lines() -> Array[String]:
	var lines := match_controller.get_round_state_lines()
	var lab_selector_line := get_lab_selector_summary_line()
	if lab_selector_line != "":
		lines.append(lab_selector_line)
	if _arena == null:
		return lines

	var edge_summary := _arena.get_active_edge_pickup_layout_summary()
	if edge_summary != "":
		lines.append("Borde | %s" % edge_summary)

	return lines


func _on_robot_fell_into_void(robot: RobotBase) -> void:
	var message := match_controller.record_robot_elimination(robot, MatchController.EliminationCause.VOID)
	if message != "":
		ui.show_status(message)


func _on_robot_respawned(robot: RobotBase) -> void:
	if match_controller.is_round_reset_pending() or _applying_lab_selector_reset:
		return

	ui.show_status("%s volvio al punto de prueba" % robot.display_name)


func _on_robot_part_destroyed(robot: RobotBase, part_name: String, _detached_part: DetachedPart) -> void:
	ui.show_status("%s perdio %s" % [robot.display_name, RobotBase.get_part_display_name(part_name)])


func _on_robot_part_restored(robot: RobotBase, part_name: String, restored_by: RobotBase) -> void:
	match_controller.record_part_restoration(robot, restored_by)
	if restored_by == robot:
		ui.show_status("%s recupero %s" % [robot.display_name, RobotBase.get_part_display_name(part_name)])
		return

	ui.show_status("%s devolvio %s a %s" % [
		restored_by.display_name,
		RobotBase.get_part_display_name(part_name),
		robot.display_name,
	])


func _on_robot_disabled(robot: RobotBase) -> void:
	if robot.is_disabled_explosion_unstable():
		ui.show_status("%s quedo inutilizado y sobrecargado" % robot.display_name)
		return

	ui.show_status("%s quedo inutilizado" % robot.display_name)


func _on_robot_exploded(robot: RobotBase) -> void:
	var cause := MatchController.EliminationCause.UNSTABLE_EXPLOSION if robot.was_last_disabled_explosion_unstable() else MatchController.EliminationCause.EXPLOSION
	var message := match_controller.record_robot_elimination(robot, cause)
	if message != "":
		ui.show_status(message)


func _on_edge_repair_pickup_collected(robot: RobotBase, repaired_part_name: String) -> void:
	match_controller.record_edge_pickup_collection(robot)
	ui.show_status("%s estabilizo %s en borde" % [
		robot.display_name,
		RobotBase.get_part_display_name(repaired_part_name),
	])


func _on_edge_mobility_pickup_collected(robot: RobotBase, boost_duration: float) -> void:
	match_controller.record_edge_pickup_collection(robot)
	ui.show_status("%s activo impulso de borde (%.1fs)" % [
		robot.display_name,
		boost_duration,
	])


func _on_edge_energy_pickup_collected(robot: RobotBase, surge_duration: float) -> void:
	match_controller.record_edge_pickup_collection(robot)
	ui.show_status("%s recargo energia de borde (%.1fs)" % [
		robot.display_name,
		surge_duration,
	])


func _on_edge_pulse_pickup_collected(robot: RobotBase, item_name: String) -> void:
	match_controller.record_edge_pickup_collection(robot)
	var item_label := robot.get_carried_item_display_name()
	if item_label == "":
		item_label = item_name

	ui.show_status("%s aseguro %s de borde" % [
		robot.display_name,
		item_label,
	])


func _on_round_started(round_number: int) -> void:
	if _arena == null:
		return

	_arena.activate_edge_pickup_layout_for_round(round_number)


func _get_selected_lab_robot() -> RobotBase:
	var robots := _get_scene_robots()
	if robots.is_empty():
		return null

	var selected_index := _get_selected_lab_robot_index(robots)
	_lab_selected_player_slot = robots[selected_index].player_index
	return robots[selected_index]


func _get_selected_lab_robot_index(robots: Array[RobotBase]) -> int:
	for index in range(robots.size()):
		if robots[index].player_index == _lab_selected_player_slot:
			return index

	return 0


func _get_lab_runtime_archetypes() -> Array[RobotArchetypeConfig]:
	var source: Array[RobotArchetypeConfig] = []
	if lab_runtime_archetypes.is_empty():
		for config in DEFAULT_LAB_ARCHETYPES:
			if config is RobotArchetypeConfig:
				source.append(config as RobotArchetypeConfig)
	else:
		source = lab_runtime_archetypes

	var result: Array[RobotArchetypeConfig] = []
	var seen_keys := {}
	for config in source:
		if config == null:
			continue

		var key := config.resource_path
		if key == "":
			key = str(config.get_instance_id())
		if seen_keys.has(key):
			continue

		seen_keys[key] = true
		result.append(config)

	return result


func _get_next_lab_archetype_index(
	archetype_pool: Array[RobotArchetypeConfig],
	current_config: RobotArchetypeConfig
) -> int:
	if archetype_pool.is_empty():
		return 0

	var current_key := ""
	if current_config != null:
		current_key = current_config.resource_path
		if current_key == "":
			current_key = str(current_config.get_instance_id())

	for index in range(archetype_pool.size()):
		var config := archetype_pool[index]
		var config_key := config.resource_path
		if config_key == "":
			config_key = str(config.get_instance_id())
		if config_key == current_key:
			return wrapi(index + 1, 0, archetype_pool.size())

	return 0


func _apply_lab_runtime_loadout(
	robot: RobotBase,
	archetype_config: RobotArchetypeConfig,
	control_mode: RobotBase.ControlMode
) -> void:
	if robot == null:
		return

	_set_lab_slot_control_mode(robot.player_index, control_mode)
	robot.apply_runtime_loadout(archetype_config, control_mode)

	_applying_lab_selector_reset = true
	for scene_robot in _get_scene_robots():
		scene_robot.reset_to_spawn()
		if scene_robot.is_player_controlled:
			scene_robot.refresh_input_setup()
	match_controller.start_match()
	_applying_lab_selector_reset = false

	ui.show_status("Lab: %s" % _get_selected_lab_robot_brief())
	_refresh_hud()


func _set_lab_slot_control_mode(player_slot: int, control_mode: RobotBase.ControlMode) -> void:
	var next_slots := PackedInt32Array()
	for slot in hard_mode_player_slots:
		if slot != player_slot:
			next_slots.append(slot)

	if control_mode == RobotBase.ControlMode.HARD:
		next_slots.append(player_slot)

	hard_mode_player_slots = next_slots


func _get_selected_lab_robot_brief() -> String:
	return _get_lab_robot_brief(_get_selected_lab_robot())


func _get_lab_robot_brief(robot: RobotBase) -> String:
	if robot == null:
		return "sin slot"

	var archetype_label := robot.get_archetype_label()
	if archetype_label == "":
		archetype_label = "Base"
	var mode_label := "Hard" if robot.control_mode == RobotBase.ControlMode.HARD else "Easy"
	return "P%s %s %s" % [robot.player_index, archetype_label, mode_label]
