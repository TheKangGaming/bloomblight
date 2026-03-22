class_name BattleProjectileVfx extends Node2D

const PROJECTILE_LENGTH := 28.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var shaft_start := Vector2(-PROJECTILE_LENGTH * 0.45, 0.0)
	var shaft_end := Vector2(PROJECTILE_LENGTH * 0.22, 0.0)
	draw_line(shaft_start, shaft_end, Color(0.47, 0.31, 0.17), 2.4, true)
	draw_line(shaft_start + Vector2(-4.0, -3.0), shaft_start, Color(0.84, 0.86, 0.9), 1.6, true)
	draw_line(shaft_start + Vector2(-4.0, 3.0), shaft_start, Color(0.84, 0.86, 0.9), 1.6, true)
	draw_colored_polygon(
		[
			Vector2(PROJECTILE_LENGTH * 0.22, -4.0),
			Vector2(PROJECTILE_LENGTH * 0.5, 0.0),
			Vector2(PROJECTILE_LENGTH * 0.22, 4.0)
		],
		Color(0.92, 0.92, 0.88)
	)
