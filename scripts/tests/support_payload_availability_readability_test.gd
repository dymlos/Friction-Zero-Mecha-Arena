extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const MatchController = preload("res://scripts/systems/match_controller.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const PilotSupportShip = preload("res://scripts/support/pilot_support_ship.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_stabilizer_warns_when_target_has_no_damage()
	await _verify_surge_warns_when_target_already_has_full_boost_window()
	await _verify_mobility_warns_when_target_already_has_full_boost_window()
	await _verify_interference_warns_when_target_has_stability()
	await _verify_interference_target_markers_dim_when_target_has_stability()
	_finish()


func _verify_stabilizer_warns_when_target_has_no_damage() -> void:
	var main = MAIN_SCENE.instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null and match_controller_preload.match_config != null:
		match_controller_preload.match_config.round_intro_duration_teams = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel") as Label
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(roster_label != null, "El HUD deberia seguir exponiendo el roster compacto.")
	_assert(support_root != null, "La escena Teams deberia seguir exponiendo SupportRoot.")
	_assert(robots.size() >= 4, "La escena Teams deberia seguir ofreciendo cuatro robots.")
	if roster_label == null or support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	robots[1].fall_into_void()
	await _wait_frames(4)

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar la disponibilidad del payload.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var stabilizer_pickup := _find_support_pickup("stabilizer")
	_assert(stabilizer_pickup != null, "El carril deberia seguir ofreciendo un pickup `stabilizer`.")
	if stabilizer_pickup == null:
		await _cleanup_main(main)
		return

	support_ship.global_position = stabilizer_pickup.global_position
	await _wait_support_spawn_grace(support_ship)

	_assert(
		roster_label.text.contains("estabilizador"),
		"El roster deberia seguir mostrando cuando la nave lleva una carga `stabilizer`."
	)
	_assert(
		roster_label.text.contains("sin daño"),
		"Si el aliado objetivo esta sano, el roster deberia explicar que `stabilizer` aun no tiene efecto util."
	)

	robots[0].apply_damage_to_part("left_arm", robots[0].max_part_health * 0.3, Vector3.LEFT)
	await _wait_frames(2)

	_assert(
		not roster_label.text.contains("sin daño"),
		"Cuando el aliado vuelve a tener una parte dañada, la advertencia de `stabilizer` deberia limpiarse sola."
	)

	await _cleanup_main(main)


func _verify_surge_warns_when_target_already_has_full_boost_window() -> void:
	var main := await _instantiate_main_scene()
	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel") as Label
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(roster_label != null, "El HUD deberia seguir exponiendo el roster compacto.")
	_assert(support_root != null, "La escena Teams deberia seguir exponiendo SupportRoot.")
	_assert(robots.size() >= 4, "La escena Teams deberia seguir ofreciendo cuatro robots.")
	if roster_label == null or support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	robots[1].fall_into_void()
	await _wait_frames(4)

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar la disponibilidad de `surge`.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var surge_pickup := _find_support_pickup("surge")
	_assert(surge_pickup != null, "El carril deberia seguir ofreciendo un pickup `surge`.")
	if surge_pickup == null:
		await _cleanup_main(main)
		return

	var surge_duration := float(support_ship.get("support_energy_surge_duration")) + 1.0
	robots[0].apply_energy_surge(surge_duration)
	robots[2].apply_energy_surge(surge_duration)
	support_ship.global_position = surge_pickup.global_position
	await _wait_support_spawn_grace(support_ship)

	_assert(
		roster_label.text.contains("energia"),
		"El roster deberia seguir mostrando cuando la nave lleva una carga `surge`."
	)
	_assert(
		roster_label.text.contains("ya activo"),
		"Si el aliado objetivo ya tiene toda la ventana util de `surge`, el roster deberia explicitar que ese payload seria redundante."
	)

	robots[2].apply_damage_to_part("left_arm", robots[2].max_part_health * 0.15, Vector3.LEFT)
	await create_timer(1.0).timeout
	await _wait_frames(2)

	_assert(
		not roster_label.text.contains("ya activo"),
		"Cuando la ventana activa de `surge` baja por debajo de la duracion que aporta la nave, la advertencia de redundancia deberia limpiarse sola."
	)

	await _cleanup_main(main)


func _verify_mobility_warns_when_target_already_has_full_boost_window() -> void:
	var main := await _instantiate_main_scene()
	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel") as Label
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(roster_label != null, "El HUD deberia seguir exponiendo el roster compacto.")
	_assert(support_root != null, "La escena Teams deberia seguir exponiendo SupportRoot.")
	_assert(robots.size() >= 4, "La escena Teams deberia seguir ofreciendo cuatro robots.")
	if roster_label == null or support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	robots[1].fall_into_void()
	await _wait_frames(4)

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar la disponibilidad de `movilidad`.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var mobility_pickup := _find_support_pickup("mobility")
	_assert(mobility_pickup != null, "El carril deberia seguir ofreciendo un pickup `mobility`.")
	if mobility_pickup == null:
		await _cleanup_main(main)
		return

	var mobility_duration := float(support_ship.get("support_mobility_boost_duration")) + 1.0
	robots[0].apply_mobility_boost(mobility_duration)
	robots[2].apply_mobility_boost(mobility_duration)
	support_ship.global_position = mobility_pickup.global_position
	await _wait_support_spawn_grace(support_ship)

	_assert(
		roster_label.text.contains("movilidad"),
		"El roster deberia seguir mostrando cuando la nave lleva una carga `mobility`."
	)
	_assert(
		roster_label.text.contains("ya activo"),
		"Si el aliado objetivo ya tiene toda la ventana util de `movilidad`, el roster deberia explicitar que ese payload seria redundante."
	)

	robots[2].apply_damage_to_part("left_leg", robots[2].max_part_health * 0.2, Vector3.LEFT)
	await create_timer(1.0).timeout
	await _wait_frames(2)

	_assert(
		not roster_label.text.contains("ya activo"),
		"Cuando la ventana activa de `movilidad` baja por debajo de lo que aportaria la nave, la advertencia de redundancia deberia limpiarse sola."
	)

	await _cleanup_main(main)


func _verify_interference_warns_when_target_has_stability() -> void:
	var main := await _instantiate_main_scene()
	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel") as Label
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(roster_label != null, "El HUD deberia seguir exponiendo el roster compacto.")
	_assert(support_root != null, "La escena Teams deberia seguir exponiendo SupportRoot.")
	_assert(robots.size() >= 4, "La escena Teams deberia seguir ofreciendo cuatro robots.")
	if roster_label == null or support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	robots[1].fall_into_void()
	await _wait_frames(4)

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar inmunidad utility.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var interference_pickup := _find_support_pickup("interference")
	_assert(interference_pickup != null, "El carril deberia seguir ofreciendo un pickup `interference`.")
	if interference_pickup == null:
		await _cleanup_main(main)
		return

	var stable_enemy := robots[2]
	var fresh_enemy := robots[3]
	var ship_position := Vector3(0.0, support_ship.global_position.y, 0.0)
	support_ship.global_position = ship_position
	stable_enemy.global_position = ship_position + Vector3(0.0, 0.0, 1.0)
	fresh_enemy.global_position = ship_position + Vector3(0.0, 0.0, 1.9)
	stable_enemy.apply_stability_boost(1.5)
	support_ship.global_position = interference_pickup.global_position
	await _wait_support_spawn_grace(support_ship)
	await _wait_frames(2)

	Input.action_press("p2_energy_next")
	await _wait_frames(2)
	Input.action_release("p2_energy_next")
	await _wait_frames(2)

	_assert(
		roster_label.text.contains("interferencia"),
		"El roster deberia seguir mostrando cuando la nave lleva una carga `interference`."
	)
	_assert(
		roster_label.text.contains("estable"),
		"Si el rival seleccionado esta protegido por `estabilidad`, el roster deberia explicitar que la interferencia no entraria."
	)

	await create_timer(1.6).timeout
	await _wait_frames(2)

	_assert(
		not roster_label.text.contains("estable"),
		"Cuando la ventana de `estabilidad` termina, la advertencia de inmunidad deberia limpiarse sola."
	)

	await _cleanup_main(main)


func _verify_interference_target_markers_dim_when_target_has_stability() -> void:
	var main := await _instantiate_main_scene()
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(support_root != null, "La escena Teams deberia seguir exponiendo SupportRoot.")
	_assert(robots.size() >= 4, "La escena Teams deberia seguir ofreciendo cuatro robots.")
	if support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	robots[1].fall_into_void()
	await _wait_frames(4)

	var support_ship := support_root.get_child(0) as PilotSupportShip
	_assert(support_ship != null, "La nave de apoyo deberia existir para validar marcadores diegeticos.")
	if support_ship == null:
		await _cleanup_main(main)
		return

	var interference_pickup := _find_support_pickup("interference")
	_assert(interference_pickup != null, "El carril deberia seguir ofreciendo un pickup `interference`.")
	if interference_pickup == null:
		await _cleanup_main(main)
		return

	var stable_enemy := robots[2]
	var fresh_enemy := robots[3]
	support_ship.global_position = interference_pickup.global_position
	var ship_position := Vector3(support_ship.global_position.x, support_ship.global_position.y, support_ship.global_position.z)
	stable_enemy.global_position = ship_position + Vector3(0.0, 0.0, 1.1)
	fresh_enemy.global_position = ship_position + Vector3(0.0, 0.0, 1.9)
	stable_enemy.apply_stability_boost(1.5)
	await _wait_support_spawn_grace(support_ship)
	await _wait_frames(2)

	var target_indicator := support_ship.get_node_or_null("SupportTargetIndicator") as MeshInstance3D
	var target_floor_indicator := support_ship.get_node_or_null("SupportTargetFloorIndicator") as MeshInstance3D
	var interference_range_indicator := support_ship.get_node_or_null("InterferenceRangeIndicator") as MeshInstance3D
	_assert(target_indicator != null, "La nave deberia seguir exponiendo un marcador diegetico sobre el target.")
	_assert(target_floor_indicator != null, "La nave deberia seguir exponiendo una marca diegetica a nivel piso.")
	_assert(interference_range_indicator != null, "La nave deberia seguir exponiendo el anillo de rango de `interferencia`.")
	if target_indicator == null or target_floor_indicator == null or interference_range_indicator == null:
		await _cleanup_main(main)
		return

	var valid_target_material := target_indicator.material_override as StandardMaterial3D
	var valid_floor_material := target_floor_indicator.material_override as StandardMaterial3D
	var valid_range_material := interference_range_indicator.material_override as StandardMaterial3D
	_assert(valid_target_material != null, "El marcador superior deberia seguir usando material legible para validar su intensidad.")
	_assert(valid_floor_material != null, "La marca de piso deberia seguir usando material legible para validar su intensidad.")
	_assert(valid_range_material != null, "El anillo de rango deberia seguir usando material legible para validar su intensidad.")
	if valid_target_material == null or valid_floor_material == null or valid_range_material == null:
		await _cleanup_main(main)
		return

	_assert(
		support_ship.get_selected_target_robot() == fresh_enemy,
		"Con un rival estable y otro afectable ambos en rango, el target inicial deberia quedar sobre el rival realmente util."
	)
	var valid_target_emission := valid_target_material.emission_energy_multiplier
	var valid_floor_emission := valid_floor_material.emission_energy_multiplier
	var valid_range_emission := valid_range_material.emission_energy_multiplier

	Input.action_press("p2_energy_next")
	await _wait_frames(2)
	Input.action_release("p2_energy_next")
	await _wait_frames(2)

	_assert(
		support_ship.get_selected_target_robot() == stable_enemy,
		"El test deberia poder ciclar hasta el rival estable para comparar la lectura diegetica del mismo payload."
	)
	var stable_target_material := target_indicator.material_override as StandardMaterial3D
	var stable_floor_material := target_floor_indicator.material_override as StandardMaterial3D
	var stable_range_material := interference_range_indicator.material_override as StandardMaterial3D
	if stable_target_material == null or stable_floor_material == null or stable_range_material == null:
		await _cleanup_main(main)
		return

	_assert(
		stable_target_material.emission_energy_multiplier < valid_target_emission,
		"Si el rival seleccionado esta inmune por `estabilidad`, el marcador superior deberia perder intensidad frente a un objetivo realmente afectable."
	)
	_assert(
		stable_floor_material.emission_energy_multiplier < valid_floor_emission,
		"Si el rival seleccionado esta inmune por `estabilidad`, la marca de piso tambien deberia verse menos comprometida que sobre un objetivo realmente util."
	)
	_assert(
		stable_range_material.emission_energy_multiplier < valid_range_emission,
		"Si el rival seleccionado esta inmune por `estabilidad`, el anillo de rango no deberia seguir viendose tan listo como sobre un objetivo realmente util."
	)

	await _cleanup_main(main)


func _instantiate_main_scene() -> Node:
	var main = MAIN_SCENE.instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null and match_controller_preload.match_config != null:
		match_controller_preload.match_config.round_intro_duration_teams = 0.0
	root.add_child(main)
	await process_frame
	await process_frame
	return main


func _find_support_pickup(payload_name: String) -> Node3D:
	for node in get_nodes_in_group("pilot_support_pickups"):
		if not (node is Node3D):
			continue
		var pickup := node as Node3D
		if str(pickup.get("payload_name")) == payload_name:
			return pickup

	return null


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


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_support_spawn_grace(support_ship: PilotSupportShip) -> void:
	var wait_seconds := float(support_ship.get("spawn_pickup_grace_duration")) + 0.05
	if wait_seconds > 0.0:
		await create_timer(wait_seconds).timeout
	await _wait_frames(2)


func _cleanup_main(main: Node) -> void:
	if not is_instance_valid(main):
		return

	var parent := main.get_parent()
	if parent != null:
		parent.remove_child(main)
	main.free()
	await process_frame


func _finish() -> void:
	quit(1 if _failed else 0)
