extends Node

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MAIN_FFA_SCENE := preload("res://scenes/main/main_ffa.tscn")


func _ready() -> void:
	var main := MAIN_FFA_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame

	var match_controller := main.get_node_or_null("Systems/MatchController") as MatchController
	var robot_root := main.get_node_or_null("RobotRoot")
	if match_controller == null or robot_root == null or robot_root.get_child_count() < 4:
		push_error("M11 aftermath QA necesita FFA con MatchController y cuatro robots.")
		return

	match_controller.match_mode = MatchController.MatchMode.FFA
	match_controller.match_config.rounds_to_win = 3
	match_controller.match_config.round_intro_duration_ffa = 0.0
	match_controller.round_intro_duration = 0.0
	match_controller.start_match()
	await get_tree().process_frame

	for child in robot_root.get_children():
		child.void_fall_y = -100.0
	robot_root.get_child(0).fall_into_void()
	await get_tree().process_frame
