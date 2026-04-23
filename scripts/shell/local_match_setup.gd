extends Control
class_name LocalMatchSetup

const MatchController = preload("res://scripts/systems/match_controller.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal back_requested
signal characters_requested
signal how_to_play_requested
signal start_requested(launch_config: MatchLaunchConfig)

const DEFAULT_LOCAL_SLOTS := [1, 2, 3, 4]

@onready var backdrop: ColorRect = $Backdrop
@onready var mode_value_label: Label = %ModeValueLabel
@onready var slot_summary_label: Label = %SlotSummaryLabel
@onready var teams_button: Button = %TeamsButton
@onready var ffa_button: Button = %FFAButton
@onready var slot_buttons: Array[Button] = [
	%Slot1Button,
	%Slot2Button,
	%Slot3Button,
	%Slot4Button,
]
@onready var start_button: Button = %StartButton
@onready var characters_button: Button = %CharactersButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var back_button: Button = %BackButton

var _match_mode: MatchController.MatchMode = MatchController.MatchMode.TEAMS
var _slot_control_modes := {}


func _ready() -> void:
	_install_qa_ids()
	backdrop.color = DEFAULT_PRESENTATION_PALETTE.surface_background_alt
	for slot in DEFAULT_LOCAL_SLOTS:
		_slot_control_modes[slot] = RobotBase.ControlMode.EASY

	teams_button.pressed.connect(func() -> void:
		set_match_mode(MatchController.MatchMode.TEAMS)
	)
	ffa_button.pressed.connect(func() -> void:
		set_match_mode(MatchController.MatchMode.FFA)
	)
	for index in range(slot_buttons.size()):
		var slot := index + 1
		slot_buttons[index].pressed.connect(func() -> void:
			toggle_slot_control_mode(slot)
		)
	characters_button.pressed.connect(_on_characters_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	start_button.text = "Iniciar"
	characters_button.text = "Characters"
	how_to_play_button.text = "How to Play"
	back_button.text = "Volver"
	_refresh_view()


func set_match_mode(next_match_mode: MatchController.MatchMode) -> void:
	_match_mode = next_match_mode
	_refresh_view()


func toggle_slot_control_mode(player_slot: int) -> void:
	if not _slot_control_modes.has(player_slot):
		return

	var next_mode := RobotBase.ControlMode.HARD
	if int(_slot_control_modes[player_slot]) == RobotBase.ControlMode.HARD:
		next_mode = RobotBase.ControlMode.EASY
	_slot_control_modes[player_slot] = next_mode
	_refresh_view()


func build_launch_config() -> MatchLaunchConfig:
	var launch_config := MatchLaunchConfig.new()
	launch_config.hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT
	launch_config.configure_for_local_match(
		_match_mode,
		_resolve_target_scene_path(),
		_build_slot_specs()
	)
	return launch_config


func get_slot_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	for player_slot in DEFAULT_LOCAL_SLOTS:
		var control_mode := int(_slot_control_modes.get(player_slot, RobotBase.ControlMode.EASY))
		var mode_label := "Hard" if control_mode == RobotBase.ControlMode.HARD else "Easy"
		lines.append("P%s | %s | teclado local" % [player_slot, mode_label])

	return lines


func _refresh_view() -> void:
	mode_value_label.text = "FFA" if _match_mode == MatchController.MatchMode.FFA else "Equipos"
	teams_button.disabled = _match_mode == MatchController.MatchMode.TEAMS
	ffa_button.disabled = _match_mode == MatchController.MatchMode.FFA
	slot_summary_label.text = "\n".join(get_slot_summary_lines())
	for index in range(slot_buttons.size()):
		var player_slot := index + 1
		var control_mode := int(_slot_control_modes.get(player_slot, RobotBase.ControlMode.EASY))
		var mode_label := "Hard" if control_mode == RobotBase.ControlMode.HARD else "Easy"
		slot_buttons[index].text = "P%s: %s" % [player_slot, mode_label]


func _build_slot_specs() -> Array:
	var slot_specs: Array = []
	for player_slot in DEFAULT_LOCAL_SLOTS:
		slot_specs.append({
			"slot": player_slot,
			"control_mode": int(_slot_control_modes.get(player_slot, RobotBase.ControlMode.EASY)),
		})

	return slot_specs


func _resolve_target_scene_path() -> String:
	if _match_mode == MatchController.MatchMode.FFA:
		return "res://scenes/main/main_ffa.tscn"

	return "res://scenes/main/main.tscn"


func _on_start_pressed() -> void:
	start_requested.emit(build_launch_config())


func _on_characters_pressed() -> void:
	characters_requested.emit()


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_how_to_play_pressed() -> void:
	how_to_play_requested.emit()


func focus_characters_button() -> void:
	if characters_button != null:
		characters_button.grab_focus()


func focus_how_to_play_button() -> void:
	if how_to_play_button != null:
		how_to_play_button.grab_focus()


func _install_qa_ids() -> void:
	mode_value_label.set_meta("qa_id", "shell_local_setup_mode")
	slot_summary_label.set_meta("qa_id", "shell_local_setup_slots")
	teams_button.set_meta("qa_id", "shell_local_setup_teams")
	ffa_button.set_meta("qa_id", "shell_local_setup_ffa")
	start_button.set_meta("qa_id", "shell_local_setup_start")
	characters_button.set_meta("qa_id", "shell_local_setup_characters")
	how_to_play_button.set_meta("qa_id", "shell_local_setup_how_to_play")
	back_button.set_meta("qa_id", "shell_local_setup_back")
