extends Control

const TITLE_FADE_IN_DURATION := 0.38
const TITLE_BUTTON_STAGGER := 0.05
const TITLE_MUSIC_FADE_IN := 0.32
const START_BUTTON_PRESS_SCALE := Vector2(0.94, 0.94)
const START_BUTTON_IDLE_SCALE := Vector2.ONE
const TITLE_BUTTON_HOVER_SCALE := Vector2(1.04, 1.04)
const TITLE_LABEL_PULSE_SCALE := Vector2(1.02, 1.02)
const TITLE_FLASH_DURATION := 0.09
const TITLE_FLASH_RECOVERY := 0.22
const TITLE_START_OVERLAP_DELAY := 0.025
const TITLE_START_MUSIC_DUCK := 0.13
const TITLE_POST_SWAP_DIM_ALPHA := 0.52
const INTRO_LINE_FADE_IN := 0.42
const INTRO_LINE_FADE_OUT := 0.36
const INTRO_FINAL_HOLD := 0.3
const INTRO_SKIP_HOLD := 0.06
const INTRO_ADVANCE_BUFFER := 0.08
const OPENING_LINES := [
	"The world turned to ash.",
	"The Empire came for the girl who could stop it.",
	"The soldier chose to save her instead.",
]

@onready var menu_root: Control = $MarginContainer
@onready var start_button: Button = $MarginContainer/VBoxContainer/Buttons/StartButton
@onready var continue_button: Button = $MarginContainer/VBoxContainer/Buttons/ContinueButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/Buttons/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/Buttons/QuitButton
@onready var title_label: Label = $MarginContainer/VBoxContainer/Label
@onready var fade_rect: ColorRect = $FadeRect
@onready var atmosphere_particles: GPUParticles2D = $AtmosphereParticles
@onready var intro_overlay: Control = $IntroOverlay
@onready var intro_label: Label = $IntroOverlay/CenterContainer/MarginContainer/VBoxContainer/IntroLabel
@onready var intro_hint: Label = $IntroOverlay/CenterContainer/MarginContainer/VBoxContainer/IntroHint

const SETTINGS_MODAL_SCENE := preload("res://scenes/ui/settings_modal.tscn")
const GAME_SCENE_PATH := "res://scenes/level/game.tscn"

@export var title_music: AudioStream 

var _is_transitioning: bool = true
var _fade_tween: Tween
var _cached_game_scene: PackedScene = null
var _intro_active := false
var _intro_advance_requested := false
var _intro_skip_requested := false
var _intro_tween: Tween = null
var _new_game_confirm_open := false
var _new_game_confirm_overlay: Control = null
var _new_game_confirm_button: Button = null
var _new_game_cancel_button: Button = null
var _title_notice_root: PanelContainer = null
var _title_notice_label: Label = null
var _title_notice_tween: Tween = null

func _ui_sound_manager() -> Node:
	return get_node_or_null("/root/UISoundManager")

func _log_run_start(message: String) -> void:
	if OS.is_debug_build():
		print("[RunStart][Title] %d %s" % [Time.get_ticks_msec(), message])

func _ready() -> void:
	get_tree().root.size_changed.connect(_update_particle_layout)
	_update_particle_layout()
	fade_rect.modulate.a = 1.0 
	start_button.disabled = true
	continue_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true
	
	start_button.modulate.a = 0.0
	continue_button.modulate.a = 0.0
	settings_button.modulate.a = 0.0
	quit_button.modulate.a = 0.0
	title_label.modulate.a = 0.0
	title_label.scale = Vector2.ONE
	menu_root.modulate.a = 1.0
	intro_overlay.visible = false
	intro_overlay.modulate.a = 0.0
	intro_label.modulate.a = 0.0
	intro_hint.modulate.a = 0.0
	start_button.scale = START_BUTTON_IDLE_SCALE
	continue_button.scale = START_BUTTON_IDLE_SCALE
	settings_button.scale = START_BUTTON_IDLE_SCALE
	quit_button.scale = START_BUTTON_IDLE_SCALE
	continue_button.visible = _can_continue()
	_build_new_game_overwrite_prompt()
	_build_title_notice()

	_cached_game_scene = Global.get_preloaded_launch_scene(GAME_SCENE_PATH)
	if title_music:
		MusicManager.crossfade_to(title_music, TITLE_MUSIC_FADE_IN)
		
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, TITLE_FADE_IN_DURATION)
	
	_fade_tween.parallel().tween_property(title_label, "modulate:a", 1.0, 0.28).set_delay(0.04)
	_fade_tween.parallel().tween_property(start_button, "modulate:a", 1.0, 0.2).set_delay(0.08)
	_fade_tween.parallel().tween_property(continue_button, "modulate:a", 1.0 if _can_continue() else 0.0, 0.2).set_delay(0.08 + TITLE_BUTTON_STAGGER)
	_fade_tween.parallel().tween_property(settings_button, "modulate:a", 1.0, 0.2).set_delay(0.08 + (TITLE_BUTTON_STAGGER * 2.0))
	_fade_tween.parallel().tween_property(quit_button, "modulate:a", 1.0, 0.2).set_delay(0.08 + (TITLE_BUTTON_STAGGER * 3.0))
	
	_fade_tween.tween_callback(_on_fade_in_complete)
	
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_wire_button_feedback(start_button)
	_wire_button_feedback(continue_button)
	_wire_button_feedback(settings_button)
	_wire_button_feedback(quit_button)

