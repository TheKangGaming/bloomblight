extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _configured := false

func configure(
	texture: Texture2D,
	frame_size: Vector2i,
	frame_count: int,
	fps: float = 16.0,
	scale_value: Vector2 = Vector2.ONE,
	offset: Vector2 = Vector2.ZERO
) -> void:
	if texture == null or frame_count <= 0 or frame_size.x <= 0 or frame_size.y <= 0:
		queue_free()
		return

	var frames := SpriteFrames.new()
	frames.add_animation(&"play")
	frames.set_animation_loop(&"play", false)
	frames.set_animation_speed(&"play", fps)

	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(&"play", atlas)

	animated_sprite.sprite_frames = frames
	animated_sprite.scale = scale_value
	animated_sprite.position = offset
	_configured = true

func _ready() -> void:
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	if _configured:
		animated_sprite.play(&"play")

func play_now() -> void:
	if not _configured:
		return
	animated_sprite.play(&"play")

func _on_animation_finished() -> void:
	queue_free()
