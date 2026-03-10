## Represents and manages the game board. Stores references to entities that are in each cell and
## tells whether cells are occupied or not.
## Units can only move around the grid one at a time.
class_name GameBoard
extends Node2D

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
const OBSTACLE_ATLAS_ID = 2
const FOLLOW_UP_SPEED_DIFF := 4
const PauseMenu = preload("res://Menus/PauseMenu.tscn")
const ActionMenu = preload("res://Menus/ActionMenu.tscn")
## Resource of type Grid.
@export var grid: Resource

enum TurnPhase { PLAYER, ENEMY }
var current_phase: TurnPhase = TurnPhase.PLAYER

## Mapping of coordinates of a cell to a reference to the unit it contains.
var _units := {}
var _enemies_defeated: int = 0
var _active_unit: Unit
var _walkable_cells := []
var _attackable_cells := []
var _movement_costs
var _prev_cell
var _prev_position
var _is_targeting_attack: bool = false
var _target_unit_for_forecast: Unit = null
var _forecast_ui_node: CanvasLayer = null
var _valid_target_cells: Array = []
var _attack_offsets_cache := {}
var _phase_banner_layer: CanvasLayer = null
var _results_canvas: CanvasLayer = null
var _results_return_button: Button = null
var _battle_ended: bool = false
var _unit_hover_tooltip: CanvasLayer = null
var _unit_hover_panel: PanelContainer = null
var _unit_hover_label: RichTextLabel = null

@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path: UnitPath = $UnitPath
@onready var _map: TileMapLayer = $Map
@onready var _cursor: Cursor = $Cursor

const MAX_VALUE: int = 99999

func _ready() -> void:
	
	##var generator = $"../MapDirector" # Ensure this name matches the node you added!
	##if generator:
		##generator.generate_new_map()
	_movement_costs = _map.get_movement_costs()
	_cursor.accept_pressed.connect(_on_Cursor_accept_pressed)
	_cursor.moved.connect(_on_Cursor_moved)
	
	_reinitialize()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_toggle"):
		_hide_unit_hover_tooltip()
		_show_pause_menu()
		get_viewport().set_input_as_handled()
		return

	if _battle_ended and is_instance_valid(_results_return_button):
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			if not _results_return_button.disabled:
				_results_return_button.pressed.emit()
				get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("up") or event.is_action_pressed("down"):
			_results_return_button.grab_focus()
			get_viewport().set_input_as_handled()
			return

	if _active_unit and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel")):
		
		# NEW: If viewing forecast, back out to targeting mode
		if _target_unit_for_forecast != null:
			_target_unit_for_forecast = null
			_hide_combat_forecast()
			return
			
		if _is_targeting_attack:
			# Player canceled targeting: clear the red tiles and bring the menu back
			_is_targeting_attack = false
			_valid_target_cells.clear()
			_unit_overlay.clear()
			_show_action_menu() 
		else:
			# Player canceled moving entirely: teleport back
			_reset_unit()


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
	var attack_offsets = _get_attack_offsets(attack_range)
	
	# Convert our walkable array into a high-speed dictionary
	for cell in walkable_cells:
		walkable_dict[cell] = true
		
	if attack_range <= 0:
		return []
		
	for cell in walkable_cells:
		if is_occupied(cell) and _units[cell] != unit:
			continue

		for offset in attack_offsets:
			var target_cell = cell + offset

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
	
	

func _get_attack_cells_from_origin(origin: Vector2, attack_range: int) -> Dictionary:
	var cells: Dictionary = {}
	for offset in _get_attack_offsets(attack_range):
		var target_cell = origin + offset
		if grid.is_within_bounds(target_cell):
			cells[target_cell] = true
	return cells

func _find_attack_origin_for_target(target_cell: Vector2) -> Variant:
	if _active_unit == null:
		return null

	var attack_range = _active_unit.attack_range
	if attack_range <= 0:
		return null

	var best_cell: Variant = null
	var best_distance := INF
	for candidate in _walkable_cells:
		if candidate != _active_unit.cell and is_occupied(candidate):
			continue

		var dist := _manhattan_distance(candidate, target_cell)
		if not _is_distance_in_attack_range(dist, attack_range):
			continue

		var move_distance := _manhattan_distance(_active_unit.cell, candidate)
		if move_distance < best_distance:
			best_distance = move_distance
			best_cell = candidate

	return best_cell

