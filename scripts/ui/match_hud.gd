extends CanvasLayer
class_name MatchHud

@onready var status_label: Label = %StatusLabel
@onready var round_label: Label = %RoundLabel
@onready var roster_label: Label = %RosterLabel
@onready var recap_panel: Control = %RecapPanel
@onready var recap_title_label: Label = %RecapTitleLabel
@onready var recap_label: Label = %RecapLabel


func _ready() -> void:
	show_status("Friction Zero: prototipo base")
	show_recap("", [])


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
