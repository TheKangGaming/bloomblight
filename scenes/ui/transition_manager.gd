extends CanvasLayer

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
