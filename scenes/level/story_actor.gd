extends Node2D

const IDLE_DOWN_FRAME := 0
const IDLE_UP_FRAME := 16
const IDLE_SIDE_FRAME := 32

@export var character_texture: Texture2D
@export var idle_frame := IDLE_DOWN_FRAME
@export var sprite_flip_h := false
@export var actor_scale := Vector2(1.5, 1.5)

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_apply_appearance()

func set_character(texture: Texture2D, frame: int = IDLE_DOWN_FRAME) -> void:
	character_texture = texture
	idle_frame = frame
	_apply_appearance()

func set_idle_frame(frame: int) -> void:
	idle_frame = frame
	_apply_appearance()

func face_down() -> void:
	idle_frame = IDLE_DOWN_FRAME
	sprite_flip_h = false
	_apply_appearance()

func face_up() -> void:
	idle_frame = IDLE_UP_FRAME
	sprite_flip_h = false
	_apply_appearance()

func face_side(face_right: bool) -> void:
	idle_frame = IDLE_SIDE_FRAME
	sprite_flip_h = not face_right
	_apply_appearance()

func _apply_appearance() -> void:
	if sprite == null:
		return

	sprite.texture = character_texture
	sprite.frame = idle_frame
	sprite.flip_h = sprite_flip_h
	scale = actor_scale
