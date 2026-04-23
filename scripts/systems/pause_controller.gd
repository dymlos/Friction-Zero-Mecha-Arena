extends RefCounted
class_name PauseController

const LocalSession = preload("res://scripts/systems/local_session.gd")

var _paused := false
var _pause_owner_slot := 0


func is_paused() -> bool:
	return _paused


func get_pause_owner_slot() -> int:
	return _pause_owner_slot


func request_pause(slot: int, local_session: LocalSession) -> bool:
	if _paused or local_session == null:
		return false
	if slot <= 0 or not local_session.is_slot_occupied(slot):
		return false

	_paused = true
	_pause_owner_slot = slot
	return true


func request_resume(slot: int) -> bool:
	if not _paused or slot != _pause_owner_slot:
		return false

	reset()
	return true


func request_restart(slot: int) -> bool:
	return _paused and slot == _pause_owner_slot


func reset() -> void:
	_paused = false
	_pause_owner_slot = 0
