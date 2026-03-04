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
	
	$CanvasLayer/SeedMenu.menu_cancelled.connect(_on_seed_menu_cancelled)

func apply_combat_time_passage(elapsed_seconds: float) -> void:
	if elapsed_seconds <= 0.0:
		return

	var day_timer = $DayTimer
	var grow_timer = $GrowTimer
	var day_time_left = day_timer.time_left
	var grow_time_left = max(grow_timer.time_left, 0.001)
	var grow_interval = grow_timer.wait_time

	# We only simulate crop ticks during the remaining day.
	var simulated_seconds = min(elapsed_seconds, day_time_left)
	if simulated_seconds <= 0.0:
		day_timer.start(0.01)
		grow_timer.stop()
		return

	var ticks_to_simulate := 0
	if simulated_seconds >= grow_time_left:
		ticks_to_simulate = 1 + int(floor((simulated_seconds - grow_time_left) / grow_interval))

	for _i in range(ticks_to_simulate):
		_on_grow_timer_timeout()

	var new_day_time_left = max(day_time_left - simulated_seconds, 0.0)
	if new_day_time_left <= 0.0:
		day_timer.start(0.01)
		grow_timer.stop()
		return

	var new_grow_time_left: float
	if ticks_to_simulate == 0:
		new_grow_time_left = max(grow_time_left - simulated_seconds, 0.001)
	else:
		var consumed_after_first_tick = simulated_seconds - grow_time_left
		var cycle_progress = fposmod(consumed_after_first_tick, grow_interval)
		new_grow_time_left = grow_interval if is_zero_approx(cycle_progress) else (grow_interval - cycle_progress)

	day_timer.start(new_day_time_left)
	grow_timer.start(max(new_grow_time_left, 0.001))
	
func _on_seed_menu_cancelled():
	# Give the player their movement back!
	player.can_move = true

func _process(_delta: float) -> void:
	var daytime_point: float = 1.0 - ($DayTimer.time_left / $DayTimer.wait_time)
	$CanvasModulate.color = daytime_gradient.sample(daytime_point)
	if Input.is_action_just_pressed('time_skip'):
		day_switch()

func _on_player_tool_use(tool: int, global_pos: Vector2) -> void:
	# Tweak this number (16, 24, or 32) until it hits the exact tile  want
	var adjusted_pos = global_pos + Vector2(0, 24)
	# Convert global position to grid coordinates using the Tillable layer
	var local_pos = tillable_layer.to_local(adjusted_pos)
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
			
			# Shift the target up by 30 pixels so we are measuring from the TRUNK, not the roots
			var trunk_pos = tree.global_position + Vector2(0, -77) 
			
			if trunk_pos.distance_squared_to(global_pos) < 2025: 
				tree.hit()
				break

func _on_player_menu_requested(target_pos: Vector2):
	# 1. Adjust the position
	var adjusted_pos = target_pos + Vector2(0, 24)
	
	# 2. Use the ADJUSTED pos to find the grid coordinates!
	var local_pos = soil_layer.to_local(adjusted_pos)
	var grid_pos = soil_layer.local_to_map(local_pos)
	
	# Check if the ground is watered (-1 means empty)
	if soil_layer.get_cell_source_id(grid_pos) != -1: 
		for plant in get_tree().get_nodes_in_group('Plants'):
			if plant.grid_pos == grid_pos:
				return # A plant is already here
		
		player.can_move = false
		
		# 3. Save the ADJUSTED pos so the seed plants in the right spot!
		pending_plant_pos = adjusted_pos 
		
		var screen_pos = player.get_global_transform_with_canvas().origin
		$CanvasLayer/SeedMenu.open(screen_pos)
	else:
		print('You can only plant on tilled soil!')
		
func _on_seed_chosen_from_menu(seed_type: int):
	player.can_move = true
	
	# Save the true/false result of the planting attempt
	var successfully_planted = _on_player_seed_use(seed_type, pending_plant_pos)
	
	# Only consume the seed if the planting was actually successful
	if successfully_planted:
		Global.inventory[seed_type] -= 1
		Global.inventory_updated.emit()

func _on_player_seed_use(seed_enum: int, global_pos: Vector2) -> bool: # Changed from void to bool
	var local_pos = soil_layer.to_local(global_pos)
	var grid_pos = soil_layer.local_to_map(local_pos)
	
	# Final check if tile is occupied
	for plant in get_tree().get_nodes_in_group('Plants'):
		if plant.grid_pos == grid_pos:
			print("Tile is occupied")
			return false # <-- ADDED: Returns false because we couldn't plant
			
	# Spawn the plant
	if soil_layer.get_cell_source_id(grid_pos) != -1:
		var plant_pos = soil_layer.map_to_local(grid_pos)
		
		plant_pos.y -= 8
		var plant = plant_scene.instantiate() as StaticBody2D
		plant.setup(seed_enum, grid_pos)
		$Objects.add_child(plant)
		plant.position = plant_pos
		return true # <-- ADDED: Returns true because the plant successfully spawned!
		
	return false # <-- ADDED: Returns false if the tile isn't soil
		
func day_switch():
	var tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, 'modulate:a', 1.0, 1.0)
	tween.tween_callback(level_reset)
	tween.tween_interval(1.0)
	tween.tween_property($CanvasLayer/ColorRect, 'modulate:a', 0.0, 1.0)
	
func level_reset():
	# 1. Calculate how many growth ticks are left in the current day
	# We use float() to get accurate division, then ceil() to round up so we don't rob the player of a partial tick!
	var remaining_time = $DayTimer.time_left
	var tick_duration = $GrowTimer.wait_time
	var ticks_to_simulate = int(ceil(remaining_time / tick_duration))
	
	# 2. Instantly simulate the missed time!
	for i in range(ticks_to_simulate):
		_on_grow_timer_timeout() # We just call the exact function we made earlier!
		
	# 3. Restart the timers for the fresh morning
	$DayTimer.start()
	$GrowTimer.start()
	water_layer.clear()
	
	# --- RESET FOOD BUFFS ---
	Global.active_food_buff.item = null
	Global.active_food_buff.stats = {"VIT": 0, "STR": 0, "DEF": 0, "DEX": 0, "INT": 0, "SPD": 0, "MOV": 0}
	
	# Emit the signal so the UI visually removes the meal and bonus stats!
	Global.stats_updated.emit()

func _on_grow_timer_timeout() -> void:
	for plant in get_tree().get_nodes_in_group('Plants'):
		# Check if this specific tile has water on it
		var is_watered = water_layer.get_cell_source_id(plant.grid_pos) != -1
		
		# If it's watered, it grows!
		plant.grow(is_watered)

func _unhandled_input(event: InputEvent) -> void:
	# Pressing "C" on your keyboard triggers combat
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		# 1. Load the combat board into memory
		var combat_scene = load("res://scenes/level/CombatMap_1.tscn").instantiate()
		
		var farm = get_tree().current_scene
		Global.begin_combat_transition()
		
		# 2. Put the farm in the memory vault so it doesn't get deleted
		Global.saved_farm_scene = farm
		
		# 3. Add the Combat board to the game
		get_tree().root.add_child(combat_scene)
		get_tree().current_scene = combat_scene
		
		# 4. UNPLUG THE FARM
		# This instantly stops all audio, cameras, and UI without deleting your crops!
		get_tree().root.remove_child(farm)