func _begin_attack_preview_on_target(target_unit: Unit) -> void:
	_target_unit_for_forecast = target_unit
	_is_targeting_attack = true
	_valid_target_cells = _get_attack_cells_from_origin(_active_unit.cell, _active_unit.attack_range).keys()
	_unit_overlay.clear()
	_unit_overlay.draw_attackable_cells(_valid_target_cells)
	_show_combat_forecast(_active_unit, target_unit)

func _hover_display(cell: Vector2) -> void:
	if is_occupied(cell):
		var curr_unit = _units[cell]
		
		# 1. Get the blue cells
		_walkable_cells = get_walkable_cells(curr_unit)
		
		# 2. Pass those blue cells directly into the red cell math!
		_attackable_cells = get_attackable_cells(_walkable_cells, curr_unit.attack_range, curr_unit)
		
		# 3. Clear the old tiles ONCE here:
		_unit_overlay.clear() 
		
		# 4. Draw the red tiles first, then the blue ones on top!
		_unit_overlay.draw_attackable_cells(_attackable_cells)
		_unit_overlay.draw_walkable_cells(_walkable_cells)


## Safely opens the pause menu, guaranteeing we don't stack duplicates.
func _show_pause_menu() -> void:
	if has_node("PauseMenu"):
		return # Menu is already open, do nothing!
		
	_hide_unit_hover_tooltip()
	var pause_menu = PauseMenu.instantiate()
	pause_menu.name = "PauseMenu" # Explicitly name it so has_node() works
	add_child(pause_menu)
	if pause_menu.has_method("_set_units"):
		pause_menu.call("_set_units", _units.values())
	if pause_menu.has_method("_reset_menu_focus"):
		pause_menu.call_deferred("_reset_menu_focus")


func _reset_unit() -> void:
	# 1. Remove the menu if it's open so it can't keep the cursor disabled.
	if has_node("ActionMenu"):
		$ActionMenu.queue_free()

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
		
	# 5. CRITICAL FIX: Give control back to the player!
	_cursor.process_mode = Node.PROCESS_MODE_INHERIT
	_cursor.show()
	_cursor.is_active = true


func _is_distance_in_attack_range(distance: int, attack_range: int) -> bool:
	return attack_range > 0 and distance == attack_range
		
## Deselects the active unit, clearing the cells overlay and interactive path drawing.
## Universally clears the active unit, resets their animations, and wipes the overlays.
func _deselect_active_unit() -> void:
	if _active_unit:
		_active_unit.is_selected = false

	_target_unit_for_forecast = null
	_hide_combat_forecast()
	_is_targeting_attack = false
	_valid_target_cells.clear()
		
	_active_unit = null
	_walkable_cells.clear()
	_attackable_cells.clear()
	_unit_overlay.clear()
	_unit_path.stop()


## Selects or moves a unit based on where the cursor is.
func _on_Cursor_accept_pressed(cell: Vector2) -> void:
	if _battle_ended:
		return

	# --- 0. CONFIRM FORECAST STATE ---
	if _target_unit_for_forecast != null:
		# We are currently viewing the forecast window and clicked Confirm again!
		var target = _target_unit_for_forecast
		_target_unit_for_forecast = null
		_hide_combat_forecast()
		
		_cursor.is_active = false 
		await execute_combat(_active_unit, target)
		
		_is_targeting_attack = false
		_valid_target_cells.clear()
		
		if is_instance_valid(_active_unit) and _active_unit.health > 0:
			finish_unit_turn()
		else:
			_deselect_active_unit()
			_cursor.is_active = true
		return

	# --- 1. TARGETING STATE INTERCEPT ---
	if _is_targeting_attack:
		if cell in _valid_target_cells and is_occupied(cell):
			var target_unit = _units[cell]
			if target_unit.is_enemy != _active_unit.is_enemy:
				_begin_attack_preview_on_target(target_unit)
		return
		
	# --- 2. MOVEMENT / SELECTION INTERCEPT ---
	if not _active_unit and _units.has(cell):
		var unit = _units[cell]
		
		# NEW: If the unit is an enemy, the player CANNOT move them!
		if unit.is_enemy:
			# Later, we can make clicking an enemy show their danger radius.
			# For now, we just completely ignore the click.
			return 
		
		# Check if the player unit has already taken its turn!
		if unit.is_wait:
			_show_pause_menu()
		else:
			_select_unit(cell)
			
	elif _active_unit != null: 
		# 1. Player clicked the active unit (waiting in place without moving)
		if is_occupied(cell) and _units[cell] == _active_unit:
			_unit_overlay.clear()
			_unit_path.stop()
			_show_action_menu()
			
		# 2. Player clicked an enemy directly while still in move phase.
		elif is_occupied(cell):
			var target_unit = _units[cell]
			if target_unit.is_enemy != _active_unit.is_enemy:
				var attack_from_cell = _find_attack_origin_for_target(cell)
				if attack_from_cell != null:
					if attack_from_cell != _active_unit.cell:
						await _move_active_unit(attack_from_cell)
						if has_node("ActionMenu"):
							$ActionMenu.hide()
					_begin_attack_preview_on_target(target_unit)

		# 3. Player clicked an empty blue tile to move
		elif not is_occupied(cell) and _walkable_cells.has(cell):
			await _move_active_unit(cell) 
	else:
		# Player clicked an empty tile
		_show_pause_menu()


