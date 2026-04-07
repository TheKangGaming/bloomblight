extends Node2D

const BASE_TEXTURE := preload("res://graphics/animations/cabin/Cabin-bot section-porch only.png")
const GRASS_TEXTURE := preload("res://graphics/animations/cabin/Cabin-grass.png")
const SHADOW_BOT_LEFT_TEXTURE := preload("res://graphics/animations/cabin/Cabin-shadow bot left.png")
const SHADOW_BOT_RIGHT_TEXTURE := preload("res://graphics/animations/cabin/Cabin-shadow bot right.png")
const SHADOW_TOP_LEFT_TEXTURE := preload("res://graphics/animations/cabin/Cabin-shadow top left.png")
const SHADOW_TOP_RIGHT_TEXTURE := preload("res://graphics/animations/cabin/Cabin-shadow top right.png")
const TOP_OPEN_TEXTURE := preload("res://graphics/animations/cabin/cabin-top section no tissue-opening animation.png")
const TOP_CLOSE_TEXTURE := preload("res://graphics/animations/cabin/cabin-top section no tissue-closing animation.png")
const DOOR_OPEN_TEXTURE := preload("res://graphics/animations/cabin/cabin -  opening animation door with slight shading detail for better integration with the cabin while accessing the interior .png")
const DOOR_CLOSE_TEXTURE := preload("res://graphics/animations/cabin/cabin -  closing animation door with slight shading detail for better integration with the cabin while accessing the interior .png")
const INTERIOR_FRONT_TEXTURE := preload("res://graphics/animations/cabin/cabin - interior - front wall.png")
const DOOR_SFX := preload("res://audio/ui/Close And Open Inventory.wav")

const TOP_FRAME_SIZE := Vector2i(480, 352)
const DOOR_FRAME_SIZE := Vector2i(96, 128)
const OPEN_DURATION := 0.5
const CLOSE_DURATION := 0.65

@onready var grass_sprite: Sprite2D = $Grass
@onready var shadow_bot_left: Sprite2D = $ShadowBotLeft
@onready var shadow_bot_right: Sprite2D = $ShadowBotRight
@onready var shadow_top_left: Sprite2D = $ShadowTopLeft
@onready var shadow_top_right: Sprite2D = $ShadowTopRight
@onready var base_sprite: Sprite2D = $Base
@onready var top_sprite: AnimatedSprite2D = $Top
@onready var door_sprite: AnimatedSprite2D = $Door
@onready var interior_front_sprite: Sprite2D = $InteriorFront
@onready var door_sfx: AudioStreamPlayer2D = $DoorSfx

var _player_in_range := false
var _is_open := false
var _built := false
var _is_animating := false

func _ready() -> void:
	grass_sprite.texture = GRASS_TEXTURE
	shadow_bot_left.texture = SHADOW_BOT_LEFT_TEXTURE
	shadow_bot_right.texture = SHADOW_BOT_RIGHT_TEXTURE
	shadow_top_left.texture = SHADOW_TOP_LEFT_TEXTURE
	shadow_top_right.texture = SHADOW_TOP_RIGHT_TEXTURE
	base_sprite.texture = BASE_TEXTURE
	interior_front_sprite.texture = INTERIOR_FRONT_TEXTURE
	door_sfx.stream = DOOR_SFX
	_build_top_animations()
	_build_door_animations()
	_apply_closed_rest_state()
	set_built(false)

func set_built(is_built: bool) -> void:
	_built = is_built
	visible = is_built
	process_mode = Node.PROCESS_MODE_INHERIT if is_built else Node.PROCESS_MODE_DISABLED
	$WallBody/CollisionShape2D.disabled = not is_built
	$WallBody/CollisionShape2D2.disabled = not is_built
	$WallBody/CollisionShape2D3.disabled = not is_built
	$DoorArea/CollisionShape2D.disabled = not is_built
	if not is_built:
		_player_in_range = false
		_is_open = false
		_is_animating = false
		_apply_closed_rest_state()

func is_built() -> bool:
	return _built

func is_open() -> bool:
	return _is_open

func open_for_entry() -> void:
	if not _built:
		return
	if _is_open:
		return
	await _play_open()

func close_for_exit() -> void:
	if not _built:
		return
	if not _is_open:
		return
	await _play_close()

