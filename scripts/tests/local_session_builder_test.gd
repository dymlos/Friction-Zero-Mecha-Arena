extends SceneTree

const LocalSessionBuilder = preload("res://scripts/systems/local_session_builder.gd")
const LocalSessionDraft = preload("res://scripts/systems/local_session_draft.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var draft := LocalSessionDraft.new()
	_assert(draft.has_method("build_active_slot_specs"), "LocalSessionDraft deberia construir specs activos.")
	_assert(draft.has_method("set_slot_active"), "LocalSessionDraft deberia permitir activar/desactivar slots.")
	_assert(draft.has_method("set_slot_input_source"), "LocalSessionDraft deberia editar la fuente de input.")
	_assert(draft.has_method("reserve_joypad_for_slot"), "LocalSessionDraft deberia reservar joypads por slot.")
	if _failed:
		_finish()
		return

	draft.configure(4)
	draft.set_slot_active(3, false)
	draft.set_slot_control_mode(2, RobotBase.ControlMode.HARD)
	draft.set_slot_input_source(2, "joypad")
	draft.reserve_joypad_for_slot(2, 42, true)
	draft.set_slot_input_source(4, "joypad")
	draft.reserve_joypad_for_slot(4, 77, false)

	var slot_specs := draft.build_active_slot_specs(4)
	_assert(slot_specs.size() == 3, "El draft deberia omitir slots inactivos.")
	_assert(int(slot_specs[0].get("slot", -1)) == 1, "Los specs deberian conservar orden por slot.")
	_assert(String(slot_specs[0].get("roster_entry_id", "")) == "ariete", "Los specs deberian conservar roster_entry_id.")
	_assert(String(slot_specs[0].get("archetype_path", "")).ends_with("ariete_archetype.tres"), "Los specs deberian conservar archetype_path.")
	_assert(String(slot_specs[1].get("input_source", "")) == "joypad", "El slot 2 deberia salir como joypad.")
	_assert(int(slot_specs[1].get("device_id", -1)) == 42, "El slot 2 deberia conservar device_id.")
	_assert(bool(slot_specs[1].get("device_connected", false)), "El slot 2 deberia salir conectado.")
	_assert(not bool(slot_specs[2].get("device_connected", true)), "El slot 4 deberia quedar reservado/desconectado.")

	_assert(
		LocalSessionBuilder.get_default_keyboard_profile_for_slot(4) == RobotBase.KeyboardProfile.IJKL,
		"El builder deberia centralizar los perfiles de teclado soportados."
	)
	var session = LocalSessionBuilder.build_from_slot_specs(slot_specs)
	_assert(session != null, "El builder deberia devolver una LocalSession.")
	if session != null:
		_assert(int(session.get_active_match_slots()) == 3, "La sesion deberia usar solo slots activos.")
		_assert(String(session.get_slot_state(1)) == "keyboard", "P1 deberia quedar en teclado.")
		_assert(String(session.get_slot_roster_entry_id(1)) == "ariete", "P1 deberia conservar su ficha de roster.")
		_assert(int(session.get_slot_keyboard_profile(1)) == RobotBase.KeyboardProfile.WASD_SPACE, "P1 deberia usar WASD por default.")
		_assert(String(session.get_slot_state(2)) == "joypad", "P2 deberia quedar en joypad conectado.")
		_assert(int(session.get_slot_device_id(2)) == 42, "P2 deberia conservar el joypad reclamado.")
		_assert(String(session.get_slot_state(4)) == "disconnected", "P4 deberia quedar reservado si su joypad no esta conectado.")
		_assert(int(session.restore_joypad_slot(77)) == 4, "El mismo device_id deberia recuperar el slot reservado.")

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