## Updates the interactive path's drawing if there's an active and selected unit.
func _on_Cursor_moved(new_cell: Vector2) -> void:
	if _active_unit and _active_unit.is_selected:
		_hide_unit_hover_tooltip()
		if _walkable_cells.has(new_cell):
			if _unit_path._pathfinder == null:
				_unit_path.initialize(_walkable_cells)
			_unit_path.draw(_active_unit.cell, new_cell)
		else:
			_unit_path.stop()
			
	else:
		if _units.has(new_cell):
			_show_unit_hover_tooltip(_units[new_cell], new_cell)
		else:
			_hide_unit_hover_tooltip()

		# CRITICAL FIX: Only show hover range if the unit hasn't taken their turn yet!
		if _units.has(new_cell) and not _units[new_cell].is_wait:
			_hover_display(new_cell)
		else:
			_unit_overlay.clear()
			_walkable_cells.clear()
		
func _on_unit_died(unit: Unit) -> void:
	# 1. The Double-Trigger Fix! 
	# If we already erased this unit, ignore the second death signal!
	if not _units.has(unit.cell):
		return
		
	# --- Your Existing UI Cleanup ---
	_units.erase(unit.cell)
	if _target_unit_for_forecast == unit:
		_target_unit_for_forecast = null
		_hide_combat_forecast()
	
	if _active_unit == unit:
		_deselect_active_unit()
		
	# --- Win/Loss Logic ---
	if unit.is_enemy:
		_enemies_defeated += 1
		
	_check_win_loss()
	
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
	if action_menu.has_method("_reset_menu_focus"):
		action_menu.call_deferred("_reset_menu_focus")
	
	# REMOVED: All the screen_pos and offset calculations.
	# The menu will now rely on the static anchors you set in ActionMenu.tscn!
	
	_cursor.is_active = false


## To be called by the Action Menu when the player chooses "Wait"
func finish_unit_turn() -> void:
	if _battle_ended:
		return

	if _active_unit:
		var visuals = _active_unit.get_node_or_null("PathFollow2D/Visuals")
		if visuals:
			visuals.modulate = Color(0.5, 0.5, 0.5, 1.0) # Grey out
		
		_active_unit.is_wait = true
		
	if has_node("ActionMenu"):
		$ActionMenu.hide()
		
	_deselect_active_unit()
	
	# --- NEW: Check if all player units have acted ---
	if _are_all_player_units_waiting():
		end_player_phase()
	else:
		_cursor.is_active = true
	
## Called when the player presses "End Turn" or all player units are exhausted
func end_player_phase() -> void:
	if _battle_ended:
		return

	# 1. Lock the player out entirely
	_cursor.is_active = false
	current_phase = TurnPhase.ENEMY
	
	print("ENEMY PHASE START")
	
	# 2. Trigger the Enemy Phase Logic (We will build the AI inside this!)
	start_enemy_phase()

func _manhattan_distance(from_cell: Vector2, to_cell: Vector2) -> int:
	return int(abs(from_cell.x - to_cell.x) + abs(from_cell.y - to_cell.y))

func _is_valid_attack_target(attacker: Unit, target: Unit) -> bool:
	return is_instance_valid(target) and target.health > 0 and target.is_enemy != attacker.is_enemy

func _get_legal_enemy_destinations(enemy: Unit, walkable_cells: Array) -> Array:
	var legal_dict := {enemy.cell: true}
	for cell in walkable_cells:
		if is_occupied(cell) and _units[cell] != enemy:
			continue
		legal_dict[cell] = true
	return legal_dict.keys()

