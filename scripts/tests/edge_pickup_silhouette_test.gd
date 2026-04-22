extends SceneTree

const PICKUP_SCENES := {
	"repair": preload("res://scenes/pickups/edge_repair_pickup.tscn"),
	"mobility": preload("res://scenes/pickups/edge_mobility_pickup.tscn"),
	"energy": preload("res://scenes/pickups/edge_energy_pickup.tscn"),
	"pulse": preload("res://scenes/pickups/edge_pulse_pickup.tscn"),
	"charge": preload("res://scenes/pickups/edge_charge_pickup.tscn"),
	"utility": preload("res://scenes/pickups/edge_utility_pickup.tscn"),
}

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_edge_pickups_expose_distinct_world_silhouettes()
	_finish()


func _verify_edge_pickups_expose_distinct_world_silhouettes() -> void:
	var pickups: Array[Node3D] = []
	var silhouette_signatures: Dictionary = {}
	var unique_signatures: Dictionary = {}

	for pickup_name in PICKUP_SCENES.keys():
		var pickup = PICKUP_SCENES[pickup_name].instantiate()
		root.add_child(pickup)
		pickups.append(pickup)

	await process_frame

	for pickup_name in PICKUP_SCENES.keys():
		var pickup := pickups[PICKUP_SCENES.keys().find(pickup_name)]
		var accent_visual := pickup.get_node_or_null("Visuals/Accent") as MeshInstance3D
		_assert(
			accent_visual != null,
			"Cada edge pickup deberia exponer un acento/silueta propia en mundo, no depender solo del color del nucleo."
		)
		if accent_visual == null:
			continue

		var mesh := accent_visual.mesh
		var material := accent_visual.material_override as StandardMaterial3D
		var signature := "%s|%s|%s" % [
			mesh.get_class() if mesh != null else "null",
			accent_visual.scale,
			accent_visual.rotation_degrees,
		]
		silhouette_signatures[pickup_name] = signature
		unique_signatures[signature] = true
		_assert(
			material != null,
			"El acento del edge pickup deberia tener material propio para sostener contraste sin pisar el nucleo."
		)
		if material != null:
			_assert(
				material.emission_enabled,
				"El acento del edge pickup deberia seguir siendo legible a distancia con emision sobria."
			)
		_assert(
			accent_visual.is_visible_in_tree(),
			"El acento del edge pickup deberia quedar visible mientras el pedestal este activo."
		)

	_assert(
		silhouette_signatures.size() == PICKUP_SCENES.size(),
		"Cada edge pickup probado deberia registrar su firma visual."
	)
	_assert(
		unique_signatures.size() == silhouette_signatures.size(),
		"Los edge pickups deberian diferenciarse por silueta, no compartir la misma firma visual."
	)

	for pickup in pickups:
		pickup.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
