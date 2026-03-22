extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/Buttons/StartButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/Buttons/QuitButton
@onready var fade_rect: ColorRect = $FadeRect
@onready var atmosphere_particles: GPUParticles2D = $AtmosphereParticles

@export var title_music: AudioStream 
@export var game_scene: PackedScene

var _is_transitioning: bool = true
var _fade_tween: Tween

func _ready() -> void:
	get_tree().root.size_changed.connect(_update_particle_layout)
	_update_particle_layout()
	fade_rect.modulate.a = 1.0 
	start_button.disabled = true
	quit_button.disabled = true
	
	start_button.modulate.a = 0.0
	quit_button.modulate.a = 0.0
	
	if title_music:
		MusicManager.crossfade_to(title_music, 1.0)
		
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 2.5)
	
	_fade_tween.parallel().tween_property(start_button, "modulate:a", 1.0, 2.0).set_delay(1.0)
	_fade_tween.parallel().tween_property(quit_button, "modulate:a", 1.0, 2.0).set_delay(1.5)
	
	_fade_tween.tween_callback(_on_fade_in_complete)
	
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_fade_in_complete() -> void:
	_is_transitioning = false
	start_button.disabled = false
	quit_button.disabled = false
	
	# Hold focus until the fade is over so controller players do not move around in the dark.
	start_button.grab_focus()

func _on_start_pressed() -> void:
	if _is_transitioning:
		return
		
	_is_transitioning = true
	start_button.disabled = true 
	quit_button.disabled = true
	
	TransitionManager.change_scene(game_scene)


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
