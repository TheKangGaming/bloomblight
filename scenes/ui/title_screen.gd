extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/Buttons/StartButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/Buttons/QuitButton
@onready var fade_rect: ColorRect = $FadeRect
@onready var atmosphere_particles: GPUParticles2D = $AtmosphereParticles

@export var title_music: AudioStream 
@export var game_scene: PackedScene # The unbreakable scene reference

# 1. State guards and tween references
var _is_transitioning: bool = true
var _fade_tween: Tween

func _ready() -> void:
	get_tree().root.size_changed.connect(_update_particle_layout)
	_update_particle_layout()
	fade_rect.modulate.a = 1.0 
	start_button.disabled = true
	quit_button.disabled = true
	
	# Start buttons completely transparent
	start_button.modulate.a = 0.0
	quit_button.modulate.a = 0.0
	
	if title_music:
		MusicManager.crossfade_to(title_music, 1.0)
		
	# 1. Fade the black screen away
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 2.5)
	
	# 2. Fade the buttons in shortly after
	_fade_tween.parallel().tween_property(start_button, "modulate:a", 1.0, 2.0).set_delay(1.0)
	_fade_tween.parallel().tween_property(quit_button, "modulate:a", 1.0, 2.0).set_delay(1.5)
	
	_fade_tween.tween_callback(_on_fade_in_complete)
	
	# 3. CRITICAL RESTORATION: Connect the buttons so the game actually starts!
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_fade_in_complete() -> void:
	# 4. Unlock the state only when the fade is 100% finished
	_is_transitioning = false
	start_button.disabled = false
	quit_button.disabled = false
	
	# Grab focus here so controller players don't blind-scroll in the dark
	start_button.grab_focus()

func _on_start_pressed() -> void:
	if _is_transitioning:
		return
		
	_is_transitioning = true
	start_button.disabled = true 
	quit_button.disabled = true
	
	# Call our new global manager to handle the heavy lifting
	TransitionManager.change_scene(game_scene)


func _on_quit_pressed() -> void:
	if _is_transitioning:
		return
	get_tree().quit()

func _update_particle_layout() -> void:
	# Get the actual size of the player's window
	var screen_size = get_viewport_rect().size
	
	# Center the emitter perfectly
	atmosphere_particles.position = screen_size / 2.0
	
	# Scale the emission box to fill the new screen size
	var mat = atmosphere_particles.process_material as ParticleProcessMaterial
	if mat:
		mat.emission_box_extents = Vector3(screen_size.x / 2.0, screen_size.y / 2.0, 1.0)