func _pick_enemy_action(enemy: Unit, players: Array, legal_destinations: Array) -> Dictionary:
	var best_choice := {
		"target": null,
		"cell": enemy.cell,
		"distance": MAX_VALUE,
		"can_attack": false,
		"target_hp": MAX_VALUE,
	}

	for player in players:
		if not _is_valid_attack_target(enemy, player):
			continue

		for destination in legal_destinations:
			var dist = _manhattan_distance(destination, player.cell)
			var can_attack_from_here = _is_distance_in_attack_range(dist, enemy.attack_range)

			# Priority: secure an attack this turn, then maximize proximity, then focus lower HP targets.
			var should_replace = false
			if can_attack_from_here and not best_choice["can_attack"]:
				should_replace = true
			elif can_attack_from_here == best_choice["can_attack"]:
				if dist < best_choice["distance"]:
					should_replace = true
				elif dist == best_choice["distance"] and player.health < best_choice["target_hp"]:
					should_replace = true

			if should_replace:
				best_choice = {
					"target": player,
					"cell": destination,
					"distance": dist,
					"can_attack": can_attack_from_here,
					"target_hp": player.health,
				}

	return best_choice

## Loops through all enemies and lets them act
func start_enemy_phase() -> void:
	if _battle_ended:
		return

	# Fire the Red Banner!
	await _show_phase_banner("ENEMY PHASE", Color(0.8, 0.1, 0.1))
	if _battle_ended:
		return
	
	# 1. Gather all living enemies currently on the board
	var enemies = []
	for cell in _units:
		var unit = _units[cell]
		if unit.is_enemy:
			enemies.append(unit)
			
	# 2. Process each enemy one by one
	for enemy in enemies:
		if _battle_ended:
			return
		# Skip if the enemy was somehow killed (future-proofing for counter-attacks)
		if not is_instance_valid(enemy) or enemy.health <= 0:
			continue

		# Recompute players each enemy turn so we don't hold stale references after kills.
		var players = []
		for cell in _units:
			var unit = _units[cell]
			if not unit.is_enemy and unit.health > 0:
				players.append(unit)

		if players.is_empty():
			break
			
		# A. Build legal movement options and select the best move+target pair.
		var walkable_cells = get_walkable_cells(enemy)
		var legal_destinations = _get_legal_enemy_destinations(enemy, walkable_cells)
		var decision = _pick_enemy_action(enemy, players, legal_destinations)

		if decision["target"] == null:
			await get_tree().create_timer(0.2).timeout
			continue

		var best_cell: Vector2 = decision["cell"]
		var target_player: Unit = decision["target"]

		# B. Move the Enemy!
		if best_cell != enemy.cell:
			# We hijack the unit_path to calculate the route, but we DON'T draw the blue line!
			_unit_path.initialize(walkable_cells)
			var path = _unit_path._pathfinder.calculate_point_path(enemy.cell, best_cell)

			# Update the GameBoard's dictionary memory
			_units.erase(enemy.cell)
			_units[best_cell] = enemy

			# Physically walk and wait for the animation to finish
			enemy.walk_along(path)
			await enemy.walk_finished
		else:
			# If they can't move, just add a tiny delay so it feels like they "thought" about it
			await get_tree().create_timer(0.2).timeout

		# C. Attack check using the chosen target.
		if _is_valid_attack_target(enemy, target_player):
			var final_dist = _manhattan_distance(enemy.cell, target_player.cell)
			if _is_distance_in_attack_range(final_dist, enemy.attack_range):
				
				# NEW: Hand the AI fight over to the combat manager!
				await execute_combat(enemy, target_player)
				
		# Add a slight delay before the next Orc takes its turn
		await get_tree().create_timer(0.3).timeout

	# 3. All enemies have acted! Pass the baton back to the player.
	if not _battle_ended:
		start_player_phase()

## Wakes all player units up and hands control back to the player
func start_player_phase() -> void:
	if _battle_ended:
		return

	current_phase = TurnPhase.PLAYER
	
	# Fire the Blue Banner!
	await _show_phase_banner("PLAYER PHASE", Color(0.1, 0.4, 0.8))
	
	# Wake up all player units!
	for cell in _units:
		var unit = _units[cell]
		if not unit.is_enemy: 
			unit.is_wait = false
			var visuals = unit.get_node_or_null("PathFollow2D/Visuals")
			if visuals:
				visuals.modulate = Color.WHITE 
	
	_cursor.is_active = true
	
