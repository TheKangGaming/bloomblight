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
var _day_timer_cycle_seconds := 0.0
var _grow_timer_cycle_seconds := 0.0
var _combat_intro_active: bool = false
var _combat_transition_active: bool = false
var _combat_intro_overlay: ColorRect
var _combat_intro_panel: PanelContainer
var _combat_intro_begin_button: Button
var _combat_intro_body: RichTextLabel

func _ready() -> void:
	player.toggle_menu_requested.connect(_on_player_menu_requested)
	$CanvasLayer/SeedMenu.seed_chosen.connect(_on_seed_chosen_from_menu)
	_day_timer_cycle_seconds = $DayTimer.wait_time
	_grow_timer_cycle_seconds = $GrowTimer.wait_time
	
	$CanvasLayer/SeedMenu.menu_cancelled.connect(_on_seed_menu_cancelled)

func apply_combat_time_passage(_elapsed_seconds: float) -> void:
	var day_timer = $DayTimer
	var grow_timer = $GrowTimer
	var day_time_left = day_timer.time_left
	var grow_time_left = max(grow_timer.time_left, 0.001)
	var grow_interval = _grow_timer_cycle_seconds

	# Combat should fast-forward the farm to night, but never into a new day.
	var simulated_seconds = day_time_left
	if simulated_seconds <= 0.0:
		day_timer.start(0.01)
		day_timer.wait_time = _day_timer_cycle_seconds
		grow_timer.stop()
		grow_timer.wait_time = _grow_timer_cycle_seconds
		return

	var ticks_to_simulate := 0
	if simulated_seconds >= grow_time_left:
		ticks_to_simulate = 1 + int(floor((simulated_seconds - grow_time_left) / grow_interval))

	for _i in range(ticks_to_simulate):
		_on_grow_timer_timeout()

	# Leave the scene at night with the next day not yet started.
	day_timer.start(0.01)
	day_timer.wait_time = _day_timer_cycle_seconds
	grow_timer.stop()
	grow_timer.wait_time = _grow_timer_cycle_seconds
	
func _on_seed_menu_cancelled():
	# Give the player their movement back!
	player.can_move = true

func _process(_delta: float) -> void:
	var daytime_point: float = 1.0 - ($DayTimer.time_left / _day_timer_cycle_seconds)
	$CanvasModulate.color = daytime_gradient.sample(daytime_point)
	if Input.is_action_just_pressed('time_skip'):
		if Global.tutorial_step == 8:
			Global.advance_tutorial()
		day_switch()

