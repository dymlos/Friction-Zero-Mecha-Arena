extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const MatchController = preload("res://scripts/systems/match_controller.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_support_ship_spawns_only_in_teams()
	_finish()


func _verify_support_ship_spawns_only_in_teams() -> void:
	var main = MAIN_SCENE.instantiate()
	var match_controller_preload := main.get_node_or_null("Systems/MatchController") as MatchController
	if match_controller_preload != null:
		match_controller_preload.round_intro_duration = 0.0
	root.add_child(main)

	await process_frame
	await process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var support_root := main.get_node_or_null("SupportRoot")
	var robots := _get_scene_robots(main)
	_assert(match_controller != null, "La escena principal deberia seguir exponiendo MatchController.")
	_assert(support_root != null, "El laboratorio Teams deberia reservar un SupportRoot para el soporte post-muerte.")
	_assert(robots.size() >= 4, "La escena principal deberia seguir ofreciendo cuatro robots para Teams.")
	if match_controller == null or support_root == null or robots.size() < 4:
		await _cleanup_main(main)
		return

	_assert(
		support_root.get_child_count() == 0,
		"No deberia haber naves de apoyo activas antes de una eliminacion."
	)

	robots[1].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 1,
		"Cuando un jugador cae en Teams y aun queda un aliado, deberia aparecer una nave de apoyo."
	)
	var roster_label := main.get_node_or_null("UI/MatchHud/Root/RosterLabel") as Label
	_assert(roster_label != null, "El HUD deberia seguir exponiendo el roster compacto.")
	if roster_label != null:
		_assert(
			roster_label.text.contains("usa /"),
			"El roster deberia recordar con que tecla usa su carga la nave de apoyo del jugador eliminado."
		)
		_assert(
			roster_label.text.contains("objetivo ,/."),
			"El roster deberia recordar como ciclar objetivos mientras la nave de apoyo sigue activa."
		)
	var support_ship := support_root.get_child(0) as Node3D
	var status_ring_visual: MeshInstance3D = null
	var status_pulse_visual: MeshInstance3D = null
	var idle_ring_color := Color.WHITE
	_assert(support_ship != null, "La nave de apoyo deberia existir como Node3D en escena.")
	if support_ship != null:
		var hull_visual := support_ship.get_node_or_null("HullVisual") as MeshInstance3D
		var glow_visual := support_ship.get_node_or_null("GlowVisual") as MeshInstance3D
		var status_beacon := support_ship.get_node_or_null("StatusBeacon") as Node3D
		status_ring_visual = support_ship.get_node_or_null("StatusBeacon/RingVisual") as MeshInstance3D
		status_pulse_visual = support_ship.get_node_or_null("StatusBeacon/PulseVisual") as MeshInstance3D
		_assert(hull_visual != null, "La nave deberia exponer un casco visible.")
		_assert(glow_visual != null, "La nave deberia exponer un glow visible.")
		_assert(status_beacon != null, "La nave deberia exponer un beacon diegetico para leer su estado en mundo.")
		_assert(status_ring_visual != null, "El beacon diegetico deberia incluir un aro base legible.")
		_assert(status_pulse_visual != null, "El beacon diegetico deberia incluir un pulso/acento para cargas o interferencia.")
		if hull_visual != null and glow_visual != null:
			_assert(
				hull_visual.material_override != glow_visual.material_override,
				"Casco y glow deberian usar materiales independientes para no pisarse el color/emision."
			)
		if status_beacon != null:
			_assert(
				status_beacon.position.y > 0.2,
				"El beacon diegetico deberia vivir por encima de la nave para no perderse contra el carril."
			)
		if status_ring_visual != null and status_ring_visual.material_override is StandardMaterial3D:
			idle_ring_color = (status_ring_visual.material_override as StandardMaterial3D).albedo_color
	if support_ship != null:
		var start_position := support_ship.global_position
		Input.action_press("p2_move_right")
		await _wait_physics_frames(3)
		Input.action_release("p2_move_right")
		_assert(
			support_ship.global_position.distance_to(start_position) > 0.05,
			"La nave de apoyo deberia moverse con el input del jugador eliminado."
		)

	var support_pickups := get_nodes_in_group("pilot_support_pickups")
	_assert(
		not support_pickups.is_empty(),
		"El slice post-muerte deberia exponer pickups discretos para la nave de apoyo."
	)
	var arena := main.get_node_or_null("ArenaRoot/ArenaBlockout")
	_assert(arena != null, "La escena principal deberia seguir exponiendo el arena para enrutar el carril externo.")
	if support_ship != null and not support_pickups.is_empty():
		robots[0].apply_damage_to_part("left_arm", robots[0].max_part_health * 0.35, Vector3.LEFT)
		var arm_health_before := robots[0].get_part_health("left_arm")
		var support_pickup := support_pickups[0] as Node3D
		_assert(support_pickup != null, "Cada pickup de apoyo deberia vivir como Node3D.")
		if support_pickup != null:
			var pedestal_visual := support_pickup.get_node_or_null("PedestalVisual") as MeshInstance3D
			var core_visual := support_pickup.get_node_or_null("CoreVisual") as MeshInstance3D
			_assert(pedestal_visual != null, "El pickup deberia exponer un pedestal visible.")
			_assert(core_visual != null, "El pickup deberia exponer un nucleo visible.")
			if pedestal_visual != null and core_visual != null:
				_assert(
					pedestal_visual.material_override != core_visual.material_override,
					"Pedestal y nucleo deberian usar materiales independientes para no perder contraste."
				)
			support_ship.global_position = support_pickup.global_position
			await _wait_frames(3)

			_assert(
				roster_label.text.contains("estabilizador"),
				"El roster deberia mostrar cuando la nave lleva una carga de apoyo."
			)
			_assert(
				support_ship.has_method("get_status_summary")
					and String(support_ship.call("get_status_summary")).contains(robots[0].get_roster_display_name()),
				"El soporte post-muerte deberia conservar `Player / Arquetipo` tambien al nombrar a su aliado objetivo."
			)
			if status_ring_visual != null and status_ring_visual.material_override is StandardMaterial3D:
				var loaded_ring_color := (status_ring_visual.material_override as StandardMaterial3D).albedo_color
				_assert(
					not loaded_ring_color.is_equal_approx(idle_ring_color),
					"El beacon diegetico deberia cambiar cuando la nave lleva una carga."
				)
			if status_pulse_visual != null:
				_assert(
					status_pulse_visual.visible,
					"El acento del beacon deberia hacerse visible cuando la nave lleva una carga."
				)

			Input.action_press("p2_throw_part")
			await _wait_frames(2)
			Input.action_release("p2_throw_part")
			await _wait_frames(2)

			_assert(
				robots[0].get_part_health("left_arm") > arm_health_before,
				"Usar la carga de apoyo deberia estabilizar al aliado vivo."
			)
			_assert(
				not roster_label.text.contains("estabilizador"),
				"Tras usar la carga, el roster deberia limpiar el estado de apoyo pendiente."
			)

			var support_surge_pickup: Node3D = null
			for pickup in support_pickups:
				if not (pickup is Node3D):
					continue
				if str((pickup as Node3D).get("payload_name")) == "surge":
					support_surge_pickup = pickup as Node3D
					break

			_assert(
				support_surge_pickup != null,
				"El carril externo deberia ofrecer al menos un segundo payload liviano de apoyo."
			)
			if support_surge_pickup != null:
				support_ship.global_position = support_surge_pickup.global_position
				await _wait_frames(3)

				_assert(
					roster_label.text.contains("energia"),
					"El roster deberia distinguir cuando la nave lleva una carga de energia."
				)

				Input.action_press("p2_throw_part")
				await _wait_frames(2)
				Input.action_release("p2_throw_part")
				await _wait_frames(2)

				_assert(
					robots[0].is_energy_surge_active(),
					"La nueva carga de apoyo deberia reforzar la energia del aliado vivo."
				)
				_assert(
					not roster_label.text.contains("apoyo energia"),
					"Tras gastar la carga de energia, el roster deberia limpiar el payload pendiente."
				)

			var support_mobility_pickup: Node3D = null
			for pickup in support_pickups:
				if not (pickup is Node3D):
					continue
				if str((pickup as Node3D).get("payload_name")) == "mobility":
					support_mobility_pickup = pickup as Node3D
					break

			_assert(
				support_mobility_pickup != null,
				"El carril externo deberia ofrecer tambien una ayuda liviana de movilidad."
			)
			if support_mobility_pickup != null:
				support_ship.global_position = support_mobility_pickup.global_position
				await _wait_frames(3)

				_assert(
					roster_label.text.contains("movilidad"),
					"El roster deberia distinguir cuando la nave lleva una carga de movilidad."
				)

				Input.action_press("p2_throw_part")
				await _wait_frames(2)
				Input.action_release("p2_throw_part")
				await _wait_frames(2)

				_assert(
					robots[0].is_mobility_boost_active(),
					"La nueva carga de movilidad deberia reforzar el desplazamiento del aliado vivo."
				)
				_assert(
					not roster_label.text.contains("apoyo movilidad"),
					"Tras gastar la carga de movilidad, el roster deberia limpiar el payload pendiente."
				)

			var support_interference_pickup: Node3D = null
			for pickup in support_pickups:
				if not (pickup is Node3D):
					continue
				if str((pickup as Node3D).get("payload_name")) == "interference":
					support_interference_pickup = pickup as Node3D
					break

			_assert(
				support_interference_pickup != null,
				"El carril externo deberia ofrecer una interferencia ligera para presionar rivales sin abrir otra capa de combate."
			)
			if support_interference_pickup != null:
				support_ship.global_position = support_interference_pickup.global_position
				await _wait_frames(3)

				_assert(
					roster_label.text.contains("interferencia"),
					"El roster deberia distinguir cuando la nave lleva una carga de interferencia."
				)
				var interference_range_indicator := support_ship.get_node_or_null("InterferenceRangeIndicator") as MeshInstance3D
				_assert(
					interference_range_indicator != null,
					"La nave de apoyo deberia exponer un telegraph diegetico del rango real de interferencia."
				)
				if interference_range_indicator != null:
					_assert(
						interference_range_indicator.visible,
						"El telegraph de rango deberia activarse cuando la nave lleva una carga de interferencia."
					)
					var expected_range_scale: float = float(support_ship.get("support_interference_range")) * 2.0
					_assert(
						is_equal_approx(interference_range_indicator.scale.x, expected_range_scale),
						"El telegraph de rango deberia usar el diametro real de la interferencia en el eje X."
					)
					_assert(
						is_equal_approx(interference_range_indicator.scale.z, expected_range_scale),
						"El telegraph de rango deberia usar el diametro real de la interferencia en el eje Z."
					)

				var enemy_robot := robots[2]
				var second_enemy_robot := robots[3]
				_assert(
					enemy_robot.has_method("is_control_zone_suppressed"),
					"La interferencia ligera deberia reutilizar el contrato de supresion legible ya expuesto por RobotBase."
				)
				Input.action_press("p2_throw_part")
				await _wait_frames(2)
				Input.action_release("p2_throw_part")
				await _wait_frames(2)

				_assert(
					roster_label.text.contains("interferencia"),
					"Si no hay un rival cerca del carril, la carga de interferencia deberia seguir disponible."
				)

				enemy_robot.global_position = support_ship.global_position + Vector3(1.2, 0.35, 0.0)
				second_enemy_robot.global_position = support_ship.global_position + Vector3(2.2, 0.35, 0.0)
				enemy_robot.velocity = Vector3.ZERO
				second_enemy_robot.velocity = Vector3.ZERO
				await _wait_physics_frames(2)

				_assert(
					support_ship.has_method("get_selected_target_robot"),
					"La nave de apoyo deberia exponer el objetivo seleccionado para que el soporte tactico pueda leerse y validarse."
				)
				_assert(
					support_ship.get_node_or_null("SupportTargetIndicator") != null,
					"La nave de apoyo deberia mostrar un indicador diegetico sobre el objetivo seleccionado."
				)
				var support_target_floor_indicator := support_ship.get_node_or_null("SupportTargetFloorIndicator") as MeshInstance3D
				_assert(
					support_target_floor_indicator != null,
					"La nave de apoyo deberia marcar tambien el objetivo seleccionado a nivel piso para que siga leyendose en pantalla compartida."
				)
				if support_target_floor_indicator != null:
					_assert(
						support_target_floor_indicator.visible,
						"La marca de piso deberia activarse mientras exista una carga de apoyo con objetivo valido."
					)
					_assert(
						support_target_floor_indicator.global_position.distance_to(enemy_robot.global_position) < 0.2,
						"La marca de piso deberia seguir al rival seleccionado, no quedarse pegada a la nave."
					)
				if support_ship.has_method("get_selected_target_robot"):
					_assert(
						support_ship.call("get_selected_target_robot") == enemy_robot,
						"La interferencia deberia apuntar por defecto al rival valido mas cercano al carril."
					)
				_assert(
					support_ship.has_method("get_status_summary")
						and String(support_ship.call("get_status_summary")).contains(enemy_robot.get_roster_display_name()),
					"El roster deberia dejar visible a que rival apunta la interferencia cargada sin perder la identidad `Player / Arquetipo`."
				)

				Input.action_press("p2_energy_next")
				await _wait_frames(2)
				Input.action_release("p2_energy_next")
				await _wait_frames(2)

				if support_ship.has_method("get_selected_target_robot"):
					_assert(
						support_ship.call("get_selected_target_robot") == second_enemy_robot,
						"El jugador eliminado deberia poder ciclar el objetivo de interferencia entre rivales validos."
					)
				_assert(
					support_ship.has_method("get_status_summary")
						and String(support_ship.call("get_status_summary")).contains(second_enemy_robot.get_roster_display_name()),
					"Tras ciclar el objetivo, el roster deberia actualizar el rival seleccionado sin volver a `Player X` pelado."
				)
				if support_target_floor_indicator != null:
					_assert(
						support_target_floor_indicator.global_position.distance_to(second_enemy_robot.global_position) < 0.2,
						"Al ciclar objetivo, la marca de piso deberia moverse junto al nuevo rival seleccionado."
					)

				Input.action_press("p2_throw_part")
				await _wait_frames(2)
				Input.action_release("p2_throw_part")
				await _wait_frames(2)

				if enemy_robot.has_method("is_control_zone_suppressed"):
					_assert(
						not bool(enemy_robot.call("is_control_zone_suppressed")),
						"Tras ciclar el objetivo, la interferencia no deberia quedarse pegada al rival previo."
					)
				if second_enemy_robot.has_method("is_control_zone_suppressed"):
					_assert(
						bool(second_enemy_robot.call("is_control_zone_suppressed")),
						"La carga de interferencia deberia aplicarse sobre el rival actualmente seleccionado."
					)
				_assert(
					not roster_label.text.contains("apoyo interferencia"),
					"Tras gastar la carga de interferencia, el roster deberia limpiar el payload pendiente."
				)
				if interference_range_indicator != null:
					_assert(
						not interference_range_indicator.visible,
						"Tras gastar la carga, el telegraph de rango deberia apagarse otra vez."
					)
				if support_target_floor_indicator != null:
					_assert(
						not support_target_floor_indicator.visible,
						"Tras gastar la carga, la marca de piso del objetivo deberia apagarse otra vez."
					)

		var support_gates := get_nodes_in_group("support_lane_gates")
		_assert(
			not support_gates.is_empty(),
			"El carril externo deberia sumar gates discretos para que la nave tenga decisiones de ruta."
		)
		if arena != null and not support_gates.is_empty():
			var north_gate: Node3D = null
			for gate in support_gates:
				if not (gate is Node3D):
					continue
				var gate_node := gate as Node3D
				if gate_node.global_position.z < 0.0:
					north_gate = gate_node
					break

			_assert(
				north_gate != null,
				"El arena deberia ofrecer al menos un gate sobre el tramo norte del carril."
			)
			if north_gate != null:
				_assert(
					north_gate.has_method("set_forced_blocking_state"),
					"Los gates del carril deberian poder fijar su estado para los tests."
				)
				var gate_progress := float(arena.call("get_support_lane_progress_near", north_gate.global_position))
				var spawn_progress := float(arena.call("advance_support_lane_progress", gate_progress, -1.8))
				var spawn_position := arena.call("get_support_lane_position_from_progress", spawn_progress) as Vector3
				support_ship.call("configure", robots[1], robots[0], spawn_position, arena)
				await _wait_frames(2)

				if north_gate.has_method("set_forced_blocking_state"):
					north_gate.call("set_forced_blocking_state", true)
				var blocked_start_x := support_ship.global_position.x
				Input.action_press("p2_move_right")
				await _wait_physics_frames(8)
				Input.action_release("p2_move_right")

				_assert(
					support_ship.global_position.x < north_gate.global_position.x - 0.2,
					"Un gate cerrado deberia impedir que la nave cruce libremente el tramo bloqueado."
				)
				_assert(
					support_ship.global_position.x <= blocked_start_x + 1.25,
					"El gate cerrado deberia cortar el avance de la nave en vez de dejarla deslizar casi completo."
				)
				_assert(
					roster_label.text.contains("interferido"),
					"El roster deberia avisar cuando la nave queda interferida por un gate cerrado."
				)
				if status_ring_visual != null and status_ring_visual.material_override is StandardMaterial3D:
					var disrupted_ring_color := (status_ring_visual.material_override as StandardMaterial3D).albedo_color
					_assert(
						not disrupted_ring_color.is_equal_approx(idle_ring_color),
						"El beacon diegetico deberia cambiar tambien cuando la nave queda interferida."
					)
				if status_pulse_visual != null:
					_assert(
						status_pulse_visual.visible,
						"El pulso del beacon deberia ayudar a leer la interferencia del carril."
					)

				if north_gate.has_method("set_forced_blocking_state"):
					north_gate.call("set_forced_blocking_state", false)
				await _wait_physics_frames(45)
				Input.action_press("p2_move_right")
				await _wait_physics_frames(18)
				Input.action_release("p2_move_right")

				_assert(
					support_ship.global_position.x > north_gate.global_position.x + 0.2,
					"Cuando el gate se abre, la nave deberia poder completar el tramo y cruzarlo."
				)
				_assert(
					not roster_label.text.contains("interferido"),
					"Tras liberarse el carril, el roster deberia limpiar la interferencia de apoyo."
				)

	if roster_label != null:
		_assert(
			roster_label.text.contains("apoyo"),
			"El roster deberia dejar visible que un jugador eliminado sigue activo como apoyo."
		)
	var support_pickup_after_cleanup := support_pickups[0] as Node3D if not support_pickups.is_empty() else null
	robots[0].fall_into_void()
	await _wait_frames(4)

	_assert(
		support_root.get_child_count() == 0,
		"Si el jugador eliminado ya no tiene ningun aliado vivo, su nave de apoyo deberia desaparecer enseguida."
	)
	if roster_label != null:
		_assert(
			not roster_label.text.contains("apoyo"),
			"Sin un aliado vivo al que asistir, el roster no deberia seguir mostrando apoyo activo."
		)
	if support_pickup_after_cleanup != null:
		_assert(
			not support_pickup_after_cleanup.visible,
			"Cuando la ultima nave se apaga, el carril post-muerte tambien deberia ocultar sus pickups."
		)

	await _cleanup_main(main)

	var ffa_scene := load("res://scenes/main/main_ffa.tscn")
	_assert(ffa_scene is PackedScene, "El proyecto deberia seguir exponiendo la escena dedicada FFA.")
	if not (ffa_scene is PackedScene):
		return

	var ffa_main = (ffa_scene as PackedScene).instantiate()
	root.add_child(ffa_main)

	await process_frame
	await process_frame

	var ffa_support_root := ffa_main.get_node_or_null("SupportRoot")
	var ffa_robots := _get_scene_robots(ffa_main)
	_assert(ffa_support_root != null, "La escena FFA deberia compartir la estructura base del laboratorio.")
	_assert(ffa_robots.size() >= 4, "La escena FFA deberia seguir ofreciendo cuatro robots.")
	if ffa_support_root == null or ffa_robots.size() < 4:
		await _cleanup_main(ffa_main)
		return

	ffa_robots[0].fall_into_void()
	await _wait_frames(4)

	_assert(
		ffa_support_root.get_child_count() == 0,
		"FFA no deberia activar naves de apoyo post-muerte."
	)

	await _cleanup_main(ffa_main)


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


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


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
