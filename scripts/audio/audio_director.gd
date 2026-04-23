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

const UI_PLAYER_COUNT := 3
const SFX_PLAYER_COUNT := 6

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audio_playback_enabled = DisplayServer.get_name() != "headless"
	_ensure_bus("UI")
	_ensure_bus("SFX")
	_ensure_bus("Music")
	if _audio_playback_enabled:
		_build_players()


func _process(_delta: float) -> void:
	if not _audio_playback_enabled:
		return
	if _music_state == "" or _music_player == null:
		return
	if _music_player.playing:
		return

	_music_player.stream = _cue_bank.get_music_stream(_music_state)
	_music_player.play()


func _exit_tree() -> void:
	_shutdown_audio_graph()


func play_cue(cue_id: String) -> void:
	var cue_stream := _cue_bank.get_cue_stream(cue_id)
	if cue_stream == null:
		return

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
	_music_player.play()


func get_music_state() -> String:
	return _music_state


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