func _on_fade_in_complete() -> void:
	_is_transitioning = false
	start_button.disabled = false
	continue_button.disabled = not _can_continue()
	continue_button.visible = _can_continue()
	settings_button.disabled = false
	quit_button.disabled = false
	
	# Hold focus until the fade is over so controller players do not move around in the dark.
	start_button.grab_focus()

func _build_new_game_overwrite_prompt() -> void:
	if _new_game_confirm_overlay != null and is_instance_valid(_new_game_confirm_overlay):
		return

	var overlay := Control.new()
	overlay.name = "NewGameOverwritePrompt"
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240.0
	panel.offset_top = -110.0
	panel.offset_right = 240.0
	panel.offset_bottom = 110.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.1, 0.96)
	panel_style.border_color = Color(0.88, 0.82, 0.56, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	margin.add_child(stack)

	var title := Label.new()
	title.text = "Overwrite Current Run?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	stack.add_child(title)

	var body := Label.new()
	body.text = "Starting a new game will replace your current save.\nContinue only if you want to begin a fresh run."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 20)
	stack.add_child(body)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	stack.add_child(buttons)

	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(160, 54)
	buttons.add_child(cancel_button)

	var confirm_button := Button.new()
	confirm_button.text = "Start New Game"
	confirm_button.custom_minimum_size = Vector2(190, 54)
	buttons.add_child(confirm_button)

	cancel_button.focus_neighbor_right = cancel_button.get_path_to(confirm_button)
	confirm_button.focus_neighbor_left = confirm_button.get_path_to(cancel_button)

	cancel_button.pressed.connect(_close_new_game_overwrite_prompt)
	confirm_button.pressed.connect(_confirm_new_game_overwrite_prompt)
	_wire_button_feedback(cancel_button)
	_wire_button_feedback(confirm_button)

	add_child(overlay)
	_new_game_confirm_overlay = overlay
	_new_game_cancel_button = cancel_button
	_new_game_confirm_button = confirm_button

func _build_title_notice() -> void:
	if _title_notice_root != null and is_instance_valid(_title_notice_root):
		return

	var notice_panel := PanelContainer.new()
	notice_panel.name = "TitleNotice"
	notice_panel.visible = false
	notice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_panel.anchor_left = 0.5
	notice_panel.anchor_right = 0.5
	notice_panel.anchor_top = 1.0
	notice_panel.anchor_bottom = 1.0
	notice_panel.offset_left = -260.0
	notice_panel.offset_right = 260.0
	notice_panel.offset_top = -132.0
	notice_panel.offset_bottom = -52.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.1, 0.94)
	panel_style.border_color = Color(0.96, 0.78, 0.44, 0.96)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	notice_panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	notice_panel.add_child(margin)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 20)
	margin.add_child(label)

	add_child(notice_panel)
	_title_notice_root = notice_panel
	_title_notice_label = label

func _show_title_notice(text: String, duration: float = 2.2) -> void:
	if _title_notice_root == null or not is_instance_valid(_title_notice_root) or _title_notice_label == null:
		return

	if _title_notice_tween != null and is_instance_valid(_title_notice_tween):
		_title_notice_tween.kill()

	_title_notice_label.text = text
	_title_notice_root.visible = true
	_title_notice_root.modulate.a = 0.0
	_title_notice_tween = create_tween()
	_title_notice_tween.tween_property(_title_notice_root, "modulate:a", 1.0, 0.18)
	_title_notice_tween.tween_interval(maxf(duration, 0.2))
	_title_notice_tween.tween_property(_title_notice_root, "modulate:a", 0.0, 0.22)
	_title_notice_tween.tween_callback(func() -> void:
		if _title_notice_root != null and is_instance_valid(_title_notice_root):
			_title_notice_root.visible = false
	)

func _open_new_game_overwrite_prompt() -> void:
	if _new_game_confirm_overlay == null or not is_instance_valid(_new_game_confirm_overlay):
		return
	_new_game_confirm_open = true
	_new_game_confirm_overlay.visible = true
	start_button.disabled = true
	continue_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true
	if _new_game_cancel_button != null and is_instance_valid(_new_game_cancel_button):
		_new_game_cancel_button.grab_focus()

