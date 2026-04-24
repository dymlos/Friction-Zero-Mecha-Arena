extends SceneTree

const MatchConfig = preload("res://scripts/systems/match_config.gd")
const MatchLaunchConfig = preload("res://scripts/systems/match_launch_config.gd")
const UserSettingsStoreScript = preload("res://scripts/autoload/user_settings_store.gd")

const TEST_STORAGE_PATH := "user://test_user_settings_store.tres"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_storage()

	var store = UserSettingsStoreScript.new()
	_configure_store(store)

	_assert(
		store.has_method("get_settings"),
		"UserSettingsStore deberia exponer get_settings()."
	)
	_assert(
		store.has_method("save_settings"),
		"UserSettingsStore deberia exponer save_settings()."
	)
	_assert(
		store.has_method("apply_settings"),
		"UserSettingsStore deberia exponer apply_settings()."
	)
	_assert(
		store.has_method("reset_to_defaults"),
		"UserSettingsStore deberia exponer reset_to_defaults()."
	)
	if _failed:
		_cleanup_storage()
		_finish()
		return

	var defaults = store.get_settings()
	_assert(defaults != null, "UserSettingsStore deberia cargar defaults cuando no existe archivo de usuario.")
	if defaults == null:
		_cleanup_storage()
		_finish()
		return

	_assert(
		int(defaults.default_hud_detail_mode) == MatchConfig.HudDetailMode.CONTEXTUAL,
		"El modo de HUD persistente deberia arrancar en contextual por default."
	)
	_assert(
		is_equal_approx(float(defaults.audio_master_volume), 1.0),
		"El volumen master default deberia arrancar normalizado."
	)
	_assert(
		String(defaults.window_mode) != "",
		"Los defaults deberian incluir un modo de ventana legible."
	)

	defaults.audio_master_volume = 0.42
	defaults.audio_music_volume = 0.18
	defaults.audio_sfx_volume = 1.7
	defaults.default_hud_detail_mode = MatchConfig.HudDetailMode.EXPLICIT
	defaults.window_mode = "borderless"
	defaults.vsync_enabled = false
	var saved := bool(store.save_settings())
	_assert(saved, "UserSettingsStore deberia persistir cambios en user://.")

	var reloaded = UserSettingsStoreScript.new()
	_configure_store(reloaded)
	var persisted = reloaded.get_settings()
	_assert(
		persisted != null and is_equal_approx(float(persisted.audio_master_volume), 0.42),
		"Una nueva instancia deberia rehidratar el volumen master persistido."
	)
	_assert(
		persisted != null and is_equal_approx(float(persisted.audio_music_volume), 0.18),
		"Una nueva instancia deberia rehidratar el volumen de musica persistido."
	)
	_assert(
		persisted != null and is_equal_approx(float(persisted.audio_sfx_volume), 1.0),
		"Los volumenes invalidos deberian clampse al persistir settings."
	)
	_assert(
		persisted != null and int(persisted.default_hud_detail_mode) == MatchConfig.HudDetailMode.EXPLICIT,
		"El default persistente de HUD explicito deberia sobrevivir entre instancias."
	)
	_assert(
		persisted != null and String(persisted.window_mode) == "borderless",
		"El modo de ventana persistente deberia sobrevivir entre instancias."
	)
	_assert(
		persisted != null and not bool(persisted.vsync_enabled),
		"El flag de vsync persistente deberia sobrevivir entre instancias."
	)

	var launch_config := MatchLaunchConfig.new()
	launch_config.configure_for_local_match(
		1,
		"res://scenes/main/main_ffa.tscn",
		[{"slot": 1, "control_mode": 0}]
	)
	_assert(
		int(launch_config.hud_detail_mode) == MatchConfig.HudDetailMode.EXPLICIT,
		"MatchLaunchConfig deberia usar el HUD efectivo de UserSettingsStore al preparar el runtime."
	)

	reloaded.reset_to_defaults()
	var reset_settings = reloaded.get_settings()
	_assert(
		reset_settings != null and int(reset_settings.default_hud_detail_mode) == MatchConfig.HudDetailMode.CONTEXTUAL,
		"Resetear defaults deberia volver a HUD contextual."
	)
	_assert(
		reset_settings != null and is_equal_approx(float(reset_settings.audio_master_volume), 1.0),
		"Resetear defaults deberia restaurar el volumen master."
	)

	_cleanup_store(store)
	_cleanup_store(reloaded)
	_cleanup_storage()
	_finish()


func _configure_store(store: Node) -> void:
	if store.has_method("set_storage_path_for_tests"):
		store.call("set_storage_path_for_tests", TEST_STORAGE_PATH)


func _cleanup_storage() -> void:
	if FileAccess.file_exists(TEST_STORAGE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_STORAGE_PATH))


func _cleanup_store(store: Node) -> void:
	if store == null or not is_instance_valid(store):
		return
	store.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