func _on_player_tool_use(tool: Global.Tools, global_pos: Vector2) -> void:
	# Tweak this number (16, 24, or 32) until it hits the exact tile  want
	var adjusted_pos = global_pos + Vector2(0, 24)
	# Convert global position to grid coordinates using the Tillable layer
	var local_pos = tillable_layer.to_local(adjusted_pos)
	var grid_pos = tillable_layer.local_to_map(local_pos)
	
	# 1. THE HOE
	if tool == Global.Tools.HOE:
		if tillable_layer.get_cell_source_id(grid_pos) != -1:
			
			# 1. Grab every dirt tile currently on the map
			var all_dirt = soil_layer.get_used_cells()
			
			# 2. Add the brand new tile we just hit with the hoe
			all_dirt.append(grid_pos)
			
			# 3. Tell Godot to re-calculate the connections for ALL of them together
			soil_layer.set_cells_terrain_connect(all_dirt, 0, 0)
			if Global.tutorial_step == 4:
				Global.advance_tutorial()
			
	# 2. THE WATERING CAN		
	if tool == Global.Tools.WATER:
		# Grab the data of the specific dirt tile we clicked
		var soil_data = soil_layer.get_cell_tile_data(grid_pos)
		
		# Check if there is dirt AND if we painted the 'waterable' tag on it
		if soil_data and soil_data.get_custom_data("waterable") == true:
			var all_water = water_layer.get_used_cells()
			all_water.append(grid_pos)
			water_layer.set_cells_terrain_connect(all_water, 0, 0)
			if Global.tutorial_step == 6:
				Global.advance_tutorial()
	
	# 3. THE AXE
	if tool == Global.Tools.AXE:
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
		if Global.tutorial_step == 5:
			Global.advance_tutorial()
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
	var tick_duration = _grow_timer_cycle_seconds
	var ticks_to_simulate = int(ceil(remaining_time / tick_duration))
	
	# 2. Instantly simulate the missed time!
	for i in range(ticks_to_simulate):
		_on_grow_timer_timeout() # We just call the exact function we made earlier!
		
	# 3. Restart the timers for the fresh morning
	$DayTimer.start()
	$DayTimer.wait_time = _day_timer_cycle_seconds
	$GrowTimer.start()
	$GrowTimer.wait_time = _grow_timer_cycle_seconds
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
	if _combat_intro_active:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			if is_instance_valid(_combat_intro_begin_button):
				_on_combat_intro_begin_pressed(_combat_intro_overlay, _combat_intro_panel)
				get_viewport().set_input_as_handled()
			return

		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
			_close_combat_intro()
			get_viewport().set_input_as_handled()
			return

		if is_instance_valid(_combat_intro_body):
			if event.is_action_pressed("ui_up") or event.is_action_pressed("up"):
				_scroll_combat_intro_text(-24.0)
				get_viewport().set_input_as_handled()
				return
			if event.is_action_pressed("ui_down") or event.is_action_pressed("down"):
				_scroll_combat_intro_text(24.0)
				get_viewport().set_input_as_handled()
				return


	if event is InputEventJoypadButton and event.pressed and not event.echo and event.button_index == JOY_BUTTON_Y:
		if not _combat_intro_active:
			_show_combat_intro()
			get_viewport().set_input_as_handled()
		return

	# Pressing "C" on your keyboard triggers combat
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		if _combat_intro_active:
			return

		if not Global.has_seen_combat_intro:
			_show_combat_intro()
			return

		_enter_combat_map()


func _scroll_combat_intro_text(delta: float) -> void:
	if not is_instance_valid(_combat_intro_body):
		return

	var scroll_bar: VScrollBar = _combat_intro_body.get_v_scroll_bar()
	if not is_instance_valid(scroll_bar):
		return

	var target_value: float = clampf(scroll_bar.value + delta, scroll_bar.min_value, scroll_bar.max_value)
	scroll_bar.value = target_value

func _show_combat_intro() -> void:
	_combat_intro_active = true

	if is_instance_valid(_combat_intro_overlay):
		_combat_intro_overlay.queue_free()

	var overlay := ColorRect.new()
	overlay.name = "CombatIntroOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.color = Color(0, 0, 0, 0)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 48
	panel.offset_top = 32
	panel.offset_right = -48
	panel.offset_bottom = -32
	panel.modulate.a = 0.0

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 14)

	var title := Label.new()
	title.text = "Battle Briefing"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)

	var body := RichTextLabel.new()
	body.fit_content = false
	body.scroll_active = true
	body.bbcode_enabled = false
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 16)
	body.text = "For this demo battle, a clone of your character fights WITH you against the Orcs.\n\n" + \
		"Your clone is a ranged attacker, which means they can hit enemies from farther away than melee units. " + \
		"Try to let your clone pressure enemies from distance while you choose safe positions and avoid standing in open danger zones.\n\n" + \
		"Good luck - press the button below when you're ready."

	var begin_button := Button.new()
	begin_button.text = "Begin Battle"
	begin_button.custom_minimum_size = Vector2(0, 44)
	begin_button.pressed.connect(_on_combat_intro_begin_pressed.bind(overlay, panel))

	content.add_child(title)
	content.add_child(body)
	content.add_child(begin_button)
	margin.add_child(content)
	panel.add_child(margin)
	overlay.add_child(panel)
	$CanvasLayer.add_child(overlay)
	_combat_intro_overlay = overlay
	_combat_intro_panel = panel
	_combat_intro_begin_button = begin_button
	_combat_intro_body = body

	begin_button.grab_focus()

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.78, 0.35)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.35)

