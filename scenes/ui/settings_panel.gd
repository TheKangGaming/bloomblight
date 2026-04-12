extends PanelContainer

signal close_requested

const DISPLAY_MODE_WINDOWED := 0
const DISPLAY_MODE_BORDERLESS := 1
const DISPLAY_MODE_EXCLUSIVE := 2

const DIALOGUE_SPEED_SLOW := 0
const DIALOGUE_SPEED_NORMAL := 1
const DIALOGUE_SPEED_FAST := 2

var _embedded_mode := false
var _is_refreshing := false
var _resolution_values: Array[Vector2i] = []

var _title_label: Label
var _mode_option: OptionButton
var _resolution_option: OptionButton
var _vsync_toggle: CheckButton
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _ambience_slider: HSlider
var _ui_slider: HSlider
var _dialogue_speed_option: OptionButton
var _screen_shake_toggle: CheckButton
var _auto_advance_toggle: CheckButton
var _preview_box: PanelContainer
var _preview_label: Label
var _confirm_button: Button
var _revert_button: Button
var _restore_button: Button
var _close_button: Button
var _scroll_container: ScrollContainer

func _ui_sound_manager() -> Node:
	return get_node_or_null("/root/UISoundManager")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolution_values = SettingsManager.get_available_resolutions() if SettingsManager else []
	_build_ui()
	_connect_manager_signals()
	_refresh_from_settings()
	_hide_preview_box()
	if not _embedded_mode:
		call_deferred("focus_default_control")

func _exit_tree() -> void:
	_disconnect_manager_signals()

func configure(options: Dictionary = {}) -> void:
	_embedded_mode = bool(options.get("embedded", false))
	if is_node_ready():
		_apply_embedded_mode()

func _build_ui() -> void:
	custom_minimum_size = Vector2(880, 680)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	_title_label = Label.new()
	_title_label.text = "Settings"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 36)
	root.add_child(_title_label)

	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.follow_focus = true
	root.add_child(_scroll_container)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	_scroll_container.add_child(content)

	content.add_child(_build_section_title("Display"))
	_mode_option = _create_option_row(content, "Window Mode", [
		["Windowed", DISPLAY_MODE_WINDOWED],
		["Borderless Fullscreen", DISPLAY_MODE_BORDERLESS],
		["Exclusive Fullscreen", DISPLAY_MODE_EXCLUSIVE],
	], _on_display_mode_changed)
	_resolution_option = _create_option_row(content, "Resolution", _build_resolution_entries(), _on_resolution_changed)
	_vsync_toggle = _create_toggle_row(content, "VSync", _on_vsync_toggled)

	_preview_box = PanelContainer.new()
	_preview_box.visible = false
	content.add_child(_preview_box)

	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 14)
	preview_margin.add_theme_constant_override("margin_right", 14)
	preview_margin.add_theme_constant_override("margin_top", 12)
	preview_margin.add_theme_constant_override("margin_bottom", 12)
	_preview_box.add_child(preview_margin)

	var preview_content := VBoxContainer.new()
	preview_content.add_theme_constant_override("separation", 10)
	preview_margin.add_child(preview_content)

	_preview_label = Label.new()
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_label.add_theme_font_size_override("font_size", 24)
	preview_content.add_child(_preview_label)

	var preview_actions := HBoxContainer.new()
	preview_actions.alignment = BoxContainer.ALIGNMENT_END
	preview_actions.add_theme_constant_override("separation", 12)
	preview_content.add_child(preview_actions)

	_confirm_button = Button.new()
	_confirm_button.text = "Keep Changes"
	_confirm_button.custom_minimum_size = Vector2(220, 54)
	_confirm_button.add_theme_font_size_override("font_size", 26)
	_confirm_button.pressed.connect(_on_confirm_preview_pressed)
	_confirm_button.focus_entered.connect(_on_focusable_control_entered.bind(_confirm_button))
	preview_actions.add_child(_confirm_button)

	_revert_button = Button.new()
	_revert_button.text = "Revert"
	_revert_button.custom_minimum_size = Vector2(180, 54)
	_revert_button.add_theme_font_size_override("font_size", 26)
	_revert_button.pressed.connect(_on_revert_preview_pressed)
	_revert_button.focus_entered.connect(_on_focusable_control_entered.bind(_revert_button))
	preview_actions.add_child(_revert_button)

	content.add_child(_build_section_title("Audio"))
	_master_slider = _create_slider_row(content, "Master Volume", _on_master_volume_changed)
	_music_slider = _create_slider_row(content, "Music Volume", _on_music_volume_changed)
	_sfx_slider = _create_slider_row(content, "SFX Volume", _on_sfx_volume_changed)
	_ambience_slider = _create_slider_row(content, "Ambience Volume", _on_ambience_volume_changed)
	_ui_slider = _create_slider_row(content, "UI Volume", _on_ui_volume_changed)

	content.add_child(_build_section_title("Gameplay & UX"))
	_dialogue_speed_option = _create_option_row(content, "Dialogue Speed", [
		["Slow", DIALOGUE_SPEED_SLOW],
		["Normal", DIALOGUE_SPEED_NORMAL],
		["Fast", DIALOGUE_SPEED_FAST],
	], _on_dialogue_speed_changed)
	_screen_shake_toggle = _create_toggle_row(content, "Screen Shake", _on_screen_shake_toggled)
	_auto_advance_toggle = _create_toggle_row(content, "Auto-Advance Dialogue", _on_auto_advance_toggled)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	root.add_child(actions)

	_restore_button = Button.new()
	_restore_button.text = "Restore Defaults"
	_restore_button.custom_minimum_size = Vector2(220, 58)
	_restore_button.add_theme_font_size_override("font_size", 26)
	_restore_button.pressed.connect(_on_restore_defaults_pressed)
	_restore_button.focus_entered.connect(_on_focusable_control_entered.bind(_restore_button))
	actions.add_child(_restore_button)

	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.custom_minimum_size = Vector2(160, 58)
	_close_button.add_theme_font_size_override("font_size", 26)
	_close_button.pressed.connect(_on_close_pressed)
	_close_button.focus_entered.connect(_on_focusable_control_entered.bind(_close_button))
	actions.add_child(_close_button)

	_apply_embedded_mode()

