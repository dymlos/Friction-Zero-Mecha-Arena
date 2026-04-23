extends Control
class_name HowToPlayScreen

const OnboardingCatalog = preload("res://scripts/systems/onboarding_catalog.gd")
const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal back_requested
signal practice_requested(module_id: String)

@onready var backdrop: ColorRect = $Backdrop
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var topic_list: ItemList = %TopicList
@onready var detail_title_label: Label = %DetailTitleLabel
@onready var summary_value_label: Label = %SummaryValueLabel
@onready var bullets_value_label: Label = %BulletsValueLabel
@onready var callout_value_label: Label = %CalloutValueLabel
@onready var practice_button: Button = %PracticeButton
@onready var back_button: Button = %BackButton

var _sections: Array = []
var _selected_index := -1


func _ready() -> void:
	_install_qa_ids()
	backdrop.color = DEFAULT_PRESENTATION_PALETTE.surface_background_alt
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = "How to Play"
	subtitle_label.text = "Reglas base del match, controles Easy/Hard y lectura general sin repetir identidad de Characters."
	practice_button.pressed.connect(open_selected_topic_practice)
	back_button.text = "Volver"
	back_button.pressed.connect(go_back)
	topic_list.item_selected.connect(_on_topic_selected)
	_sections = OnboardingCatalog.get_sections()
	_rebuild_list()
	if not _sections.is_empty():
		_select_index(0)
	call_deferred("_focus_initial_list")


func get_selected_topic_id() -> String:
	if _selected_index < 0 or _selected_index >= _sections.size():
		return ""

	return String(_sections[_selected_index].get("id", ""))


func focus_back_button() -> void:
	if back_button != null:
		back_button.grab_focus()


func open_selected_topic_practice() -> void:
	var module_id := OnboardingCatalog.get_practice_module_id_for_section(get_selected_topic_id())
	if module_id.is_empty():
		return

	practice_requested.emit(module_id)


func go_back() -> void:
	back_requested.emit()


func _rebuild_list() -> void:
	topic_list.clear()
	for section in _sections:
		topic_list.add_item(String(section.get("label", "")))


func _select_index(index: int) -> void:
	if index < 0 or index >= _sections.size():
		return

	_selected_index = index
	topic_list.select(index)
	_apply_section(_sections[index])


func _apply_section(section: Dictionary) -> void:
	detail_title_label.text = String(section.get("label", ""))
	summary_value_label.text = String(section.get("summary", ""))
	var bullets := PackedStringArray()
	for bullet in section.get("bullets", []):
		bullets.append("- %s" % String(bullet))
	bullets_value_label.text = "\n".join(bullets)
	callout_value_label.text = String(section.get("callout", ""))
	var practice_module_id := String(section.get("practice_module_id", ""))
	practice_button.disabled = practice_module_id.is_empty()
	practice_button.text = "Probar %s" % practice_module_id.capitalize()


func _on_topic_selected(index: int) -> void:
	_select_index(index)


func _focus_initial_list() -> void:
	if topic_list == null:
		return

	topic_list.grab_focus()


func _install_qa_ids() -> void:
	title_label.set_meta("qa_id", "shell_how_to_play_title")
	topic_list.set_meta("qa_id", "shell_how_to_play_list")
	detail_title_label.set_meta("qa_id", "shell_how_to_play_detail_title")
	summary_value_label.set_meta("qa_id", "shell_how_to_play_summary")
	callout_value_label.set_meta("qa_id", "shell_how_to_play_callout")
	practice_button.set_meta("qa_id", "shell_how_to_play_practice")
	back_button.set_meta("qa_id", "shell_how_to_play_back")
