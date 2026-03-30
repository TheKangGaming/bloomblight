extends Node

signal settings_loaded
signal setting_changed(key: String, value: Variant)
signal settings_changed(settings: Dictionary)
signal display_preview_started(timeout_seconds: int)
signal display_preview_updated(seconds_left: int)
signal display_preview_finished(confirmed: bool)

const CONFIG_PATH := "user://settings.cfg"
const DISPLAY_PREVIEW_TIMEOUT_SECONDS := 12
const WINDOWED_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

const DEFAULT_SETTINGS := {
	"display_mode": "borderless",
	"window_width": 2560,
	"window_height": 1440,
	"vsync_enabled": true,
	"master_volume": 100.0,
	"music_volume": 50.0,
	"sfx_volume": 80.0,
	"ambience_volume": 70.0,
	"ui_volume": 60.0,
	"dialogue_speed": 1.0,
	"screen_shake_enabled": true,
	"auto_advance_dialogue": false,
}

var _settings: Dictionary = {}
var _confirmed_display_settings: Dictionary = {}
var _pending_display_settings: Dictionary = {}
var _preview_seconds_remaining: int = 0
var _preview_timeout_timer: Timer = null
var _preview_tick_timer: Timer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_preview_timers()
	_load_settings()
	_apply_all_settings()
	settings_loaded.emit()
	settings_changed.emit(get_settings_copy())

func get_settings_copy() -> Dictionary:
	return _settings.duplicate(true)

func get_default_settings() -> Dictionary:
	return DEFAULT_SETTINGS.duplicate(true)

func get_available_resolutions() -> Array[Vector2i]:
	return WINDOWED_RESOLUTIONS.duplicate()

func get_setting(key: String, fallback: Variant = null) -> Variant:
	return _settings.get(key, fallback)

func get_dialogue_speed_multiplier() -> float:
	return float(_settings.get("dialogue_speed", 1.0))

func is_screen_shake_enabled() -> bool:
	return bool(_settings.get("screen_shake_enabled", true))

func is_auto_advance_dialogue_enabled() -> bool:
	return bool(_settings.get("auto_advance_dialogue", false))

func has_pending_display_preview() -> bool:
	return not _pending_display_settings.is_empty()

func set_audio_volume(key: String, value: float) -> void:
	var clamped_value := clampf(value, 0.0, 100.0)
	if is_equal_approx(float(_settings.get(key, clamped_value)), clamped_value):
		return

	_settings[key] = clamped_value
	_apply_audio_settings()
	_save_settings()
	_emit_setting_changed(key)

func set_dialogue_speed(value: float) -> void:
	var clamped_value := clampf(value, 0.6, 1.5)
	if is_equal_approx(float(_settings.get("dialogue_speed", clamped_value)), clamped_value):
		return

	_settings["dialogue_speed"] = clamped_value
	_save_settings()
	_emit_setting_changed("dialogue_speed")

func set_screen_shake_enabled(enabled: bool) -> void:
	if bool(_settings.get("screen_shake_enabled", enabled)) == enabled:
		return

	_settings["screen_shake_enabled"] = enabled
	_save_settings()
	_emit_setting_changed("screen_shake_enabled")

func set_auto_advance_dialogue(enabled: bool) -> void:
	if bool(_settings.get("auto_advance_dialogue", enabled)) == enabled:
		return

	_settings["auto_advance_dialogue"] = enabled
	_save_settings()
	_emit_setting_changed("auto_advance_dialogue")

func preview_display_settings(display_mode: String, resolution: Vector2i, vsync_enabled: bool) -> void:
	var normalized := _normalize_display_settings({
		"display_mode": display_mode,
		"window_width": resolution.x,
		"window_height": resolution.y,
		"vsync_enabled": vsync_enabled,
	})

	var same_as_confirmed := _display_settings_equal(normalized, _confirmed_display_settings)
	if same_as_confirmed:
		if has_pending_display_preview():
			revert_display_preview()
		return

	if _confirmed_display_settings.is_empty():
		_confirmed_display_settings = _get_display_settings().duplicate(true)

	_pending_display_settings = normalized
	_apply_display_settings(_pending_display_settings)
	_start_display_preview()

