extends Node

const ProceduralCueBank = preload("res://scripts/audio/procedural_cue_bank.gd")

const MUSIC_STATES := [
	"shell",
	"match_intro",
	"match_live",
	"final_pressure",
	"pause",
	"results",
]

const MUSIC_STATE_PROFILES := {
	"shell": {"role": "shell_idle", "intensity": 0.25, "music_gain": 0.68},
	"match_intro": {"role": "match_intro", "intensity": 0.48, "music_gain": 0.66},
	"match_live": {"role": "match_base", "intensity": 0.58, "music_gain": 0.64},
	"final_pressure": {"role": "final_escalation", "intensity": 0.82, "music_gain": 0.7},
	"pause": {"role": "pause_low", "intensity": 0.2, "music_gain": 0.5},
	"results": {"role": "results_release", "intensity": 0.45, "music_gain": 0.62},
}

const UI_PLAYER_COUNT := 3
const SFX_PLAYER_COUNT := 6
const MIN_VOLUME_DB := -80.0
const MUSIC_DISABLED := true

static var _singleton: Node = null

var _cue_bank := ProceduralCueBank.new()
var _ui_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null
var _bus_playback_indices := {
	"UI": 0,
	"SFX": 0,
}
var _music_state := ""
var _debug_history: Array[Dictionary] = []
var _is_shutting_down := false
var _audio_playback_enabled := true
var _music_duck_remaining := 0.0
var _music_duck_gain := 1.0


static func get_singleton() -> Node:
	return _singleton


func _ready() -> void:
	_singleton = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audio_playback_enabled = DisplayServer.get_name() != "headless"
	_ensure_bus("UI")
	_ensure_bus("SFX")
	_ensure_bus("Music")
	if _audio_playback_enabled:
		_build_players()


func _process(delta: float) -> void:
	_update_music_duck(delta)
	if not _audio_playback_enabled:
		return
	if _music_state == "" or _music_player == null:
		return
	if _music_player.playing:
		return

	_music_player.stream = _cue_bank.get_music_stream(_music_state)
	_apply_music_profile_gain()
	_music_player.play()


func _exit_tree() -> void:
	_shutdown_audio_graph()
	if _singleton == self:
		_singleton = null


func play_cue(cue_id: String) -> void:
	var cue_stream := _cue_bank.get_cue_stream(cue_id)
	if cue_stream == null:
		return

	var cue_profile := _cue_bank.get_cue_profile(cue_id) if _cue_bank.has_method("get_cue_profile") else {}
	if bool(cue_profile.get("ducks_music", false)):
		_trigger_music_duck(cue_id, cue_profile)

	if not _audio_playback_enabled:
		_record_debug("cue", cue_id)
		return

	var bus_name := _cue_bank.get_bus_for_cue(cue_id)
	var player := _next_player_for_bus(bus_name)
	if player == null:
		return

	player.bus = bus_name
	player.stream = cue_stream
	player.play()
	_record_debug("cue", cue_id)


func set_music_state(state_name: String) -> void:
	if MUSIC_DISABLED:
		_music_state = ""
		if _audio_playback_enabled and _music_player != null:
			_music_player.stop()
			_music_player.stream = null
		return

	var next_state := state_name if MUSIC_STATES.has(state_name) else ""
	if _music_state == next_state:
		return

	_music_state = next_state
	if _music_state != "":
		_record_debug("music", _music_state)
	if not _audio_playback_enabled:
		return
	if _music_player == null:
		return
	if _music_state == "":
		_music_player.stop()
		return

	_music_player.bus = "Music"
	_music_player.stream = _cue_bank.get_music_stream(_music_state)
	_apply_music_profile_gain()
	_music_player.play()


func get_music_state() -> String:
	return _music_state


func get_music_state_profile(state_name: String) -> Dictionary:
	var profile: Dictionary = MUSIC_STATE_PROFILES.get(state_name, {})
	return profile.duplicate(true)


func get_current_music_duck_gain() -> float:
	return _music_duck_gain


func get_cue_profile(cue_id: String) -> Dictionary:
	if not _cue_bank.has_method("get_cue_profile"):
		return {}

	return _cue_bank.get_cue_profile(cue_id)


func set_master_volume(next_volume: float) -> void:
	_set_bus_volume_linear("Master", next_volume)


func get_master_volume() -> float:
	return _get_bus_volume_linear("Master")


func set_music_volume(next_volume: float) -> void:
	_set_bus_volume_linear("Music", next_volume)


