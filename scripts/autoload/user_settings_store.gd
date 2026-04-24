extends Node

const AudioDirector = preload("res://scripts/audio/audio_director.gd")
const MatchConfig = preload("res://scripts/systems/match_config.gd")
const UserSettings = preload("res://scripts/systems/user_settings.gd")

const DEFAULT_SETTINGS_RESOURCE_PATH := "res://data/config/default_user_settings.tres"
const DEFAULT_STORAGE_PATH := "user://user_settings.tres"
const MIN_VOLUME_DB := -80.0

static var _singleton: Node = null

var _settings: UserSettings = null
var _storage_path := DEFAULT_STORAGE_PATH
var _default_settings_resource_path := DEFAULT_SETTINGS_RESOURCE_PATH


static func get_singleton() -> Node:
	return _singleton


func _init() -> void:
	_singleton = self


func _ready() -> void:
	_ensure_settings_loaded()
	apply_settings(_settings)


func _exit_tree() -> void:
	_settings = null
	if _singleton == self:
		_singleton = null


func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	if _singleton == self:
		_singleton = null
	_settings = null


func set_storage_path_for_tests(path: String) -> void:
	_storage_path = path
	_settings = null


func get_settings() -> UserSettings:
	_ensure_settings_loaded()
	return _settings


func get_default_hud_detail_mode() -> MatchConfig.HudDetailMode:
	return get_settings().default_hud_detail_mode


func save_settings() -> bool:
	_ensure_settings_loaded()
	_settings = _sanitize_settings(_settings)
	var result := ResourceSaver.save(_settings, _storage_path)
	if result == OK:
		apply_settings(_settings)
		return true
	return false


func apply_settings(settings: UserSettings = _settings) -> void:
	_settings = _sanitize_settings(settings)
	_apply_audio_settings(_settings)
	_apply_video_settings(_settings)


func reset_to_defaults() -> void:
	_settings = _load_default_settings()
	apply_settings(_settings)
	save_settings()


func _ensure_settings_loaded() -> void:
	if _settings != null:
		return
	_settings = _load_saved_settings()
	if _settings == null:
		_settings = _load_default_settings()


func _load_saved_settings() -> UserSettings:
	if not FileAccess.file_exists(_storage_path):
		return null
	var loaded := ResourceLoader.load(_storage_path, "", ResourceLoader.CACHE_MODE_IGNORE) as UserSettings
	return _sanitize_settings(loaded)


func _load_default_settings() -> UserSettings:
	var defaults := ResourceLoader.load(
		_default_settings_resource_path,
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	) as UserSettings
	if defaults == null:
		defaults = UserSettings.new()
	return defaults.duplicate_sanitized()


func _sanitize_settings(settings: UserSettings) -> UserSettings:
	if settings == null:
		return _load_default_settings()
	return settings.duplicate_sanitized()


func _apply_audio_settings(settings: UserSettings) -> void:
	var audio_director := AudioDirector.get_singleton()
	if audio_director == null:
		return
	audio_director.set_master_volume(settings.audio_master_volume)
	audio_director.set_music_volume(settings.audio_music_volume)
	audio_director.set_sfx_volume(settings.audio_sfx_volume)


func _apply_video_settings(settings: UserSettings) -> void:
	if DisplayServer.get_name() == "headless":
		return

	match settings.window_mode:
		UserSettings.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		UserSettings.WINDOW_MODE_BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings.vsync_enabled else DisplayServer.VSYNC_DISABLED
	)
