extends Control
class_name PracticeSetup

const OnboardingCatalog = preload("res://scripts/systems/onboarding_catalog.gd")
const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal back_requested
signal start_requested

@onready var backdrop: ColorRect = $Backdrop
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var module_list: ItemList = %ModuleList
@onready var module_title_label: Label = %ModuleTitleLabel
@onready var summary_value_label: Label = %SummaryValueLabel
@onready var recommended_value_label: Label = %RecommendedValueLabel
@onready var related_topics_value_label: Label = %RelatedTopicsValueLabel
@onready var slots_summary_label: Label = %SlotsSummaryLabel
@onready var slot_buttons: Array[Button] = [%Slot1Button, %Slot2Button]
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton

const DEFAULT_LOCAL_SLOTS := [1, 2]

var _modules: Array = []
var _selected_index := -1
var _slot_control_modes := {}


func _ready() -> void:
	_install_qa_ids()
	backdrop.color = DEFAULT_PRESENTATION_PALETTE.surface_background_alt
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = "Practica"
	subtitle_label.text = "Modulos cortos para probar sistemas sin duplicar la lectura base de Characters ni How to Play."
	back_button.text = "Volver"
	start_button.text = "Entrar"
	module_list.item_selected.connect(_on_module_selected)
	back_button.pressed.connect(func() -> void:
		back_requested.emit()
	)
	start_button.disabled = true
	for slot in DEFAULT_LOCAL_SLOTS:
		_slot_control_modes[slot] = RobotBase.ControlMode.EASY
	for index in range(slot_buttons.size()):
		var slot := index + 1
		slot_buttons[index].pressed.connect(func() -> void:
			toggle_slot_control_mode(slot)
		)

	_modules = PracticeCatalog.get_modules()
	_rebuild_module_list()
	if not _modules.is_empty():
		_select_index(0)
	call_deferred("_focus_initial_list")


func set_selected_module(module_id: String) -> void:
	for index in range(_modules.size()):
		if String(_modules[index].get("id", "")) == module_id:
			_select_index(index)
			return

	if not _modules.is_empty():
		_select_index(0)


func get_selected_module_id() -> String:
	if _selected_index < 0 or _selected_index >= _modules.size():
		return ""

	return String(_modules[_selected_index].get("id", ""))


func get_recommended_robot_label() -> String:
	var module_spec := _get_selected_module()
	var roster_entry_id := String(module_spec.get("recommended_roster_entry_id", ""))
	return RosterCatalog.get_shell_roster_entry_label(roster_entry_id)


func get_related_topic_labels() -> Array[String]:
	var labels: Array[String] = []
	for topic_id_variant in _get_selected_module().get("onboarding_topic_ids", []):
		var topic_id := String(topic_id_variant)
		var section := OnboardingCatalog.get_section(topic_id)
		var label := String(section.get("label", ""))
		if not label.is_empty():
			labels.append(label)

	return labels


func focus_back_button() -> void:
	if back_button != null:
		back_button.grab_focus()


func toggle_slot_control_mode(player_slot: int) -> void:
	if not _slot_control_modes.has(player_slot):
		return

	var next_mode := RobotBase.ControlMode.HARD
	if int(_slot_control_modes[player_slot]) == RobotBase.ControlMode.HARD:
		next_mode = RobotBase.ControlMode.EASY
	_slot_control_modes[player_slot] = next_mode
	_refresh_slot_summary()


func _rebuild_module_list() -> void:
	module_list.clear()
	for module_spec in _modules:
		module_list.add_item(String(module_spec.get("label", "")))


func _select_index(index: int) -> void:
	if index < 0 or index >= _modules.size():
		return

	_selected_index = index
	module_list.select(index)
	_apply_module(_modules[index])


func _apply_module(module_spec: Dictionary) -> void:
	module_title_label.text = String(module_spec.get("label", ""))
	summary_value_label.text = String(module_spec.get("summary", ""))
	recommended_value_label.text = get_recommended_robot_label()
	related_topics_value_label.text = " · ".join(get_related_topic_labels())
	_refresh_slot_summary()


func _refresh_slot_summary() -> void:
	var lines: PackedStringArray = []
	for index in range(slot_buttons.size()):
		var player_slot := index + 1
		var control_mode := int(_slot_control_modes.get(player_slot, RobotBase.ControlMode.EASY))
		var mode_label := "Hard" if control_mode == RobotBase.ControlMode.HARD else "Easy"
		slot_buttons[index].text = "P%s: %s" % [player_slot, mode_label]
		lines.append("P%s listo | %s" % [player_slot, mode_label])

	slots_summary_label.text = "\n".join(lines)


func _get_selected_module() -> Dictionary:
	if _selected_index < 0 or _selected_index >= _modules.size():
		return {}

	return _modules[_selected_index]


func _on_module_selected(index: int) -> void:
	_select_index(index)


func _focus_initial_list() -> void:
	if module_list != null:
		module_list.grab_focus()


func _install_qa_ids() -> void:
	module_list.set_meta("qa_id", "shell_practice_setup_list")
	module_title_label.set_meta("qa_id", "shell_practice_setup_title")
	recommended_value_label.set_meta("qa_id", "shell_practice_setup_recommended")
	related_topics_value_label.set_meta("qa_id", "shell_practice_setup_topics")
	back_button.set_meta("qa_id", "shell_practice_setup_back")
