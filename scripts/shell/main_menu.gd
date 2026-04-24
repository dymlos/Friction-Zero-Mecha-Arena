extends Control
class_name MainMenu

const DEFAULT_PRESENTATION_PALETTE := preload("res://data/presentation/default_presentation_palette.tres")

signal play_local_requested
signal characters_requested
signal how_to_play_requested
signal settings_requested
signal practice_requested
signal exit_requested

@onready var backdrop: ColorRect = $Backdrop
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var play_local_button: Button = %PlayLocalButton
@onready var characters_button: Button = %CharactersButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var settings_button: Button = %SettingsButton
@onready var practice_button: Button = %PracticeButton
@onready var exit_button: Button = %ExitButton


func _ready() -> void:
	_install_qa_ids()
	backdrop.color = DEFAULT_PRESENTATION_PALETTE.surface_background
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = "Friction Zero"
	subtitle_label.text = "Entrar, configurar, practicar y revisar reglas sin herramientas de laboratorio."
	play_local_button.text = "Jugar local"
	characters_button.text = "Characters"
	how_to_play_button.text = "How to Play"
	settings_button.text = "Settings"
	practice_button.text = "Practica"
	exit_button.text = "Salir"
	play_local_button.pressed.connect(_on_play_local_pressed)
	characters_button.pressed.connect(_on_characters_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	practice_button.pressed.connect(_on_practice_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	call_deferred("focus_play_local_button")


func _on_play_local_pressed() -> void:
	play_local_requested.emit()


func _on_characters_pressed() -> void:
	characters_requested.emit()


func _on_how_to_play_pressed() -> void:
	how_to_play_requested.emit()


func _on_settings_pressed() -> void:
	settings_requested.emit()


func _on_practice_pressed() -> void:
	practice_requested.emit()


func _on_exit_pressed() -> void:
	exit_requested.emit()


func request_start_from_shortcut() -> bool:
	play_local_requested.emit()
	return true


func focus_play_local_button() -> void:
	if play_local_button != null:
		play_local_button.grab_focus()


func focus_characters_button() -> void:
	if characters_button != null:
		characters_button.grab_focus()


func focus_how_to_play_button() -> void:
	if how_to_play_button != null:
		how_to_play_button.grab_focus()


func focus_settings_button() -> void:
	if settings_button != null:
		settings_button.grab_focus()


func focus_practice_button() -> void:
	if practice_button != null:
		practice_button.grab_focus()


func _install_qa_ids() -> void:
	title_label.set_meta("qa_id", "shell_main_menu_title")
	subtitle_label.set_meta("qa_id", "shell_main_menu_subtitle")
	play_local_button.set_meta("qa_id", "shell_main_menu_play_local")
	characters_button.set_meta("qa_id", "shell_main_menu_characters")
	how_to_play_button.set_meta("qa_id", "shell_main_menu_how_to_play")
	settings_button.set_meta("qa_id", "shell_main_menu_settings")
	practice_button.set_meta("qa_id", "shell_main_menu_practice")
	exit_button.set_meta("qa_id", "shell_main_menu_exit")
