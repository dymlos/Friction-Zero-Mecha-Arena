extends SceneTree

const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")
const ARIETE_ARCHETYPE := preload("res://data/config/robots/ariete_archetype.tres")
const AGUJA_ARCHETYPE := preload("res://data/config/robots/aguja_archetype.tres")
const ANCLA_ARCHETYPE := preload("res://data/config/robots/ancla_archetype.tres")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_archetype_accent_nodes_exist_and_differ()
	await _validate_runtime_loadout_rebuilds_the_accent()
	await _validate_core_skill_states_refresh_archetype_accent()
	_finish()


func _validate_archetype_accent_nodes_exist_and_differ() -> void:
	var ariete := _spawn_robot(ARIETE_ARCHETYPE, 1, Vector3(-2.0, 0.0, 0.0))
	var aguja := _spawn_robot(AGUJA_ARCHETYPE, 2, Vector3(0.0, 0.0, 0.0))
	var ancla := _spawn_robot(ANCLA_ARCHETYPE, 3, Vector3(2.0, 0.0, 0.0))

	await process_frame
	await physics_frame

	_assert(
		ariete.has_method("get_archetype_visual_signature"),
		"RobotBase deberia exponer una firma visual para tests/documentacion de arquetipo."
	)
	if not ariete.has_method("get_archetype_visual_signature"):
		await _cleanup_robot(ariete)
		await _cleanup_robot(aguja)
		await _cleanup_robot(ancla)
		return

	var ariete_signature := String(ariete.call("get_archetype_visual_signature"))
	var aguja_signature := String(aguja.call("get_archetype_visual_signature"))
	var ancla_signature := String(ancla.call("get_archetype_visual_signature"))
	_assert(ariete_signature != "", "Ariete deberia declarar una firma visual legible.")
	_assert(aguja_signature != "", "Aguja deberia declarar una firma visual legible.")
	_assert(ancla_signature != "", "Ancla deberia declarar una firma visual legible.")
	_assert(
		ariete_signature != aguja_signature and aguja_signature != ancla_signature,
		"Los arquetipos deberian distinguirse por algo mas que el texto del roster."
	)

	var ariete_accent := ariete.get_node_or_null("UpperBodyPivot/ArchetypeAccent") as Node3D
	var aguja_accent := aguja.get_node_or_null("UpperBodyPivot/ArchetypeAccent") as Node3D
	var ancla_accent := ancla.get_node_or_null("UpperBodyPivot/ArchetypeAccent") as Node3D
	_assert(ariete_accent != null, "Ariete deberia exponer un acento diegetico en el cuerpo.")
	_assert(aguja_accent != null, "Aguja deberia exponer un acento diegetico en el cuerpo.")
	_assert(ancla_accent != null, "Ancla deberia exponer un acento diegetico en el cuerpo.")
	if ariete_accent == null or aguja_accent == null or ancla_accent == null:
		await _cleanup_robot(ariete)
		await _cleanup_robot(aguja)
		await _cleanup_robot(ancla)
		return

	_assert(
		ariete_accent.get_child_count() == 3,
		"Ariete deberia leerse como un frente de empuje con tres piezas simples."
	)
	_assert(
		aguja_accent.get_child_count() == 1,
		"Aguja deberia mantener un perfil mas limpio y punzante."
	)
	_assert(
		ancla_accent.get_child_count() == 2,
		"Ancla deberia combinar halo + soporte para marcar zona/control."
	)

	var ariete_visual := ariete_accent.get_child(0) as MeshInstance3D
	var ancla_visual := ancla_accent.get_child(0) as MeshInstance3D
	_assert(ariete_visual != null, "El acento de Ariete deberia usar mesh runtime legible.")
	_assert(ancla_visual != null, "El acento de Ancla deberia usar mesh runtime legible.")
	if ariete_visual != null and ancla_visual != null:
		var ariete_material := ariete_visual.material_override as StandardMaterial3D
		var ancla_material := ancla_visual.material_override as StandardMaterial3D
		_assert(ariete_material != null, "El acento de Ariete deberia poder tintarse por arquetipo.")
		_assert(ancla_material != null, "El acento de Ancla deberia poder tintarse por arquetipo.")
		if ariete_material != null and ancla_material != null:
			_assert(
				not ariete_material.albedo_color.is_equal_approx(ancla_material.albedo_color),
				"Los acentos deberian aportar contraste entre arquetipos distintos."
			)

	await _cleanup_robot(ariete)
	await _cleanup_robot(aguja)
	await _cleanup_robot(ancla)