func get_music_volume() -> float:
	return _get_bus_volume_linear("Music")


func set_sfx_volume(next_volume: float) -> void:
	_set_bus_volume_linear("SFX", next_volume)


func get_sfx_volume() -> float:
	return _get_bus_volume_linear("SFX")


func reset_debug_history() -> void:
	_debug_history.clear()


func get_debug_history() -> Array:
	return _debug_history.duplicate(true)


func _shutdown_audio_graph() -> void:
	if _is_shutting_down:
		return

	_is_shutting_down = true
	_music_state = ""
	_audio_playback_enabled = false
	for player in _ui_players:
		_release_player(player)
	for player in _sfx_players:
		_release_player(player)
	_release_player(_music_player)
	_ui_players.clear()
	_sfx_players.clear()
	_music_player = null
	_cue_bank = ProceduralCueBank.new()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return

	var bus_index := AudioServer.get_bus_count()
	AudioServer.add_bus(bus_index)
	AudioServer.set_bus_name(bus_index, bus_name)


func _build_players() -> void:
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "MusicPlayer"
		_music_player.bus = "Music"
		add_child(_music_player)
	if _ui_players.is_empty():
		for index in range(UI_PLAYER_COUNT):
			var player := AudioStreamPlayer.new()
			player.name = "UIPlayer%s" % index
			player.bus = "UI"
			add_child(player)
			_ui_players.append(player)
	if _sfx_players.is_empty():
		for index in range(SFX_PLAYER_COUNT):
			var player := AudioStreamPlayer.new()
			player.name = "SFXPlayer%s" % index
			player.bus = "SFX"
			add_child(player)
			_sfx_players.append(player)


func _next_player_for_bus(bus_name: String) -> AudioStreamPlayer:
	var players := _ui_players if bus_name == "UI" else _sfx_players
	if players.is_empty():
		return null

	var current_index := int(_bus_playback_indices.get(bus_name, 0))
	var player := players[wrapi(current_index, 0, players.size())]
	_bus_playback_indices[bus_name] = wrapi(current_index + 1, 0, players.size())
	return player


func _trigger_music_duck(cue_id: String, cue_profile: Dictionary) -> void:
	var priority := clampf(float(cue_profile.get("functional_priority", 0.0)), 0.0, 1.0)
	_music_duck_remaining = maxf(_music_duck_remaining, 0.18 + priority * 0.18)
	_music_duck_gain = minf(_music_duck_gain, 1.0 - priority * 0.38)
	_record_debug("duck", cue_id)


func _update_music_duck(delta: float) -> void:
	if _music_duck_remaining <= 0.0:
		_music_duck_gain = minf(_music_duck_gain + delta * 4.0, 1.0)
	else:
		_music_duck_remaining = maxf(_music_duck_remaining - delta, 0.0)
	_apply_music_profile_gain()


func _apply_music_profile_gain() -> void:
	if not _audio_playback_enabled or _music_player == null:
		return

	var profile: Dictionary = MUSIC_STATE_PROFILES.get(_music_state, {})
	var profile_gain := clampf(float(profile.get("music_gain", 0.65)), 0.0, 1.0)
	var final_gain := clampf(profile_gain * _music_duck_gain, 0.0, 1.0)
	_music_player.volume_db = linear_to_db(maxf(final_gain, 0.001))


func _release_player(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return

	player.stop()
	player.stream = null
	if player.get_parent() == self:
		remove_child(player)
	player.free()


func _record_debug(entry_type: String, value: String) -> void:
	_debug_history.append({
		"type": entry_type,
		"value": value,
	})


func _set_bus_volume_linear(bus_name: String, next_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		if bus_name == "Master":
			return
		_ensure_bus(bus_name)
		bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var normalized_volume := clampf(next_volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, _linear_to_db_safe(normalized_volume))


func _get_bus_volume_linear(bus_name: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return 1.0
	return _db_to_linear_safe(AudioServer.get_bus_volume_db(bus_index))


func _linear_to_db_safe(value: float) -> float:
	var normalized_value := clampf(value, 0.0, 1.0)
	if normalized_value <= 0.0:
		return MIN_VOLUME_DB
	return linear_to_db(normalized_value)


func _db_to_linear_safe(value_db: float) -> float:
	if value_db <= MIN_VOLUME_DB:
		return 0.0
	return clampf(db_to_linear(value_db), 0.0, 1.0)