func _on_combat_intro_begin_pressed(overlay: ColorRect, panel: PanelContainer) -> void:
	if not _combat_intro_active:
		return
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.25)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.2)
	await tween.finished

	_close_combat_intro()
	Global.has_seen_combat_intro = true
	_enter_combat_map()

func _close_combat_intro() -> void:
	if is_instance_valid(_combat_intro_overlay):
		_combat_intro_overlay.queue_free()

	_combat_intro_overlay = null
	_combat_intro_panel = null
	_combat_intro_begin_button = null
	_combat_intro_body = null
	_combat_intro_active = false

func _enter_combat_map() -> void:
	if _combat_transition_active:
		return
	_combat_transition_active = true

	var scene_tree := get_tree()
	if scene_tree == null:
		_combat_transition_active = false
		return

	if Global.tutorial_step == 13:
		Global.advance_tutorial()

	# Keep transition UI alive even after the farm scene is detached.
	var transition_layer := CanvasLayer.new()
	transition_layer.layer = 100
	transition_layer.name = "CombatSceneTransitionLayer"
	scene_tree.root.add_child(transition_layer)

	var fade_rect := ColorRect.new()
	fade_rect.name = "CombatSceneTransition"
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_rect.color = Color(0, 0, 0, 0)
	transition_layer.add_child(fade_rect)

	var farm_music: AudioStreamPlayer = $WhispersOfTheOldWood if has_node("WhispersOfTheOldWood") else null
	var fade_out := scene_tree.create_tween()
	fade_out.set_ease(Tween.EASE_IN_OUT)
	fade_out.set_trans(Tween.TRANS_SINE)
	fade_out.tween_property(fade_rect, "color:a", 1.0, 0.45)
	if is_instance_valid(farm_music):
		fade_out.parallel().tween_property(farm_music, "volume_db", -48.0, 0.4)
	await fade_out.finished

	# 1. Load the combat board into memory
	var combat_scene = load("res://scenes/level/CombatMap_1.tscn").instantiate()
	var combat_music: AudioStreamPlayer = combat_scene.get_node_or_null("AudioStreamPlayer")
	if is_instance_valid(combat_music):
		combat_music.autoplay = false
		combat_music.volume_db = -40.0

	var farm = scene_tree.current_scene
	Global.begin_combat_transition()

	# 2. Put the farm in the memory vault so it doesn't get deleted
	Global.saved_farm_scene = farm

	# 3. Add the Combat board to the game
	scene_tree.root.add_child(combat_scene)
	scene_tree.current_scene = combat_scene

	# 4. UNPLUG THE FARM
	# This instantly stops all audio, cameras, and UI without deleting your crops!
	scene_tree.root.remove_child(farm)

	# Ensure the combat scene is initialized before we focus gameplay elements.
	await scene_tree.process_frame

	# Start combat music with a gentle fade-in.
	if is_instance_valid(combat_music):
		combat_music.play()
		var combat_fade := scene_tree.create_tween()
		combat_fade.set_ease(Tween.EASE_OUT)
		combat_fade.set_trans(Tween.TRANS_SINE)
		combat_fade.tween_property(combat_music, "volume_db", -15.0, 1.5)

	# Center player attention immediately on Savannah.
	var board: Node = combat_scene.get_node_or_null("GameBoard")
	var savannah: Unit = combat_scene.get_node_or_null("GameBoard/Savannah") as Unit
	var cursor: Cursor = combat_scene.get_node_or_null("GameBoard/Cursor") as Cursor
	if board != null and savannah != null and cursor != null:
		cursor.cell = savannah.cell.round()
		cursor.is_active = true

	# Reveal the battlefield from black after focus has been set.
	var reveal := scene_tree.create_tween()
	reveal.set_ease(Tween.EASE_IN_OUT)
	reveal.set_trans(Tween.TRANS_SINE)
	reveal.tween_property(fade_rect, "color:a", 0.0, 0.35)
	await reveal.finished

	if is_instance_valid(transition_layer):
		transition_layer.queue_free()

	_combat_transition_active = false
