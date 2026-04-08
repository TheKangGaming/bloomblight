extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/Buttons/StartButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/Buttons/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/Buttons/QuitButton
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
	
	if title_music:
		MusicManager.crossfade_to(title_music, 1.0)
		
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 2.5)
	
	_fade_tween.parallel().tween_property(start_button, "modulate:a", 1.0, 2.0).set_delay(1.0)
	_fade_tween.parallel().tween_property(settings_button, "modulate:a", 1.0, 2.0).set_delay(1.25)
	_fade_tween.parallel().tween_property(quit_button, "modulate:a", 1.0, 2.0).set_delay(1.5)
	
	_fade_tween.tween_callback(_on_fade_in_complete)
	
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

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
	_begin_demo_scene_transition()

func _begin_demo_scene_transition() -> void:
	TransitionManager.change_scene_path(GAME_SCENE_PATH)

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
