extends StaticBody2D

@onready var water_layer: TileMapLayer = _resolve_water_layer()
@onready var sparkle_fx = $SparkleFX

const HFRAMES = 34
const VFRAMES = 18
const ATLAS_TEXTURE = preload("res://graphics/plants/Atlas-Props4-crops update.png")

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
			age = min(age + grow_speed, max_age)
			var origin = plant_data[plant_type]['origin']
			var current_x = origin.x + int(age)
		
			$Sprite2D.frame_coords = Vector2i(current_x, origin.y)
			
		if age >= max_age:
			if not sparkle_fx.visible:
				sparkle_fx.visible = true
				sparkle_fx.play("sparkle")
	
func _ready() -> void:
	add_to_group('Plants')


func _on_area_2d_body_entered(_body: Node2D) -> void:
	if age >= max_age:
		if plant_type in Global.HARVEST_DROPS:
			var drop = Global.HARVEST_DROPS[plant_type]
			Global.add_item(drop)
		else:
			Global.add_item(plant_type) 

		if Global.tutorial_step == 9:
			Global.advance_tutorial()
			
		queue_free()
		if water_layer:
			water_layer.erase_cell(grid_pos)
