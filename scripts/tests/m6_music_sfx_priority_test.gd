extends SceneTree

const AudioDirector = preload("res://scripts/audio/audio_director.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var director := AudioDirector.new()
	root.add_child(director)
	await process_frame

	_assert(director.has_method("get_music_state_profile"), "AudioDirector debe exponer perfiles musicales M6.")
	_assert(director.has_method("get_current_music_duck_gain"), "AudioDirector debe exponer ducking para testear prioridad SFX.")
	_assert(director.has_method("get_cue_profile"), "AudioDirector debe exponer perfil de cue usado por mezcla.")
	if not director.has_method("get_music_state_profile"):
		_cleanup_director(director)
		_finish()
		return

	var live_profile: Dictionary = director.call("get_music_state_profile", "match_live")
	var pressure_profile: Dictionary = director.call("get_music_state_profile", "final_pressure")
	_assert(String(live_profile.get("role", "")) == "match_base", "`match_live` debe ser base musical de match.")
	_assert(String(pressure_profile.get("role", "")) == "final_escalation", "`final_pressure` debe ser escalada final.")
	_assert(float(pressure_profile.get("intensity", 0.0)) > float(live_profile.get("intensity", 0.0)), "La escalada final debe tener mas intensidad que la base.")
	_assert(float(pressure_profile.get("music_gain", 1.0)) <= 0.72, "La escalada no debe tapar SFX clave.")

	director.set_music_state("final_pressure")
	director.play_cue("impact_heavy")
	await process_frame
	var duck_gain := float(director.call("get_current_music_duck_gain"))
	_assert(duck_gain < 1.0, "Un SFX clave debe duckear musica.")
	_assert(duck_gain >= 0.5, "El ducking debe abrir espacio sin mutear completamente la musica.")

	var cue_profile: Dictionary = director.call("get_cue_profile", "impact_heavy")
	_assert(bool(cue_profile.get("ducks_music", false)), "impact_heavy debe pedir ducking.")
	_assert(float(cue_profile.get("functional_priority", 0.0)) >= 0.9, "impact_heavy debe tener prioridad funcional alta.")

	_cleanup_director(director)
	_finish()


func _cleanup_director(director: Node) -> void:
	if director == null or not is_instance_valid(director):
		return
	var parent := director.get_parent()
	if parent != null:
		parent.remove_child(director)
	director.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
