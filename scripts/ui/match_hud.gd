extends CanvasLayer
class_name MatchHud

@onready var status_label: Label = %StatusLabel
@onready var round_label: Label = %RoundLabel
@onready var roster_label: Label = %RosterLabel
@onready var recap_panel: Control = %RecapPanel
@onready var recap_title_label: Label = %RecapTitleLabel
@onready var recap_label: Label = %RecapLabel
@onready var match_result_panel: Control = %MatchResultPanel
@onready var match_result_title_label: Label = %MatchResultTitleLabel
@onready var match_result_label: Label = %MatchResultLabel
@onready var pause_panel: Control = %PausePanel
@onready var pause_title_label: Label = %PauseTitleLabel
@onready var pause_label: Label = %PauseLabel


func _ready() -> void:
	_install_qa_ids()
	show_status("Friction Zero: prototipo base")
	show_recap("", [])
	show_match_result("", [])
	show_pause_overlay("", [])


func show_status(message: String) -> void:
	# El HUD empieza minimo. La informacion final debe ser legible y no tapar el combate.
	status_label.text = message


func show_round_state(lines: Array[String]) -> void:
	round_label.text = "\n".join(lines)


func show_roster(lines: Array[String]) -> void:
	roster_label.text = "\n".join(lines)


func show_recap(title: String, lines: Array[String]) -> void:
	var should_show := title != "" and not lines.is_empty()
	recap_panel.visible = should_show
	if not should_show:
		recap_title_label.text = ""
		recap_label.text = ""
		return

	recap_title_label.text = title
	recap_label.text = "\n".join(lines)


func show_match_result(title: String, lines: Array[String]) -> void:
	var should_show := title != "" and not lines.is_empty()
	match_result_panel.visible = should_show
	if not should_show:
		match_result_title_label.text = ""
		match_result_label.text = ""
		return

	match_result_title_label.text = title
	match_result_label.text = "\n".join(lines)


func show_pause_overlay(title: String, lines: Array[String]) -> void:
	var should_show := title != "" and not lines.is_empty()
	pause_panel.visible = should_show
	if not should_show:
		pause_title_label.text = ""
		pause_label.text = ""
		return

	pause_title_label.text = title
	pause_label.text = "\n".join(lines)


func _install_qa_ids() -> void:
	status_label.set_meta("qa_id", "match_hud_status")
	round_label.set_meta("qa_id", "match_hud_round")
	roster_label.set_meta("qa_id", "match_hud_roster")
	recap_panel.set_meta("qa_id", "match_hud_recap_panel")
	match_result_panel.set_meta("qa_id", "match_hud_result_panel")
	pause_panel.set_meta("qa_id", "match_hud_pause_panel")
