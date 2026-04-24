extends SceneTree

const LocalSessionBuilder = preload("res://scripts/systems/local_session_builder.gd")
const LocalSessionDraft = preload("res://scripts/systems/local_session_draft.gd")
const RobotBase = preload("res://scripts/robots/robot_base.gd")
const ROBOT_SCENE := preload("res://scenes/robots/robot_base.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var draft := LocalSessionDraft.new()
	draft.configure(8)

	var p5_info := draft.get_slot_info(5)
	_assert(String(p5_info.get("roster_entry_id", "")) == "aguja", "P5 deberia preseleccionar Aguja.")
	_assert(not bool(p5_info.get("active", true)), "P5 deberia arrancar inactivo.")
	draft.set_slot_active(5, true)
	_assert(not draft.is_slot_launchable(5), "P5 activo con teclado sin perfil no deberia poder lanzar.")

	draft.set_slot_roster_entry(1, "ancla")
	var p1_info := draft.get_slot_info(1)
	_assert(String(p1_info.get("roster_entry_id", "")) == "ancla", "Cambiar P1 a Ancla deberia guardar el id player-facing.")
	_assert(
		String(p1_info.get("archetype_path", "")) == "res://data/config/robots/ancla_archetype.tres",
		"Cambiar P1 a Ancla deberia actualizar archetype_path junto al id."
	)

	var sanitized := LocalSessionBuilder.sanitize_slot_specs([
		draft.get_slot_info(5),
		draft.get_slot_info(1),
	])
	_assert(sanitized.size() == 2, "Sanitizar specs deberia preservar specs validos con loadout.")
	_assert(int(sanitized[0].get("slot", -1)) == 1, "Sanitizar specs deberia ordenar por slot.")
	_assert(String(sanitized[0].get("roster_entry_id", "")) == "ancla", "El spec sanitizado deberia conservar Ancla en P1.")
	_assert(String(sanitized[1].get("roster_entry_id", "")) == "aguja", "El spec sanitizado deberia conservar Aguja en P5.")

	var session = LocalSessionBuilder.build_from_slot_specs([draft.get_slot_info(1)])
	_assert(session != null, "El builder deberia crear LocalSession con loadout.")
	if session != null:
		_assert(String(session.get_slot_roster_entry_id(1)) == "ancla", "LocalSession deberia conservar roster_entry_id.")
		_assert(
			String(session.get_slot_archetype_path(1)) == "res://data/config/robots/ancla_archetype.tres",
			"LocalSession deberia conservar archetype_path."
		)
		var robot := ROBOT_SCENE.instantiate() as RobotBase
		root.add_child(robot)
		session.apply_to_robot(robot, 1)
		_assert(robot.get_archetype_label() == "Ancla", "LocalSession.apply_to_robot() deberia convertir P1 en Ancla.")
		robot.free()

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
