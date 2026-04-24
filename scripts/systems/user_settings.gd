extends Resource
class_name UserSettings

const MatchConfig = preload("res://scripts/systems/match_config.gd")

const WINDOW_MODE_WINDOWED := "windowed"
const WINDOW_MODE_BORDERLESS := "borderless"
const WINDOW_MODE_FULLSCREEN := "fullscreen"

const VALID_WINDOW_MODES := [
	WINDOW_MODE_WINDOWED,
	WINDOW_MODE_BORDERLESS,
	WINDOW_MODE_FULLSCREEN,
]

@export_range(0.0, 1.0, 0.01) var audio_master_volume := 1.0
@export_range(0.0, 1.0, 0.01) var audio_music_volume := 1.0
@export_range(0.0, 1.0, 0.01) var audio_sfx_volume := 1.0
@export var window_mode := WINDOW_MODE_WINDOWED
@export var vsync_enabled := true
@export var default_hud_detail_mode: MatchConfig.HudDetailMode = MatchConfig.HudDetailMode.CONTEXTUAL


func sanitize_in_place():
	audio_master_volume = clampf(audio_master_volume, 0.0, 1.0)
	audio_music_volume = clampf(audio_music_volume, 0.0, 1.0)
	audio_sfx_volume = clampf(audio_sfx_volume, 0.0, 1.0)
	if not VALID_WINDOW_MODES.has(window_mode):
		window_mode = WINDOW_MODE_WINDOWED
	if default_hud_detail_mode != MatchConfig.HudDetailMode.CONTEXTUAL:
		default_hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT
	vsync_enabled = bool(vsync_enabled)
	return self


func duplicate_sanitized():
	var clone = duplicate(true)
	return clone.sanitize_in_place()