func confirm_display_preview() -> void:
	if not has_pending_display_preview():
		return

	for key in _pending_display_settings.keys():
		_settings[key] = _pending_display_settings[key]

	_confirmed_display_settings = _pending_display_settings.duplicate(true)
	_pending_display_settings.clear()
	_stop_display_preview_timers()
	_preview_seconds_remaining = 0
	_save_settings()
	display_preview_finished.emit(true)
	_emit_settings_changed()

func revert_display_preview() -> void:
	if not has_pending_display_preview():
		return

	_apply_display_settings(_confirmed_display_settings)
	_pending_display_settings.clear()
	_stop_display_preview_timers()
	_preview_seconds_remaining = 0
	display_preview_finished.emit(false)

func restore_defaults() -> void:
	var defaults := get_default_settings()
	var non_display_keys := [
		"master_volume",
		"music_volume",
		"sfx_volume",
		"ambience_volume",
		"ui_volume",
		"dialogue_speed",
		"screen_shake_enabled",
		"auto_advance_dialogue",
	]
	var changed := false
	for key in non_display_keys:
		var default_value = defaults[key]
		if _settings.get(key) == default_value:
			continue
		_settings[key] = default_value
		setting_changed.emit(String(key), default_value)
		changed = true

	if changed:
		_apply_audio_settings()
		_save_settings()
		_emit_settings_changed()

	preview_display_settings(
		String(defaults["display_mode"]),
		Vector2i(int(defaults["window_width"]), int(defaults["window_height"])),
		bool(defaults["vsync_enabled"])
	)

func _setup_preview_timers() -> void:
	_preview_timeout_timer = Timer.new()
	_preview_timeout_timer.one_shot = true
	_preview_timeout_timer.wait_time = DISPLAY_PREVIEW_TIMEOUT_SECONDS
	_preview_timeout_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_preview_timeout_timer.timeout.connect(_on_display_preview_timeout)
	add_child(_preview_timeout_timer)

	_preview_tick_timer = Timer.new()
	_preview_tick_timer.one_shot = false
	_preview_tick_timer.wait_time = 1.0
	_preview_tick_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_preview_tick_timer.timeout.connect(_on_display_preview_tick)
	add_child(_preview_tick_timer)

func _load_settings() -> void:
	_settings = DEFAULT_SETTINGS.duplicate(true)

	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_confirmed_display_settings = _get_display_settings().duplicate(true)
		return

	for key in DEFAULT_SETTINGS.keys():
		_settings[key] = config.get_value("settings", key, DEFAULT_SETTINGS[key])

	_normalize_loaded_settings()
	_confirmed_display_settings = _get_display_settings().duplicate(true)

func _normalize_loaded_settings() -> void:
	_settings["display_mode"] = _normalize_display_mode(String(_settings.get("display_mode", "borderless")))
	_settings["window_width"] = maxi(int(_settings.get("window_width", 2560)), 640)
	_settings["window_height"] = maxi(int(_settings.get("window_height", 1440)), 360)
	_settings["vsync_enabled"] = bool(_settings.get("vsync_enabled", true))
	for key in ["master_volume", "music_volume", "sfx_volume", "ambience_volume", "ui_volume"]:
		_settings[key] = clampf(float(_settings.get(key, DEFAULT_SETTINGS[key])), 0.0, 100.0)
	_settings["dialogue_speed"] = clampf(float(_settings.get("dialogue_speed", 1.0)), 0.6, 1.5)
	_settings["screen_shake_enabled"] = bool(_settings.get("screen_shake_enabled", true))
	_settings["auto_advance_dialogue"] = bool(_settings.get("auto_advance_dialogue", false))

func _save_settings() -> void:
	var config := ConfigFile.new()
	for key in _settings.keys():
		config.set_value("settings", key, _settings[key])
	config.save(CONFIG_PATH)

func _apply_all_settings() -> void:
	_apply_display_settings(_get_display_settings())
	_apply_audio_settings()

