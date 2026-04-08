extends Node2D

const FRAME_SIZE := Vector2i(128, 128)

const IDLE_TEXTURE := preload("res://graphics/npcs/merchant/vendor-idle.png")
const ENTRY_TEXTURE := IDLE_TEXTURE
const LOOP_TEXTURE := IDLE_TEXTURE
const REST_TEXTURE := IDLE_TEXTURE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_build_animation(&"idle", IDLE_TEXTURE, 8, true, 8.0)
	_build_animation(&"entry", ENTRY_TEXTURE, 8, false, 8.0)
	_build_animation(&"loop", LOOP_TEXTURE, 8, true, 8.0)
	_build_animation(&"rest", REST_TEXTURE, 8, false, 8.0)
	play_idle()

func face_side(face_right: bool) -> void:
	animated_sprite.flip_h = not face_right

func play_idle() -> void:
	animated_sprite.play(&"idle")

func play_walk() -> void:
	play_idle()

func play_entry() -> void:
	animated_sprite.play(&"entry")

func play_rest() -> void:
	animated_sprite.play(&"rest")

func play_talk_loop() -> void:
	animated_sprite.play(&"loop")

func _build_animation(anim_name: StringName, texture: Texture2D, frame_count: int, loops: bool, fps: float) -> void:
	if texture == null or animated_sprite == null:
		return

	var frames := animated_sprite.sprite_frames
	if frames == null:
		frames = SpriteFrames.new()
		animated_sprite.sprite_frames = frames

	if frames.has_animation(anim_name):
		frames.remove_animation(anim_name)
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loops)
	frames.set_animation_speed(anim_name, fps)

	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(anim_name, atlas)