## Enters the targeting state, drawing red squares around the unit's current position
func enter_attack_targeting() -> void:
	_is_targeting_attack = true
	_valid_target_cells.clear()
	_unit_overlay.clear()
	
	var atk_range = _active_unit.attack_range
	var center_cell = _active_unit.cell
	var attack_offsets = _get_attack_offsets(atk_range)
	
	# Calculate attack range from where the unit is currently standing
	for offset in attack_offsets:
		var target_cell = center_cell + offset
		if grid.is_within_bounds(target_cell):
			_valid_target_cells.append(target_cell)
					
	# Draw the red tiles (passing an empty array for the blue tiles)
	_unit_overlay.draw_attackable_cells(_valid_target_cells)
	
	# Wake the cursor back up so the player can pick a target
	_cursor.is_active = true
	
## Orchestrates the turn-based combat sequence between two units
func execute_combat(attacker: Unit, defender: Unit) -> void:
	if _battle_ended or not is_instance_valid(attacker) or not is_instance_valid(defender):
		return

	# 1. Initiator swings first
	await attacker.attack(defender)
	if _battle_ended or not is_instance_valid(attacker):
		return
	
	var defender_countered := false

	# 2. Check if defender survived the hit
	if is_instance_valid(defender) and defender.health > 0:
		
		# 3. Strategy logic: Is the attacker inside the defender's attack range?
		if _can_unit_attack_target(defender, attacker):
			
			# 4. Cinematic pause, then counter-attack!
			await get_tree().create_timer(0.3).timeout
			print(defender.name + " retaliates!")
			await defender.attack(attacker)
			defender_countered = true

	# 5. Follow-up strike from the faster unit, if still alive and in range.
	if is_instance_valid(attacker) and is_instance_valid(defender) and _can_unit_follow_up(attacker, defender):
		await get_tree().create_timer(0.2).timeout
		print(attacker.name + " follows up!")
		await attacker.attack(defender)
	elif defender_countered and is_instance_valid(defender) and is_instance_valid(attacker) and _can_unit_follow_up(defender, attacker):
		await get_tree().create_timer(0.2).timeout
		print(defender.name + " follows up!")
		await defender.attack(attacker)
			
	# Give the final animation a tiny bit of time to settle before unlocking the cursor
	await get_tree().create_timer(0.2).timeout

## Generates a classic Strategy RPG preview window on the fly
## Generates a miniature, scaled-down Strategy RPG preview window


