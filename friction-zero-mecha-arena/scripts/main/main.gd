extends Node3D
class_name Main

@onready var arena_root: Node3D = $ArenaRoot
@onready var robot_root: Node3D = $RobotRoot
@onready var systems: Node = $Systems
@onready var match_controller: MatchController = $Systems/MatchController
@onready var ui: MatchHud = $UI/MatchHud


func _ready() -> void:
	# Esta escena solo conecta piezas grandes: arena, robots, UI y sistemas.
	# La logica concreta vive en scripts mas chicos para que el proyecto crezca ordenado.
	_register_existing_robots()
	_report_startup_structure()
	ui.show_status("Friction Zero: %s robots en arena" % match_controller.registered_robots.size())


func _register_existing_robots() -> void:
	# Por ahora los robots estan puestos a mano en la escena.
	# Cuando haya seleccion de jugadores, este punto puede pasar a usar spawns y datos.
	for child in robot_root.get_children():
		if child is RobotBase:
			match_controller.register_robot(child)


func _report_startup_structure() -> void:
	var arena_count := arena_root.get_child_count()
	var robot_count := robot_root.get_child_count()
	var system_count := systems.get_child_count()

	print("Friction Zero base cargada.")
	print("Arenas: %s | Robots: %s | Sistemas: %s" % [arena_count, robot_count, system_count])
