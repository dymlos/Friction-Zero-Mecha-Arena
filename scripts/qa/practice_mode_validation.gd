extends Node

const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const ShellSession = preload("res://scripts/systems/shell_session.gd")
const PRACTICE_MODE_SCENE := preload("res://scenes/practice/practice_mode.tscn")

const MODULE_SEQUENCE := [
	"movimiento",
	"impacto",
	"sandbox",
]

var _active_practice_mode: Node = null
var _frame_count := 0
var _next_switch_index := 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_show_module(MODULE_SEQUENCE[0])


func _process(_delta: float) -> void:
	_frame_count += 1
	if _next_switch_index >= MODULE_SEQUENCE.size():
		return

	if _frame_count == 30:
		_show_module(MODULE_SEQUENCE[_next_switch_index])
		_next_switch_index += 1
	elif _frame_count == 60:
		_show_module(MODULE_SEQUENCE[_next_switch_index])
		_next_switch_index += 1


func _show_module(module_id: String) -> void:
	if is_instance_valid(_active_practice_mode):
		remove_child(_active_practice_mode)
		_active_practice_mode.queue_free()
		_active_practice_mode = null

	var shell_session := ShellSession.new()
	var launch_config := MatchLaunchConfig.new()
	launch_config.configure_for_practice(
		module_id,
		"res://scenes/practice/practice_mode.tscn",
		[{"slot": 1, "control_mode": 0}]
	)
	shell_session.store_match_launch_config(launch_config)
	var practice_mode := PRACTICE_MODE_SCENE.instantiate()
	add_child(practice_mode)
	_active_practice_mode = practice_mode
