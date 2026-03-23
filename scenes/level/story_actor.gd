extends Node2D

@export var character_texture: Texture2D
@export var idle_frame := 133
@export var actor_scale := Vector2(1.5, 1.5)

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_apply_appearance()

func set_character(texture: Texture2D, frame: int = 133) -> void:
	character_texture = texture
	idle_frame = frame
	_apply_appearance()

func set_idle_frame(frame: int) -> void:
	idle_frame = frame
	if sprite:
		sprite.frame = idle_frame

func _apply_appearance() -> void:
	if sprite == null:
		return

	sprite.texture = character_texture
	sprite.frame = idle_frame
	scale = actor_scale
