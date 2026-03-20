extends CanvasLayer

signal overlay_closed
@onready var fade_rect: ColorRect = $FadeRect
var _is_transitioning: bool = false

func change_scene(scene: PackedScene, fade_duration: float = 1.5) -> void:
	if _is_transitioning or scene == null:
		return
		
	_is_transitioning = true
	
	# 1. Fade to black
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	
	# 2. Swap the scene invisibly while the screen is black, then fade back in
	tween.tween_callback(func():
		get_tree().change_scene_to_packed(scene)
		
		var in_tween = create_tween()
		in_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
		in_tween.tween_callback(func(): _is_transitioning = false)
)

func open_overlay(scene: PackedScene, fade_duration: float = 0.5) -> void:
	if _is_transitioning or scene == null:
		return
		
	_is_transitioning = true
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	
	tween.tween_callback(func():
		var overlay = scene.instantiate()
		
		# Add the battle scene directly on top of the current map
		get_tree().current_scene.add_child(overlay)
		
		# Optional: Pause the map so enemies don't walk around during the animation
		get_tree().paused = true 
		
		var in_tween = create_tween()
		in_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
		in_tween.tween_callback(func(): _is_transitioning = false)
	)

func close_overlay(overlay_node: Node, fade_duration: float = 0.5) -> void:
	if _is_transitioning or overlay_node == null:
		return
		
	_is_transitioning = true
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	
	tween.tween_callback(func():
		# Destroy the battle scene
		overlay_node.queue_free()
		
		# Unpause the map
		get_tree().paused = false
		
		var in_tween = create_tween()
		in_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
		in_tween.tween_callback(func(): 
			_is_transitioning = false
			# ADD THIS LINE: Tell the game the door is fully closed
			overlay_closed.emit()
		)
)
