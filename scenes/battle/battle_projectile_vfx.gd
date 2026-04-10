class_name BattleProjectileVfx extends Node2D

const PROJECTILE_LENGTH := 28.0
var projectile_style: StringName = &"arrow"

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	match String(projectile_style):
		"dagger":
			_draw_dagger()
		"spear":
			_draw_spear()
		"whip":
			_draw_whip()
		_:
			_draw_arrow()

func _draw_arrow() -> void:
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

func _draw_dagger() -> void:
	var blade_tip := Vector2(PROJECTILE_LENGTH * 0.52, 0.0)
	var blade_base_top := Vector2(PROJECTILE_LENGTH * 0.08, -4.0)
	var blade_base_bottom := Vector2(PROJECTILE_LENGTH * 0.08, 4.0)
	var handle_start := Vector2(-PROJECTILE_LENGTH * 0.34, 0.0)
	var handle_end := Vector2(PROJECTILE_LENGTH * 0.1, 0.0)
	draw_line(handle_start, handle_end, Color(0.28, 0.19, 0.12), 3.0, true)
	draw_line(Vector2(-4.0, -5.0), Vector2(-4.0, 5.0), Color(0.86, 0.74, 0.48), 1.6, true)
	draw_colored_polygon(
		[
			blade_base_top,
			blade_tip,
			blade_base_bottom,
			Vector2(-2.0, 0.0)
		],
		Color(0.92, 0.92, 0.94)
	)

func _draw_spear() -> void:
	var shaft_start := Vector2(-PROJECTILE_LENGTH * 0.55, 0.0)
	var shaft_end := Vector2(PROJECTILE_LENGTH * 0.26, 0.0)
	draw_line(shaft_start, shaft_end, Color(0.56, 0.40, 0.24), 2.8, true)
	draw_colored_polygon(
		[
			Vector2(PROJECTILE_LENGTH * 0.22, -5.0),
			Vector2(PROJECTILE_LENGTH * 0.54, 0.0),
			Vector2(PROJECTILE_LENGTH * 0.22, 5.0),
			Vector2(PROJECTILE_LENGTH * 0.06, 0.0)
		],
		Color(0.90, 0.92, 0.96)
	)

func _draw_whip() -> void:
	var points := PackedVector2Array([
		Vector2(-20.0, -6.0),
		Vector2(-8.0, -2.0),
		Vector2(2.0, 0.0),
		Vector2(12.0, 4.0),
		Vector2(22.0, 0.0)
	])
	draw_polyline(points, Color(0.45, 0.24, 0.14), 3.0, true)
	draw_line(Vector2(-24.0, -7.0), Vector2(-16.0, -4.0), Color(0.76, 0.62, 0.35), 2.0, true)
