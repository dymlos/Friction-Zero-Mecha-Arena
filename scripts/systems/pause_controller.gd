extends RefCounted
class_name PauseController

const LocalSession = preload("res://scripts/systems/local_session.gd")

enum PauseAction { RESUME, RESTART, TOGGLE_HUD, AUDIO_MASTER, AUDIO_MUSIC, AUDIO_SFX, RETURN_TO_MENU }

const ACTION_IDS := {
	PauseAction.RESUME: "resume",
	PauseAction.RESTART: "restart",
	PauseAction.TOGGLE_HUD: "toggle_hud",
	PauseAction.AUDIO_MASTER: "audio_master",
	PauseAction.AUDIO_MUSIC: "audio_music",
	PauseAction.AUDIO_SFX: "audio_sfx",
	PauseAction.RETURN_TO_MENU: "return_to_menu",
}

var _paused := false
var _pause_owner_slot := 0
var _selected_action := PauseAction.RESUME
var _allow_return_to_menu := false
var _confirm_return_to_menu := false


func is_paused() -> bool:
	return _paused


func get_pause_owner_slot() -> int:
	return _pause_owner_slot


func get_selected_action() -> int:
	return _selected_action


func allows_return_to_menu() -> bool:
	return _allow_return_to_menu


func is_return_to_menu_confirmation_active() -> bool:
	return _confirm_return_to_menu


func request_pause(slot: int, local_session: LocalSession, allow_return_to_menu: bool = false) -> bool:
	if _paused or local_session == null:
		return false
	if slot <= 0 or not local_session.is_slot_occupied(slot):
		return false

	_paused = true
	_pause_owner_slot = slot
	_selected_action = PauseAction.RESUME
	_allow_return_to_menu = allow_return_to_menu
	_confirm_return_to_menu = false
	return true


func request_resume(slot: int) -> bool:
	if not _paused or slot != _pause_owner_slot:
		return false

	reset()
	return true


func request_restart(slot: int) -> bool:
	return _paused and slot == _pause_owner_slot


func move_selection(slot: int, direction: int) -> bool:
	if not _paused or slot != _pause_owner_slot or direction == 0:
		return false
	if _confirm_return_to_menu:
		return false

	var actions := _get_available_actions()
	if actions.is_empty():
		return false

	var current_index := maxi(actions.find(_selected_action), 0)
	var next_index := wrapi(current_index + signi(direction), 0, actions.size())
	_selected_action = actions[next_index]
	return true


func select_action(slot: int, action_id: String) -> bool:
	if not _paused or slot != _pause_owner_slot or _confirm_return_to_menu:
		return false
	for action in _get_available_actions():
		if String(ACTION_IDS.get(action, "")) == action_id:
			_selected_action = action
			return true
	return false


func activate_selected_action(slot: int) -> String:
	if not _paused or slot != _pause_owner_slot:
		return ""

	match _selected_action:
		PauseAction.RESUME:
			return "resume"
		PauseAction.RESTART:
			return "restart"
		PauseAction.TOGGLE_HUD:
			return "toggle_hud"
		PauseAction.AUDIO_MASTER:
			return "audio_master"
		PauseAction.AUDIO_MUSIC:
			return "audio_music"
		PauseAction.AUDIO_SFX:
			return "audio_sfx"
		PauseAction.RETURN_TO_MENU:
			if _confirm_return_to_menu:
				return "return_to_menu"
			_confirm_return_to_menu = true
			return "confirm_return_to_menu"

	return ""


func cancel_return_to_menu_confirmation(slot: int) -> bool:
	if not _paused or slot != _pause_owner_slot or not _confirm_return_to_menu:
		return false

	_confirm_return_to_menu = false
	return true


func get_action_labels() -> Array[String]:
	var lines: Array[String] = []
	for action in _get_available_actions():
		var prefix := "> " if action == _selected_action else "  "
		lines.append("%s%s" % [prefix, _get_action_label(action)])

	return lines


func get_selected_action_id() -> String:
	return String(ACTION_IDS.get(_selected_action, ""))


func reset() -> void:
	_paused = false
	_pause_owner_slot = 0
	_selected_action = PauseAction.RESUME
	_allow_return_to_menu = false
	_confirm_return_to_menu = false


func _get_available_actions() -> Array[int]:
	var actions: Array[int] = [
		PauseAction.RESUME,
		PauseAction.RESTART,
	]
	if _allow_return_to_menu:
		actions.append(PauseAction.RETURN_TO_MENU)
	actions.append(PauseAction.TOGGLE_HUD)
	actions.append(PauseAction.AUDIO_MASTER)
	actions.append(PauseAction.AUDIO_MUSIC)
	actions.append(PauseAction.AUDIO_SFX)

	return actions


func _get_action_label(action: int) -> String:
	match action:
		PauseAction.RESUME:
			return "Reanudar"
		PauseAction.RESTART:
			return "Reiniciar"
		PauseAction.TOGGLE_HUD:
			return "HUD"
		PauseAction.AUDIO_MASTER:
			return "Master"
		PauseAction.AUDIO_MUSIC:
			return "Musica"
		PauseAction.AUDIO_SFX:
			return "SFX"
		PauseAction.RETURN_TO_MENU:
			return "Volver al menu"

	return "Accion"
