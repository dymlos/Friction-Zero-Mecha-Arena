extends Resource
class_name MatchConfig

@export_range(2, 8) var max_players := 4
@export var round_time_seconds := 180
@export var allow_team_mode := true
@export var progressive_space_reduction := true

# Configuracion inicial de prototipo. La intencion es ajustar estos valores
# desde recursos .tres sin tener que tocar scripts cada vez.
@export var default_arena_scene: PackedScene
@export var default_robot_scene: PackedScene
