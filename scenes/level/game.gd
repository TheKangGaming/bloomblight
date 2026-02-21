extends Node2D

const TILE_SIZE = 32
@onready var player = $Objects/Player
var plant_scene:PackedScene = preload('res://scenes/level/plant.tscn')
@export var daytime_gradient: Gradient

# --- NEW LAYER REFERENCES ---
@onready var tillable_layer = $World/Tillable
@onready var soil_layer = $SoilLayer
@onready var water_layer = $SoilWaterLayer

var pending_plant_pos: Vector2

func _ready() -> void:
	player.toggle_menu_requested.connect(_on_player_menu_requested)
	$CanvasLayer/SeedMenu.seed_chosen.connect(_on_seed_chosen_from_menu)

func _process(_delta: float) -> void:
	var daytime_point: float = 1.0 - ($DayTimer.time_left / $DayTimer.wait_time)
	$CanvasModulate.color = daytime_gradient.sample(daytime_point)
	if Input.is_action_just_pressed('time_skip'):
		day_switch()

func _on_player_tool_use(tool: int, global_pos: Vector2) -> void:
	# Convert global position to grid coordinates using the Tillable layer
	var local_pos = tillable_layer.to_local(global_pos)
	var grid_pos = tillable_layer.local_to_map(local_pos)
	
	# 1. THE HOE
	if tool == player.Tools.HOE:
		if tillable_layer.get_cell_source_id(grid_pos) != -1:
			
			# 1. Grab every dirt tile currently on the map
			var all_dirt = soil_layer.get_used_cells()
			
			# 2. Add the brand new tile we just hit with the hoe
			all_dirt.append(grid_pos)
			
			# 3. Tell Godot to re-calculate the connections for ALL of them together
			soil_layer.set_cells_terrain_connect(all_dirt, 0, 0)
			
	# 2. THE WATERING CAN		
	if tool == player.Tools.WATER:
		# Grab the data of the specific dirt tile we clicked
		var soil_data = soil_layer.get_cell_tile_data(grid_pos)
		
		# Check if there is dirt AND if we painted the 'waterable' tag on it
		if soil_data and soil_data.get_custom_data("waterable") == true:
			var all_water = water_layer.get_used_cells()
			all_water.append(grid_pos)
			water_layer.set_cells_terrain_connect(all_water, 0, 0)
	
	# 3. THE AXE
	if tool == player.Tools.AXE:
		for tree in get_tree().get_nodes_in_group('Trees'):
			if tree.global_position.distance_to(global_pos) < 30:
				tree.hit()

func _on_player_menu_requested(target_pos: Vector2):
	var local_pos = water_layer.to_local(target_pos)
	var grid_pos = water_layer.local_to_map(local_pos)
	
	# Check if the ground is watered (-1 means empty)
	if water_layer.get_cell_source_id(grid_pos) != -1: 
		for plant in get_tree().get_nodes_in_group('Plants'):
			if plant.grid_pos == grid_pos:
				return # A plant is already here
		
		player.can_move = false
		pending_plant_pos = target_pos
		
		var screen_pos = player.get_global_transform_with_canvas().origin
		$CanvasLayer/SeedMenu.open(screen_pos)
	else:
		print('You can only plant on watered soil!')
		
func _on_seed_chosen_from_menu(seed_type: int):
	player.can_move = true
	_on_player_seed_use(seed_type, pending_plant_pos)
	
	Global.inventory[seed_type] -= 1
	Global.inventory_updated.emit()

func _on_player_seed_use(seed_enum: int, global_pos: Vector2) -> void:
	var local_pos = soil_layer.to_local(global_pos)
	var grid_pos = soil_layer.local_to_map(local_pos)
	
	# Final check if tile is occupied
	for plant in get_tree().get_nodes_in_group('Plants'):
		if plant.grid_pos == grid_pos:
			print("Tile is occupied")
			return 
			
	# Spawn the plant
	if soil_layer.get_cell_source_id(grid_pos) != -1:
		var plant_pos = Vector2(grid_pos.x * TILE_SIZE + 16, grid_pos.y * TILE_SIZE + 16)
		var plant = plant_scene.instantiate() as StaticBody2D
		plant.setup(seed_enum, grid_pos)
		$Objects.add_child(plant)
		plant.position = plant_pos
		
func day_switch():
	var tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, 'modulate:a', 1.0, 1.0)
	tween.tween_callback(level_reset)
	tween.tween_interval(1.0)
	tween.tween_property($CanvasLayer/ColorRect, 'modulate:a', 0.0, 1.0)
	
func level_reset():
	for plant in get_tree().get_nodes_in_group('Plants'):
		# Grow if water exists at the plant's position
		plant.grow(water_layer.get_cell_source_id(plant.grid_pos) != -1)
	
	water_layer.clear()
	$DayTimer.start()
