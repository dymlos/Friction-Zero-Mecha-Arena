extends Resource
class_name MatchConfig

enum HudDetailMode { EXPLICIT, CONTEXTUAL }

@export_range(2, 8) var max_players := 4
@export_range(1, 4) var local_player_count := 4
@export var round_time_seconds := 60
@export_range(1, 9) var rounds_to_win := 3
@export var allow_team_mode := true
@export var progressive_space_reduction := true
@export var hud_detail_mode: HudDetailMode = HudDetailMode.EXPLICIT
@export var hud_detail_mode_ffa: HudDetailMode = HudDetailMode.EXPLICIT
@export var hud_detail_mode_teams: HudDetailMode = HudDetailMode.EXPLICIT
@export_range(0, 12, 1) var void_elimination_round_points := 2
@export_range(0, 12, 1) var destruction_elimination_round_points := 1
@export_range(0, 12, 1) var unstable_elimination_round_points := 4
@export_range(0.0, 3.0, 0.05) var round_intro_duration_ffa := 1.0
@export_range(0.0, 3.0, 0.05) var round_intro_duration_teams := 0.6


func get_default_hud_detail_mode(is_ffa_mode: bool) -> HudDetailMode:
	if is_ffa_mode:
		return hud_detail_mode_ffa

	return hud_detail_mode_teams


func get_round_intro_duration(is_ffa_mode: bool) -> float:
	return round_intro_duration_ffa if is_ffa_mode else round_intro_duration_teams


func get_round_victory_points_for_cause(cause: int) -> int:
	match cause:
		0:
			return max(0, void_elimination_round_points)
		1:
			return max(0, destruction_elimination_round_points)
		2:
			return max(0, unstable_elimination_round_points)

	return 1

# Configuracion inicial de prototipo. La intencion es ajustar estos valores
# desde recursos .tres sin tener que tocar scripts cada vez.
@export var default_arena_scene: PackedScene
@export var default_robot_scene: PackedScene
