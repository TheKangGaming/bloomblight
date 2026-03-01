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

@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path: UnitPath = $UnitPath
@onready var _map: TileMapLayer = $Map
@onready var _cursor: Cursor = $Cursor

const MAX_VALUE: int = 99999

func _ready() -> void:
	_movement_costs = _map.get_movement_costs()
	_reinitialize()
	_cursor.accept_pressed.connect(_on_Cursor_accept_pressed)
	_cursor.moved.connect(_on_Cursor_moved)

	for child in get_children():
		if child is Unit:
			_units[child.cell] = child
			# (Your existing signals, if any)
			
			# ADD THIS LINE: Listen for their death!
			child.died.connect(_on_unit_died)

func _unhandled_input(event: InputEvent) -> void:
	if _active_unit and event.is_action_pressed("ui_cancel"):
		_deselect_active_unit()
		_clear_active_unit()


func _get_configuration_warning() -> String:
	var warning := ""
	if not grid:
		warning = "You need a Grid resource for this node to work."
	return warning


## Returns `true` if the cell is occupied by a unit.
func is_occupied(cell: Vector2) -> bool:
	return _units.has(cell)


## Returns an array of cells a given unit can walk using the flood fill algorithm.
func get_walkable_cells(unit: Unit) -> Array:
	return _dijkstra(unit.cell, unit.move_range, false)
	
## Calculates attackable cells by extending outward from all walkable cells using math
func get_attackable_cells(walkable_cells: Array, attack_range: int) -> Array:
	var attackable_cells = []
	
	# Safety check: if they have no weapon/range, skip everything
	if attack_range <= 0:
		return attackable_cells
		
	for cell in walkable_cells:
		# Mathematically check a grid area around each blue cell
		for x in range(-attack_range, attack_range + 1):
			for y in range(-attack_range, attack_range + 1):
				
				# If the distance is within our weapon's reach (Manhattan distance)
				if abs(x) + abs(y) > 0 and abs(x) + abs(y) <= attack_range:
					var target_cell = cell + Vector2(x, y)
					
					# If the cell exists on the map, isn't blue, and isn't already red...
					if grid.is_within_bounds(target_cell):
						if target_cell not in walkable_cells and target_cell not in attackable_cells:
							attackable_cells.append(target_cell)
							
	return attackable_cells


## Clears, and refills the `_units` dictionary with game objects that are on the board.
func _reinitialize() -> void:
	_units.clear()

	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
		_units[unit.cell] = unit


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
func _dijkstra(cell: Vector2, max_distance: int, attackable_check: bool) -> Array:
	var curr_unit = _units[cell]
	var moveable_cells = [cell] # append our base cell to the array
	var visited = [] # 2d array that keeps track of which cells we've already looked at
	var distances = [] # shows distance to each cell
	var previous = [] # 2d array that shows you which cell you have to take to get there
	
	# OPTIMIZATION: Ensure size limits are integers
	var size_x = int(grid.size.x)
	var size_y = int(grid.size.y)
	
	## iterate over width and height of the grid
	for y in range(size_y):
		visited.append([])
		distances.append([])
		previous.append([])
		for x in range(size_x):
			visited[y].append(false)
			distances[y].append(MAX_VALUE)
			previous[y].append(null)
	
	## Make new queue
	var queue = PriorityQueue.new()
	queue.push(cell, 0) # starting cell
	
	# FIX: Cast coordinates to int before using as Array indexes
	var start_x = int(cell.x)
	var start_y = int(cell.y)
	distances[start_y][start_x] = 0
	
	var occupied_cells = []
	
	## While there is still a node in the queue, we'll keep looping
	while not queue.is_empty():
		var current = queue.pop() # take out the front node
		
		# FIX: Cast to int
		var cur_x = int(current.value.x)
		var cur_y = int(current.value.y)
		visited[cur_y][cur_x] = true # mark front node as visited
		
		for direction in DIRECTIONS:
			var coordinates = current.value + direction 
			
			if grid.is_within_bounds(coordinates):
				# FIX: Create integer bounds for our Godot 4 Arrays
				var cx = int(coordinates.x)
				var cy = int(coordinates.y)
				
				if visited[cy][cx]:
					continue
				
				# Because of 'continue' above, we don't need 'else' here.
				# FIX: _movement_costs is a 1D dictionary keyed by Vector2i.
				var coord_v2i = Vector2i(cx, cy)
				# .get() pulls the cost safely, and defaults to 1 if the tile isn't in the dict
				var tile_cost = _movement_costs.get(coord_v2i, 1) 
				
				var distance_to_node = current.priority + tile_cost 
				
				if is_occupied(coordinates):
					if curr_unit.is_enemy != _units[coordinates].is_enemy:
						distance_to_node = current.priority + MAX_VALUE
					elif _units[coordinates].is_wait and attackable_check:
						occupied_cells.append(coordinates)
						
				visited[cy][cx] = true
				distances[cy][cx] = distance_to_node
			
				if distance_to_node <= max_distance: # check if node is actually reachable
					previous[cy][cx] = current.value 
					moveable_cells.append(coordinates) 
					queue.push(coordinates, distance_to_node) 
	
	return moveable_cells.filter(func(i): return i not in occupied_cells)