func _validate_runtime_loadout_rebuilds_the_accent() -> void:
	var robot := _spawn_robot(ARIETE_ARCHETYPE, 1, Vector3.ZERO)
	await process_frame
	await physics_frame

	var before_signature := String(robot.call("get_archetype_visual_signature"))
	var before_accent := robot.get_node_or_null("UpperBodyPivot/ArchetypeAccent") as Node3D
	var before_piece_count := before_accent.get_child_count() if before_accent != null else 0

	robot.apply_runtime_loadout(AGUJA_ARCHETYPE, RobotBase.ControlMode.EASY)
	await process_frame
	await physics_frame

	var after_signature := String(robot.call("get_archetype_visual_signature"))
	var after_accent := robot.get_node_or_null("UpperBodyPivot/ArchetypeAccent") as Node3D
	var after_piece_count := after_accent.get_child_count() if after_accent != null else 0
	_assert(
		before_signature != after_signature,
		"El selector runtime deberia actualizar la firma visual del arquetipo al cambiar loadout."
	)
	_assert(after_accent != null, "Tras cambiar el loadout, el robot deberia reconstruir su acento visual.")
	_assert(
		before_piece_count != after_piece_count,
		"El acento visual deberia reconstruirse y no quedarse con la silueta del arquetipo anterior."
	)

	await _cleanup_robot(robot)


func _validate_core_skill_states_refresh_archetype_accent() -> void:
	var aguja := _spawn_robot(AGUJA_ARCHETYPE, 1, Vector3(-1.5, 0.0, 0.0))
	var ariete := _spawn_robot(ARIETE_ARCHETYPE, 2, Vector3(1.5, 0.0, 0.0))
	await process_frame
	await physics_frame

	var aguja_ready_energy := _get_accent_peak_emission_energy(aguja)
	_assert(
		aguja.use_core_skill(),
		"Aguja deberia poder gastar una carga para validar la lectura del acento mientras la skill deja de estar lista."
	)
	_assert(
		aguja.use_core_skill(),
		"Aguja deberia poder agotar sus cargas para comparar el acento listo contra el agotado."
	)
	await process_frame
	await physics_frame

	var aguja_depleted_energy := _get_accent_peak_emission_energy(aguja)
	_assert(
		aguja_ready_energy > aguja_depleted_energy + 0.05,
		"El acento de arquetipo deberia latir mas fuerte cuando la skill propia esta lista que cuando ya no quedan cargas."
	)

	var ariete_ready_energy := _get_accent_peak_emission_energy(ariete)
	_assert(
		ariete.use_core_skill(),
		"Ariete deberia poder activar Embestida para reforzar la lectura activa sobre su acento."
	)
	await process_frame
	await physics_frame

	var ariete_active_energy := _get_accent_peak_emission_energy(ariete)
	_assert(
		ariete_active_energy > ariete_ready_energy + 0.08,
		"El acento de arquetipo deberia intensificarse durante la ventana activa de la skill propia."
	)

	await _cleanup_robot(aguja)
	await _cleanup_robot(ariete)


func _spawn_robot(archetype: Resource, player_index: int, position: Vector3) -> RobotBase:
	var robot := ROBOT_SCENE.instantiate() as RobotBase
	robot.archetype_config = archetype
	robot.player_index = player_index
	robot.position = position
	robot.gravity = 0.0
	robot.void_fall_y = -100.0
	root.add_child(robot)
	return robot


func _get_accent_peak_emission_energy(robot: RobotBase) -> float:
	if robot == null:
		return 0.0

	var accent_root := robot.get_node_or_null("UpperBodyPivot/ArchetypeAccent") as Node3D
	if accent_root == null:
		return 0.0

	var peak_energy := 0.0
	for child in accent_root.get_children():
		if not (child is MeshInstance3D):
			continue

		var material := (child as MeshInstance3D).material_override as StandardMaterial3D
		if material == null:
			continue

		peak_energy = maxf(peak_energy, material.emission_energy_multiplier)

	return peak_energy


func _cleanup_robot(robot: RobotBase) -> void:
	if not is_instance_valid(robot):
		return

	var parent := robot.get_parent()
	if parent != null:
		parent.remove_child(robot)
	robot.free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
