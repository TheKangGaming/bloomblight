## Represents and manages the game board. Stores references to entities that are in each cell and
## tells whether cells are occupied or not.
## Units can only move around the grid one at a time.
class_name GameBoard
extends Node2D

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
const OBSTACLE_ATLAS_ID = 2
const PauseMenu = preload("res://Menus/PauseMenu.tscn")
const ActionMenu = preload("res://Menus/ActionMenu.tscn")
## Resource of type Grid.
@export var grid: Resource

## Mapping of coordinates of a cell to a reference to the unit it contains.
var _units := {}
var _active_unit: Unit
var _walkable_cells := []
var _attackable_cells := []
var _movement_costs
var _prev_cell
var _prev_position
var _is_targeting_attack: bool = false
var _valid_target_cells: Array = []

@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path: UnitPath = $UnitPath
@onready var _map: TileMapLayer = $Map
@onready var _cursor: Cursor = $Cursor

const MAX_VALUE: int = 99999

func _ready() -> void:
	_movement_costs = _map.get_movement_costs()
	_cursor.accept_pressed.connect(_on_Cursor_accept_pressed)
	_cursor.moved.connect(_on_Cursor_moved)
	
	_reinitialize()

func _unhandled_input(event: InputEvent) -> void:
	if _active_unit and event.is_action_pressed("ui_cancel"):
		if _is_targeting_attack:
			# Player canceled targeting: clear the red tiles and bring the menu back
			_is_targeting_attack = false
			_valid_target_cells.clear()
			_unit_overlay.clear()
			_show_action_menu() 
		else:
			# Player canceled moving entirely: teleport back
			_deselect_active_unit()


func _get_configuration_warning() -> String:
	var warning := ""
	if not grid:
		warning = "You need a Grid resource for this node to work."
	return warning


## Returns `true` if the cell is occupied by a unit.
func is_occupied(cell: Vector2) -> bool:
	return _units.has(cell)


## Returns an array of cells a given unit can walk using Dijkstra.
func get_walkable_cells(unit: Unit) -> Array:
	return _dijkstra(unit, unit.move_range, false)
	
### Calculates attackable cells by extending outward from all walkable cells using math
## Calculates attackable cells using high-speed dictionary lookups (O(1)) instead of arrays
func get_attackable_cells(walkable_cells: Array, attack_range: int, unit: Unit) -> Array:
	var attackable_dict = {}
	var walkable_dict = {}
	
	# Convert our walkable array into a high-speed dictionary
	for cell in walkable_cells:
		walkable_dict[cell] = true
		
	if attack_range <= 0:
		return []
		
	for cell in walkable_cells:
		if is_occupied(cell) and _units[cell] != unit:
			continue
			
		for x in range(-attack_range, attack_range + 1):
			for y in range(-attack_range, attack_range + 1):
				var distance = abs(x) + abs(y)
				
				if distance > 0 and distance <= attack_range:
					var target_cell = cell + Vector2(x, y)
					
					if grid.is_within_bounds(target_cell):
						# CRITICAL FIX: Using .has() on a dictionary is exponentially faster!
						if not walkable_dict.has(target_cell) and not attackable_dict.has(target_cell):
							
							if is_occupied(target_cell) and _units[target_cell].is_enemy == unit.is_enemy:
								continue
								
							# Add to our high-speed dictionary
							attackable_dict[target_cell] = true
							
	# Return just the keys (the Vector2 coordinates) as an Array
	return attackable_dict.keys()


## Clears, and refills the `_units` dictionary with game objects that are on the board.
func _reinitialize() -> void:
	_units.clear()

	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
			
		# CRITICAL FIX: Force the cell to be a perfect integer to prevent float crashes!
		unit.cell = unit.cell.round()
		_units[unit.cell] = unit
		
		# Safely connect the died signal so memory is cleared when enemies are defeated
		if not unit.died.is_connected(_on_unit_died):
			unit.died.connect(_on_unit_died)


