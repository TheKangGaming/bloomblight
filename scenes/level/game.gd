extends Node2D

const TILE_SIZE = 32
@onready var player = $Objects/Player
var plant_scene:PackedScene = preload('res://scenes/level/plant.tscn')
@export var daytime_gradient: Gradient


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var daytime_point: float = 1.0 - ($DayTimer.time_left / $DayTimer.wait_time)
	$CanvasModulate.color = daytime_gradient.sample(daytime_point)
	if Input.is_action_just_pressed('ui_focus_next'):
		day_switch()


func _on_player_tool_use(tool: int, global_pos: Vector2) -> void:
	var local_pos = $Layers/SoilLayer.to_local(global_pos)
	var grid_pos = $Layers/SoilLayer.local_to_map(local_pos)
	
	# 1. THE HOE
	if tool == player.Tools.HOE:
		var cell =  $Layers/GrassLayer.get_cell_tile_data(grid_pos) as TileData
		
		if cell and cell.get_custom_data('usable'):
			$Layers/SoilLayer.set_cells_terrain_connect([grid_pos], 0, 0)
			
	# 2. THE WATERING CAN		
	if tool == player.Tools.WATER:
		if $Layers/SoilLayer.get_cell_tile_data(grid_pos):
			$Layers/SoilWaterLayer.set_cell(grid_pos, 0, Vector2i(0, 0))
	
	# 3. THE AXE
	if tool == player.Tools.AXE:
		for tree in get_tree().get_nodes_in_group('Trees'):
			if tree.position.distance_to(grid_pos) < 30:
				tree.hit()

var pending_plant_pos: Vector2

func _ready() -> void:
	$Objects/Player.toggle_menu_requested.connect(_on_player_menu_requested)
	
	$CanvasLayer/SeedMenu.seed_chosen.connect(_on_seed_chosen_from_menu)
	
func _on_player_menu_requested(target_pos: Vector2):
	var local_pos = $Layers/SoilWaterLayer.to_local(target_pos)
	var grid_pos = $Layers/SoilWaterLayer.local_to_map(local_pos)
	
	var tile_data = $Layers/SoilWaterLayer.get_cell_tile_data(grid_pos)
	
	if tile_data: #If there is a tile here, it is watered soil.
		for plant in get_tree().get_nodes_in_group('Plants'):
			if plant.grid_pos == grid_pos:
				return
		
		$Objects/Player.can_move = false
		
		# save the position and open the menu
		pending_plant_pos = target_pos
		$CanvasLayer/SeedMenu.open() #show UI
	else:
		print('You can only plant on watered soil!')
		
func _on_seed_chosen_from_menu(seed_type: int):
	$Objects/Player.can_move = true
	_on_player_seed_use(seed_type, pending_plant_pos)
	
	Global.inventory[seed_type] -= 1
	Global.inventory_updated.emit()
		

func _on_player_seed_use(seed_enum: int, global_pos: Vector2) -> void:
	var local_pos = $Layers/SoilLayer.to_local(global_pos)
	var grid_pos = $Layers/SoilLayer.local_to_map(local_pos)
	
	#check if plant already exists
	for plant in get_tree().get_nodes_in_group('Plants'):
		if plant.grid_pos == grid_pos:
			print("Tile is occupied")
			return # Stop! Don't plant a second seed.
			
	var cell = $Layers/SoilLayer.get_cell_tile_data(grid_pos) as TileData
	if cell:
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
		plant.grow(plant.grid_pos in $Layers/SoilWaterLayer.get_used_cells())
	$Layers/SoilWaterLayer.clear()
	$DayTimer.start()
