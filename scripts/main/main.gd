extends Node3D
class_name Main

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchHud = preload("res://scripts/ui/match_hud.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RobotArchetypeConfig = preload("res://scripts/robots/robot_archetype_config.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const PilotSupportShip = preload("res://scripts/support/pilot_support_ship.gd")
const PilotSupportPickup = preload("res://scripts/support/pilot_support_pickup.gd")
const SupportLaneGate = preload("res://scripts/support/support_lane_gate.gd")
const EdgeRepairPickup = preload("res://scripts/pickups/edge_repair_pickup.gd")
const EdgeMobilityPickup = preload("res://scripts/pickups/edge_mobility_pickup.gd")
const EdgeEnergyPickup = preload("res://scripts/pickups/edge_energy_pickup.gd")
const EdgePulsePickup = preload("res://scripts/pickups/edge_pulse_pickup.gd")
const EdgeChargePickup = preload("res://scripts/pickups/edge_charge_pickup.gd")
const EdgeUtilityPickup = preload("res://scripts/pickups/edge_utility_pickup.gd")
const PILOT_SUPPORT_SHIP_SCENE = preload("res://scenes/support/pilot_support_ship.tscn")
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
const LAB_SCENE_CYCLE_KEY := KEY_F6
const LAB_PLAYER_SLOT_KEY_MIN := KEY_1
const LAB_PLAYER_SLOT_KEY_MAX := KEY_8
const DEFAULT_LAB_ARCHETYPES := [
	ARIETE_ARCHETYPE,
	GRUA_ARCHETYPE,
	CIZALLA_ARCHETYPE,
	PATIN_ARCHETYPE,
	AGUJA_ARCHETYPE,
	ANCLA_ARCHETYPE,
]
const LAB_SCENE_VARIANTS := [
	{
		"path": "res://scenes/main/main.tscn",
		"label": "Equipos base",
	},
	{
		"path": "res://scenes/main/main_teams_validation.tscn",
		"label": "Equipos rapido",
	},
	{
		"path": "res://scenes/main/main_ffa.tscn",
		"label": "FFA base",
	},
	{
		"path": "res://scenes/main/main_ffa_validation.tscn",
		"label": "FFA rapido",
	},
]

@export var hard_mode_player_slots: PackedInt32Array = PackedInt32Array()
@export var lab_runtime_selector_enabled := true
@export var lab_runtime_archetypes: Array[RobotArchetypeConfig] = []
@export_range(8, 64, 1) var detached_part_cleanup_limit := 20
@export_group("FFA Bootstrap")
@export_range(2.5, 12.0, 0.1) var ffa_spawn_radius := 5.6
@export_range(0.0, 180.0, 1.0) var ffa_spawn_angle_offset_degrees := 45.0

@onready var arena_root: Node3D = $ArenaRoot
@onready var robot_root: Node3D = $RobotRoot
@onready var support_root: Node3D = $SupportRoot
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
	_sync_round_intro_locks()
	_apply_match_pressure_to_arena()
	_cleanup_detached_parts()
	_sync_lab_selector_visuals()
	_report_startup_structure()
	ui.show_status(_build_hud_toggle_status())
	_refresh_hud()


func _process(_delta: float) -> void:
	_apply_match_pressure_to_arena()
	_sync_round_intro_locks()
	_sync_post_death_support_state()
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
	if key_event.keycode == LAB_SCENE_CYCLE_KEY:
		cycle_lab_scene_variant()
		get_viewport().set_input_as_handled()
		return
	var player_slot := _get_player_slot_from_lab_key(key_event.keycode)
	if player_slot > 0:
		toggle_lab_control_mode_for_player_slot(player_slot)
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
	_sync_lab_selector_visuals()
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


func toggle_lab_control_mode_for_player_slot(player_slot: int) -> void:
	if not lab_runtime_selector_enabled or player_slot <= 0:
		return

	var robot := _get_scene_robot_by_player_slot(player_slot)
	if robot == null:
		return

	_lab_selected_player_slot = robot.player_index
	var next_mode := RobotBase.ControlMode.HARD
	if robot.control_mode == RobotBase.ControlMode.HARD:
		next_mode = RobotBase.ControlMode.EASY

	_apply_lab_runtime_loadout(
		robot,
		robot.archetype_config,
		next_mode
	)


func get_lab_selector_summary_line() -> String:
	if not lab_runtime_selector_enabled:
		return ""

	var robot := _get_selected_lab_robot()
	if robot == null:
		return ""

	return "Lab | %s | 1-8 modo | F2 slot | F3 arquetipo | F4 modo" % _get_lab_robot_brief(robot)


func get_lab_scene_variant_summary_line() -> String:
	var scene_variant := _get_current_lab_scene_variant()
	return "Escena | %s | F6 cambia" % String(scene_variant.get("label", "laboratorio"))


func cycle_lab_scene_variant() -> void:
	var current_index := _get_current_lab_scene_variant_index()
	var next_index := wrapi(current_index + 1, 0, LAB_SCENE_VARIANTS.size())
	var next_scene_path := String(LAB_SCENE_VARIANTS[next_index].get("path", ""))
	if next_scene_path == "":
		return

	get_tree().change_scene_to_file(next_scene_path)


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
	var spawn_transforms := _get_bootstrap_spawn_transforms(robots.size())
	var local_player_count: int = min(match_controller.get_local_player_count(), robots.size())

	for index in range(robots.size()):
		var robot: RobotBase = robots[index]
		robot.player_index = index + 1
		robot.is_player_controlled = index < local_player_count
		robot.control_mode = _resolve_control_mode_for_slot(robot.player_index)
		_assign_default_local_inputs(robot, index)
		if index < spawn_transforms.size():
			var spawn_transform := spawn_transforms[index]
			robot.global_position = spawn_transform.origin
			robot.global_basis = spawn_transform.basis
		robot.capture_spawn_transform()
		if robot.is_player_controlled:
			robot.refresh_input_setup()
		robot.set_round_intro_locked(false)


func _sync_round_intro_locks() -> void:
	var intro_locked := match_controller != null and match_controller.is_round_intro_active()
	for robot in _get_scene_robots():
		robot.set_round_intro_locked(intro_locked)


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


func _get_bootstrap_spawn_transforms(robot_count: int) -> Array[Transform3D]:
	if match_controller != null and match_controller.match_mode == MatchController.MatchMode.FFA:
		return _build_ffa_spawn_transforms(robot_count)

	var spawn_transforms: Array[Transform3D] = []
	for spawn_point in _get_arena_spawn_points():
		spawn_transforms.append(spawn_point.global_transform)

	return spawn_transforms


func _build_ffa_spawn_transforms(robot_count: int) -> Array[Transform3D]:
	var spawn_transforms: Array[Transform3D] = []
	if robot_count <= 0:
		return spawn_transforms

	var spawn_height := _get_default_spawn_height()
	var angle_offset_radians := deg_to_rad(ffa_spawn_angle_offset_degrees)
	for index in range(robot_count):
		var angle := angle_offset_radians + (TAU * float(index) / float(robot_count))
		var planar_position := Vector2(cos(angle), sin(angle)) * ffa_spawn_radius
		var spawn_position := Vector3(planar_position.x, spawn_height, planar_position.y)
		var facing_direction := Vector3(-planar_position.x, 0.0, -planar_position.y).normalized()
		var spawn_basis := Basis.IDENTITY
		if facing_direction.length_squared() > 0.0001:
			spawn_basis = Basis.looking_at(facing_direction, Vector3.UP)
		spawn_transforms.append(Transform3D(spawn_basis, spawn_position))

	return spawn_transforms


func _get_default_spawn_height() -> float:
	var spawn_points := _get_arena_spawn_points()
	if not spawn_points.is_empty():
		return spawn_points[0].global_position.y

	return 0.8


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
	_arena.set_pressure_warning_strength(match_controller.get_space_reduction_warning_strength())


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
	_arena.set_edge_pickup_allowed_ids(_build_allowed_edge_pickup_ids())


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

	for node in get_tree().get_nodes_in_group("edge_charge_pickups"):
		if not (node is EdgeChargePickup):
			continue

		var charge_pickup := node as EdgeChargePickup
		if charge_pickup.pickup_collected.is_connected(_on_edge_charge_pickup_collected):
			continue

		charge_pickup.pickup_collected.connect(_on_edge_charge_pickup_collected)

	for node in get_tree().get_nodes_in_group("edge_utility_pickups"):
		if not (node is EdgeUtilityPickup):
			continue

		var utility_pickup := node as EdgeUtilityPickup
		if utility_pickup.pickup_collected.is_connected(_on_edge_utility_pickup_collected):
			continue

		utility_pickup.pickup_collected.connect(_on_edge_utility_pickup_collected)


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


func _get_current_lab_scene_variant() -> Dictionary:
	return LAB_SCENE_VARIANTS[_get_current_lab_scene_variant_index()]


func _get_current_lab_scene_variant_index() -> int:
	var current_scene_path := String(scene_file_path)
	for index in range(LAB_SCENE_VARIANTS.size()):
		var variant: Dictionary = LAB_SCENE_VARIANTS[index]
		if String(variant.get("path", "")) == current_scene_path:
			return index

	return 0


func _build_hud_toggle_status() -> String:
	return "%s | %s con F1" % [
		_build_startup_status(),
		match_controller.get_hud_detail_mode_label(),
	]


func _build_round_state_lines() -> Array[String]:
	var lines := match_controller.get_round_state_lines()
	lines.append(get_lab_scene_variant_summary_line())
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
	var message := match_controller.record_robot_elimination(
		robot,
		MatchController.EliminationCause.VOID,
		robot.get_recent_elimination_source()
	)
	if message != "":
		ui.show_status(message)
	_spawn_post_death_support_if_needed(robot)


func _on_robot_respawned(robot: RobotBase) -> void:
	if match_controller.is_round_reset_pending() or _applying_lab_selector_reset:
		return

	ui.show_status("%s volvio al punto de prueba" % robot.display_name)


func _on_robot_part_destroyed(robot: RobotBase, part_name: String, _detached_part: DetachedPart) -> void:
	if _detached_part != null and not _detached_part.recovery_lost.is_connected(_on_detached_part_recovery_lost):
		_detached_part.recovery_lost.connect(_on_detached_part_recovery_lost)
	match_controller.record_part_loss(robot, part_name)
	ui.show_status("%s perdio %s" % [robot.display_name, RobotBase.get_part_display_name(part_name)])
	_cleanup_detached_parts()


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


func _on_detached_part_recovery_lost(detached_part: DetachedPart, reason: String) -> void:
	if detached_part == null or reason != "void":
		return

	var original_robot := detached_part.get_original_robot() as RobotBase
	var denied_by := detached_part.get_last_recovery_loss_source() as RobotBase
	if original_robot == null or denied_by == null:
		return
	if denied_by.is_ally_of(original_robot):
		return

	match_controller.record_part_denial(original_robot, denied_by)
	ui.show_status("%s nego %s de %s" % [
		denied_by.display_name,
		RobotBase.get_part_display_name(detached_part.part_name),
		original_robot.display_name,
	])


func _on_robot_disabled(robot: RobotBase) -> void:
	if robot.is_disabled_explosion_unstable():
		ui.show_status("%s quedo inutilizado y sobrecargado" % robot.display_name)
		return

	ui.show_status("%s quedo inutilizado" % robot.display_name)


func _on_robot_exploded(robot: RobotBase) -> void:
	var cause := MatchController.EliminationCause.UNSTABLE_EXPLOSION if robot.was_last_disabled_explosion_unstable() else MatchController.EliminationCause.EXPLOSION
	var message := match_controller.record_robot_elimination(
		robot,
		cause,
		robot.get_recent_elimination_source()
	)
	if message != "":
		ui.show_status(message)
	_spawn_post_death_support_if_needed(robot)


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


func _on_edge_charge_pickup_collected(robot: RobotBase, restored_charges: int) -> void:
	match_controller.record_edge_pickup_collection(robot)
	var skill_label := robot.get_core_skill_label()
	if skill_label == "":
		skill_label = "skill"

	ui.show_status("%s recargo municion de %s (+%s)" % [
		robot.display_name,
		skill_label,
		restored_charges,
	])


func _on_edge_utility_pickup_collected(robot: RobotBase, stability_duration: float) -> void:
	match_controller.record_edge_pickup_collection(robot)
	ui.show_status("%s activo estabilidad de borde (%.1fs)" % [
		robot.display_name,
		stability_duration,
	])


func _on_round_started(round_number: int) -> void:
	_clear_post_death_support()
	_cleanup_detached_parts()
	if _arena == null:
		return

	_arena.activate_edge_pickup_layout_for_round(round_number)


func _cleanup_detached_parts() -> void:
	if detached_part_cleanup_limit <= 0 or get_tree() == null:
		return

	var active_parts: Array[DetachedPart] = []
	for node in get_tree().get_nodes_in_group("detached_parts"):
		if not (node is DetachedPart):
			continue

		var detached_part := node as DetachedPart
		if not is_instance_valid(detached_part) or detached_part.is_carried():
			continue

		active_parts.append(detached_part)

	active_parts.sort_custom(func(a: DetachedPart, b: DetachedPart) -> bool:
		return a.get_cleanup_time_left() < b.get_cleanup_time_left()
	)

	var excess_count := active_parts.size() - detached_part_cleanup_limit
	if excess_count <= 0:
		return

	for i in range(excess_count):
		var stale_part := active_parts[i]
		if not is_instance_valid(stale_part):
			continue

		stale_part.queue_free()


func _spawn_post_death_support_if_needed(robot: RobotBase) -> void:
	if robot == null:
		return
	if support_root == null:
		return
	if match_controller.match_mode != MatchController.MatchMode.TEAMS:
		return
	if _find_post_death_support_ship(robot) != null:
		return

	var allied_robot := _find_living_support_target(robot)
	if allied_robot == null:
		return

	var scene_instance := PILOT_SUPPORT_SHIP_SCENE.instantiate()
	if not (scene_instance is PilotSupportShip):
		return

	var support_ship := scene_instance as PilotSupportShip
	support_root.add_child(support_ship)
	var spawn_position := robot.global_position
	if _arena != null:
		spawn_position = _arena.get_support_lane_spawn_position_near(robot.global_position)
	support_ship.configure(robot, allied_robot, spawn_position, _arena)
	if not support_ship.state_changed.is_connected(_on_post_death_support_state_changed):
		support_ship.state_changed.connect(_on_post_death_support_state_changed)
	if not support_ship.payload_collected.is_connected(_on_post_death_support_payload_collected):
		support_ship.payload_collected.connect(_on_post_death_support_payload_collected)
	if not support_ship.payload_used.is_connected(_on_post_death_support_payload_used):
		support_ship.payload_used.connect(_on_post_death_support_payload_used)
	match_controller.set_robot_support_state(robot, support_ship.get_status_summary())


func _find_living_support_target(robot: RobotBase) -> RobotBase:
	for other_robot in match_controller.get_alive_robots():
		if other_robot == robot:
			continue
		if not robot.is_ally_of(other_robot):
			continue

		return other_robot

	return null


func _find_post_death_support_ship(robot: RobotBase) -> PilotSupportShip:
	if support_root == null or robot == null:
		return null

	for child in support_root.get_children():
		if not (child is PilotSupportShip):
			continue

		var support_ship := child as PilotSupportShip
		if support_ship.belongs_to_owner(robot):
			return support_ship

	return null


func _clear_post_death_support() -> void:
	if support_root != null:
		for child in support_root.get_children():
			child.queue_free()
		_set_post_death_support_lane_active(false, true)

	for robot in match_controller.registered_robots:
		if not is_instance_valid(robot):
			continue

		match_controller.clear_robot_support_state(robot)


func _sync_post_death_support_state() -> void:
	_prune_post_death_support_ships()
	var support_enabled := match_controller.match_mode == MatchController.MatchMode.TEAMS and support_root != null and support_root.get_child_count() > 0
	for robot in match_controller.registered_robots:
		if not is_instance_valid(robot):
			continue

		match_controller.clear_robot_support_state(robot)

	if support_enabled:
		for child in support_root.get_children():
			if not (child is PilotSupportShip):
				continue

			var support_ship := child as PilotSupportShip
			if not is_instance_valid(support_ship.owner_robot):
				continue

			match_controller.set_robot_support_state(
				support_ship.owner_robot,
				support_ship.get_status_summary()
			)

	_set_post_death_support_lane_active(support_enabled)


func _prune_post_death_support_ships() -> void:
	if support_root == null:
		return

	for child in support_root.get_children():
		if not (child is PilotSupportShip):
			continue

		var support_ship := child as PilotSupportShip
		var owner_robot := support_ship.owner_robot
		var should_remove := not is_instance_valid(owner_robot)
		if not should_remove:
			should_remove = not owner_robot.is_held_for_round_reset()
		if not should_remove:
			should_remove = _find_living_support_target(owner_robot) == null
		if not should_remove:
			continue

		if is_instance_valid(owner_robot):
			match_controller.clear_robot_support_state(owner_robot)
		support_root.remove_child(support_ship)
		support_ship.queue_free()


func _set_post_death_support_lane_active(is_active: bool, reset_pickups: bool = false) -> void:
	for node in get_tree().get_nodes_in_group("pilot_support_pickups"):
		if not (node is PilotSupportPickup):
			continue

		var support_pickup := node as PilotSupportPickup
		support_pickup.set_support_active(is_active)
		if reset_pickups:
			support_pickup.reset_pickup()
	for node in get_tree().get_nodes_in_group("support_lane_gates"):
		if not (node is SupportLaneGate):
			continue

		var support_gate := node as SupportLaneGate
		support_gate.set_support_active(is_active)
		if reset_pickups:
			support_gate.reset_gate()


func _on_post_death_support_state_changed(support_ship: PilotSupportShip) -> void:
	if support_ship == null or not is_instance_valid(support_ship.owner_robot):
		return

	match_controller.set_robot_support_state(
		support_ship.owner_robot,
		support_ship.get_status_summary()
	)
	_refresh_hud()


func _on_post_death_support_payload_collected(support_ship: PilotSupportShip, payload_name: String) -> void:
	if support_ship == null or not is_instance_valid(support_ship.owner_robot):
		return

	match_controller.record_support_pickup_collection(support_ship.owner_robot, payload_name)


func _on_post_death_support_payload_used(
	support_ship: PilotSupportShip,
	payload_name: String,
	target_robot: RobotBase
) -> void:
	if support_ship == null or not is_instance_valid(support_ship.owner_robot):
		return

	match_controller.record_support_payload_use(support_ship.owner_robot, payload_name, target_robot)


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
	_configure_edge_pickup_layout_profile()

	_applying_lab_selector_reset = true
	for scene_robot in _get_scene_robots():
		scene_robot.reset_to_spawn()
		if scene_robot.is_player_controlled:
			scene_robot.refresh_input_setup()
	match_controller.start_match()
	_applying_lab_selector_reset = false

	_sync_lab_selector_visuals()
	ui.show_status("Lab: %s" % _get_selected_lab_robot_brief())
	_refresh_hud()


func _get_scene_robot_by_player_slot(player_slot: int) -> RobotBase:
	for robot in _get_scene_robots():
		if robot.player_index == player_slot:
			return robot

	return null


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


func _get_player_slot_from_lab_key(keycode: int) -> int:
	if keycode < LAB_PLAYER_SLOT_KEY_MIN or keycode > LAB_PLAYER_SLOT_KEY_MAX:
		return 0

	return keycode - LAB_PLAYER_SLOT_KEY_MIN + 1


func _sync_lab_selector_visuals() -> void:
	var robots := _get_scene_robots()
	if robots.is_empty():
		return

	var selected_robot := _get_selected_lab_robot()
	for robot in robots:
		robot.set_lab_selected(lab_runtime_selector_enabled and robot == selected_robot)


func _build_allowed_edge_pickup_ids() -> PackedStringArray:
	var allowed_ids := PackedStringArray(ArenaBase.DEFAULT_EDGE_PICKUP_ALLOWED_IDS)
	if _should_enable_charge_pickups():
		allowed_ids.append("charge")

	return allowed_ids


func _should_enable_charge_pickups() -> bool:
	var robots := _get_scene_robots()
	if robots.is_empty():
		return false

	if match_controller.match_mode == MatchController.MatchMode.FFA:
		var skill_robot_count := 0
		for robot in robots:
			if robot.has_core_skill():
				skill_robot_count += 1

		return skill_robot_count >= 2

	var teams_present := {}
	var teams_with_skills := {}
	for robot in robots:
		var team_id := robot.get_team_identity()
		teams_present[team_id] = true
		if robot.has_core_skill():
			teams_with_skills[team_id] = true

	return teams_present.size() >= 2 and teams_present.size() == teams_with_skills.size()