## Updates the _units dictionary with the target position for the unit and asks the _active_unit to walk to it.
func _move_active_unit(new_cell: Vector2) -> void:
	# 1. Check if the tile is valid
	if is_occupied(new_cell) or not new_cell in _walkable_cells:
		return
	
	# CRITICAL FIX: Disable the cursor instantly so stray mouse movements 
	# during the run animation don't crash the empty pathfinder!
	_cursor.is_active = false
	
	# 2. Clear the blue/red visual tiles immediately so the board looks clean
	_unit_overlay.clear()
	_unit_path.stop()
	
	# 3. Tell the unit to start running!
	_active_unit.walk_along(_unit_path.current_path)
	
	# 4. Wait right here until the puppet is completely finished running
	await _active_unit.walk_finished
	
	# 5. Update the board's memory with her new location
	_units.erase(_active_unit.cell)
	_units[new_cell] = _active_unit
	_active_unit.cell = new_cell
	
	# 6. POP UP THE ACTION MENU!
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
	_attackable_cells = get_attackable_cells(_walkable_cells, _active_unit.attack_range)
	
	_unit_overlay.draw_attackable_cells(_attackable_cells)
	
	_unit_overlay.draw_walkable_cells(_walkable_cells)
	
	

	_unit_path.initialize(_walkable_cells)
	
	
func _hover_display(cell: Vector2) -> void:
	if is_occupied(cell):
		var curr_unit = _units[cell]
		
		# 1. Get the blue cells
		_walkable_cells = get_walkable_cells(curr_unit)
		
		# 2. Pass those blue cells directly into the red cell math!
		_attackable_cells = get_attackable_cells(_walkable_cells, curr_unit.attack_range)
		
		print("Blue tiles: ", _walkable_cells.size(), " | Red tiles: ", _attackable_cells.size())
		
		# 3. Clear the old tiles ONCE here:
		_unit_overlay.clear() 
		
		# 4. Draw the red tiles first, then the blue ones on top!
		_unit_overlay.draw_attackable_cells(_attackable_cells)
		_unit_overlay.draw_walkable_cells(_walkable_cells)

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
		_clear_active_unit()
		
	# 5. CRITICAL FIX: Give control back to the player!
	_cursor.is_active = true
		
## Deselects the active unit, clearing the cells overlay and interactive path drawing.
func _deselect_active_unit() -> void:
	_active_unit.is_selected = false
	_unit_overlay.clear()
	_unit_path.stop()


## Clears the reference to the _active_unit and the corresponding walkable cells.
func _clear_active_unit() -> void:
	_active_unit = null
	_walkable_cells.clear()


## Selects or moves a unit based on where the cursor is.
func _on_Cursor_accept_pressed(cell: Vector2) -> void:
	if not _active_unit and _units.has(cell):
		_select_unit(cell)
	elif _active_unit != null: 
		# 1. Player clicked the active unit (waiting in place without moving)
		if is_occupied(cell) and _units[cell] == _active_unit:
			_unit_overlay.clear()
			_unit_path.stop()
			_show_action_menu()
			
		# 2. Player clicked an empty blue tile to move
		elif not is_occupied(cell) and _walkable_cells.has(cell):
			# _move_active_unit already pops up the menu when the walk finishes!
			await _move_active_unit(cell) 
	else:
		var pause_menu = PauseMenu.instantiate()
		add_child(pause_menu)


## Updates the interactive path's drawing if there's an active and selected unit.
func _on_Cursor_moved(new_cell: Vector2) -> void:
	if _active_unit and _active_unit.is_selected and _unit_path._pathfinder:
		if _walkable_cells.has(new_cell):
			_unit_path.draw(_active_unit.cell, new_cell)
		else:
			# If they move the mouse out of bounds, stop drawing the path
			_unit_path.stop()
		
	elif _unit_overlay != null and _walkable_cells != []:
		_walkable_cells.clear()
		_unit_overlay.clear()
	if _units.has(new_cell) and _active_unit == null:
		_hover_display(new_cell)
		
func _on_unit_died(unit: Unit) -> void:
	_units.erase(unit.cell)
	
	# If the active unit died, clear the cursor selection
	if _active_unit == unit:
		_clear_active_unit()

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
		
	_clear_active_unit()
	_cursor.is_active = true
