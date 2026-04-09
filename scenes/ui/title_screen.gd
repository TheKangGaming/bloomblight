extends Control

const TITLE_FADE_IN_DURATION := 0.38
const TITLE_BUTTON_STAGGER := 0.05
const TITLE_MUSIC_FADE_IN := 0.32
const START_BUTTON_PRESS_SCALE := Vector2(0.94, 0.94)
const START_BUTTON_IDLE_SCALE := Vector2.ONE
const TITLE_BUTTON_HOVER_SCALE := Vector2(1.04, 1.04)
const TITLE_LABEL_PULSE_SCALE := Vector2(1.02, 1.02)
const TITLE_FLASH_DURATION := 0.07
const TITLE_FLASH_RECOVERY := 0.12
const TITLE_START_OVERLAP_DELAY := 0.025

@onready var menu_root: Control = $MarginContainer
@onready var start_button: Button = $MarginContainer/VBoxContainer/Buttons/StartButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/Buttons/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/Buttons/QuitButton
@onready var title_label: Label = $MarginContainer/VBoxContainer/Label
@onready var fade_rect: ColorRect = $FadeRect
@onready var atmosphere_particles: GPUParticles2D = $AtmosphereParticles

const SETTINGS_MODAL_SCENE := preload("res://scenes/ui/settings_modal.tscn")
const GAME_SCENE_PATH := "res://scenes/level/game.tscn"

@export var title_music: AudioStream 

var _is_transitioning: bool = true
var _fade_tween: Tween

func _ui_sound_manager() -> Node:
	return get_node_or_null("/root/UISoundManager")

func _ready() -> void:
	get_tree().root.size_changed.connect(_update_particle_layout)
	_update_particle_layout()
	fade_rect.modulate.a = 1.0 
	start_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true
	
	start_button.modulate.a = 0.0
	settings_button.modulate.a = 0.0
	quit_button.modulate.a = 0.0
	title_label.modulate.a = 0.0
	title_label.scale = Vector2.ONE
	menu_root.modulate.a = 1.0
	start_button.scale = START_BUTTON_IDLE_SCALE
	settings_button.scale = START_BUTTON_IDLE_SCALE
	quit_button.scale = START_BUTTON_IDLE_SCALE
		
	if title_music:
		MusicManager.crossfade_to(title_music, TITLE_MUSIC_FADE_IN)
		
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, TITLE_FADE_IN_DURATION)
	
	_fade_tween.parallel().tween_property(title_label, "modulate:a", 1.0, 0.28).set_delay(0.04)
	_fade_tween.parallel().tween_property(start_button, "modulate:a", 1.0, 0.2).set_delay(0.08)
	_fade_tween.parallel().tween_property(settings_button, "modulate:a", 1.0, 0.2).set_delay(0.08 + TITLE_BUTTON_STAGGER)
	_fade_tween.parallel().tween_property(quit_button, "modulate:a", 1.0, 0.2).set_delay(0.08 + (TITLE_BUTTON_STAGGER * 2.0))
	
	_fade_tween.tween_callback(_on_fade_in_complete)
	
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_wire_button_feedback(start_button)
	_wire_button_feedback(settings_button)
	_wire_button_feedback(quit_button)

func _on_fade_in_complete() -> void:
	_is_transitioning = false
	start_button.disabled = false
	settings_button.disabled = false
	quit_button.disabled = false
	
	# Hold focus until the fade is over so controller players do not move around in the dark.
	start_button.grab_focus()

func _on_settings_pressed() -> void:
	if _is_transitioning:
		return

	var modal := SETTINGS_MODAL_SCENE.instantiate()
	add_child(modal)

func _on_start_pressed() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_start_game()
	start_button.disabled = true 
	settings_button.disabled = true
	quit_button.disabled = true

	Global.begin_loop_hub_run()
	_play_start_transition()

func _play_start_transition() -> void:
	var press_tween := create_tween().set_parallel(true)
	press_tween.tween_property(start_button, "scale", START_BUTTON_PRESS_SCALE, 0.03).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	press_tween.tween_property(menu_root, "modulate:a", 0.0, 0.08).set_delay(0.005)
	press_tween.tween_property(atmosphere_particles, "modulate:a", 0.0, 0.08)

	if MusicManager and MusicManager.has_method("fade_to_silence"):
		MusicManager.fade_to_silence(0.08)

	await get_tree().create_timer(TITLE_START_OVERLAP_DELAY, true).timeout
	_begin_demo_scene_transition()

func _begin_demo_scene_transition() -> void:
	if TransitionManager and TransitionManager.has_method("change_scene_path_bloom"):
		TransitionManager.change_scene_path_bloom(GAME_SCENE_PATH, TITLE_FLASH_DURATION, TITLE_FLASH_RECOVERY)
	else:
		TransitionManager.change_scene_path(GAME_SCENE_PATH, 0.16)

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
