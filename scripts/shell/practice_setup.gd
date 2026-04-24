extends Control
class_name PracticeSetup

const OnboardingCatalog = preload("res://scripts/systems/onboarding_catalog.gd")
const LocalSessionDraft = preload("res://scripts/systems/local_session_draft.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const PracticeCatalog = preload("res://scripts/systems/practice_catalog.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const RosterCatalog = preload("res://scripts/systems/roster_catalog.gd")
const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal back_requested
signal start_requested(launch_config: MatchLaunchConfig)

@onready var backdrop: ColorRect = $Backdrop
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var module_list: ItemList = %ModuleList
@onready var module_title_label: Label = %ModuleTitleLabel
@onready var summary_value_label: Label = %SummaryValueLabel
@onready var recommended_value_label: Label = %RecommendedValueLabel
@onready var related_topics_value_label: Label = %RelatedTopicsValueLabel
@onready var context_card_value_label: Label = %ContextCardValueLabel
@onready var player_scope_value_label: Label = %PlayerScopeValueLabel
@onready var slots_summary_label: Label = %SlotsSummaryLabel
@onready var slot_buttons: Array[Button] = [%Slot1Button, %Slot2Button]
@onready var slot_roster_buttons: Array[Button] = [%Slot1RosterButton, %Slot2RosterButton]
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton

const DEFAULT_LOCAL_SLOTS := [1, 2]

var _modules: Array = []
var _selected_index := -1
var _session_draft := LocalSessionDraft.new()
var _preserve_existing_roster := false


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
	start_button.pressed.connect(_on_start_pressed)
	_session_draft.configure(2)
	for index in range(slot_buttons.size()):
		var slot := index + 1
		slot_buttons[index].pressed.connect(func() -> void:
			cycle_slot_state(slot)
		)
	for index in range(slot_roster_buttons.size()):
		var slot := index + 1
		slot_roster_buttons[index].pressed.connect(func() -> void:
			cycle_slot_roster_entry(slot)
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


func get_context_card_lines() -> Array[String]:
	var context_card: Dictionary = _get_selected_module().get("context_card", {})
	var lines: Array[String] = []
	for line in context_card.get("lines", []):
		var normalized := String(line).strip_edges()
		if not normalized.is_empty():
			lines.append(normalized)
	return lines


func get_player_scope_line() -> String:
	return "1-2 jugadores locales | HUD explicito | sin score competitivo"


func focus_back_button() -> void:
	if back_button != null:
		back_button.grab_focus()


func set_session_draft(session_draft: LocalSessionDraft) -> void:
	if session_draft == null:
		return
	_session_draft = session_draft
	_session_draft.configure(8)
	_refresh_slot_summary()


func set_preserve_existing_roster(preserve_existing_roster: bool) -> void:
	_preserve_existing_roster = preserve_existing_roster


func set_slot_active(player_slot: int, active: bool) -> void:
	_session_draft.set_slot_active(player_slot, active)
	_refresh_slot_summary()


func set_slot_control_mode(player_slot: int, control_mode: int) -> void:
	_session_draft.set_slot_control_mode(player_slot, control_mode)
	_refresh_slot_summary()


func set_slot_input_source(player_slot: int, input_source: String) -> void:
	_session_draft.set_slot_input_source(player_slot, input_source)
	_refresh_slot_summary()


func reserve_joypad_for_slot(player_slot: int, device_id: int, connected: bool = true) -> void:
	_session_draft.reserve_joypad_for_slot(player_slot, device_id, connected)
	_refresh_slot_summary()


func cycle_slot_state(player_slot: int) -> void:
	_session_draft.cycle_slot_state(player_slot)
	_refresh_slot_summary()


func cycle_slot_roster_entry(player_slot: int) -> void:
	_session_draft.cycle_slot_roster_entry(player_slot)
	_refresh_slot_summary()


func toggle_slot_control_mode(player_slot: int) -> void:
	_session_draft.toggle_slot_control_mode(player_slot)
	_refresh_slot_summary()


func build_launch_config() -> MatchLaunchConfig:
	var launch_config := MatchLaunchConfig.new()
	launch_config.configure_for_practice(
		get_selected_module_id(),
		"res://scenes/practice/practice_mode.tscn",
		_session_draft.build_active_slot_specs(DEFAULT_LOCAL_SLOTS.size())
	)
	return launch_config


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
	context_card_value_label.text = "\n".join(get_context_card_lines())
	player_scope_value_label.text = get_player_scope_line()
	if not _preserve_existing_roster:
		_session_draft.set_slot_roster_entry(1, String(module_spec.get("recommended_roster_entry_id", "")))
	_refresh_slot_summary()


func _refresh_slot_summary() -> void:
	var lines: PackedStringArray = []
	for index in range(slot_buttons.size()):
		var player_slot := index + 1
		var line := String(_session_draft.get_slot_summary_lines(DEFAULT_LOCAL_SLOTS.size())[index])
		slot_buttons[index].text = _build_slot_state_button_text(player_slot)
		slot_roster_buttons[index].text = _build_slot_roster_button_text(player_slot)
		lines.append(line)

	slots_summary_label.text = "\n".join(lines)


func _build_slot_state_button_text(player_slot: int) -> String:
	var slot_info := _session_draft.get_slot_info(player_slot)
	if not bool(slot_info.get("active", false)):
		return "P%s | activar" % player_slot
	var mode_label := "Hard" if int(slot_info.get("control_mode", RobotBase.ControlMode.EASY)) == RobotBase.ControlMode.HARD else "Easy"
	var input_source := String(slot_info.get("input_source", LocalSessionDraft.INPUT_SOURCE_KEYBOARD))
	if input_source == LocalSessionDraft.INPUT_SOURCE_JOYPAD:
		var connection_label := "ok" if bool(slot_info.get("device_connected", false)) else "sin joy"
		return "P%s | %s | %s" % [player_slot, mode_label, connection_label]
	return "P%s | %s | teclado" % [player_slot, mode_label]


func _build_slot_roster_button_text(player_slot: int) -> String:
	var slot_info := _session_draft.get_slot_info(player_slot)
	var roster_entry := RosterCatalog.get_competitive_entry(String(slot_info.get("roster_entry_id", "")))
	return String(roster_entry.get("label", slot_info.get("roster_entry_id", "")))


func _get_selected_module() -> Dictionary:
	if _selected_index < 0 or _selected_index >= _modules.size():
		return {}

	return _modules[_selected_index]


func _on_module_selected(index: int) -> void:
	_select_index(index)


func _on_start_pressed() -> void:
	start_requested.emit(build_launch_config())


func _focus_initial_list() -> void:
	if module_list != null:
		module_list.grab_focus()


func _install_qa_ids() -> void:
	module_list.set_meta("qa_id", "shell_practice_setup_list")
	module_title_label.set_meta("qa_id", "shell_practice_setup_title")
	summary_value_label.set_meta("qa_id", "shell_practice_setup_summary")
	recommended_value_label.set_meta("qa_id", "shell_practice_setup_recommended")
	related_topics_value_label.set_meta("qa_id", "shell_practice_setup_topics")
	context_card_value_label.set_meta("qa_id", "shell_practice_setup_context_card")
	player_scope_value_label.set_meta("qa_id", "shell_practice_setup_scope")
	slots_summary_label.set_meta("qa_id", "shell_practice_setup_slots")
	start_button.set_meta("qa_id", "shell_practice_setup_start")
	back_button.set_meta("qa_id", "shell_practice_setup_back")
	for index in range(slot_roster_buttons.size()):
		slot_roster_buttons[index].set_meta("qa_id", "shell_practice_setup_slot_%s_robot" % (index + 1))
