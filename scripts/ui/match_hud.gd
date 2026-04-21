extends CanvasLayer
class_name MatchHud

@onready var status_label: Label = %StatusLabel
@onready var round_label: Label = %RoundLabel
@onready var roster_label: Label = %RosterLabel


func _ready() -> void:
	show_status("Friction Zero: prototipo base")


func show_status(message: String) -> void:
	# El HUD empieza minimo. La informacion final debe ser legible y no tapar el combate.
	status_label.text = message


func show_round_state(lines: Array[String]) -> void:
	round_label.text = "\n".join(lines)


func show_roster(lines: Array[String]) -> void:
	roster_label.text = "\n".join(lines)