func _close_new_game_overwrite_prompt() -> void:
	if _new_game_confirm_overlay == null or not is_instance_valid(_new_game_confirm_overlay):
		return
	_new_game_confirm_open = false
	_new_game_confirm_overlay.visible = false
	if _is_transitioning:
		return
	start_button.disabled = false
	continue_button.disabled = not _can_continue()
	settings_button.disabled = false
	quit_button.disabled = false
	start_button.grab_focus()

func _confirm_new_game_overwrite_prompt() -> void:
	_close_new_game_overwrite_prompt()
	_begin_new_game_start()

func _begin_new_game_start() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_log_run_start("Start pressed")
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_start_game()
	start_button.disabled = true
	continue_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true

	Global.begin_loop_hub_run()
	call_deferred("_play_new_game_intro_sequence")

func _on_settings_pressed() -> void:
	if _is_transitioning:
		return

	var modal := SETTINGS_MODAL_SCENE.instantiate()
	add_child(modal)

func _on_start_pressed() -> void:
	if _is_transitioning or _new_game_confirm_open:
		return

	if _can_continue():
		_open_new_game_overwrite_prompt()
		return

	_begin_new_game_start()

func _on_continue_pressed() -> void:
	if _is_transitioning or not _can_continue():
		return

	_is_transitioning = true
	_log_run_start("Continue pressed")
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_start_game()
	start_button.disabled = true
	continue_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true

	if SaveManager == null or not SaveManager.has_method("load_current_run") or not SaveManager.load_current_run():
		_is_transitioning = false
		start_button.disabled = false
		continue_button.disabled = not _can_continue()
		settings_button.disabled = false
		quit_button.disabled = false
		_show_title_notice("Continue failed. The current save could not be loaded.")
		if _can_continue():
			continue_button.grab_focus()
		else:
			start_button.grab_focus()
		return

	_play_start_transition()

func _play_start_transition() -> void:
	var press_tween := create_tween().set_parallel(true)
	press_tween.tween_property(start_button, "scale", START_BUTTON_PRESS_SCALE, 0.03).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	press_tween.tween_property(continue_button, "modulate:a", 0.0, 0.08)
	press_tween.tween_property(menu_root, "modulate:a", 0.0, 0.09).set_delay(0.004)
	press_tween.tween_property(atmosphere_particles, "modulate:a", 0.0, 0.09)

	if MusicManager and MusicManager.has_method("fade_to_silence"):
		MusicManager.fade_to_silence(TITLE_START_MUSIC_DUCK)

	await get_tree().create_timer(TITLE_START_OVERLAP_DELAY, true).timeout
	_begin_demo_scene_transition()

func _play_new_game_intro_sequence() -> void:
	await _fade_title_menu_for_intro()
	await _run_opening_intro()
	_begin_new_game_scene_transition()

func _fade_title_menu_for_intro() -> void:
	var press_tween := create_tween().set_parallel(true)
	press_tween.tween_property(start_button, "scale", START_BUTTON_PRESS_SCALE, 0.03).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	press_tween.tween_property(continue_button, "modulate:a", 0.0, 0.08)
	press_tween.tween_property(menu_root, "modulate:a", 0.0, 0.12).set_delay(0.004)
	press_tween.tween_property(atmosphere_particles, "modulate:a", 0.0, 0.12)
	if MusicManager and MusicManager.has_method("fade_to_silence"):
		MusicManager.fade_to_silence(TITLE_START_MUSIC_DUCK)
	await press_tween.finished

func _run_opening_intro() -> void:
	_intro_active = true
	_intro_advance_requested = false
	_intro_skip_requested = false
	intro_overlay.visible = true
	intro_overlay.modulate.a = 1.0
	intro_label.modulate.a = 0.0
	intro_hint.modulate.a = 0.0
	intro_hint.text = "Press %s to continue   Press %s to skip" % [_get_confirm_hint_text(), _get_cancel_hint_text()]
	var hint_tween := create_tween()
	hint_tween.tween_property(intro_hint, "modulate:a", 1.0, 0.22).set_delay(0.16)

	for line in OPENING_LINES:
		if _intro_skip_requested:
			break
		intro_label.text = line
		await _play_intro_line()

	_intro_active = false
	if _intro_tween != null and is_instance_valid(_intro_tween):
		_intro_tween.kill()
		_intro_tween = null
	var outro_tween := create_tween().set_parallel(true)
	outro_tween.tween_property(intro_label, "modulate:a", 0.0, 0.12)
	outro_tween.tween_property(intro_hint, "modulate:a", 0.0, 0.1)
	await outro_tween.finished
	await get_tree().create_timer(INTRO_SKIP_HOLD if _intro_skip_requested else INTRO_FINAL_HOLD, true).timeout
	intro_overlay.visible = false