## Returns an array with all the coordinates of walkable cells based on the `max_distance`.
func _flood_fill(cell: Vector2, max_distance: int) -> Array:
	var full_array := []
	var wall_array := []
	var stack := [cell]
	
	while not stack.size() == 0:
		var current = stack.pop_back()
		if not grid.is_within_bounds(current):
			continue
		if current in full_array:
			continue

		var difference: Vector2 = (current - cell).abs()
		var distance := int(difference.x + difference.y)
		if distance > max_distance:
			continue

		full_array.append(current)
		for direction in DIRECTIONS:
			var coordinates: Vector2 = current + direction
			
			# FIX: get_cell_source_id requires a Vector2i in Godot 4!
			var coord_v2i = Vector2i(int(coordinates.x), int(coordinates.y))
			if _map.get_cell_source_id(coord_v2i) == OBSTACLE_ATLAS_ID:
				wall_array.append(coordinates)
			
			if coordinates in full_array:
				continue
			if coordinates in stack:
				continue

			stack.append(coordinates)
			
	return full_array.filter(func(i): return i not in wall_array)

## Generates a list of walkable cells based on unit movement value and tile movement cost
## Generates a list of walkable cells based on unit movement value and tile movement cost
func _dijkstra(unit: Unit, max_distance: int, attackable_check: bool) -> Array:
	var start_cell = unit.cell.round()
	
	# Dictionary to store the absolute shortest distance to each cell
	var distances = {}
	distances[start_cell] = 0
	
	var queue = PriorityQueue.new()
	queue.push(start_cell, 0) # starting cell
	
	while not queue.is_empty():
		var current_node = queue.pop()
		var current_cell = current_node.value
		var current_dist = current_node.priority
		
		# If we already found a shorter path to this cell, skip it
		if current_dist > distances.get(current_cell, MAX_VALUE):
			continue
			
		for direction in DIRECTIONS:
			var neighbor = current_cell + direction 
			
			if not grid.is_within_bounds(neighbor):
				continue
				
			# Enemies act as solid brick walls! Use .get() for 100% safety
			var neighbor_unit = _units.get(neighbor)
			if neighbor_unit != null and neighbor_unit.is_enemy != unit.is_enemy:
				continue
				
			var coord_v2i = Vector2i(int(neighbor.x), int(neighbor.y))
			var tile_cost = _movement_costs.get(coord_v2i, 1) 
			var new_cost = current_dist + tile_cost 
			
			# If we can reach the tile, and this is the fastest route we've found so far...
			if new_cost <= max_distance:
				if new_cost < distances.get(neighbor, MAX_VALUE):
					distances[neighbor] = new_cost
					queue.push(neighbor, new_cost) 
	
	# Return all the keys we found. These are our blue tiles!
	return distances.keys()


## Moves the active unit to the new cell and shows the action menu
func _move_active_unit(new_cell: Vector2) -> void:
	# 1. Validate and explicitly draw the path to the target
	if _unit_path._pathfinder == null:
		_unit_path.initialize(_walkable_cells)
	_unit_path.draw(_active_unit.cell, new_cell)
	
	# 2. Safety Check: If the path is somehow empty or doesn't reach the target, abort
	if _unit_path.current_path.is_empty() or _unit_path.current_path[-1] != new_cell:
		return 
	
	# 3. Path is secure! Safe to clear visual memory.
	_walkable_cells.clear()
	_attackable_cells.clear()
	_unit_overlay.clear()
	_cursor.is_active = false
	
	# 4. CRITICAL FIX: Erase the old position from the board's memory and log the new one!
	_units.erase(_active_unit.cell)
	_units[new_cell] = _active_unit
	
	# 5. Tell the unit to walk, and wait for the specific 'walk_finished' signal!
	_active_unit.walk_along(_unit_path.current_path)
	await _active_unit.walk_finished
	
	_show_action_menu()
	


