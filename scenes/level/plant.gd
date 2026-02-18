extends StaticBody2D

const HFRAMES = 34 # How many growth stages (columns)
const VFRAMES = 18  # How many types of crops (rows)
const ATLAS_TEXTURE = preload("res://graphics/plants/Atlas-Props4-crops update.png")

var grid_pos: Vector2i
var age: float
var max_age: int
var grow_speed: float
var plant_type: Global.Seeds

# --- 2. MAP SEEDS TO ROWS ---
# 'origin': The grid coordinate Vector2i(column, row) of the FIRST frame (Seed)
# You need to find these X,Y coordinates in your sprite editor.
const plant_data = {
	Global.Seeds.CORN: {
		'origin': Vector2i(3, 11), # EXAMPLE: Column 2, Row 10
		'max age': 5, 
		'grow speed': 2
	},
	Global.Seeds.TOMATO: {
		'origin': Vector2i(3, 15), # EXAMPLE: Column 8, Row 10
		'max age': 5, 
		'grow speed': 2
	},
	Global.Seeds.PUMPKIN: {
		'origin': Vector2i(23, 8), # EXAMPLE: Column 22, Row 10
		'max age': 5, 
		'grow speed': 1
	}
}

func setup(seed_enum: Global.Seeds, grid_position: Vector2i):
	# save the type of plant
	plant_type = seed_enum
	max_age = plant_data[seed_enum]['max age']
	grow_speed = plant_data[seed_enum]['grow speed']
	grid_pos = grid_position
	
	# Setup the Sprite Sheet
	
	$Sprite2D.texture = ATLAS_TEXTURE
	$Sprite2D.hframes = HFRAMES
	$Sprite2D.vframes = VFRAMES
	
	# Jump to the starting coordinate (Seed Stage)
	var origin = plant_data[seed_enum]['origin']
	$Sprite2D.frame_coords = origin

func grow(watered: bool):
		if watered:
			age = min(age + grow_speed, max_age)
			# CALCULATE NEW FRAME
			# Start at the origin X, then move Right (+X) by the current age
			var origin = plant_data[plant_type]['origin']
			var current_x = origin.x + int(age)
		
			$Sprite2D.frame_coords = Vector2i(current_x, origin.y)
	
func _ready() -> void:
	add_to_group('Plants')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_body_entered(_body: Node2D) -> void:
	if age >= max_age:
		Global.add_item(plant_type)
		queue_free()
