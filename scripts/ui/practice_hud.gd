extends Control
class_name PracticeHud

@onready var module_value_label: Label = %ModuleValueLabel
@onready var objective_value_label: Label = %ObjectiveValueLabel
@onready var progress_value_label: Label = %ProgressValueLabel
@onready var controls_value_label: Label = %ControlsValueLabel
@onready var pause_value_label: Label = %PauseValueLabel


func set_module_title(module_label: String) -> void:
	module_value_label.text = module_label


func set_objective_lines(lines: Array[String]) -> void:
	objective_value_label.text = "\n".join(lines)


func set_progress_text(text: String) -> void:
	progress_value_label.text = text


func set_controls_lines(lines: Array[String]) -> void:
	controls_value_label.text = "\n".join(lines)


func set_pause_lines(lines: Array[String]) -> void:
	pause_value_label.text = "\n".join(lines)
