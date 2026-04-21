extends Node3D
class_name Main

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchHud = preload("res://scripts/ui/match_hud.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const DetachedPart = preload("res://scripts/robots/detached_part.gd")

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
			child.fell_into_void.connect(_on_robot_fell_into_void)
			child.respawned.connect(_on_robot_respawned)
			child.part_destroyed.connect(_on_robot_part_destroyed)
			child.part_restored.connect(_on_robot_part_restored)
			child.robot_disabled.connect(_on_robot_disabled)
			child.robot_exploded.connect(_on_robot_exploded)


func _report_startup_structure() -> void:
	var arena_count := arena_root.get_child_count()
	var robot_count := robot_root.get_child_count()
	var system_count := systems.get_child_count()

	print("Friction Zero base cargada.")
	print("Arenas: %s | Robots: %s | Sistemas: %s" % [arena_count, robot_count, system_count])


func _on_robot_fell_into_void(robot: RobotBase) -> void:
	ui.show_status("%s cayo al vacio. Reinicio de prototipo..." % robot.display_name)


func _on_robot_respawned(robot: RobotBase) -> void:
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
	ui.show_status("%s exploto tras quedar inutilizado" % robot.display_name)