func _show_unit_hover_tooltip(unit: Unit, cell: Vector2) -> void:
	if not is_instance_valid(unit):
		_hide_unit_hover_tooltip()
		return

	if _unit_hover_tooltip == null:
		_unit_hover_tooltip = CanvasLayer.new()
		add_child(_unit_hover_tooltip)

	if _unit_hover_panel == null:
		_unit_hover_panel = PanelContainer.new()
		_unit_hover_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_unit_hover_tooltip.add_child(_unit_hover_panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_right", 6)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		_unit_hover_panel.add_child(margin)

		_unit_hover_label = RichTextLabel.new()
		_unit_hover_label.bbcode_enabled = true
		_unit_hover_label.fit_content = true
		_unit_hover_label.scroll_active = false
		_unit_hover_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_unit_hover_label.add_theme_font_size_override("normal_font_size", 10)
		margin.add_child(_unit_hover_label)

	var unit_class_name := "Unknown"
	if unit.character_data != null and unit.character_data.class_data != null:
		unit_class_name = String(unit.character_data.class_data.metadata_name)
		if unit_class_name.is_empty():
			unit_class_name = String(unit.character_data.display_name)

	var team_name := "Enemy" if unit.is_enemy else "Ally"
	var display_name := "Unit"
	if unit.character_data != null and not String(unit.character_data.display_name).is_empty():
		display_name = String(unit.character_data.display_name)

	_unit_hover_label.text = "[b]%s[/b] (%s)\nClass: %s  Lv.%d\nHP: %d/%d  STR: %d  DEF: %d" % [
		display_name,
		team_name,
		unit_class_name,
		maxi(unit.level, 1),
		unit.health,
		unit.max_health,
		unit.strength,
		unit.defense,
	]

	var tooltip_size := _unit_hover_label.get_combined_minimum_size() + Vector2(12.0, 8.0)
	_unit_hover_panel.custom_minimum_size = tooltip_size

	var screen_point: Vector2 = grid.calculate_map_position(cell)
	var target_pos: Vector2 = screen_point + Vector2(20, -40)
	var viewport_size: Vector2 = get_viewport_rect().size
	target_pos.x = clampf(target_pos.x, 8.0, max(8.0, viewport_size.x - tooltip_size.x - 8.0))
	target_pos.y = clampf(target_pos.y, 8.0, max(8.0, viewport_size.y - tooltip_size.y - 8.0))
	_unit_hover_panel.position = target_pos.round()
	_unit_hover_panel.visible = true


func _hide_unit_hover_tooltip() -> void:
	if _unit_hover_panel != null:
		_unit_hover_panel.visible = false

func _show_combat_forecast(attacker: Unit, defender: Unit) -> void:
	_hide_combat_forecast() 
	
	_forecast_ui_node = CanvasLayer.new()
	add_child(_forecast_ui_node)
	
	var panel = PanelContainer.new()
	_forecast_ui_node.add_child(panel)
	panel.position = Vector2(10, 10) # Tucked slightly tighter into the corner
	
	var margin = MarginContainer.new()
	# Halved the margins to remove the bulky borders
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	# Force the rows to sit much closer together
	vbox.add_theme_constant_override("separation", 1) 
	margin.add_child(vbox)
	
	# 1. Attacker Stats
	var atk_stats = attacker.get_combat_stats(defender)
	var title = Label.new()
	title.text = ">> " + attacker.name + " <<"
	title.add_theme_color_override("font_color", Color.AQUA)
	title.add_theme_font_size_override("font_size", 12) # Smaller font
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	vbox.add_child(_create_stat_row("HP", str(attacker.health) + "/" + str(attacker.max_health)))
	vbox.add_child(_create_stat_row("DMG", _format_forecast_damage(attacker, defender, atk_stats["damage"])))
	vbox.add_child(_create_stat_row("HIT", str(atk_stats["hit"]) + "%"))
	vbox.add_child(_create_stat_row("CRIT", str(atk_stats["crit"]) + "%"))
	
	vbox.add_child(HSeparator.new())
	
	# 2. Defender Stats
	var def_title = Label.new()
	def_title.text = ">> " + defender.name + " <<"
	def_title.add_theme_color_override("font_color", Color.ORANGE_RED)
	def_title.add_theme_font_size_override("font_size", 12) # Smaller font
	def_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(def_title)
	
	vbox.add_child(_create_stat_row("HP", str(defender.health) + "/" + str(defender.max_health)))
	
	var dist = _manhattan_distance(defender.cell, attacker.cell)
	if _is_distance_in_attack_range(dist, defender.attack_range):
		var def_stats = defender.get_combat_stats(attacker)
		vbox.add_child(_create_stat_row("DMG", _format_forecast_damage(defender, attacker, def_stats["damage"])))
		vbox.add_child(_create_stat_row("HIT", str(def_stats["hit"]) + "%"))
		vbox.add_child(_create_stat_row("CRIT", str(def_stats["crit"]) + "%"))
	else:
		var no_counter = Label.new()
		no_counter.text = "-- No Counter --"
		no_counter.add_theme_color_override("font_color", Color.GRAY)
		no_counter.add_theme_font_size_override("font_size", 10) # Smaller font
		no_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(no_counter)


## Helper function to create tightly packed, right-aligned stat rows
func _create_stat_row(stat_name: String, value: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	
	var name_lbl = Label.new()
	name_lbl.text = stat_name + ":"
	name_lbl.custom_minimum_size = Vector2(35, 0) # Squished width
	name_lbl.add_theme_font_size_override("font_size", 10) # Smaller font
	
	var val_lbl = Label.new()
	val_lbl.text = value
	val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # Pushes the numbers perfectly to the right border!
	val_lbl.add_theme_font_size_override("font_size", 10) # Smaller font
	
	hbox.add_child(name_lbl)
	hbox.add_child(val_lbl)
	return hbox


func _hide_combat_forecast() -> void:
	if _forecast_ui_node:
		_forecast_ui_node.queue_free()
		_forecast_ui_node = null


func _can_unit_attack_target(unit: Unit, target: Unit) -> bool:
	if not is_instance_valid(unit) or not is_instance_valid(target):
		return false
	if unit.health <= 0 or target.health <= 0:
		return false

	var dist = _manhattan_distance(unit.cell, target.cell)
	return _is_distance_in_attack_range(dist, unit.attack_range)


func _can_unit_follow_up(unit: Unit, target: Unit) -> bool:
	if not _can_unit_attack_target(unit, target):
		return false

	return (unit.speed - target.speed) >= FOLLOW_UP_SPEED_DIFF


func _format_forecast_damage(unit: Unit, target: Unit, base_damage: int) -> String:
	if _can_unit_follow_up(unit, target):
		return str(base_damage) + " x2"

	return str(base_damage)

## Generates a cinematic banner that sweeps across the screen
func _show_phase_banner(text: String, bg_color: Color) -> void:
	_cursor.is_active = false # Lock input while animating

	if is_instance_valid(_phase_banner_layer):
		_phase_banner_layer.queue_free()
		_phase_banner_layer = null
	
	_phase_banner_layer = CanvasLayer.new()
	_phase_banner_layer.layer = 100 # Ensure it sits above all other UI
	add_child(_phase_banner_layer)
	
	var screen_size = get_viewport_rect().size
	
	var band = ColorRect.new()
	band.color = bg_color
	band.color.a = 0.8
	band.size = Vector2(screen_size.x, 100)
	
	# Start completely off-screen to the right
	band.position = Vector2(screen_size.x, (screen_size.y / 2.0) - 50)
	_phase_banner_layer.add_child(band)
	
	var label = Label.new()
	label.text = text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	band.add_child(label)
	
	var tween = create_tween()
	var center_x = 0
	var end_x = -screen_size.x
	
	# Slide in fast
	tween.tween_property(band, "position:x", center_x, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Hold for the player to read
	tween.tween_interval(1.0)
	# Slide out fast
	tween.tween_property(band, "position:x", end_x, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tween.finished
	if is_instance_valid(_phase_banner_layer):
		_phase_banner_layer.queue_free()
		_phase_banner_layer = null

func _get_attack_offsets(attack_range: int) -> Array:
	if attack_range <= 0:
		return []

	if _attack_offsets_cache.has(attack_range):
		return _attack_offsets_cache[attack_range]

	var offsets: Array = []
	for x in range(-attack_range, attack_range + 1):
		for y in range(-attack_range, attack_range + 1):
			var distance = abs(x) + abs(y)
			if distance == attack_range:
				offsets.append(Vector2(x, y))

	_attack_offsets_cache[attack_range] = offsets
	return offsets

func _are_all_player_units_waiting() -> bool:
	for unit in _units.values():
		if not unit.is_enemy and not unit.is_wait:
			return false
	return true

func _check_win_loss() -> void:
	# 2. Stop the game from spawning multiple UI screens!
	if _battle_ended:
		return 
		
	var players_alive = false
	var enemies_alive = false
	
	# Scan the remaining units on the board
	for cell in _units:
		if _units[cell].is_enemy:
			enemies_alive = true
		else:
			players_alive = true
			
	# Trigger the stylish screen if a condition is met
	if not enemies_alive:
		_battle_ended = true
		_show_results_screen(true)
	elif not players_alive:
		_battle_ended = true
		_show_results_screen(false)


func _show_results_screen(is_victory: bool) -> void:
	_cursor.is_active = false 
	
	# 3. Fade Out Map Music! 
	# This searches the Map for the AudioStreamPlayer and tweens it to silence
	for child in get_parent().get_children():
		if child is AudioStreamPlayer and child.playing:
			var bgm_tween = create_tween()
			bgm_tween.tween_property(child, "volume_db", -80.0, 1.5)
			bgm_tween.tween_callback(child.stop)
	
	if is_instance_valid(_results_canvas):
		_results_canvas.queue_free()
	_results_return_button = null

	_results_canvas = CanvasLayer.new()
	_results_canvas.layer = 120 
	add_child(_results_canvas)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.0) 
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_results_canvas.add_child(bg)
	
	# 4. Volume Control for the Fanfare!
	var audio = AudioStreamPlayer.new()
	if is_victory:
		audio.stream = load("res://audio/Music_Victory03.wav")
	else:
		audio.stream = load("res://audio/Music_Defeat03.wav")
		
	audio.volume_db = -12.0 # Tweak this negative number to make it quieter! (-15, -20, etc.)
	_results_canvas.add_child(audio)
	audio.play()
	
	# 3. Build the Text Layout
	var vbox = VBoxContainer.new()
	
	# NEW: Forces the container to respect screen boundaries!
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT) 
	
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	_results_canvas.add_child(vbox)
	
	var title = Label.new()
	title.text = "VICTORY!" if is_victory else "DEFEAT..."
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2) if is_victory else Color(0.8, 0.2, 0.2))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var stats = Label.new()
	stats.text = "Enemies Defeated: %d\n\nLoot Acquired:\n- None (Yet)" % _enemies_defeated
	stats.add_theme_font_size_override("font_size", 16)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)
	
	# 5. A Much Bigger, Unmissable Button
	var btn = Button.new()
	btn.text = "Return to Farm"
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_size_override("font_size", 20)
	btn.custom_minimum_size = Vector2(300, 60) # Forces the button to be nice and wide
	btn.pressed.connect(_on_return_button_pressed.bind(btn))
	vbox.add_child(btn)
	_results_return_button = btn
	btn.grab_focus()
	
	vbox.modulate.a = 0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(bg, "color:a", 0.85, 1.5)
	tween.tween_property(vbox, "modulate:a", 1.0, 1.5)
	
