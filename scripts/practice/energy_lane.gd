extends "res://scripts/practice/practice_lane_base.gd"
class_name EnergyLane

var _robot_states := {}
var _saw_leg_focus := false
var _saw_arm_focus := false
var _saw_overdrive := false


func configure_lane(module_spec: Dictionary, player_robots: Array) -> void:
	super.configure_lane(module_spec, player_robots)
	set_objective_lines([
		"Mueve energia a piernas, luego a brazos y cierra con Overdrive.",
		"Mira como cambia el cuerpo, no solo el texto del HUD.",
	])
	set_callout_lines([
		"Las piernas cambian el control; los brazos cambian el empuje.",
	])
	_robot_states.clear()
	_saw_leg_focus = false
	_saw_arm_focus = false
	_saw_overdrive = false
	for robot in get_player_robots():
		if robot != null and is_instance_valid(robot):
			_robot_states[robot.get_instance_id()] = 0
	call_deferred("_sync_lane_state")


func _ready() -> void:
	_sync_lane_state()


func _physics_process(_delta: float) -> void:
	_sync_lane_state()


func _sync_lane_state() -> void:
	var robots := get_player_robots()
	var progress_lines: Array[String] = []
	var completed := false
	for robot in robots:
		if robot == null or not is_instance_valid(robot):
			continue

		var state := int(_robot_states.get(robot.get_instance_id(), 0))
		var focus_part := robot.get_energy_focus_part_name()
		if focus_part.contains("leg"):
			_saw_leg_focus = true
			if state == 0:
				state = 1
		if focus_part.contains("arm"):
			_saw_arm_focus = true
			if state >= 1:
				state = maxi(state, 2)
		if robot.is_overdrive_active():
			_saw_overdrive = true
			if _saw_leg_focus and _saw_arm_focus:
				state = 3
				completed = true

		_robot_states[robot.get_instance_id()] = state
		var state_label := "piernas" if state == 0 else "brazos" if state == 1 else "listo OD" if state == 2 else "OD activo"
		progress_lines.append("P%s | %s | %s" % [robot.player_index, robot.get_energy_state_summary(), state_label])

	set_progress_lines(progress_lines)
	if completed and not _lane_completed:
		set_callout_lines([
			"Aprendiste: redistribuir energia cambia lectura y rendimiento.",
			"Siguiente sugerido: Recuperacion.",
		])
		set_context_card_lines([
			"Aprendiste a leer piernas, brazos y Overdrive como plan.",
			"Siguiente sugerido: Recuperacion.",
		])
		complete_lane()
