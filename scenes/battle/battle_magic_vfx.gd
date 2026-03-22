class_name BattleMagicVfx extends Node2D

var beam_height := 0.0:
	set(value):
		beam_height = maxf(0.0, value)
		queue_redraw()

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var outer_width := 34.0
	var inner_width := 18.0
	var height := maxf(beam_height, 1.0)

	draw_colored_polygon(
		[
			Vector2(-outer_width * 0.5, 0.0),
			Vector2(outer_width * 0.5, 0.0),
			Vector2(outer_width * 0.3, -height),
			Vector2(-outer_width * 0.3, -height)
		],
		Color(0.49, 0.22, 1.0, 0.72)
	)
	draw_colored_polygon(
		[
			Vector2(-inner_width * 0.5, 0.0),
			Vector2(inner_width * 0.5, 0.0),
			Vector2(inner_width * 0.35, -height),
			Vector2(-inner_width * 0.35, -height)
		],
		Color(0.93, 0.86, 1.0, 0.88)
	)
	draw_circle(Vector2(0.0, -height), 10.0, Color(0.77, 0.5, 1.0, 0.45))
