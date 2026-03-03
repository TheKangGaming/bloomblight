class_name MapGenerator
extends Node

# Export all three layers so we can stack our terrain!
@export var water_layer: TileMapLayer
@export var ground_layer: TileMapLayer
@export var elevated_layer: TileMapLayer

@export var map_width: int = 30
@export var map_height: int = 20

# Replace these with the exact IDs from your Tiny Swords setup!
const TERRAIN_SET_ID = 0
const WATER_ID = 2
const GRASS_ID = 0 
const ELEVATED_ID = 1

var _noise: FastNoiseLite

func generate_new_map() -> void:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.noise_type = FastNoiseLite.TYPE_PERLIN
		_noise.frequency = 0.1 # Very smooth, natural coastlines
		
	_noise.seed = randi() 

	# 1. Clear previous map data
	water_layer.clear()
	ground_layer.clear()
	elevated_layer.clear()
	
	var water_cells: Array[Vector2i] = []
	var grass_cells: Array[Vector2i] = []
	var elevated_cells: Array[Vector2i] = []
	
	# 2. Read the noise map
	for x in range(map_width):
		for y in range(map_height):
			var cell = Vector2i(x, y)
			var noise_val = _noise.get_noise_2d(x, y)
			
			# EVERY tile gets water underneath it as a safe baseline!
			water_cells.append(cell)
			
			# 3. Sort the heights
			if noise_val > -0.15:
				# It's high enough to be an island!
				grass_cells.append(cell)
				
				if noise_val > 0.25:
					# It's REALLY high, build a mountain/plateau here!
					elevated_cells.append(cell)
					
	# 4. Paint the layers from bottom to top!
	water_layer.set_cells_terrain_connect(water_cells, TERRAIN_SET_ID, WATER_ID)
	ground_layer.set_cells_terrain_connect(grass_cells, TERRAIN_SET_ID, GRASS_ID)
	elevated_layer.set_cells_terrain_connect(elevated_cells, TERRAIN_SET_ID, ELEVATED_ID)
	
	print("3D Map Generation Complete!")