func _on_return_button_pressed(btn: Button) -> void:
	btn.disabled = true
	_results_return_button = null

	Global.last_battle_result = {
		"victory": _are_all_players_alive(),
		"enemies_defeated": _enemies_defeated,
		"returned_at_unix": Time.get_unix_time_from_system()
	}

	if Global.tutorial_step == 14 and Global.last_battle_result.victory:
		Global.advance_tutorial()

	if Global.saved_farm_scene:
		var elapsed_seconds = Global.consume_combat_elapsed_seconds()

		# 1. Plug the farm back in
		get_tree().root.add_child(Global.saved_farm_scene)
		get_tree().current_scene = Global.saved_farm_scene
		
		# 2. WAIT ONE FRAME FOR GROUPS TO RE-REGISTER
		await get_tree().process_frame 
		
		# 3. Now it is safe to apply elapsed farm time.
		if Global.saved_farm_scene.has_method("apply_combat_time_passage"):
			Global.saved_farm_scene.apply_combat_time_passage(elapsed_seconds)
			
		Global.saved_farm_scene = null

	get_parent().queue_free()

func _are_all_players_alive() -> bool:
	for unit in _units.values():
		if not unit.is_enemy:
			return true
	return false

# ==============================================================================
# ABILITY PIPELINE
# ==============================================================================

