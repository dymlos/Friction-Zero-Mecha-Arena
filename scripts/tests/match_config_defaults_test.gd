extends SceneTree

const MatchConfig = preload("res://scripts/systems/match_config.gd")
const DEFAULT_MATCH_CONFIG := preload("res://data/config/default_match_config.tres")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runtime_defaults := MatchConfig.new()
	var shipped_defaults := DEFAULT_MATCH_CONFIG as MatchConfig

	_assert(shipped_defaults != null, "El recurso default_match_config.tres deberia cargar como MatchConfig.")
	if shipped_defaults == null:
		_finish()
		return

	_assert(
		runtime_defaults.local_player_count == shipped_defaults.local_player_count,
		"`MatchConfig.new()` deberia conservar el mismo local_player_count que el config base del prototipo."
	)
	_assert(
		runtime_defaults.round_intro_duration_ffa == shipped_defaults.round_intro_duration_ffa,
		"`MatchConfig.new()` deberia conservar el intro FFA del config base del prototipo."
	)
	_assert(
		runtime_defaults.round_intro_duration_teams == shipped_defaults.round_intro_duration_teams,
		"`MatchConfig.new()` deberia conservar el intro Teams del config base del prototipo."
	)
	_assert(
		runtime_defaults.void_elimination_round_points == shipped_defaults.void_elimination_round_points,
		"`MatchConfig.new()` deberia conservar el score por vacio del config base del prototipo."
	)
	_assert(
		runtime_defaults.destruction_elimination_round_points == shipped_defaults.destruction_elimination_round_points,
		"`MatchConfig.new()` deberia conservar el score por destruccion total del config base del prototipo."
	)
	_assert(
		runtime_defaults.unstable_elimination_round_points == shipped_defaults.unstable_elimination_round_points,
		"`MatchConfig.new()` deberia conservar el score por explosion inestable del config base del prototipo."
	)

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
