extends StaticBody2D

@onready var water_layer: TileMapLayer = _resolve_water_layer()
@onready var sparkle_fx = $SparkleFX
@onready var crop_sprite: Sprite2D = $Sprite2D

const HFRAMES = 34
const VFRAMES = 18
const ATLAS_TEXTURE = preload("res://graphics/plants/Atlas-Props4-crops update.png")
const BLOOM_PRIMARY_VFX := preload("res://graphics/animations/vfx/Fantasy Spells/spell_heal_001/spell_heal_001_large_green/spritesheet.png")
const BLOOM_ACCENT_VFX := preload("res://graphics/animations/vfx/Magic Bursts/round_sparkle_burst_002/round_sparkle_burst_002_large_white/spritesheet.png")
const BLOOM_SFX := preload("res://audio/sfx/Spell Impact 1.wav")
const HARVEST_POP_SFX := preload("res://audio/ui/UIMisc_Neutral Pop Up 01_KRST_NONE.wav")

var grid_pos: Vector2i
var age: float
var max_age: int
var grow_speed: float

const plant_data = {
	Global.Items.BLUEBERRY_SEED: {
		'origin': Vector2i(3, 8),
		'max age': 5,
		'grow speed': 1.0
	},
	Global.Items.WHEAT_SEED: {
		'origin': Vector2i(3, 9),
		'max age': 5,
		'grow speed': 1.0
	},
	Global.Items.MELON_SEED: {
		'origin': Vector2i(3, 10),
		'max age': 5,
		'grow speed': 0.75
	},
	Global.Items.CORN_SEED: {
		'origin': Vector2i(3, 11),
		'max age': 5,
		'grow speed': 1.0
	},
	Global.Items.HOT_PEPPER_SEED: {
		'origin': Vector2i(3, 12),
		'max age': 5,
		'grow speed': 0.75
	},
	Global.Items.RADISH_SEED: {
		'origin': Vector2i(3, 13),
		'max age': 5,
		'grow speed': 1.0
	},
	Global.Items.RED_CABBAGE_SEED: {
		'origin': Vector2i(3, 14),
		'max age': 5,
		'grow speed': 0.75
	},
	Global.Items.TOMATO_SEED: {
		'origin': Vector2i(3, 15),
		'max age': 5,
		'grow speed': 0.75
	},

	Global.Items.CARROT_SEED: {
		'origin': Vector2i(13, 8),
		'max age': 5,
		'grow speed': 1.0
	},
	Global.Items.CAULIFLOWER_SEED: {
		'origin': Vector2i(13, 9),
		'max age': 5,
		'grow speed': 0.75
	},
	Global.Items.POTATO_SEED: {
		'origin': Vector2i(13, 10),
		'max age': 5,
		'grow speed': 1.0
	},
	Global.Items.PARSNIP_SEED: {
		'origin': Vector2i(13, 11),
		'max age': 5,
		'grow speed': 1.0
	},
	Global.Items.GARLIC_SEED: {
		'origin': Vector2i(13, 12),
		'max age': 5,
		'grow speed': 1.0
	},
	Global.Items.GREEN_BEANS_SEED: {
		'origin': Vector2i(13, 13),
		'max age': 5,
		'grow speed': 0.75
	},
	Global.Items.STRAWBERRY_SEED: {
		'origin': Vector2i(13, 14),
		'max age': 5,
		'grow speed': 0.75
	},
	Global.Items.COFFEE_BEAN_SEED: {
		'origin': Vector2i(13, 15),
		'max age': 5,
		'grow speed': 0.75
	},

	Global.Items.PUMPKIN_SEED: {
		'origin': Vector2i(23, 8),
		'max age': 5,
		'grow speed': 0.2
	},
	Global.Items.BROCCOLI_SEED: {
		'origin': Vector2i(23, 9),
		'max age': 5,
		'grow speed': 0.75
	},
	Global.Items.ARTICHOKE_SEED: {
		'origin': Vector2i(23, 10),
		'max age': 5,
		'grow speed': 0.75
	},
	Global.Items.EGGPLANT_SEED: {
		'origin': Vector2i(23, 11),
		'max age': 5,
		'grow speed': 0.75
	},
	Global.Items.BOK_CHOY_SEED: {
		'origin': Vector2i(23, 12),
		'max age': 5,
		'grow speed': 1.0
	},
	Global.Items.GRAPE_SEED: {
		'origin': Vector2i(23, 13),
		'max age': 5,
		'grow speed': 0.75
	}
}