## Routes the selected ability to its specific logic block
func execute_ability(caster: Unit, ability: AbilityData, target_cell: Vector2) -> void:
	match ability.type:
		AbilityData.AbilityType.BLOOM:
			_execute_bloom_wave(caster, target_cell, ability.radius)
		AbilityData.AbilityType.HARVEST:
			pass # We will build this next!
		_:
			print("Ability logic not implemented yet for: ", ability.ability_name)
			
	# Put it on cooldown after a successful cast
	caster.start_cooldown(ability)

## Specific logic for Tera's Bloom
func _execute_bloom_wave(caster: Unit, center_cell: Vector2, radius: int) -> void:
	var empty_cells: Array[Vector2] = []
	
	# 1. Collect valid cells using Manhattan distance
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if abs(x) + abs(y) <= radius:
				var check_cell = center_cell + Vector2(x, y)
				
				# 2. Check bounds and occupancy
				if grid.is_within_bounds(check_cell):
					# If there is no unit standing there
					if not _units.has(check_cell):
						empty_cells.append(check_cell)
	
	# 3. Randomize and Sprout
	var plants_to_spawn = randi_range(2, 4) # Spawns 2 to 4 plants
	empty_cells.shuffle()
	
	for i in range(min(plants_to_spawn, empty_cells.size())):
		_spawn_battle_plant(empty_cells[i])

## Instantiates the plant physically on the map
func _spawn_battle_plant(cell: Vector2) -> void:
	# For now, we will use your existing plant scene. We will make a custom BattlePlant next!
	var plant_scene = load("res://scenes/level/plant.tscn")
	var new_plant = plant_scene.instantiate()
	
	add_child(new_plant)
	new_plant.position = grid.calculate_map_position(cell)
	
	# Optional: A magical pop-in animation
	new_plant.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(new_plant, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BOUNCE)
