extends Control
class_name CharactersScreen

const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal back_requested

@onready var backdrop: ColorRect = $Backdrop
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var character_list: ItemList = %CharacterList
@onready var accent_panel: ColorRect = %AccentPanel
@onready var name_label: Label = %NameLabel
@onready var role_value_label: Label = %RoleValueLabel
@onready var fantasy_value_label: Label = %FantasyValueLabel
@onready var strength_value_label: Label = %StrengthValueLabel
@onready var risk_value_label: Label = %RiskValueLabel
@onready var signature_value_label: Label = %SignatureValueLabel
@onready var body_read_value_label: Label = %BodyReadValueLabel
@onready var easy_value_label: Label = %EasyValueLabel
@onready var hard_value_label: Label = %HardValueLabel
@onready var back_button: Button = %BackButton

var _roster: Array = []
var _selected_index := -1


func _ready() -> void:
	_install_qa_ids()
	backdrop.color = DEFAULT_PRESENTATION_PALETTE.surface_background
	title_label.text = "Characters"
	subtitle_label.text = "Roster base visible hoy en shell. Identidad por robot, sin mezclar reglas generales del match."
	back_button.text = "Volver"
	back_button.pressed.connect(go_back)
	character_list.item_selected.connect(_on_character_selected)
	_roster = RosterCatalog.get_shell_roster()
	_rebuild_list()
	if not _roster.is_empty():
		_select_index(0)
	call_deferred("_focus_initial_list")


func get_selected_character_label() -> String:
	if _selected_index < 0 or _selected_index >= _roster.size():
		return ""

	return String(_roster[_selected_index].get("label", ""))


func focus_back_button() -> void:
	if back_button != null:
		back_button.grab_focus()


func go_back() -> void:
	back_requested.emit()


func _rebuild_list() -> void:
	character_list.clear()
	for entry in _roster:
		character_list.add_item(String(entry.get("label", "")))


func _select_index(index: int) -> void:
	if index < 0 or index >= _roster.size():
		return

	_selected_index = index
	character_list.select(index)
	_apply_entry(_roster[index])


func _apply_entry(entry: Dictionary) -> void:
	var accent_color := entry.get("accent_color", Color.WHITE) as Color
	accent_panel.color = accent_color
	name_label.text = String(entry.get("label", ""))
	name_label.modulate = accent_color.lightened(0.12)
	role_value_label.text = String(entry.get("role", ""))
	fantasy_value_label.text = String(entry.get("fantasy", ""))
	strength_value_label.text = String(entry.get("strength", ""))
	risk_value_label.text = String(entry.get("risk", ""))
	signature_value_label.text = String(entry.get("signature", ""))
	body_read_value_label.text = String(entry.get("body_read", ""))
	easy_value_label.text = String(entry.get("easy", ""))
	hard_value_label.text = String(entry.get("hard", ""))


func _on_character_selected(index: int) -> void:
	_select_index(index)


func _focus_initial_list() -> void:
	if character_list == null:
		return

	character_list.grab_focus()


func _install_qa_ids() -> void:
	title_label.set_meta("qa_id", "shell_characters_title")
	character_list.set_meta("qa_id", "shell_characters_list")
	name_label.set_meta("qa_id", "shell_characters_name")
	signature_value_label.set_meta("qa_id", "shell_characters_signature")
	back_button.set_meta("qa_id", "shell_characters_back")
