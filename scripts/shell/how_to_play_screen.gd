extends Control
class_name HowToPlayScreen

const OnboardingCatalog = preload("res://scripts/systems/onboarding_catalog.gd")
const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal back_requested
signal practice_requested(module_id: String)

const SURFACE_SCOPE_GLOBAL := "global"
const SURFACE_SCOPE_PAUSE := "pause"

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
var _surface_scope := SURFACE_SCOPE_GLOBAL


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
	_apply_surface_scope()
	if not _sections.is_empty():
		_select_index(0)
	call_deferred("_focus_initial_list")


func set_surface_scope(scope_id: String) -> void:
	if not [SURFACE_SCOPE_GLOBAL, SURFACE_SCOPE_PAUSE].has(scope_id):
		scope_id = SURFACE_SCOPE_GLOBAL
	_surface_scope = scope_id
	_apply_surface_scope()


func get_selected_topic_id() -> String:
	if _selected_index < 0 or _selected_index >= _sections.size():
		return ""

	return String(_sections[_selected_index].get("id", ""))


func focus_back_button() -> void:
	if back_button != null:
		back_button.grab_focus()


func open_selected_topic_practice() -> void:
	if _surface_scope == SURFACE_SCOPE_PAUSE:
		return
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
	practice_button.disabled = _surface_scope == SURFACE_SCOPE_PAUSE or practice_module_id.is_empty()
	practice_button.text = _get_practice_button_label(practice_module_id)
	_apply_surface_scope()


func _on_topic_selected(index: int) -> void:
	_select_index(index)


func _focus_initial_list() -> void:
	if topic_list == null:
		return

	topic_list.grab_focus()


func focus_practice_button() -> void:
	if practice_button != null and not practice_button.disabled:
		practice_button.grab_focus()


func _apply_surface_scope() -> void:
	if not is_node_ready():
		return
	var pause_scope := _surface_scope == SURFACE_SCOPE_PAUSE
	practice_button.visible = not pause_scope
	if pause_scope:
		practice_button.disabled = true
	subtitle_label.text = (
		"Lectura breve de reglas durante pausa. Practica queda fuera del match congelado."
		if pause_scope
		else "Reglas base del match, controles Easy/Hard y lectura general sin repetir identidad de Characters."
	)


func _install_qa_ids() -> void:
	title_label.set_meta("qa_id", "shell_how_to_play_title")
	topic_list.set_meta("qa_id", "shell_how_to_play_list")
	detail_title_label.set_meta("qa_id", "shell_how_to_play_detail_title")
	summary_value_label.set_meta("qa_id", "shell_how_to_play_summary")
	bullets_value_label.set_meta("qa_id", "shell_how_to_play_bullets")
	callout_value_label.set_meta("qa_id", "shell_how_to_play_callout")
	practice_button.set_meta("qa_id", "shell_how_to_play_practice")
	back_button.set_meta("qa_id", "shell_how_to_play_back")


func _get_practice_button_label(module_id: String) -> String:
	if module_id.is_empty():
		return "Probar"

	var module_spec := PracticeCatalog.get_module(module_id)
	var module_label := String(module_spec.get("label", ""))
	if module_label.is_empty():
		module_label = module_id.capitalize()

	return "Probar %s" % module_label