func _apply_audio_settings() -> void:
	_set_bus_volume("Master", float(_settings.get("master_volume", 100.0)))
	_set_bus_volume("Music", float(_settings.get("music_volume", 55.0)))
	_set_bus_volume("SFX", float(_settings.get("sfx_volume", 82.0)))
	_set_bus_volume("Ambience", float(_settings.get("ambience_volume", 58.0)))
	_set_bus_volume("UI", float(_settings.get("ui_volume", 80.0)))

func _set_bus_volume(bus_name: String, slider_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	var normalized := clampf(slider_value / 100.0, 0.0, 1.0)
	var db_value := -80.0 if normalized <= 0.0 else linear_to_db(normalized)
	AudioServer.set_bus_volume_db(bus_index, db_value)

func _apply_display_settings(display_settings: Dictionary) -> void:
	var mode_name := _normalize_display_mode(String(display_settings.get("display_mode", "borderless")))
	var resolution := Vector2i(
		int(display_settings.get("window_width", DEFAULT_SETTINGS["window_width"])),
		int(display_settings.get("window_height", DEFAULT_SETTINGS["window_height"]))
	)
	var vsync_enabled := bool(display_settings.get("vsync_enabled", true))

	match mode_name:
		"windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(resolution)
			var screen_size := DisplayServer.screen_get_size()
			var window_pos := Vector2i(
				roundi((screen_size.x - resolution.x) * 0.5),
				roundi((screen_size.y - resolution.y) * 0.5)
			)
			DisplayServer.window_set_position(window_pos)
		"exclusive_fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)

func _get_display_settings() -> Dictionary:
	return {
		"display_mode": _normalize_display_mode(String(_settings.get("display_mode", "borderless"))),
		"window_width": int(_settings.get("window_width", DEFAULT_SETTINGS["window_width"])),
		"window_height": int(_settings.get("window_height", DEFAULT_SETTINGS["window_height"])),
		"vsync_enabled": bool(_settings.get("vsync_enabled", true)),
	}

func _normalize_display_settings(raw_settings: Dictionary) -> Dictionary:
	return {
		"display_mode": _normalize_display_mode(String(raw_settings.get("display_mode", "borderless"))),
		"window_width": maxi(int(raw_settings.get("window_width", DEFAULT_SETTINGS["window_width"])), 640),
		"window_height": maxi(int(raw_settings.get("window_height", DEFAULT_SETTINGS["window_height"])), 360),
		"vsync_enabled": bool(raw_settings.get("vsync_enabled", true)),
	}

func _normalize_display_mode(mode_name: String) -> String:
	match mode_name:
		"windowed", "exclusive_fullscreen", "borderless":
			return mode_name
		_:
			return "borderless"

func _display_settings_equal(a: Dictionary, b: Dictionary) -> bool:
	return (
		String(a.get("display_mode", "")) == String(b.get("display_mode", "")) and
		int(a.get("window_width", 0)) == int(b.get("window_width", 0)) and
		int(a.get("window_height", 0)) == int(b.get("window_height", 0)) and
		bool(a.get("vsync_enabled", false)) == bool(b.get("vsync_enabled", false))
	)

func _start_display_preview() -> void:
	_preview_seconds_remaining = DISPLAY_PREVIEW_TIMEOUT_SECONDS
	display_preview_started.emit(_preview_seconds_remaining)
	display_preview_updated.emit(_preview_seconds_remaining)
	_preview_timeout_timer.start()
	_preview_tick_timer.start()

func _stop_display_preview_timers() -> void:
	if _preview_timeout_timer != null:
		_preview_timeout_timer.stop()
	if _preview_tick_timer != null:
		_preview_tick_timer.stop()

func _on_display_preview_timeout() -> void:
	revert_display_preview()

func _on_display_preview_tick() -> void:
	if _preview_seconds_remaining <= 0:
		return

	_preview_seconds_remaining -= 1
	if _preview_seconds_remaining > 0:
		display_preview_updated.emit(_preview_seconds_remaining)

func _emit_setting_changed(key: String) -> void:
	setting_changed.emit(key, _settings.get(key))
	_emit_settings_changed()

func _emit_settings_changed() -> void:
	settings_changed.emit(get_settings_copy())