var plant_type: Global.Items
var _is_harvesting := false

func _resolve_water_layer() -> TileMapLayer:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	return current_scene.get_node_or_null("SoilWaterLayer")

func setup(seed_enum: Global.Items, grid_position: Vector2i):
	plant_type = seed_enum
	max_age = plant_data[seed_enum]['max age']
	grow_speed = plant_data[seed_enum]['grow speed']
	grid_pos = grid_position
	
	$Sprite2D.texture = ATLAS_TEXTURE
	$Sprite2D.hframes = HFRAMES
	$Sprite2D.vframes = VFRAMES
	var origin = plant_data[seed_enum]['origin']
	$Sprite2D.frame_coords = origin

func grow(watered: bool):
		if watered:
			advance_growth()
			
		if age >= max_age:
			if not sparkle_fx.visible:
				sparkle_fx.visible = true
				sparkle_fx.play("sparkle")

func advance_growth() -> void:
	age = min(age + grow_speed, max_age)
	var origin = plant_data[plant_type]['origin']
	var current_x = origin.x + int(age)
	crop_sprite.frame_coords = Vector2i(current_x, origin.y)

func force_mature() -> void:
	await _play_bloom_feedback()
	age = max_age
	var origin = plant_data[plant_type]['origin']
	crop_sprite.frame_coords = Vector2i(origin.x + max_age, origin.y)
	if not sparkle_fx.visible:
		sparkle_fx.visible = true
		sparkle_fx.play("sparkle")
	
func _ready() -> void:
	add_to_group('Plants')


func _on_area_2d_body_entered(_body: Node2D) -> void:
	if _is_harvesting or age < max_age:
		return
	_is_harvesting = true
	$Area2D/CollisionShape2D.set_deferred("disabled", true)

	var harvested_item: int = plant_type
	if plant_type in Global.HARVEST_DROPS:
		harvested_item = int(Global.HARVEST_DROPS[plant_type])

	await _play_harvest_feedback()
	Global.add_item(harvested_item)
	if plant_type in Global.HARVEST_DROPS and DemoDirector:
		DemoDirector.notify_story_crop_harvested(harvested_item)

	if Global.tutorial_step == 9:
		Global.advance_tutorial()

	queue_free()
	if water_layer:
		water_layer.erase_cell(grid_pos)

func _play_bloom_feedback() -> void:
	var current_scene := get_tree().current_scene
	var bloom_anchor := global_position + Vector2(0, -28)
	if current_scene != null and current_scene.has_method("spawn_overworld_burst"):
		current_scene.spawn_overworld_burst(
			bloom_anchor,
			BLOOM_PRIMARY_VFX,
			Vector2i(128, 128),
			16,
			18.0,
			Vector2(0.95, 0.95)
		)
		current_scene.spawn_overworld_burst(
			bloom_anchor + Vector2(0, -8),
			BLOOM_ACCENT_VFX,
			Vector2i(128, 128),
			16,
			18.0,
			Vector2(0.9, 0.9)
		)
	if current_scene != null and current_scene.has_method("play_overworld_camera_shake"):
		current_scene.play_overworld_camera_shake(4.0, 0.16)
	_play_one_shot_sfx(BLOOM_SFX, bloom_anchor)
	await get_tree().create_timer(0.12, true).timeout

func _play_harvest_feedback() -> void:
	var current_scene := get_tree().current_scene
	var harvest_anchor := global_position + Vector2(0, -20)
	if current_scene != null and current_scene.has_method("spawn_overworld_burst"):
		current_scene.spawn_overworld_burst(
			harvest_anchor,
			BLOOM_ACCENT_VFX,
			Vector2i(128, 128),
			16,
			20.0,
			Vector2(0.6, 0.6)
		)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(crop_sprite, "scale", Vector2(1.18, 1.18), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(crop_sprite, "position", crop_sprite.position + Vector2(0, -10), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	var fade_tween := create_tween().set_parallel(true)
	fade_tween.tween_property(crop_sprite, "scale", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(crop_sprite, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_play_one_shot_sfx(HARVEST_POP_SFX, harvest_anchor)
	await fade_tween.finished

func _play_one_shot_sfx(stream: AudioStream, at_global_position: Vector2) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.global_position = at_global_position
	get_tree().current_scene.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
