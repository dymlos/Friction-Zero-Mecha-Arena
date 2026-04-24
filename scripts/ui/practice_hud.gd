extends Control
class_name PracticeHud

@onready var module_value_label: Label = %ModuleValueLabel
@onready var panel: PanelContainer = $Root/Panel
@onready var objective_value_label: Label = %ObjectiveValueLabel
@onready var progress_value_label: Label = %ProgressValueLabel
@onready var context_card_title_label: Label = %ContextCardTitleLabel
@onready var context_card_value_label: Label = %ContextCardValueLabel
@onready var controls_value_label: Label = %ControlsValueLabel
@onready var callout_value_label: Label = %CalloutValueLabel
@onready var pause_value_label: Label = %PauseValueLabel

var _explicit_mode := true


func _ready() -> void:
	_install_qa_ids()


func set_module_title(module_label: String) -> void:
	module_value_label.text = module_label


func set_objective_lines(lines: Array) -> void:
	objective_value_label.text = "\n".join(lines)


func set_progress_text(text: String) -> void:
	progress_value_label.text = text


func set_progress_lines(lines: Array) -> void:
	progress_value_label.text = "\n".join(lines)


func set_controls_lines(lines: Array) -> void:
	controls_value_label.text = "\n".join(lines)


func set_context_card_title(title: String) -> void:
	context_card_title_label.text = title


func set_context_card_lines(lines: Array) -> void:
	context_card_value_label.text = "\n".join(lines)


func set_callout_lines(lines: Array) -> void:
	callout_value_label.text = "\n".join(lines)


func set_pause_lines(lines: Array) -> void:
	pause_value_label.text = "\n".join(lines)


func set_explicit_mode(enabled: bool) -> void:
	_explicit_mode = enabled
	if context_card_title_label != null:
		context_card_title_label.visible = enabled
	if context_card_value_label != null:
		context_card_value_label.visible = enabled


func is_explicit_layout() -> bool:
	return _explicit_mode


func _install_qa_ids() -> void:
	panel.set_meta("qa_id", "practice_hud_panel")
	module_value_label.set_meta("qa_id", "practice_hud_module")
	objective_value_label.set_meta("qa_id", "practice_hud_objective")
	progress_value_label.set_meta("qa_id", "practice_hud_progress")
	context_card_title_label.set_meta("qa_id", "practice_hud_context_title")
	context_card_value_label.set_meta("qa_id", "practice_hud_context_card")
	controls_value_label.set_meta("qa_id", "practice_hud_controls")
	callout_value_label.set_meta("qa_id", "practice_hud_callout")
	pause_value_label.set_meta("qa_id", "practice_hud_pause")
