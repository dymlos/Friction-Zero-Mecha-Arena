extends "res://scripts/practice/practice_lane_base.gd"
class_name MovementLane

const FINISH_DISTANCE := 6.0


func configure_lane(module_spec: Dictionary, player_robots: Array) -> void:
	super.configure_lane(module_spec, player_robots)
	set_objective_lines([
		"Cruza el arco sin perder lectura del deslizamiento.",
		"Compara control simple y avanzado sobre la misma pista.",
	])
	set_callout_lines([
		"Arranque pesado, deslizamiento libre y frenado legible.",
	])
	call_deferred("_sync_lane_state")


func _ready() -> void:
	_sync_lane_state()


func _physics_process(_delta: float) -> void:
	_sync_lane_state()


func _sync_lane_state() -> void:
	var robots := get_player_robots()
	if robots.is_empty():
		return

	var progress_lines: Array[String] = []
	var completed_count := 0
	for robot in robots:
		if robot == null or not is_instance_valid(robot):
			continue

		var remaining := maxf(0.0, robot.global_position.z + FINISH_DISTANCE)
		var control_label := "Avanzado" if robot.control_mode == RobotBase.ControlMode.HARD else "Simple"
		var state_label := "cruzado" if robot.global_position.z <= -FINISH_DISTANCE else "en ruta"
		if robot.global_position.z <= -FINISH_DISTANCE:
			completed_count += 1
		progress_lines.append("P%s | %s | %s | %.1fm" % [robot.player_index, control_label, state_label, remaining])

	set_progress_lines(progress_lines)
	if completed_count < max(1, robots.size()) or _lane_completed:
		return

	set_callout_lines([
		"Aprendiste: entrar, frenar y volver a acelerar sin perder control.",
		"Siguiente sugerido: Impacto.",
	])
	set_context_card_lines([
		"Aprendiste a entrar, frenar y volver a acelerar.",
		"Siguiente sugerido: Impacto.",
	])
	complete_lane()
