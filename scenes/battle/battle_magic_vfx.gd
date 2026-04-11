class_name BattleMagicVfx
extends Node2D

const TERA_ATTACK_TEXTURE := preload("res://graphics/abilities/tera_attack/spritesheet.png")
const FRAME_SIZE := Vector2i(96, 128)
const FRAME_COUNT := 14
const FRAMES_PER_SECOND := 18.0
const TARGET_BEAM_HEIGHT := 120.0

var beam_height := 0.0:
	set(value):
		beam_height = maxf(0.0, value)
		_update_visual_scale()

var _sprite: AnimatedSprite2D = null

func _ready() -> void:
	_ensure_sprite()
	_update_visual_scale()
	if _sprite != null:
		_sprite.play(&"play")

func _ensure_sprite() -> void:
	if _sprite != null:
		return

	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	_sprite.position = Vector2(0, -24)
	_sprite.modulate = Color(0.96, 1.0, 0.98, 1.0)
	add_child(_sprite)

	var frames := SpriteFrames.new()
	frames.add_animation(&"play")
	frames.set_animation_loop(&"play", false)
	frames.set_animation_speed(&"play", FRAMES_PER_SECOND)
	for frame_index in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = TERA_ATTACK_TEXTURE
		atlas.region = Rect2(frame_index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(&"play", atlas)
	_sprite.sprite_frames = frames

func _update_visual_scale() -> void:
	if _sprite == null:
		return
	var height_ratio := clampf(beam_height / TARGET_BEAM_HEIGHT, 0.0, 1.0)
	var squash := lerpf(0.78, 1.0, height_ratio)
	_sprite.scale = Vector2(0.92 + (height_ratio * 0.1), squash)
