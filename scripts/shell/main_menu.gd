extends Control
class_name MainMenu

signal play_local_requested
signal exit_requested

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var play_local_button: Button = %PlayLocalButton
@onready var exit_button: Button = %ExitButton


func _ready() -> void:
	_install_qa_ids()
	title_label.text = "Friction Zero"
	subtitle_label.text = "Shell local minima para entrar al match sin herramientas de laboratorio."
	play_local_button.text = "Jugar local"
	exit_button.text = "Salir"
	play_local_button.pressed.connect(_on_play_local_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _on_play_local_pressed() -> void:
	play_local_requested.emit()


func _on_exit_pressed() -> void:
	exit_requested.emit()


func _install_qa_ids() -> void:
	title_label.set_meta("qa_id", "shell_main_menu_title")
	subtitle_label.set_meta("qa_id", "shell_main_menu_subtitle")
	play_local_button.set_meta("qa_id", "shell_main_menu_play_local")
	exit_button.set_meta("qa_id", "shell_main_menu_exit")