## Selects the unit in the `cell` if there's one there.
## Sets it as the `_active_unit` and draws its walkable cells and interactive move path. 
func _select_unit(cell: Vector2) -> void:
	if not _units.has(cell):
		return

	_active_unit = _units[cell]
	_prev_cell = cell
	_prev_position = _active_unit.position
	_active_unit.is_selected = true
	_walkable_cells = get_walkable_cells(_active_unit)
	_attackable_cells = get_attackable_cells(_walkable_cells, _active_unit.attack_range, _active_unit)
	
	_unit_overlay.draw_attackable_cells(_attackable_cells)
	
	_unit_overlay.draw_walkable_cells(_walkable_cells)
	
	

	_unit_path.initialize(_walkable_cells)
	
	
func _hover_display(cell: Vector2) -> void:
	if is_occupied(cell):
		var curr_unit = _units[cell]
		
		# 1. Get the blue cells
		_walkable_cells = get_walkable_cells(curr_unit)
		
		# 2. Pass those blue cells directly into the red cell math!
		_attackable_cells = get_attackable_cells(_walkable_cells, curr_unit.attack_range, curr_unit)
		
		print("Blue tiles: ", _walkable_cells.size(), " | Red tiles: ", _attackable_cells.size())
		
		# 3. Clear the old tiles ONCE here:
		_unit_overlay.clear() 
		
		# 4. Draw the red tiles first, then the blue ones on top!
		_unit_overlay.draw_attackable_cells(_attackable_cells)
		_unit_overlay.draw_walkable_cells(_walkable_cells)


## Safely opens the pause menu, guaranteeing we don't stack duplicates.
func _show_pause_menu() -> void:
	if has_node("PauseMenu"):
		return # Menu is already open, do nothing!
		
	var pause_menu = PauseMenu.instantiate()
	pause_menu.name = "PauseMenu" # Explicitly name it so has_node() works
	add_child(pause_menu)


func _reset_unit() -> void:
	# 1. Hide the menu if it's open to get it out of our way
	if has_node("ActionMenu"):
		$ActionMenu.hide()

	if _active_unit != null:
		# 2. Only physically teleport her if she actually moved away from her start tile
		if _active_unit.cell != _prev_cell:
			_active_unit.position = _prev_position
			_units.erase(_active_unit.cell)
			_units[_prev_cell] = _active_unit
			_active_unit.cell = _prev_cell
			
		# 3. ALWAYS clear out these memory variables, even if she didn't move
		_prev_cell = null
		_prev_position = null
		
		# 4. Deselect her so the animations reset and the board forgets her
		_deselect_active_unit()
		_deselect_active_unit()
		
	# 5. CRITICAL FIX: Give control back to the player!
	_cursor.is_active = true
		
## Deselects the active unit, clearing the cells overlay and interactive path drawing.
## Universally clears the active unit, resets their animations, and wipes the overlays.
func _deselect_active_unit() -> void:
	if _active_unit:
		_active_unit.is_selected = false
		
	_active_unit = null
	_walkable_cells.clear()
	_attackable_cells.clear()
	_unit_overlay.clear()
	_unit_path.stop()


## Selects or moves a unit based on where the cursor is.
func _on_Cursor_accept_pressed(cell: Vector2) -> void:
	# --- 1. NEW COMBAT STATE INTERCEPT ---
	if _is_targeting_attack:
		if cell in _valid_target_cells and is_occupied(cell):
			var target_unit = _units[cell]
			
			# Ensure we are actually clicking an enemy!
			if target_unit.is_enemy != _active_unit.is_enemy:
				_cursor.is_active = false # Freeze input during the fight
				
				# FIGHT! Wait for the lunge to finish.
				await _active_unit.attack(target_unit)
				
				# Cleanup and automatically end the unit's turn
				_is_targeting_attack = false
				_valid_target_cells.clear()
				finish_unit_turn()
				
		return # Stop running the rest of the function if we are in targeting mode!
		
	if not _active_unit and _units.has(cell):
		var unit = _units[cell]
		
		# Check if the unit has already taken its turn!
		if unit.is_wait:
			# Open the pause menu so the player can easily click "End Turn"
			var pause_menu = PauseMenu.instantiate()
			add_child(pause_menu)
		else:
			# Wakey wakey, time to move!
			_select_unit(cell)
			
	elif _active_unit != null: 
		# 1. Player clicked the active unit (waiting in place without moving)
		if is_occupied(cell) and _units[cell] == _active_unit:
			_unit_overlay.clear()
			_unit_path.stop()
			_show_action_menu()
			
		# 2. Player clicked an empty blue tile to move
		elif not is_occupied(cell) and _walkable_cells.has(cell):
			await _move_active_unit(cell) 
	else:
		# Player clicked an empty tile
		_show_pause_menu()