func _build_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 30)
	return label

func _create_option_row(parent: VBoxContainer, label_text: String, entries: Array, callback: Callable) -> OptionButton:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(260, 0)
	label.add_theme_font_size_override("font_size", 24)
	row.add_child(label)

	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(320, 48)
	option.add_theme_font_size_override("font_size", 24)
	for entry in entries:
		option.add_item(String(entry[0]), int(entry[1]))
	option.item_selected.connect(callback)
	option.focus_entered.connect(_on_focusable_control_entered.bind(option))
	row.add_child(option)
	return option

func _create_toggle_row(parent: VBoxContainer, label_text: String, callback: Callable) -> CheckButton:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(260, 0)
	label.add_theme_font_size_override("font_size", 24)
	row.add_child(label)

	var toggle := CheckButton.new()
	toggle.custom_minimum_size = Vector2(260, 48)
	toggle.add_theme_font_size_override("font_size", 24)
	toggle.toggled.connect(callback)
	toggle.focus_entered.connect(_on_focusable_control_entered.bind(toggle))
	row.add_child(toggle)
	return toggle

func _create_slider_row(parent: VBoxContainer, label_text: String, callback: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(260, 0)
	label.add_theme_font_size_override("font_size", 24)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.custom_minimum_size = Vector2(320, 48)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	slider.focus_entered.connect(_on_focusable_control_entered.bind(slider))
	row.add_child(slider)

	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.custom_minimum_size = Vector2(74, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 24)
	row.add_child(value_label)

	return slider

func _build_resolution_entries() -> Array:
	var entries: Array = []
	for i in range(_resolution_values.size()):
		var resolution: Vector2i = _resolution_values[i]
		entries.append(["%d x %d" % [resolution.x, resolution.y], i])
	return entries

func _connect_manager_signals() -> void:
	if SettingsManager == null:
		return
	if not SettingsManager.settings_changed.is_connected(_on_settings_changed):
		SettingsManager.settings_changed.connect(_on_settings_changed)
	if not SettingsManager.display_preview_started.is_connected(_on_display_preview_started):
		SettingsManager.display_preview_started.connect(_on_display_preview_started)
	if not SettingsManager.display_preview_updated.is_connected(_on_display_preview_updated):
		SettingsManager.display_preview_updated.connect(_on_display_preview_updated)
	if not SettingsManager.display_preview_finished.is_connected(_on_display_preview_finished):
		SettingsManager.display_preview_finished.connect(_on_display_preview_finished)

func _disconnect_manager_signals() -> void:
	if SettingsManager == null:
		return
	if SettingsManager.settings_changed.is_connected(_on_settings_changed):
		SettingsManager.settings_changed.disconnect(_on_settings_changed)
	if SettingsManager.display_preview_started.is_connected(_on_display_preview_started):
		SettingsManager.display_preview_started.disconnect(_on_display_preview_started)
	if SettingsManager.display_preview_updated.is_connected(_on_display_preview_updated):
		SettingsManager.display_preview_updated.disconnect(_on_display_preview_updated)
	if SettingsManager.display_preview_finished.is_connected(_on_display_preview_finished):
		SettingsManager.display_preview_finished.disconnect(_on_display_preview_finished)

func _apply_embedded_mode() -> void:
	if _title_label != null:
		_title_label.visible = not _embedded_mode
	if _close_button != null:
		_close_button.visible = not _embedded_mode

func focus_default_control() -> void:
	if not is_visible_in_tree():
		return

	if _preview_box != null and _preview_box.visible and _confirm_button != null and _confirm_button.visible:
		_confirm_button.grab_focus()
		return

	var focus_candidates: Array[Control] = [
		_mode_option,
		_resolution_option,
		_vsync_toggle,
		_master_slider,
		_music_slider,
		_sfx_slider,
		_ambience_slider,
		_ui_slider,
		_dialogue_speed_option,
		_screen_shake_toggle,
		_auto_advance_toggle,
		_restore_button,
		_close_button,
	]

	for candidate in focus_candidates:
		if _is_focus_candidate_interactable(candidate):
			candidate.grab_focus()
			return

func _is_focus_candidate_interactable(candidate: Control) -> bool:
	if candidate == null or not candidate.visible:
		return false
	if candidate.get_focus_mode_with_override() != Control.FOCUS_ALL:
		return false
	if candidate is BaseButton and (candidate as BaseButton).disabled:
		return false
	return true

func _on_focusable_control_entered(control: Control) -> void:
	if _scroll_container == null or control == null:
		return
	if not _scroll_container.is_ancestor_of(control):
		return
	_scroll_container.ensure_control_visible(control)

func _refresh_from_settings() -> void:
	if SettingsManager == null:
		return

	_is_refreshing = true
	var settings := SettingsManager.get_settings_copy()
	_mode_option.select(_mode_index_from_name(String(settings.get("display_mode", "borderless"))))
	_resolution_option.select(_resolution_index_from_value(Vector2i(int(settings.get("window_width", 2560)), int(settings.get("window_height", 1440)))))
	_vsync_toggle.button_pressed = bool(settings.get("vsync_enabled", true))
	_master_slider.value = float(settings.get("master_volume", 100.0))
	_music_slider.value = float(settings.get("music_volume", 50.0))
	_sfx_slider.value = float(settings.get("sfx_volume", 80.0))
	_ambience_slider.value = float(settings.get("ambience_volume", 70.0))
	_ui_slider.value = float(settings.get("ui_volume", 60.0))
	_dialogue_speed_option.select(_dialogue_speed_index_from_value(float(settings.get("dialogue_speed", 1.0))))
	_screen_shake_toggle.button_pressed = bool(settings.get("screen_shake_enabled", true))
	_auto_advance_toggle.button_pressed = bool(settings.get("auto_advance_dialogue", false))
	_update_slider_value_labels()
	_update_resolution_interactivity()
	_is_refreshing = false

func _update_slider_value_labels() -> void:
	_set_slider_value_label(_master_slider)
	_set_slider_value_label(_music_slider)
	_set_slider_value_label(_sfx_slider)
	_set_slider_value_label(_ambience_slider)
	_set_slider_value_label(_ui_slider)

func _set_slider_value_label(slider: HSlider) -> void:
	if slider == null:
		return
	var label := slider.get_parent().get_node_or_null("ValueLabel") as Label
	if label != null:
		label.text = "%d%%" % int(round(slider.value))

func _update_resolution_interactivity() -> void:
	var is_windowed := _mode_option.get_selected_id() == DISPLAY_MODE_WINDOWED
	_resolution_option.disabled = not is_windowed
	_resolution_option.modulate.a = 1.0 if is_windowed else 0.5

func _mode_index_from_name(mode_name: String) -> int:
	match mode_name:
		"windowed":
			return DISPLAY_MODE_WINDOWED
		"exclusive_fullscreen":
			return DISPLAY_MODE_EXCLUSIVE
		_:
			return DISPLAY_MODE_BORDERLESS

func _mode_name_from_index(index: int) -> String:
	match index:
		DISPLAY_MODE_WINDOWED:
			return "windowed"
		DISPLAY_MODE_EXCLUSIVE:
			return "exclusive_fullscreen"
		_:
			return "borderless"

func _resolution_index_from_value(value: Vector2i) -> int:
	for i in range(_resolution_values.size()):
		if _resolution_values[i] == value:
			return i
	return 0

func _dialogue_speed_index_from_value(value: float) -> int:
	if value <= 0.85:
		return DIALOGUE_SPEED_SLOW
	if value >= 1.2:
		return DIALOGUE_SPEED_FAST
	return DIALOGUE_SPEED_NORMAL

func _dialogue_speed_value_from_index(index: int) -> float:
	match index:
		DIALOGUE_SPEED_SLOW:
			return 0.8
		DIALOGUE_SPEED_FAST:
			return 1.35
		_:
			return 1.0

func _current_resolution() -> Vector2i:
	var selected_index := maxi(_resolution_option.get_selected_id(), 0)
	if selected_index >= 0 and selected_index < _resolution_values.size():
		return _resolution_values[selected_index]
	return _resolution_values[0] if not _resolution_values.is_empty() else Vector2i(1280, 720)

func _preview_current_display_settings() -> void:
	if _is_refreshing or SettingsManager == null:
		return

	SettingsManager.preview_display_settings(
		_mode_name_from_index(_mode_option.get_selected_id()),
		_current_resolution(),
		_vsync_toggle.button_pressed
	)

func _show_preview_box(seconds_left: int) -> void:
	_preview_box.visible = true
	_preview_label.text = "Keep these display settings? They will revert automatically in %d seconds." % seconds_left
	if _confirm_button != null and _confirm_button.visible:
		_confirm_button.grab_focus()

func _hide_preview_box() -> void:
	if _preview_box != null:
		_preview_box.visible = false

func _on_display_mode_changed(_index: int) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	_update_resolution_interactivity()
	_preview_current_display_settings()

func _on_resolution_changed(_index: int) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	_preview_current_display_settings()

func _on_vsync_toggled(_pressed: bool) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	_preview_current_display_settings()

func _on_master_volume_changed(value: float) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	_set_slider_value_label(_master_slider)
	SettingsManager.set_audio_volume("master_volume", value)

func _on_music_volume_changed(value: float) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	_set_slider_value_label(_music_slider)
	SettingsManager.set_audio_volume("music_volume", value)

func _on_sfx_volume_changed(value: float) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	_set_slider_value_label(_sfx_slider)
	SettingsManager.set_audio_volume("sfx_volume", value)

func _on_ambience_volume_changed(value: float) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	_set_slider_value_label(_ambience_slider)
	SettingsManager.set_audio_volume("ambience_volume", value)

func _on_ui_volume_changed(value: float) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	_set_slider_value_label(_ui_slider)
	SettingsManager.set_audio_volume("ui_volume", value)

func _on_dialogue_speed_changed(index: int) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	SettingsManager.set_dialogue_speed(_dialogue_speed_value_from_index(index))

func _on_screen_shake_toggled(enabled: bool) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	SettingsManager.set_screen_shake_enabled(enabled)

func _on_auto_advance_toggled(enabled: bool) -> void:
	if _is_refreshing or SettingsManager == null:
		return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	SettingsManager.set_auto_advance_dialogue(enabled)

func _on_confirm_preview_pressed() -> void:
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	if SettingsManager:
		SettingsManager.confirm_display_preview()

func _on_revert_preview_pressed() -> void:
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	if SettingsManager:
		SettingsManager.revert_display_preview()

func _on_restore_defaults_pressed() -> void:
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	if SettingsManager:
		SettingsManager.restore_defaults()
		_refresh_from_settings()

func _on_close_pressed() -> void:
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	close_requested.emit()

func _on_settings_changed(_settings: Dictionary) -> void:
	_refresh_from_settings()

func _on_display_preview_started(timeout_seconds: int) -> void:
	_show_preview_box(timeout_seconds)

func _on_display_preview_updated(seconds_left: int) -> void:
	_show_preview_box(seconds_left)

func _on_display_preview_finished(_confirmed: bool) -> void:
	_hide_preview_box()
	_refresh_from_settings()
	call_deferred("focus_default_control")
