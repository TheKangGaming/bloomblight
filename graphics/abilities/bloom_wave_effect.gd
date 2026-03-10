extends Node2D
class_name BloomWaveEffect

var current_radius: float = 0.0
var max_radius: float = 100.0

func _ready() -> void:
	var tween = create_tween()
	tween.set_parallel(true) # Make the size and transparency animate at the same time
	
	# Grow the circle outward smoothly
	tween.tween_property(self, "current_radius", max_radius, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Fade it to invisible
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	
	# Delete it when finished!
	tween.chain().tween_callback(queue_free)

func _process(_delta: float) -> void:
	# Forces Godot to redraw the circle every single frame while the tween is running
	queue_redraw()

func _draw() -> void:
	# 1. The inner translucent green fill
	draw_circle(Vector2.ZERO, current_radius, Color(0.2, 0.8, 0.3, 0.4))
	# 2. The bright green glowing outer ring
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, Color(0.4, 0.9, 0.4, 0.8), 2.0)