func _unhandled_input(event: InputEvent) -> void:
	if not _built or not _player_in_range or _is_animating:
		return
	if not (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		return
	if event is InputEventKey and event.echo:
		return

	if _is_open:
		await _play_close()
	else:
		await _play_open()

func _on_door_area_body_entered(body: Node2D) -> void:
	if body != null and body.is_in_group("Player"):
		_player_in_range = true

func _on_door_area_body_exited(body: Node2D) -> void:
	if body != null and body.is_in_group("Player"):
		_player_in_range = false

func _build_top_animations() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"open")
	frames.set_animation_loop(&"open", false)
	frames.set_animation_speed(&"open", 12.0)
	for frame_index in range(7):
		var atlas := AtlasTexture.new()
		atlas.atlas = TOP_OPEN_TEXTURE
		atlas.region = Rect2(frame_index * TOP_FRAME_SIZE.x, 0, TOP_FRAME_SIZE.x, TOP_FRAME_SIZE.y)
		frames.add_frame(&"open", atlas)

	frames.add_animation(&"close")
	frames.set_animation_loop(&"close", false)
	frames.set_animation_speed(&"close", 12.0)
	for frame_index in range(8):
		var atlas := AtlasTexture.new()
		atlas.atlas = TOP_CLOSE_TEXTURE
		atlas.region = Rect2(frame_index * TOP_FRAME_SIZE.x, 0, TOP_FRAME_SIZE.x, TOP_FRAME_SIZE.y)
		frames.add_frame(&"close", atlas)

	top_sprite.sprite_frames = frames

func _build_door_animations() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"open")
	frames.set_animation_loop(&"open", false)
	frames.set_animation_speed(&"open", 12.0)
	for frame_index in range(7):
		var atlas := AtlasTexture.new()
		atlas.atlas = DOOR_OPEN_TEXTURE
		atlas.region = Rect2(frame_index * DOOR_FRAME_SIZE.x, 0, DOOR_FRAME_SIZE.x, DOOR_FRAME_SIZE.y)
		frames.add_frame(&"open", atlas)

	frames.add_animation(&"close")
	frames.set_animation_loop(&"close", false)
	frames.set_animation_speed(&"close", 12.0)
	for frame_index in range(14):
		var atlas := AtlasTexture.new()
		atlas.atlas = DOOR_CLOSE_TEXTURE
		atlas.region = Rect2(frame_index * DOOR_FRAME_SIZE.x, 0, DOOR_FRAME_SIZE.x, DOOR_FRAME_SIZE.y)
		frames.add_frame(&"close", atlas)

	door_sprite.sprite_frames = frames

func _play_open() -> void:
	_is_animating = true
	_play_door_sfx()
	top_sprite.speed_scale = float(top_sprite.sprite_frames.get_frame_count(&"open")) / (OPEN_DURATION * top_sprite.sprite_frames.get_animation_speed(&"open"))
	door_sprite.speed_scale = float(door_sprite.sprite_frames.get_frame_count(&"open")) / (OPEN_DURATION * door_sprite.sprite_frames.get_animation_speed(&"open"))
	top_sprite.play(&"open")
	door_sprite.play(&"open")
	await get_tree().create_timer(OPEN_DURATION, true).timeout
	_is_open = true
	interior_front_sprite.visible = true
	top_sprite.stop()
	door_sprite.stop()
	top_sprite.frame = top_sprite.sprite_frames.get_frame_count(&"open") - 1
	door_sprite.frame = door_sprite.sprite_frames.get_frame_count(&"open") - 1
	_is_animating = false

func _play_close() -> void:
	_is_animating = true
	_play_door_sfx()
	top_sprite.speed_scale = float(top_sprite.sprite_frames.get_frame_count(&"close")) / (CLOSE_DURATION * top_sprite.sprite_frames.get_animation_speed(&"close"))
	door_sprite.speed_scale = float(door_sprite.sprite_frames.get_frame_count(&"close")) / (CLOSE_DURATION * door_sprite.sprite_frames.get_animation_speed(&"close"))
	top_sprite.play(&"close")
	door_sprite.play(&"close")
	await get_tree().create_timer(CLOSE_DURATION, true).timeout
	_is_open = false
	interior_front_sprite.visible = false
	_apply_closed_rest_state()
	_is_animating = false

func _apply_closed_rest_state() -> void:
	top_sprite.play(&"open")
	top_sprite.stop()
	top_sprite.frame = 0
	door_sprite.play(&"open")
	door_sprite.stop()
	door_sprite.frame = 0
	interior_front_sprite.visible = false

func _play_door_sfx() -> void:
	if door_sfx == null or door_sfx.stream == null:
		return
	door_sfx.play()
