extends Node2D

const TILE_SIZE = 32
@onready var player = $Objects/Player
var plant_scene:PackedScene = preload('res://scenes/level/plant.tscn')
@export var daytime_gradient: Gradient

@onready var tillable_layer = $World/Tillable
@onready var soil_layer = $SoilLayer
@onready var water_layer = $SoilWaterLayer

var pending_plant_pos: Vector2
var _day_timer_cycle_seconds := 0.0
var _grow_timer_cycle_seconds := 0.0
var _warning_ui_scene: PackedScene = preload("res://scenes/ui/warning_ui.tscn")

func _ready() -> void:
	player.toggle_menu_requested.connect(_on_player_menu_requested)
	$CanvasLayer/SeedMenu.seed_chosen.connect(_on_seed_chosen_from_menu)
	_day_timer_cycle_seconds = $DayTimer.wait_time
	_grow_timer_cycle_seconds = $GrowTimer.wait_time
	
	$CanvasLayer/SeedMenu.menu_cancelled.connect(_on_seed_menu_cancelled)

func apply_combat_time_passage(elapsed_seconds: float) -> void:
	var day_timer = $DayTimer
	var grow_timer = $GrowTimer
	
	# Battles should still cost a meaningful chunk of the day even if the scene resolves quickly.
	var battle_duration_seconds = max(elapsed_seconds, _day_timer_cycle_seconds * 0.65)
	var simulated_seconds = min(battle_duration_seconds, day_timer.time_left - 2.0)
	
	var grow_time_left = max(grow_timer.time_left, 0.001)
	var grow_interval = _grow_timer_cycle_seconds

	var ticks_to_simulate := 0
	if simulated_seconds >= grow_time_left:
		ticks_to_simulate = 1 + int(floor((simulated_seconds - grow_time_left) / grow_interval))

	for _i in range(ticks_to_simulate):
		if has_method("_on_grow_timer_timeout"):
			_on_grow_timer_timeout()

	var new_day_time = day_timer.time_left - simulated_seconds
	day_timer.start(max(new_day_time, 1.0))
	day_timer.wait_time = _day_timer_cycle_seconds
	
	# Keep the grow timer aligned so crops do not lose partial progress.
	var remainder_grow = simulated_seconds - (ticks_to_simulate * grow_interval)
	var new_grow_time = grow_time_left - remainder_grow
	if new_grow_time <= 0:
		new_grow_time += grow_interval
	grow_timer.start(max(new_grow_time, 0.01))
	grow_timer.wait_time = _grow_timer_cycle_seconds

	var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
	if hud and hud.has_method("_update_view"):
		hud._update_view(true)
	
func _on_seed_menu_cancelled():
	player.can_move = true

func _process(_delta: float) -> void:
	var daytime_point: float = 1.0 - ($DayTimer.time_left / _day_timer_cycle_seconds)
	$CanvasModulate.color = daytime_gradient.sample(daytime_point)
	if Input.is_action_just_pressed('time_skip'):
		if Global.tutorial_step == 8:
			Global.advance_tutorial()
		request_end_day()

func _on_player_tool_use(tool: Global.Tools, global_pos: Vector2) -> void:
	var adjusted_pos = global_pos + Vector2(0, 24)
	var local_pos = tillable_layer.to_local(adjusted_pos)
	var grid_pos = tillable_layer.local_to_map(local_pos)
	
	if tool == Global.Tools.HOE:
		if tillable_layer.get_cell_source_id(grid_pos) != -1:
			var all_dirt = soil_layer.get_used_cells()
			all_dirt.append(grid_pos)
			soil_layer.set_cells_terrain_connect(all_dirt, 0, 0)
			if Global.tutorial_step == 4:
				Global.advance_tutorial()
			
	if tool == Global.Tools.WATER:
		var soil_data = soil_layer.get_cell_tile_data(grid_pos)
		if soil_data and soil_data.get_custom_data("waterable") == true:
			var all_water = water_layer.get_used_cells()
			all_water.append(grid_pos)
			water_layer.set_cells_terrain_connect(all_water, 0, 0)
			if Global.tutorial_step == 6:
				Global.advance_tutorial()
	
	if tool == Global.Tools.AXE:
		for tree in get_tree().get_nodes_in_group('Trees'):
			# Aim at the trunk, not the bottom of the sprite.
			var trunk_pos = tree.global_position + Vector2(0, -77) 
			
			if trunk_pos.distance_squared_to(global_pos) < 2025: 
				tree.hit()
				break

