extends Control
class_name CharactersScreen

const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal back_requested

@onready var backdrop: ColorRect = $Backdrop
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var all_filter_button: Button = %AllFilterButton
@onready var impact_filter_button: Button = %ImpactFilterButton
@onready var range_zone_filter_button: Button = %RangeZoneFilterButton
@onready var character_list: ItemList = %CharacterList
@onready var accent_panel: ColorRect = %AccentPanel
@onready var name_label: Label = %NameLabel
@onready var role_value_label: Label = %RoleValueLabel
@onready var ffa_mode_value_label: Label = %FfaModeValueLabel
@onready var teams_mode_value_label: Label = %TeamsModeValueLabel
@onready var fantasy_value_label: Label = %FantasyValueLabel
@onready var strength_value_label: Label = %StrengthValueLabel
@onready var risk_value_label: Label = %RiskValueLabel
@onready var signature_value_label: Label = %SignatureValueLabel
@onready var body_read_value_label: Label = %BodyReadValueLabel
@onready var easy_value_label: Label = %EasyValueLabel
@onready var hard_value_label: Label = %HardValueLabel
@onready var back_button: Button = %BackButton

var _roster: Array = []
var _visible_roster: Array = []
var _selected_index := -1
var _active_filter := "all"

const FILTER_ALL := "all"
const FILTER_IMPACT := "impact"
const FILTER_RANGE_ZONE := "range_zone"
const IMPACT_ENTRY_IDS := ["ariete", "cizalla", "patin"]
const RANGE_ZONE_ENTRY_IDS := ["aguja", "ancla", "grua"]


func _ready() -> void:
	_install_qa_ids()
	backdrop.color = DEFAULT_PRESENTATION_PALETTE.surface_background
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = "Characters"
	subtitle_label.text = "Roster competitivo visible. Identidad por robot, sin mezclar reglas generales del match."
	all_filter_button.text = "Todos"
	impact_filter_button.text = "Impacto"
	range_zone_filter_button.text = "Rango / zona"
	back_button.text = "Volver"
	back_button.pressed.connect(go_back)
	all_filter_button.pressed.connect(func() -> void:
		set_filter(FILTER_ALL)
	)
	impact_filter_button.pressed.connect(func() -> void:
		set_filter(FILTER_IMPACT)
	)
	range_zone_filter_button.pressed.connect(func() -> void:
		set_filter(FILTER_RANGE_ZONE)
	)
	character_list.item_selected.connect(_on_character_selected)
	_roster = RosterCatalog.get_shell_roster()
	_rebuild_list()
	if not _visible_roster.is_empty():
		_select_index(0)
	call_deferred("_focus_initial_list")


func get_selected_character_label() -> String:
	if _selected_index < 0 or _selected_index >= _visible_roster.size():
		return ""

	return String(_visible_roster[_selected_index].get("label", ""))


func get_visible_character_labels() -> Array:
	var labels: Array = []
	for entry in _visible_roster:
		labels.append(String(entry.get("label", "")))
	return labels


func get_detail_text() -> String:
	var lines := PackedStringArray([
		name_label.text,
		role_value_label.text,
		ffa_mode_value_label.text,
		teams_mode_value_label.text,
		fantasy_value_label.text,
		strength_value_label.text,
		risk_value_label.text,
		signature_value_label.text,
		body_read_value_label.text,
		easy_value_label.text,
		hard_value_label.text,
	])
	return "\n".join(lines)


func set_filter(filter_id: String) -> void:
	var previous_id := _get_selected_entry_id()
	if not [FILTER_ALL, FILTER_IMPACT, FILTER_RANGE_ZONE].has(filter_id):
		filter_id = FILTER_ALL

	_active_filter = filter_id
	_rebuild_list()
	_select_first_available(previous_id)


func select_character_by_id(entry_id: String) -> void:
	for index in range(_visible_roster.size()):
		if String(_visible_roster[index].get("id", "")) == entry_id:
			_select_index(index)
			return


func focus_back_button() -> void:
	if back_button != null:
		back_button.grab_focus()


func go_back() -> void:
	back_requested.emit()


func _rebuild_list() -> void:
	character_list.clear()
	_visible_roster = _filter_roster(_roster)
	for entry in _visible_roster:
		character_list.add_item(String(entry.get("label", "")))


func _select_index(index: int) -> void:
	if index < 0 or index >= _visible_roster.size():
		return

	_selected_index = index
	character_list.select(index)
	_apply_entry(_visible_roster[index])


func _apply_entry(entry: Dictionary) -> void:
	var accent_color := entry.get("accent_color", Color.WHITE) as Color
	accent_panel.color = accent_color
	name_label.text = String(entry.get("label", ""))
	name_label.modulate = accent_color.lightened(0.12)
	role_value_label.text = String(entry.get("role", ""))
	var mode_notes: Dictionary = entry.get("mode_notes", {})
	ffa_mode_value_label.text = "FFA | %s" % String(mode_notes.get("ffa", ""))
	teams_mode_value_label.text = "Teams | %s" % String(mode_notes.get("teams", ""))
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


func _filter_roster(roster: Array) -> Array:
	var entries: Array = []
	for entry in roster:
		var entry_id := String(entry.get("id", ""))
		if _active_filter == FILTER_ALL:
			entries.append(entry)
		elif _active_filter == FILTER_IMPACT and IMPACT_ENTRY_IDS.has(entry_id):
			entries.append(entry)
		elif _active_filter == FILTER_RANGE_ZONE and RANGE_ZONE_ENTRY_IDS.has(entry_id):
			entries.append(entry)
	return entries


func _select_first_available(preferred_entry_id: String = "") -> void:
	if not preferred_entry_id.is_empty():
		for index in range(_visible_roster.size()):
			if String(_visible_roster[index].get("id", "")) == preferred_entry_id:
				_select_index(index)
				return

	_selected_index = -1
	if not _visible_roster.is_empty():
		_select_index(0)


func _get_selected_entry_id() -> String:
	if _selected_index < 0 or _selected_index >= _visible_roster.size():
		return ""
	return String(_visible_roster[_selected_index].get("id", ""))


func _install_qa_ids() -> void:
	title_label.set_meta("qa_id", "shell_characters_title")
	all_filter_button.set_meta("qa_id", "shell_characters_filter_all")
	impact_filter_button.set_meta("qa_id", "shell_characters_filter_impact")
	range_zone_filter_button.set_meta("qa_id", "shell_characters_filter_range_zone")
	character_list.set_meta("qa_id", "shell_characters_list")
	name_label.set_meta("qa_id", "shell_characters_name")
	signature_value_label.set_meta("qa_id", "shell_characters_signature")
	ffa_mode_value_label.set_meta("qa_id", "shell_characters_mode_ffa")
	teams_mode_value_label.set_meta("qa_id", "shell_characters_mode_teams")
	back_button.set_meta("qa_id", "shell_characters_back")