## Updates the interactive path's drawing if there's an active and selected unit.
func _on_Cursor_moved(new_cell: Vector2) -> void:
	if _active_unit and _active_unit.is_selected:
		if _walkable_cells.has(new_cell):
			if _unit_path._pathfinder == null:
				_unit_path.initialize(_walkable_cells)
			_unit_path.draw(_active_unit.cell, new_cell)
		else:
			_unit_path.stop()
			
	else:
		# CRITICAL FIX: Only show hover range if the unit hasn't taken their turn yet!
		if _units.has(new_cell) and not _units[new_cell].is_wait:
			_hover_display(new_cell)
		else:
			_unit_overlay.clear()
			_walkable_cells.clear()
		
func _on_unit_died(unit: Unit) -> void:
	_units.erase(unit.cell)
	
	# If the active unit died, clear the cursor selection
	if _active_unit == unit:
		_deselect_active_unit()

func _show_action_menu() -> void:
	var action_menu
	
	if has_node("ActionMenu"):
		action_menu = $ActionMenu
	else:
		action_menu = ActionMenu.instantiate()
		action_menu.name = "ActionMenu"
		# Optional: Add it to a dedicated UI layer if you have one, 
		# e.g., get_node("/root/Main/CanvasLayer").add_child(action_menu)
		add_child(action_menu)
		
	action_menu.show()
	
	# REMOVED: All the screen_pos and offset calculations.
	# The menu will now rely on the static anchors you set in ActionMenu.tscn!
	
	_cursor.is_active = false


## To be called by the Action Menu when the player chooses "Wait"
func finish_unit_turn() -> void:
	# Make the unit grey out to show their turn is over
	if _active_unit:
		var visuals = _active_unit.get_node_or_null("PathFollow2D/Visuals")
		if visuals:
			visuals.modulate = Color(0.5, 0.5, 0.5, 1.0) # Grey out
		
		_active_unit.is_wait = true
		
	if has_node("ActionMenu"):
		$ActionMenu.hide()
		
	_deselect_active_unit()
	_cursor.is_active = true
	
func end_player_phase() -> void:
	# 1. Loop through all units on the board
	for cell in _units:
		var unit = _units[cell]
		if unit.is_player:
			# Wake them up!
			unit.is_wait = false
			var visuals = unit.get_node_or_null("PathFollow2D/Visuals")
			if visuals:
				visuals.modulate = Color.WHITE # Remove the grey filter
	
	# 2. Re-enable the cursor
	_cursor.is_active = true
	
## Enters the targeting state, drawing red squares around the unit's current position
func enter_attack_targeting() -> void:
	_is_targeting_attack = true
	_valid_target_cells.clear()
	_unit_overlay.clear()
	
	var atk_range = _active_unit.attack_range
	var center_cell = _active_unit.cell
	
	# Calculate attack range from where the unit is currently standing
	for x in range(-atk_range, atk_range + 1):
		for y in range(-atk_range, atk_range + 1):
			var distance = abs(x) + abs(y)
			if distance > 0 and distance <= atk_range:
				var target_cell = center_cell + Vector2(x, y)
				if grid.is_within_bounds(target_cell):
					_valid_target_cells.append(target_cell)
					
	# Draw the red tiles (passing an empty array for the blue tiles)
	_unit_overlay.draw_attackable_cells(_valid_target_cells)
	
	# Wake the cursor back up so the player can pick a target
	_cursor.is_active = true