func _on_player_menu_requested(target_pos: Vector2):
	var adjusted_pos = target_pos + Vector2(0, 24)
	var local_pos = soil_layer.to_local(adjusted_pos)
	var grid_pos = soil_layer.local_to_map(local_pos)
	
	if soil_layer.get_cell_source_id(grid_pos) != -1: 
		for plant in get_tree().get_nodes_in_group('Plants'):
			if plant.grid_pos == grid_pos:
				return
		
		player.can_move = false
		
		pending_plant_pos = adjusted_pos 
		
		var screen_pos = player.get_global_transform_with_canvas().origin
		$CanvasLayer/SeedMenu.open(screen_pos)
	else:
		print('You can only plant on tilled soil!')
		
func _on_seed_chosen_from_menu(seed_type: int):
	player.can_move = true
	
	var successfully_planted = _on_player_seed_use(seed_type, pending_plant_pos)
	
	if successfully_planted:
		if Global.tutorial_step == 5:
			Global.advance_tutorial()
		Global.inventory[seed_type] -= 1
		Global.inventory_updated.emit()

func _on_player_seed_use(seed_enum: int, global_pos: Vector2) -> bool:
	var season := CalendarService.get_current_season()
	if not Global.is_seed_in_season(seed_enum, season):
		print("%s cannot be planted during %s." % [Global.Items.keys()[seed_enum], String(season).capitalize()])
		return false

	var local_pos = soil_layer.to_local(global_pos)
	var grid_pos = soil_layer.local_to_map(local_pos)
	
	for plant in get_tree().get_nodes_in_group('Plants'):
		if plant.grid_pos == grid_pos:
			print("Tile is occupied")
			return false
			
	if soil_layer.get_cell_source_id(grid_pos) != -1:
		var plant_pos = soil_layer.map_to_local(grid_pos)
		
		plant_pos.y -= 8
		var plant = plant_scene.instantiate() as StaticBody2D
		plant.setup(seed_enum, grid_pos)
		$Objects.add_child(plant)
		plant.position = plant_pos
		return true
		
	return false
		
func request_end_day():
	if Global.pending_day_transition:
		return
	Global.pending_day_transition = true
	
	var tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, 'modulate:a', 1.0, 1.0)
	tween.tween_callback(_process_night_transition)

func _process_night_transition():
	Global.current_day += 1
	var encounter = CalendarService.get_encounter_for_day(Global.current_day)
	
	if encounter.is_empty():
		level_reset()
		Global.pending_day_transition = false
		var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
		if hud and hud.has_method("_update_view"):
			hud._update_view(true)
		
		var tween = create_tween()
		tween.tween_interval(1.0)
		tween.tween_property($CanvasLayer/ColorRect, 'modulate:a', 0.0, 1.0)
	else:
		Global.pending_combat_scene_path = String(encounter.get("combat_scene", ""))
		if Global.pending_combat_scene_path.is_empty():
			push_error("Calendar encounter for day %d is missing a combat_scene path." % Global.current_day)
			Global.pending_day_transition = false
			return
		Global.pending_day_transition = false
		
		level_reset() 
		
		var main_tree = get_tree()
		var main_root = main_tree.root
		Global.saved_farm_scene = self
		main_root.remove_child(self)
		var warning_ui = _warning_ui_scene.instantiate()
		main_root.add_child(warning_ui)
		main_tree.current_scene = warning_ui
	
func level_reset():
	var remaining_time = $DayTimer.time_left
	var tick_duration = _grow_timer_cycle_seconds
	var ticks_to_simulate = int(ceil(remaining_time / tick_duration))
	
	for i in range(ticks_to_simulate):
		_on_grow_timer_timeout()
		
	$DayTimer.start()
	$DayTimer.wait_time = _day_timer_cycle_seconds
	$GrowTimer.start()
	$GrowTimer.wait_time = _grow_timer_cycle_seconds
	water_layer.clear()
	
	Global.active_food_buff.item = null
	Global.active_food_buff.stats = {"VIT": 0, "STR": 0, "DEF": 0, "DEX": 0, "INT": 0, "SPD": 0, "MOV": 0}
	Global.stats_updated.emit()
	Global.day_changed.emit(Global.current_day)
	
func _on_grow_timer_timeout() -> void:
	for plant in get_tree().get_nodes_in_group('Plants'):
		var is_watered = water_layer.get_cell_source_id(plant.grid_pos) != -1
		plant.grow(is_watered)
