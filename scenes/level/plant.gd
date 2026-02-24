extends StaticBody2D

@onready var sparkle_fx = $SparkleFX

const HFRAMES = 34 # (columns)
const VFRAMES = 18  # (rows)
const ATLAS_TEXTURE = preload("res://graphics/plants/Atlas-Props4-crops update.png")

var grid_pos: Vector2i
var age: float
var max_age: int
var grow_speed: float

# --- 2. MAP SEEDS TO ROWS ---
# 'origin': The grid coordinate Vector2i(column, row) of the FIRST frame (Seed)


const plant_data = {
	Global.Items.CORN_SEED: { 
		'origin': Vector2i(3, 11),
		'max age': 5, 
		'grow speed': 1
	},
	Global.Items.TOMATO_SEED: { 
		'origin': Vector2i(3, 15),
		'max age': 5, 
		'grow speed': 1
	},
	Global.Items.PUMPKIN_SEED: { 
		'origin': Vector2i(23, 8), 
		'max age': 5, 
		'grow speed': 0.5
	}
}

var plant_type: Global.Items # Updated type

func setup(seed_enum: Global.Items, grid_position: Vector2i):
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
			
			# If the plant just reached max growth, show and play the sparkles!
		if age >= max_age:
			if not sparkle_fx.visible:
				sparkle_fx.visible = true
				sparkle_fx.play("sparkle")
	
func _ready() -> void:
	add_to_group('Plants')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_body_entered(_body: Node2D) -> void:
	if age >= max_age:
		
		# LOGIC FIX: Check the Harvest Map to see what this seed drops
		if plant_type in Global.HARVEST_DROPS:
			var drop = Global.HARVEST_DROPS[plant_type]
			Global.add_item(drop)
		else:
			# Fallback if we forgot to add it to the map
			Global.add_item(plant_type) 
			
		queue_free()
