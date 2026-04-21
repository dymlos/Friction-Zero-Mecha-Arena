extends Resource
class_name MatchConfig

enum HudDetailMode { EXPLICIT, CONTEXTUAL }

@export_range(2, 8) var max_players := 4
@export_range(1, 4) var local_player_count := 2
@export var round_time_seconds := 60
@export_range(1, 9) var rounds_to_win := 3
@export var allow_team_mode := true
@export var progressive_space_reduction := true
@export var hud_detail_mode: HudDetailMode = HudDetailMode.EXPLICIT

# Configuracion inicial de prototipo. La intencion es ajustar estos valores
# desde recursos .tres sin tener que tocar scripts cada vez.
@export var default_arena_scene: PackedScene
@export var default_robot_scene: PackedScene
