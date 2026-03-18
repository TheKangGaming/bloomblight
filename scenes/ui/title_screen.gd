extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/Buttons/StartButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/Buttons/QuitButton
@onready var fade_rect: ColorRect = $FadeRect

@export var title_music: AudioStream 
@export var game_scene: PackedScene # The unbreakable scene reference

# 1. State guards and tween references
var _is_transitioning: bool = true
var _fade_tween: Tween

func _ready() -> void:
	fade_rect.modulate.a = 1.0 
	start_button.disabled = true
	quit_button.disabled = true
	
	# Start buttons completely transparent
	start_button.modulate.a = 0.0
	quit_button.modulate.a = 0.0
	
	if title_music:
		MusicManager.crossfade_to(title_music, 1.0)
		
	# 1. Fade the black screen away (Revealing the title and particles)
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 2.5)
	
	# 2. Fade the buttons in shortly after
	_fade_tween.parallel().tween_property(start_button, "modulate:a", 1.0, 2.0).set_delay(1.0)
	_fade_tween.parallel().tween_property(quit_button, "modulate:a", 1.0, 2.0).set_delay(1.5)
	
	_fade_tween.tween_callback(_on_fade_in_complete)

func _on_fade_in_complete() -> void:
	# 4. Unlock the state only when the fade is 100% finished
	_is_transitioning = false
	start_button.disabled = false
	quit_button.disabled = false
	
	# Grab focus here so controller players don't blind-scroll in the dark
	start_button.grab_focus()

func _on_start_pressed() -> void:
	# Double-check the state guard just in case
	if _is_transitioning:
		return
		
	_is_transitioning = true
	start_button.disabled = true 
	quit_button.disabled = true
	
	# 5. Kill the intro tween if it's somehow still hanging around
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5)
	_fade_tween.tween_callback(_load_farm_map)

func _load_farm_map() -> void:
	if game_scene:
		# Loads the assigned scene using its UID, immune to file path changes
		get_tree().change_scene_to_packed(game_scene)
	else:
		# Fails gracefully and alerts you if the field is empty
		push_error("Title Screen Error: No game scene assigned in the Inspector!")

func _on_quit_pressed() -> void:
	if _is_transitioning:
		return
	get_tree().quit()
