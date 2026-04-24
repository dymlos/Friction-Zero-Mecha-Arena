extends SceneTree

const AudioDirector = preload("res://scripts/audio/audio_director.gd")
const UserSettings = preload("res://scripts/systems/user_settings.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio_director := AudioDirector.new()
	root.add_child(audio_director)
	await process_frame

	_assert(audio_director.has_method("set_master_volume"), "AudioDirector deberia exponer set_master_volume().")
	_assert(audio_director.has_method("get_master_volume"), "AudioDirector deberia exponer get_master_volume().")
	_assert(audio_director.has_method("set_music_volume"), "AudioDirector deberia exponer set_music_volume().")
	_assert(audio_director.has_method("get_music_volume"), "AudioDirector deberia exponer get_music_volume().")
	_assert(audio_director.has_method("set_sfx_volume"), "AudioDirector deberia exponer set_sfx_volume().")
	_assert(audio_director.has_method("get_sfx_volume"), "AudioDirector deberia exponer get_sfx_volume().")
	if _failed:
		_cleanup_director(audio_director)
		_finish()
		return

	audio_director.set_master_volume(-0.5)
	audio_director.set_music_volume(0.33)
	audio_director.set_sfx_volume(1.8)

	_assert(
		is_equal_approx(float(audio_director.get_master_volume()), 0.0),
		"AudioDirector deberia clampsear el volumen master."
	)
	_assert(
		is_equal_approx(float(audio_director.get_music_volume()), 0.33),
		"AudioDirector deberia conservar volumenes validos de musica."
	)
	_assert(
		is_equal_approx(float(audio_director.get_sfx_volume()), 1.0),
		"AudioDirector deberia clampsear el volumen de SFX."
	)

	var settings := UserSettings.new()
	settings.audio_master_volume = 0.25
	settings.audio_music_volume = 0.5
	settings.audio_sfx_volume = 0.75

	var before_headless_name := DisplayServer.get_name()
	_assert(before_headless_name != "", "El entorno de test deberia exponer DisplayServer aun en headless.")

	var store_script = load("res://scripts/autoload/user_settings_store.gd")
	var store = store_script.new()
	if store.has_method("apply_settings"):
		store.apply_settings(settings)

	_assert(
		is_equal_approx(float(audio_director.get_master_volume()), 0.25),
		"Aplicar settings deberia actualizar master sobre AudioDirector."
	)
	_assert(
		is_equal_approx(float(audio_director.get_music_volume()), 0.5),
		"Aplicar settings deberia actualizar musica sobre AudioDirector."
	)
	_assert(
		is_equal_approx(float(audio_director.get_sfx_volume()), 0.75),
		"Aplicar settings deberia actualizar SFX sobre AudioDirector."
	)

	if is_instance_valid(store):
		store.free()
	_cleanup_director(audio_director)
	_finish()


func _cleanup_director(audio_director: Node) -> void:
	if audio_director == null or not is_instance_valid(audio_director):
		return

	var parent := audio_director.get_parent()
	if parent != null:
		parent.remove_child(audio_director)
	audio_director.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
