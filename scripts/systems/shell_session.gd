extends RefCounted
class_name ShellSession

const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")

static var _pending_match_launch_config: MatchLaunchConfig = null


func store_match_launch_config(launch_config: MatchLaunchConfig) -> void:
	if launch_config == null:
		_pending_match_launch_config = null
		return

	_pending_match_launch_config = launch_config.duplicate_for_runtime()


func consume_match_launch_config() -> MatchLaunchConfig:
	var launch_config := _pending_match_launch_config
	_pending_match_launch_config = null
	if launch_config == null:
		return null

	return launch_config.duplicate_for_runtime()
