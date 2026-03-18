extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/Buttons/StartButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/Buttons/QuitButton
@onready var fade_rect: ColorRect = $FadeRect

@export var title_music: AudioStream 

func _ready() -> void:
	# 1. Start the screen completely black
	fade_rect.modulate.a = 1.0 
	
	# 2. Elegantly fade in over 2 seconds
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 2.0)
	
	start_button.grab_focus()
	
	if title_music:
		MusicManager.crossfade_to(title_music, 1.0)

	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	# Disable the button so the player can't spam-click it during the fade
	start_button.disabled = true 
	quit_button.disabled = true
	
	# Fade to black over 1.5 seconds
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5)
	
	# Wait for the fade to finish, then load the map
	tween.tween_callback(_load_farm_map)

func _load_farm_map() -> void:
	# WARNING: Make sure this path exactly matches your main game scene!
	get_tree().change_scene_to_file("res://scenes/level/game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
