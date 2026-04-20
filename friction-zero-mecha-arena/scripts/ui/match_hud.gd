extends CanvasLayer
class_name MatchHud

@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	show_status("Friction Zero: prototipo base")


func show_status(message: String) -> void:
	# El HUD empieza minimo. La informacion final debe ser legible y no tapar el combate.
	status_label.text = message
