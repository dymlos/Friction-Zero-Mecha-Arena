extends RefCounted
class_name PauseController

const LocalSession = preload("res://scripts/systems/local_session.gd")

enum PauseAction { RESUME, RESTART, RETURN_TO_MENU }

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


func activate_selected_action(slot: int) -> String:
	if not _paused or slot != _pause_owner_slot:
		return ""

	match _selected_action:
		PauseAction.RESUME:
			return "resume"
		PauseAction.RESTART:
			return "restart"
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

	return actions


func _get_action_label(action: int) -> String:
	match action:
		PauseAction.RESUME:
			return "Reanudar"
		PauseAction.RESTART:
			return "Reiniciar"
		PauseAction.RETURN_TO_MENU:
			return "Volver al menu"

	return "Accion"