func _play_intro_line() -> void:
	intro_label.modulate.a = 0.0
	_intro_advance_requested = false
	_intro_tween = create_tween()
	_intro_tween.tween_property(intro_label, "modulate:a", 1.0, INTRO_LINE_FADE_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _intro_tween.finished
	if _intro_skip_requested:
		return
	await get_tree().create_timer(INTRO_ADVANCE_BUFFER, true).timeout
	await _wait_for_intro_advance()
	if _intro_skip_requested:
		return
	_intro_tween = create_tween()
	_intro_tween.tween_property(intro_label, "modulate:a", 0.0, INTRO_LINE_FADE_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _intro_tween.finished

func _wait_for_intro_advance() -> void:
	while not _intro_advance_requested and not _intro_skip_requested:
		var timer := get_tree().create_timer(0.05, true)
		await timer.timeout

func _unhandled_input(event: InputEvent) -> void:
	if _new_game_confirm_open:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
			_close_new_game_overwrite_prompt()
			get_viewport().set_input_as_handled()
		return
	if not _intro_active or event == null:
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		_intro_skip_requested = true
		_intro_advance_requested = true
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_intro_advance_requested = true
		get_viewport().set_input_as_handled()
		return

func _begin_new_game_scene_transition() -> void:
	if TransitionManager == null:
		return
	_log_run_start("Scene transition begin")
	TransitionManager.change_scene_path(GAME_SCENE_PATH, 0.18)

func _begin_demo_scene_transition() -> void:
	if TransitionManager == null:
		return
	if _cached_game_scene == null:
		_cached_game_scene = Global.get_preloaded_launch_scene(GAME_SCENE_PATH)
	_log_run_start("Scene transition begin")
	if TransitionManager and _cached_game_scene != null and TransitionManager.has_method("change_scene_packed_bloom"):
		TransitionManager.change_scene_packed_bloom(_cached_game_scene, TITLE_FLASH_DURATION, TITLE_FLASH_RECOVERY, TITLE_POST_SWAP_DIM_ALPHA)
	elif TransitionManager and TransitionManager.has_method("change_scene_path_bloom"):
		_log_run_start("Falling back to path-based bloom swap")
		TransitionManager.change_scene_path_bloom(GAME_SCENE_PATH, TITLE_FLASH_DURATION, TITLE_FLASH_RECOVERY, TITLE_POST_SWAP_DIM_ALPHA)
	else:
		TransitionManager.change_scene_path(GAME_SCENE_PATH, 0.16)

func _can_continue() -> bool:
	return SaveManager != null and SaveManager.has_method("has_save") and SaveManager.has_save()

func _wire_button_feedback(button: Button) -> void:
	if button == null:
		return
	button.mouse_entered.connect(_animate_title_button.bind(button, true))
	button.mouse_exited.connect(_animate_title_button.bind(button, false))
	button.focus_entered.connect(_animate_title_button.bind(button, true))
	button.focus_exited.connect(_animate_title_button.bind(button, false))

func _animate_title_button(button: Button, highlighted: bool) -> void:
	if button == null:
		return
	var target_scale := TITLE_BUTTON_HOVER_SCALE if highlighted and not button.disabled else START_BUTTON_IDLE_SCALE
	var label_scale := TITLE_LABEL_PULSE_SCALE if highlighted else Vector2.ONE
	var tween := create_tween().set_parallel(true)
	tween.tween_property(button, "scale", target_scale, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_label, "scale", label_scale, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_quit_pressed() -> void:
	if _is_transitioning:
		return
	get_tree().quit()

func _update_particle_layout() -> void:
	var screen_size = get_viewport_rect().size
	atmosphere_particles.position = screen_size / 2.0
	var mat = atmosphere_particles.process_material as ParticleProcessMaterial
	if mat:
		mat.emission_box_extents = Vector3(screen_size.x / 2.0, screen_size.y / 2.0, 1.0)

func _get_confirm_hint_text() -> String:
	# DemoDirector still owns the shared input-label helpers used by both the
	# modern loop UI and the legacy narrative/tutorial flow.
	if DemoDirector != null:
		return DemoDirector.get_confirm_label()
	return "Enter"

func _get_cancel_hint_text() -> String:
	# Keep this DemoDirector dependency until input-label helpers are extracted
	# into a loop-safe shared service.
	if DemoDirector != null and DemoDirector.current_input_mode == DemoDirector.InputMode.CONTROLLER:
		return "B"
	return "Esc"
