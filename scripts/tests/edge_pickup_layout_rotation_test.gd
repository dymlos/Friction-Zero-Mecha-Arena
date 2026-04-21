extends SceneTree

const ARENA_SCENE := preload("res://scenes/arenas/arena_blockout.tscn")
const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")
const ArenaBase = preload("res://scripts/arenas/arena_base.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_arena_rotates_mirrored_pickup_layouts()
	await _validate_main_scene_advances_pickup_layout_between_rounds()
	await _validate_ffa_scene_uses_denser_edge_pickup_rotation()
	_finish()


func _validate_arena_rotates_mirrored_pickup_layouts() -> void:
	var arena := ARENA_SCENE.instantiate()
	root.add_child(arena)

	await process_frame
	await process_frame

	_assert(arena is ArenaBase, "La escena de arena deberia seguir exponiendo ArenaBase.")
	if not (arena is ArenaBase):
		await _cleanup_node(arena)
		return

	var arena_base := arena as ArenaBase
	var edge_pickups := _get_edge_pickups(arena)
	_assert(edge_pickups.size() >= 8, "La arena blockout deberia seguir teniendo los ocho pedestales de borde como base.")
	_assert(
		arena_base.has_method("activate_edge_pickup_layout_for_round"),
		"La arena deberia poder activar layouts de pickups por ronda para variar el borde sin perder control."
	)
	for pickup in edge_pickups:
		_assert(
			pickup.has_method("is_spawn_enabled"),
			"Cada pickup de borde deberia poder informar si su pedestal esta habilitado en el layout actual."
		)

	if not arena_base.has_method("activate_edge_pickup_layout_for_round"):
		await _cleanup_node(arena)
		return

	var layout_signatures: Array[String] = []
	for round_number in range(1, 5):
		arena_base.call("activate_edge_pickup_layout_for_round", round_number)
		await process_frame

		var active_pickups := _get_spawn_enabled_pickups(edge_pickups)
		_assert(
			active_pickups.size() == 4,
			"Cada ronda deberia dejar solo dos pares de pickups activos para mantener el borde legible."
		)

		var active_type_counts := _count_pickups_by_type(active_pickups)
		_assert(
			active_type_counts.size() == 2,
			"Cada layout deberia activar exactamente dos tipos de pickup: uno por cada par espejado."
		)
		for pickup_count in active_type_counts.values():
			_assert(
				int(pickup_count) == 2,
				"Cada tipo activo deberia aparecer como par espejado para conservar justicia espacial."
			)

		layout_signatures.append(_build_layout_signature(active_type_counts))

	_assert(
		layout_signatures.size() >= 2 and layout_signatures[0] != layout_signatures[1],
		"El layout del borde deberia cambiar entre rondas consecutivas, no quedar fijo para todo el match."
	)
	_assert(
		_count_unique_strings(layout_signatures) == 4,
		"Las primeras cuatro rondas deberian recorrer los cuatro cruces base de pickups de borde sin repetir de inmediato."
	)

	await _cleanup_node(arena)


func _validate_main_scene_advances_pickup_layout_between_rounds() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var arena := main.get_node_or_null("ArenaRoot/ArenaBlockout")
	var match_controller := main.get_node_or_null("Systems/MatchController")
	var robots := _get_scene_robots(main)
	_assert(arena is ArenaBase, "La escena principal deberia seguir montando una arena real para probar el layout.")
	_assert(match_controller is MatchController, "La escena principal deberia seguir exponiendo MatchController.")
	_assert(robots.size() >= 4, "La escena principal deberia seguir montando cuatro robots para el laboratorio 2v2.")
	if not (arena is ArenaBase) or not (match_controller is MatchController) or robots.size() < 4:
		await _cleanup_node(main)
		return

	var controller := match_controller as MatchController
	controller.round_reset_delay = 0.01

	var initial_signature := _get_active_layout_signature(main)
	_assert(
		initial_signature != "",
		"La ronda inicial deberia arrancar con un layout activo de pickups, no con todos los bordes apagados."
	)
	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel")
	_assert(round_label is Label, "La escena principal deberia seguir exponiendo el bloque de estado de ronda en HUD.")
	if round_label is Label:
		_assert(
			String((round_label as Label).text).contains("Borde |"),
			"El HUD compacto deberia resumir que tipos de pickups de borde estan activos en la ronda actual."
		)

	main.call("_on_robot_fell_into_void", robots[2])
	await process_frame
	main.call("_on_robot_fell_into_void", robots[3])
	await _wait_frames(10)

	var next_signature := _get_active_layout_signature(main)
	_assert(
		next_signature != "",
		"Tras el reset de ronda, la escena principal deberia volver a activar un layout valido de pickups."
	)
	_assert(
		initial_signature != next_signature,
		"La escena principal deberia avanzar la rotacion de pickups al comenzar una ronda nueva."
	)

	await _cleanup_node(main)


func _validate_ffa_scene_uses_denser_edge_pickup_rotation() -> void:
	var main := FFA_SCENE.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame

	var arena := main.get_node_or_null("ArenaRoot/ArenaBlockout")
	var match_controller := main.get_node_or_null("Systems/MatchController")
	var robots := _get_scene_robots(main)
	_assert(arena is ArenaBase, "La escena FFA deberia seguir montando una arena real para probar el layout.")
	_assert(match_controller is MatchController, "La escena FFA deberia seguir exponiendo MatchController.")
	_assert(robots.size() >= 4, "La escena FFA deberia seguir ofreciendo cuatro robots para validar la rotacion FFA.")
	if not (arena is ArenaBase) or not (match_controller is MatchController) or robots.size() < 4:
		await _cleanup_node(main)
		return

	var controller := match_controller as MatchController
	controller.round_reset_delay = 0.01

	var initial_pickups := _get_spawn_enabled_pickups(_get_edge_pickups(main))
	var initial_counts := _count_pickups_by_type(initial_pickups)
	_assert(
		initial_pickups.size() == 6,
		"FFA deberia activar tres pares de pickups por ronda para sostener mas oportunismo sin volver al borde completo."
	)
	_assert(
		initial_counts.size() == 3,
		"FFA deberia exponer tres tipos de pickup por ronda para que el borde tenga mas decisiones activas."
	)
	_assert(
		initial_counts.has("pulse"),
		"FFA deberia priorizar que pulso aparezca en la mayoria de las rondas para medir mejor la tension parte vs pulso."
	)
	for pickup_count in initial_counts.values():
		_assert(
			int(pickup_count) == 2,
			"Cada tipo activo en FFA deberia seguir apareciendo como par espejado."
		)

	var round_label := main.get_node_or_null("UI/MatchHud/Root/RoundLabel")
	_assert(round_label is Label, "La escena FFA deberia seguir exponiendo el bloque de estado de ronda en HUD.")
	if round_label is Label:
		var round_text := String((round_label as Label).text)
		_assert(
			round_text.contains("Borde |"),
			"El HUD compacto deberia resumir tambien en FFA los tipos activos de pickup por ronda."
		)
		_assert(
			round_text.contains("pulso"),
			"El resumen del borde en FFA deberia dejar visible cuando pulso forma parte de la ronda actual."
		)

	main.call("_on_robot_fell_into_void", robots[1])
	await process_frame
	main.call("_on_robot_fell_into_void", robots[2])
	await process_frame
	main.call("_on_robot_fell_into_void", robots[3])
	await _wait_frames(10)

	var next_signature := _get_active_layout_signature(main)
	_assert(
		next_signature != "",
		"Tras el reset de ronda, FFA deberia volver a activar un layout valido de pickups."
	)
	_assert(
		next_signature != _build_layout_signature(initial_counts),
		"FFA deberia rotar el layout entre rondas en lugar de repetir siempre el mismo trio."
	)

	await _cleanup_node(main)


func _get_edge_pickups(root_node: Node) -> Array[Node]:
	var pickups: Array[Node] = []
	for node in root_node.get_tree().get_nodes_in_group("edge_pickups"):
		if not root_node.is_ancestor_of(node):
			continue

		pickups.append(node)

	return pickups


func _get_spawn_enabled_pickups(pickups: Array[Node]) -> Array[Node]:
	var enabled_pickups: Array[Node] = []
	for pickup in pickups:
		if pickup.has_method("is_spawn_enabled") and bool(pickup.call("is_spawn_enabled")):
			enabled_pickups.append(pickup)

	return enabled_pickups


func _count_pickups_by_type(pickups: Array[Node]) -> Dictionary:
	var counts := {}
	for pickup in pickups:
		var pickup_type := _get_pickup_type_label(pickup)
		counts[pickup_type] = int(counts.get(pickup_type, 0)) + 1

	return counts


func _get_pickup_type_label(pickup: Node) -> String:
	if pickup.is_in_group("edge_repair_pickups"):
		return "repair"
	if pickup.is_in_group("edge_mobility_pickups"):
		return "mobility"
	if pickup.is_in_group("edge_energy_pickups"):
		return "energy"
	if pickup.is_in_group("edge_pulse_pickups"):
		return "pulse"
	if pickup.is_in_group("edge_charge_pickups"):
		return "charge"
	if pickup.is_in_group("edge_utility_pickups"):
		return "utility"

	return "unknown"


func _build_layout_signature(active_type_counts: Dictionary) -> String:
	var parts: PackedStringArray = []
	var keys := active_type_counts.keys()
	keys.sort()
	for key in keys:
		parts.append("%s:%s" % [key, active_type_counts[key]])

	return "|".join(parts)


func _count_unique_strings(values: Array[String]) -> int:
	var unique := {}
	for value in values:
		unique[value] = true

	return unique.size()


func _get_active_layout_signature(root_node: Node) -> String:
	var pickups := _get_edge_pickups(root_node)
	var enabled_pickups := _get_spawn_enabled_pickups(pickups)
	return _build_layout_signature(_count_pickups_by_type(enabled_pickups))


func _get_scene_robots(main: Node) -> Array[RobotBase]:
	var robots: Array[RobotBase] = []
	var robot_root := main.get_node("RobotRoot")
	for child in robot_root.get_children():
		if child is RobotBase:
			robots.append(child as RobotBase)

	return robots


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _cleanup_node(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	await process_frame


func _wait_frames(frame_count: int) -> void:
	for _frame in range(maxi(frame_count, 1)):
		await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
