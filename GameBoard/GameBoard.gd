class_name GameBoard
extends Node2D

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
const OBSTACLE_ATLAS_ID = 2
const FOLLOW_UP_SPEED_DIFF := 4
const PauseMenu = preload("res://Menus/PauseMenu.tscn")
const ActionMenu = preload("res://Menus/ActionMenu.tscn")
const STORY_DIALOGUE_SCENE = preload("res://scenes/ui/story_dialogue_box.tscn")
const OVERLAY_SCENE = preload("res://scenes/ui/overlay.tscn")
const DORMANT_SPROUT_TEXTURE = preload("res://graphics/plants/Atlas-Props4-crops update.png")
@export var grid: Resource

const DEFAULT_BATTLE_SCENE = preload("res://scenes/battle/battle_scene.tscn")
@export var battle_scene: PackedScene = DEFAULT_BATTLE_SCENE

enum TurnPhase { PLAYER, ENEMY }
var current_phase: TurnPhase = TurnPhase.PLAYER

signal demo_first_unit_selected(unit: Unit)
signal demo_first_move_completed(unit: Unit)
signal demo_first_action_completed
signal demo_dormant_plant_discovered
signal demo_bloom_used
signal demo_healflower_harvested

var _battle_plants := {}
var _units := {}
var _enemies_defeated: int = 0
var _active_unit: Unit
var _walkable_cells := []
var _attackable_cells := []
var _movement_costs
var _prev_cell
var _prev_position
var _is_targeting_attack: bool = false
var _is_targeting_ability: bool = false
var _selected_ability: AbilityData = null
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
var _demo_battle_active := false
var _demo_first_selection_done := false
var _demo_first_move_done := false
var _demo_first_action_done := false
var _demo_bloom_prompt_shown := false
var _demo_bloom_used := false
var _demo_harvest_done := false
var _demo_story_dialogue_layer: CanvasLayer = null
var _demo_story_dialogue: Control = null
var _demo_overlay: Control = null
var _battle_camera: Camera2D = null
var _dormant_focus_sprite: Sprite2D = null
var _dormant_focus_cell := Vector2.ZERO
var _default_camera_focus := Vector2.ZERO

@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path: UnitPath = $UnitPath
@onready var _map: TileMapLayer = $Map
@onready var _cursor: Cursor = $Cursor
@onready var _cursor_camera: Camera2D = $Cursor/Camera2D

const MAX_VALUE: int = 99999

func _ready() -> void:
	_movement_costs = _map.get_movement_costs()
	_cursor.accept_pressed.connect(_on_Cursor_accept_pressed)
	_cursor.moved.connect(_on_Cursor_moved)
	_sync_scene_music_to_manager()
	
	_reinitialize()
	_setup_demo_support_nodes()

	if DemoDirector and DemoDirector.consume_pending_day_two_battle_intro():
		_demo_battle_active = true
		call_deferred("_run_demo_battle_opening")

func _sync_scene_music_to_manager() -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return

	var scene_music := scene_root.get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer
	if scene_music == null or scene_music.stream == null:
		return

	scene_music.autoplay = false
	if MusicManager and MusicManager.has_method("crossfade_to"):
		MusicManager.crossfade_to(scene_music.stream, 1.25, scene_music.volume_db)
	scene_music.stop()

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
		
		if _target_unit_for_forecast != null:
			_target_unit_for_forecast = null
			_hide_combat_forecast()
			return
			
		if _is_targeting_attack:
			_is_targeting_attack = false
			_valid_target_cells.clear()
			_unit_overlay.clear()
			_show_action_menu() 
		else:
			_reset_unit()


func _get_configuration_warning() -> String:
	var warning := ""
	if not grid:
		warning = "You need a Grid resource for this node to work."
	return warning


func is_occupied(cell: Vector2) -> bool:
	return _units.has(cell)


func get_walkable_cells(unit: Unit) -> Array:
	return _dijkstra(unit, unit.move_range, false)
	
func get_attackable_cells(walkable_cells: Array, attack_range: int, unit: Unit) -> Array:
	var attackable_dict = {}
	var walkable_dict = {}
	var attack_offsets = _get_attack_offsets(attack_range)
	
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
				if not walkable_dict.has(target_cell) and not attackable_dict.has(target_cell):

					if is_occupied(target_cell) and _units[target_cell].is_enemy == unit.is_enemy:
						continue

					attackable_dict[target_cell] = true
							
	return attackable_dict.keys()

func _reinitialize() -> void:
	_units.clear()

	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
			
		unit.cell = unit.cell.round()
		_units[unit.cell] = unit
		
		if not unit.died.is_connected(_on_unit_died):
			unit.died.connect(_on_unit_died)

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
			
			var coord_v2i = Vector2i(int(coordinates.x), int(coordinates.y))
			if _map.get_cell_source_id(coord_v2i) == OBSTACLE_ATLAS_ID:
				wall_array.append(coordinates)
			
			if coordinates in full_array:
				continue
			if coordinates in stack:
				continue

			stack.append(coordinates)
			
	return full_array.filter(func(i): return i not in wall_array)

func _dijkstra(unit: Unit, max_distance: int, _attackable_check: bool) -> Array:
	var start_cell = unit.cell.round()
	
	var distances = {}
	distances[start_cell] = 0
	
	var queue = PriorityQueue.new()
	queue.push(start_cell, 0)
	
	while not queue.is_empty():
		var current_node = queue.pop()
		var current_cell = current_node.value
		var current_dist = current_node.priority
		
		if current_dist > distances.get(current_cell, MAX_VALUE):
			continue
			
		for direction in DIRECTIONS:
			var neighbor = current_cell + direction 
			
			if not grid.is_within_bounds(neighbor):
				continue
				
			# Opposing units block movement. Allies can be moved through.
			var neighbor_unit = _units.get(neighbor)
			if neighbor_unit != null and neighbor_unit.is_enemy != unit.is_enemy:
				continue
				
			var coord_v2i = Vector2i(int(neighbor.x), int(neighbor.y))
			var tile_cost = _movement_costs.get(coord_v2i, 1) 
			var new_cost = current_dist + tile_cost 
			
			if new_cost <= max_distance:
				if new_cost < distances.get(neighbor, MAX_VALUE):
					distances[neighbor] = new_cost
					queue.push(neighbor, new_cost) 
	
	return distances.keys()

func _move_active_unit(new_cell: Vector2, show_action_menu: bool = true) -> void:
	if _unit_path._pathfinder == null:
		_unit_path.initialize(_walkable_cells)
	_unit_path.draw(_active_unit.cell, new_cell)
	
	if _unit_path.current_path.is_empty() or _unit_path.current_path[-1] != new_cell:
		return 
	
	_walkable_cells.clear()
	_attackable_cells.clear()
	_unit_overlay.clear()
	_cursor.is_active = false
	
	# Update board occupancy before the walk starts so follow-up logic sees the right state.
	_units.erase(_active_unit.cell)
	_units[new_cell] = _active_unit
	
	_active_unit.walk_along(_unit_path.current_path)
	await _active_unit.walk_finished

	if _demo_battle_active and _active_unit != null and _active_unit.name == "Savannah" and not _demo_first_move_done:
		_demo_first_move_done = true
		demo_first_move_completed.emit(_active_unit)
		if DemoDirector:
			DemoDirector.show_context_prompt("battle_choose_attack")
	
	if show_action_menu:
		_show_action_menu()
	else:
		_cursor.process_mode = Node.PROCESS_MODE_INHERIT
		_cursor.show()
		_cursor.is_active = true
	


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

	if _demo_battle_active and _active_unit.name == "Savannah" and not _demo_first_selection_done:
		_demo_first_selection_done = true
		demo_first_unit_selected.emit(_active_unit)
		if DemoDirector:
			DemoDirector.show_context_prompt("battle_move_savannah")
	
	

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

	if _demo_battle_active and _active_unit != null and _active_unit.name == "Savannah" and not _demo_first_action_done:
		_complete_demo_first_action()

func _hover_display(cell: Vector2) -> void:
	if is_occupied(cell):
		var curr_unit = _units[cell]
		
		_walkable_cells = get_walkable_cells(curr_unit)
		_attackable_cells = get_attackable_cells(_walkable_cells, curr_unit.attack_range, curr_unit)
		_unit_overlay.clear() 
		_unit_overlay.draw_attackable_cells(_attackable_cells)
		_unit_overlay.draw_walkable_cells(_walkable_cells)


func _show_pause_menu() -> void:
	if has_node("PauseMenu"):
		return
		
	_hide_unit_hover_tooltip()
	var pause_menu = PauseMenu.instantiate()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	if pause_menu.has_method("_set_units"):
		pause_menu.call("_set_units", _units.values())
	if pause_menu.has_method("_reset_menu_focus"):
		pause_menu.call_deferred("_reset_menu_focus")


func _reset_unit() -> void:
	if has_node("ActionMenu"):
		$ActionMenu.queue_free()

	if _active_unit != null:
		if _active_unit.cell != _prev_cell:
			_active_unit.position = _prev_position
			_units.erase(_active_unit.cell)
			_units[_prev_cell] = _active_unit
			_active_unit.cell = _prev_cell
			
		_prev_cell = null
		_prev_position = null
		
		_deselect_active_unit()
		
	_cursor.process_mode = Node.PROCESS_MODE_INHERIT
	_cursor.show()
	_cursor.is_active = true


func _is_distance_in_attack_range(distance: int, attack_range: int) -> bool:
	return CombatCalculator.can_attack_at_distance(distance, attack_range)
		
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


func _on_Cursor_accept_pressed(cell: Vector2) -> void:
	if _battle_ended:
		return

	if _demo_battle_active and not _demo_first_selection_done:
		var savannah := get_node_or_null("Savannah") as Unit
		if savannah != null and cell != savannah.cell:
			if DemoDirector:
				DemoDirector.show_context_prompt("battle_select_savannah")
			return

	if _target_unit_for_forecast != null:
		var target = _target_unit_for_forecast
		_target_unit_for_forecast = null
		_hide_combat_forecast()
		
		_cursor.is_active = false 
		
		var combat_completed := await execute_combat(_active_unit, target)
		if not combat_completed:
			return
		
		_is_targeting_attack = false
		_valid_target_cells.clear()
		
		if is_instance_valid(_active_unit) and _active_unit.health > 0:
			finish_unit_turn()
		else:
			_deselect_active_unit()
			_cursor.is_active = true
		return

	if _is_targeting_attack:
		if cell in _valid_target_cells and is_occupied(cell):
			var target_unit = _units[cell]
			if target_unit.is_enemy != _active_unit.is_enemy:
				_begin_attack_preview_on_target(target_unit)
		return
		
	if _is_targeting_ability:
		if cell in _valid_target_cells:
			var success = execute_ability(_active_unit, _selected_ability, cell)
			
			if success:
				_is_targeting_ability = false
				_selected_ability = null
				_valid_target_cells.clear()
				_unit_overlay.clear()
				_cursor.is_active = false
				finish_unit_turn() 
		return
		
	if not _active_unit and _units.has(cell):
		var unit = _units[cell]
		
		if unit.is_enemy:
			return 
		
		if unit.is_wait:
			_show_pause_menu()
		else:
			_select_unit(cell)
			
	elif _active_unit != null: 
		if _demo_battle_active and _active_unit.name == "Savannah" and _demo_first_selection_done and not _demo_first_move_done and cell == _active_unit.cell:
			if DemoDirector:
				DemoDirector.show_context_prompt("battle_move_savannah")
			return

		if is_occupied(cell) and _units[cell] == _active_unit:
			_unit_overlay.clear()
			_unit_path.stop()
			_show_action_menu()
			
		elif is_occupied(cell):
			var target_unit = _units[cell]
			if target_unit.is_enemy != _active_unit.is_enemy:
				var attack_from_cell = _find_attack_origin_for_target(cell)
				if attack_from_cell != null:
					if attack_from_cell != _active_unit.cell:
						await _move_active_unit(attack_from_cell, false)
					_begin_attack_preview_on_target(target_unit)

		elif not is_occupied(cell) and _walkable_cells.has(cell):
			await _move_active_unit(cell) 
	else:
		_show_pause_menu()


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

		if _units.has(new_cell) and not _units[new_cell].is_wait:
			_hover_display(new_cell)
		else:
			_unit_overlay.clear()
			_walkable_cells.clear()
		
func _on_unit_died(unit: Unit) -> void:
	# Death cleanup can be triggered more than once during combat resolution.
	if not _units.has(unit.cell):
		return
		
	_units.erase(unit.cell)
	if _target_unit_for_forecast == unit:
		_target_unit_for_forecast = null
		_hide_combat_forecast()
	
	if _active_unit == unit:
		_deselect_active_unit()
		
	if unit.is_enemy:
		_enemies_defeated += 1
		
	_check_win_loss()
	
func _show_action_menu() -> void:
	if has_node("ActionMenu"):
		$ActionMenu.queue_free()

	var action_menu = ActionMenu.instantiate()
	action_menu.name = "ActionMenu"
	add_child(action_menu)
		
	action_menu.show()
	if action_menu.has_method("_reset_menu_focus"):
		action_menu.call_deferred("_reset_menu_focus")
	
	_cursor.is_active = false


## To be called by the Action Menu when the player chooses "Wait"
func finish_unit_turn() -> void:
	if _battle_ended:
		return

	if _demo_battle_active and _active_unit != null and _active_unit.name == "Savannah" and _demo_first_move_done and not _demo_first_action_done:
		_complete_demo_first_action()

	if _active_unit:
		var visuals = _active_unit.get_node_or_null("PathFollow2D/Visuals")
		if visuals:
			visuals.modulate = Color(0.5, 0.5, 0.5, 1.0) # Grey out
		
		_active_unit.is_wait = true
		
	if has_node("ActionMenu"):
		$ActionMenu.queue_free()
		
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
				var combat_completed := await execute_combat(enemy, target_player)
				if not combat_completed:
					return
				
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
			unit.tick_cooldowns()
			var visuals = unit.get_node_or_null("PathFollow2D/Visuals")
			if visuals:
				visuals.modulate = Color.WHITE 

	if _demo_battle_active and _demo_first_action_done and not _demo_bloom_prompt_shown:
		await _present_demo_bloom_prompt()

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

func enter_ability_targeting(ability: AbilityData) -> void:
	_is_targeting_ability = true
	_selected_ability = ability
	_valid_target_cells.clear()
	_unit_overlay.clear()
	
	var center_cell = _active_unit.cell
	
	# Calculate cast range from where the unit is currently standing
	if ability.range == 0:
		# Self-cast only (Like Bloom, they must click themselves)
		_valid_target_cells.append(center_cell)
	else:
		# Ranged cast (Creates a diamond based on ability.range)
		var ability_offsets = _get_attack_offsets(ability.range)
		for offset in ability_offsets:
			var target_cell = center_cell + offset
			if grid.is_within_bounds(target_cell):
				_valid_target_cells.append(target_cell)
					
	# Draw the red tiles to show where the player can click
	_unit_overlay.draw_attackable_cells(_valid_target_cells)
	
	# Wake the cursor back up so the player can pick a target
	_cursor.is_active = true
	
## Orchestrates the turn-based combat sequence between two units
func execute_combat(attacker: Unit, defender: Unit) -> bool:
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return false

	var combat_scene := battle_scene if battle_scene != null else DEFAULT_BATTLE_SCENE
	if combat_scene == null:
		push_error("GameBoard: No battle scene assigned for execute_combat.")
		return false

	# 1. Calculate the context
	var distance := int(abs(attacker.cell.x - defender.cell.x) + abs(attacker.cell.y - defender.cell.y))
	var terrain_modifier := 0 # We can hook this up to your tilemap data later!
	
	# 1. Pack the briefcase FIRST
	var payload := CombatManager.setup_combat(attacker, defender, terrain_modifier, distance)
	
	if payload == null:
		push_error("GameBoard: Failed to build combat payload. Aborting combat transition.")
		return false
	
	# 2. Ask the Calculator to roll the dice and write the combat script!
	var strikes := CombatCalculator.resolve_combat(attacker, defender, distance)
	payload.strikes = strikes

	# 3. Clean up the map UI so it isn't stuck open when we return
	_target_unit_for_forecast = null
	_is_targeting_attack = false
	_valid_target_cells.clear()
	if _unit_overlay:
		_unit_overlay.clear()
	if _cursor:
		_cursor.is_active = false
	if has_node("ActionMenu"):
		$ActionMenu.hide()

	# 1. Open the arena as an overlay!
	TransitionManager.open_overlay(combat_scene, 0.5) 
	
	# 2. Wait for the battle to finish
	await TransitionManager.overlay_closed
	
	# --- 3. APPLY THE ACTUAL COMBAT RESULTS ---
	# Iterate through the script and let the Unit script handle the exact damage!
	for strike in payload.strikes:
		if strike.is_attacker_striking:
			if is_instance_valid(defender):
				defender.apply_battle_result_damage(strike.damage_dealt)
		else:
			if is_instance_valid(attacker):
				attacker.apply_battle_result_damage(strike.damage_dealt)

	# (The manual queue_free / die() checks are DELETED here because 
	# apply_battle_result_damage() already handles death natively!)
			
			# The battle is fully resolved, hand control back to the caller!
	return true

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
		_unit_hover_panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.08, 0.1, 0.12, 0.94)
		hover_style.border_width_left = 2
		hover_style.border_width_top = 2
		hover_style.border_width_right = 2
		hover_style.border_width_bottom = 2
		hover_style.border_color = Color(0.95, 0.83, 0.45, 0.95)
		hover_style.corner_radius_top_left = 8
		hover_style.corner_radius_top_right = 8
		hover_style.corner_radius_bottom_right = 8
		hover_style.corner_radius_bottom_left = 8
		_unit_hover_panel.add_theme_stylebox_override("panel", hover_style)
		_unit_hover_tooltip.add_child(_unit_hover_panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		_unit_hover_panel.add_child(margin)

		_unit_hover_label = RichTextLabel.new()
		_unit_hover_label.bbcode_enabled = true
		_unit_hover_label.fit_content = true
		_unit_hover_label.scroll_active = false
		_unit_hover_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_unit_hover_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_unit_hover_label.add_theme_font_size_override("normal_font_size", 26)
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

	var tooltip_size := _unit_hover_label.get_combined_minimum_size() + Vector2(24.0, 18.0)
	_unit_hover_panel.custom_minimum_size = tooltip_size

	var screen_point: Vector2 = grid.calculate_map_position(cell)
	var target_pos: Vector2 = screen_point + Vector2(28, -52)
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
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var forecast_style := StyleBoxFlat.new()
	forecast_style.bg_color = Color(0.05, 0.06, 0.09, 0.93)
	forecast_style.border_width_left = 2
	forecast_style.border_width_top = 2
	forecast_style.border_width_right = 2
	forecast_style.border_width_bottom = 2
	forecast_style.border_color = Color(0.82, 0.88, 0.97, 0.92)
	forecast_style.corner_radius_top_left = 10
	forecast_style.corner_radius_top_right = 10
	forecast_style.corner_radius_bottom_right = 10
	forecast_style.corner_radius_bottom_left = 10
	panel.add_theme_stylebox_override("panel", forecast_style)
	_forecast_ui_node.add_child(panel)
	panel.position = Vector2(24, 20)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	
	var dist = _manhattan_distance(defender.cell, attacker.cell)
	var forecast = CombatCalculator.get_combat_forecast(attacker, defender, dist)

	# 1. Attacker Stats
	var title = Label.new()
	title.text = ">> " + attacker.name + " <<"
	title.add_theme_color_override("font_color", Color.AQUA)
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	vbox.add_child(_create_stat_row("HP", str(attacker.health) + "/" + str(attacker.max_health)))
	vbox.add_child(_create_stat_row("DMG", _format_forecast_damage(forecast.attacker_damage, forecast.attacker_can_double)))
	vbox.add_child(_create_stat_row("HIT", str(forecast.attacker_hit_chance) + "%"))
	vbox.add_child(_create_stat_row("CRIT", str(forecast.attacker_crit_chance) + "%"))
	
	vbox.add_child(HSeparator.new())
	
	# 2. Defender Stats
	var def_title = Label.new()
	def_title.text = ">> " + defender.name + " <<"
	def_title.add_theme_color_override("font_color", Color.ORANGE_RED)
	def_title.add_theme_font_size_override("font_size", 30)
	def_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(def_title)
	
	vbox.add_child(_create_stat_row("HP", str(defender.health) + "/" + str(defender.max_health)))
	
	if forecast.defender_can_counter:
		vbox.add_child(_create_stat_row("DMG", _format_forecast_damage(forecast.defender_damage, forecast.defender_can_double)))
		vbox.add_child(_create_stat_row("HIT", str(forecast.defender_hit_chance) + "%"))
		vbox.add_child(_create_stat_row("CRIT", str(forecast.defender_crit_chance) + "%"))
	else:
		var no_counter = Label.new()
		no_counter.text = "-- No Counter --"
		no_counter.add_theme_color_override("font_color", Color.GRAY)
		no_counter.add_theme_font_size_override("font_size", 24)
		no_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(no_counter)


## Helper function to create tightly packed, right-aligned stat rows
func _create_stat_row(stat_name: String, value: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	
	var name_lbl = Label.new()
	name_lbl.text = stat_name + ":"
	name_lbl.custom_minimum_size = Vector2(96, 0)
	name_lbl.add_theme_font_size_override("font_size", 24)
	
	var val_lbl = Label.new()
	val_lbl.text = value
	val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # Pushes the numbers perfectly to the right border!
	val_lbl.add_theme_font_size_override("font_size", 24)
	
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


func _format_forecast_damage(base_damage: int, can_double: bool) -> String:
	if can_double:
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
	label.add_theme_font_size_override("font_size", 96)
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
	
	if MusicManager and MusicManager.has_method("fade_to_silence"):
		MusicManager.fade_to_silence(1.5)
	
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
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2) if is_victory else Color(0.8, 0.2, 0.2))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var stats = Label.new()
	stats.text = "Enemies Defeated: %d\n\nLoot Acquired:\n- None (Yet)" % _enemies_defeated
	stats.add_theme_font_size_override("font_size", 38)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)
	
	# 5. A Much Bigger, Unmissable Button
	var btn = Button.new()
	btn.text = "Return to Farm"
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_size_override("font_size", 40)
	btn.custom_minimum_size = Vector2(540, 104)
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

	var is_victory = _are_all_players_alive()
	Global.last_battle_result = {
		"victory": is_victory,
		"enemies_defeated": _enemies_defeated,
		"returned_at_unix": Time.get_unix_time_from_system()
	}

	if Global.tutorial_step == 14 and is_victory:
		Global.advance_tutorial()

	if Global.saved_farm_scene:
		var elapsed_seconds = Global.consume_combat_elapsed_seconds()
		var farm = Global.saved_farm_scene

		# 1. Plug the farm back in
		get_tree().root.add_child(farm)
		get_tree().current_scene = farm
		
		# 2. WAIT ONE FRAME FOR GROUPS TO RE-REGISTER
		await get_tree().process_frame 
		
		var color_rect = farm.get_node_or_null("CanvasLayer/ColorRect")
		var hud = farm.get_node_or_null("CanvasLayer/DayTimeHUD")
		if farm.has_method("resume_after_combat"):
			farm.resume_after_combat()
		
		if is_victory:
			# ==========================================
			# --- THE VICTORY PATH (Late Afternoon) ---
			# ==========================================
			if Global.current_day == 3 and Global.learn_recipe(Global.Items.MORNING_COFFEE):
				print("Unlocked Morning Coffee recipe from combat!")

			if color_rect:
				var tween = farm.create_tween()
				tween.tween_property(color_rect, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
				
			if farm.has_method("apply_combat_time_passage"):
				farm.apply_combat_time_passage(elapsed_seconds)
				
		else:
			# ==========================================
			# --- THE DEFEAT PATH (The Coma) ---
			# ==========================================
			# 1. The Penalty: They were unconscious for a full day!
			Global.current_day += 1
			
			# 2. Force a massive night cycle to grow crops and reset clock to 6:00 AM
			if farm.has_method("level_reset"):
				farm.level_reset()
				
			# 3. Force the UI to reflect the missed day instantly behind the dark screen
			if hud and hud.has_method("_update_view"):
				hud._update_view(true)
				
			# 4. Slowly wake up (Longer fade from black to simulate grogginess)
			if color_rect:
				color_rect.modulate.a = 1.0 # Ensure it starts pitch black
				var tween = farm.create_tween()
				tween.tween_interval(2.0) # Stay in the dark for 2 seconds to let the music linger
				tween.tween_property(color_rect, "modulate:a", 0.0, 4.0).set_trans(Tween.TRANS_SINE)

		Global.saved_farm_scene = null

		if is_victory and DemoDirector and _demo_battle_active:
			await get_tree().process_frame
			var card_parent: Node = farm.get_node_or_null("CanvasLayer")
			if card_parent == null:
				card_parent = farm
			DemoDirector.show_demo_complete_card(card_parent)

	get_parent().queue_free()

func _are_all_players_alive() -> bool:
	for unit in _units.values():
		if not unit.is_enemy:
			return true
	return false

# ==============================================================================
# ABILITY PIPELINE
# ==============================================================================

func execute_ability(caster: Unit, ability: AbilityData, target_cell: Vector2) -> bool:
	var dist = abs(caster.cell.x - target_cell.x) + abs(caster.cell.y - target_cell.y)
	if dist > ability.range:
		return false

	var success: bool = false
	
	match ability.type:
		AbilityData.AbilityType.BLOOM:
			success = _execute_bloom_wave(caster, target_cell, ability.radius)
		AbilityData.AbilityType.HARVEST:
			success = _execute_harvest(caster, target_cell)
			
	if success:
		caster.start_cooldown(ability)
		
	return success

func _execute_bloom_wave(_caster: Unit, center_cell: Vector2, radius: int) -> bool:
	var empty_cells: Array[Vector2] = []
	
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if abs(x) + abs(y) <= radius:
				var check_cell = center_cell + Vector2(x, y)
				if grid.is_within_bounds(check_cell):
					if not _units.has(check_cell) and not is_occupied(check_cell):
						empty_cells.append(check_cell)
	
	if empty_cells.is_empty():
		return false
	
	var wave = BloomWaveEffect.new()
	add_child(wave)
	wave.position = grid.calculate_map_position(center_cell)
	# Calculate how big the wave should get based on grid size!
	wave.max_radius = radius * grid.cell_size.x 
	
	var plants_to_spawn = randi_range(2, 4)
	empty_cells.shuffle()

	var chosen_cells: Array[Vector2] = []
	if _demo_battle_active and not _demo_bloom_used:
		var savannah := get_node_or_null("Savannah") as Unit
		if savannah != null:
			for direction in DIRECTIONS:
				var preferred_cell: Vector2 = savannah.cell + direction
				if preferred_cell in empty_cells and preferred_cell not in chosen_cells:
					chosen_cells.append(preferred_cell)
					break

	for candidate in empty_cells:
		if chosen_cells.size() >= min(plants_to_spawn, empty_cells.size()):
			break
		if candidate not in chosen_cells:
			chosen_cells.append(candidate)

	for i in range(chosen_cells.size()):
		_spawn_battle_plant(chosen_cells[i], i)

	if _demo_battle_active and not _demo_bloom_used:
		_demo_bloom_used = true
		demo_bloom_used.emit()
		if DemoDirector:
			DemoDirector.set_stage(DemoDirector.DemoStage.BLOOM_TUTORIAL)
			DemoDirector.show_context_prompt("battle_harvest_healflower")
		
	return true

func _spawn_battle_plant(cell: Vector2, spawn_index: int = 0) -> void:
	var plant_scene = load("res://scenes/level/plant.tscn")
	var new_plant = plant_scene.instantiate()
	
	add_child(new_plant)
	new_plant.position = grid.calculate_map_position(cell) + Vector2(0, -16)
	
	_battle_plants[cell] = new_plant
	
	# --- THE ELEGANT BLOOM ANIMATION ---
	new_plant.scale = Vector2.ZERO # Start invisible
	
	var tween = create_tween()
	# 1. Stagger the animation: wait 0.15 seconds per plant
	tween.tween_interval(spawn_index * 0.15) 
	
	# 2. Pop up slightly larger than normal (1.3x) with a smooth spring effect
	tween.tween_property(new_plant, "scale", Vector2(1.3, 1.3), 0.3)\
		.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		
	# 3. Softly settle back down to normal size (1.0x)
	tween.tween_property(new_plant, "scale", Vector2(1.0, 1.0), 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
## Consumes a plant on the grid and heals the caster
func _execute_harvest(caster: Unit, target_cell: Vector2) -> bool:
	if not _battle_plants.has(target_cell):
		print("No plant found on that tile!")
		return false # Failed cast!
		
	var plant = _battle_plants[target_cell]
	
	# 1. The Healing Math
	var heal_amount = 10
	var actual_healed := caster.heal(heal_amount)
	if actual_healed <= 0:
		print(caster.name, " could not be healed.")
		return false
		
	# 2. Visual Cleanup
	_battle_plants.erase(target_cell) # Remove from memory
	
	# Shrink it away smoothly
	var tween = create_tween()
	tween.tween_property(plant, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(plant.queue_free) # Delete the node
	
	print(caster.name, " harvested a plant and healed for ", actual_healed, " HP!")
	if _demo_battle_active and not _demo_harvest_done:
		_demo_harvest_done = true
		demo_healflower_harvested.emit()
		if DemoDirector:
			DemoDirector.show_context_prompt("battle_defeat_enemies")
	return true

func _setup_demo_support_nodes() -> void:
	if DemoDirector == null or not DemoDirector.is_demo_active():
		return

	if get_parent() != null and get_parent().get_node_or_null("DemoOverlay") == null:
		_demo_overlay = OVERLAY_SCENE.instantiate()
		_demo_overlay.name = "DemoOverlay"
		get_parent().add_child(_demo_overlay)

	if _battle_camera == null:
		_battle_camera = Camera2D.new()
		_battle_camera.name = "BattleCamera"
		if _cursor_camera != null:
			_battle_camera.zoom = _cursor_camera.zoom
			_battle_camera.limit_left = _cursor_camera.limit_left
			_battle_camera.limit_top = _cursor_camera.limit_top
			_battle_camera.limit_right = _cursor_camera.limit_right
			_battle_camera.limit_bottom = _cursor_camera.limit_bottom
			_battle_camera.limit_smoothed = _cursor_camera.limit_smoothed
			_battle_camera.drag_horizontal_enabled = false
			_battle_camera.drag_vertical_enabled = false
			_battle_camera.position_smoothing_enabled = _cursor_camera.position_smoothing_enabled
			_battle_camera.position_smoothing_speed = _cursor_camera.position_smoothing_speed
		else:
			_battle_camera.position_smoothing_enabled = true
			_battle_camera.position_smoothing_speed = 8.0
		add_child(_battle_camera)

	_default_camera_focus = _compute_default_camera_focus()
	var camera_start := _default_camera_focus
	if _cursor_camera != null:
		camera_start = _cursor_camera.get_screen_center_position()
	_battle_camera.global_position = camera_start
	_battle_camera.make_current()

func _run_demo_battle_opening() -> void:
	_cursor.is_active = false
	current_phase = TurnPhase.PLAYER
	_hide_unit_hover_tooltip()
	_spawn_dormant_focus_sprite()

	await get_tree().create_timer(0.12).timeout
	var focus_target := _default_camera_focus
	if _dormant_focus_sprite != null and is_instance_valid(_dormant_focus_sprite):
		focus_target = _dormant_focus_sprite.global_position
	await _focus_battle_camera(focus_target, 0.45)
	await _pulse_dormant_focus_sprite()
	demo_dormant_plant_discovered.emit()

	await _play_demo_story_dialogue([
		{"speaker": "Tera", "text": "Wait... do you feel that? Under the ash... there's a heartbeat."},
		{"speaker": "Savannah", "text": "Something alive?"}, 
		{"speaker": "Tera", "text": "Dormant roots. If I can wake them, they might keep us standing."}
	])

	await _focus_battle_camera(_default_camera_focus, 0.4)
	await _show_phase_banner("PLAYER PHASE", Color(0.1, 0.4, 0.8))
	if DemoDirector:
		DemoDirector.set_stage(DemoDirector.DemoStage.BATTLE_TUTORIAL)
		DemoDirector.show_context_prompt("battle_select_savannah")
	if _cursor_camera != null:
		_cursor_camera.reset_smoothing()
		_cursor_camera.make_current()
	_cursor.is_active = true

func _compute_default_camera_focus() -> Vector2:
	var focus_points: Array[Vector2] = []
	for child in get_children():
		if child is Unit:
			focus_points.append((child as Unit).global_position)

	if focus_points.is_empty():
		return global_position

	var midpoint := Vector2.ZERO
	for point in focus_points:
		midpoint += point
	return midpoint / float(focus_points.size())

func _spawn_dormant_focus_sprite() -> void:
	if _dormant_focus_sprite != null and is_instance_valid(_dormant_focus_sprite):
		return

	var tera := get_node_or_null("Tera") as Unit
	if tera == null:
		return

	_dormant_focus_cell = tera.cell + Vector2(1, -1)
	if not grid.is_within_bounds(_dormant_focus_cell):
		_dormant_focus_cell = tera.cell + Vector2(1, 0)
	if not grid.is_within_bounds(_dormant_focus_cell):
		_dormant_focus_cell = tera.cell

	_dormant_focus_sprite = Sprite2D.new()
	_dormant_focus_sprite.texture = DORMANT_SPROUT_TEXTURE
	_dormant_focus_sprite.hframes = 34
	_dormant_focus_sprite.vframes = 18
	_dormant_focus_sprite.frame_coords = Vector2i(13, 8)
	_dormant_focus_sprite.position = grid.calculate_map_position(_dormant_focus_cell) + Vector2(0.0, -16.0)
	_dormant_focus_sprite.modulate = Color(0.64, 0.64, 0.64, 0.95)
	add_child(_dormant_focus_sprite)

func _pulse_dormant_focus_sprite() -> void:
	if _dormant_focus_sprite == null or not is_instance_valid(_dormant_focus_sprite):
		return

	var tween := create_tween()
	tween.tween_property(_dormant_focus_sprite, "scale", Vector2(1.16, 1.16), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_dormant_focus_sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _focus_battle_camera(target_position: Vector2, duration: float) -> void:
	if _battle_camera == null:
		return

	var tween := create_tween()
	tween.tween_property(_battle_camera, "global_position", target_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _ensure_demo_story_dialogue() -> Control:
	if _demo_story_dialogue != null and is_instance_valid(_demo_story_dialogue):
		return _demo_story_dialogue

	_demo_story_dialogue_layer = CanvasLayer.new()
	_demo_story_dialogue_layer.layer = 110
	add_child(_demo_story_dialogue_layer)
	_demo_story_dialogue = STORY_DIALOGUE_SCENE.instantiate()
	_demo_story_dialogue_layer.add_child(_demo_story_dialogue)
	return _demo_story_dialogue

func _play_demo_story_dialogue(lines: Array[Dictionary]) -> void:
	var dialogue_box := _ensure_demo_story_dialogue()
	dialogue_box.play(lines)
	await dialogue_box.dialogue_finished

func _complete_demo_first_action() -> void:
	_demo_first_action_done = true
	demo_first_action_completed.emit()
	if DemoDirector:
		DemoDirector.show_context_prompt("battle_defeat_enemies")

func _present_demo_bloom_prompt() -> void:
	if _demo_bloom_prompt_shown:
		return

	_demo_bloom_prompt_shown = true
	if _demo_bloom_used:
		if DemoDirector and not _demo_harvest_done:
			DemoDirector.set_stage(DemoDirector.DemoStage.BLOOM_TUTORIAL)
			DemoDirector.show_context_prompt("battle_harvest_healflower")
		return

	var savannah := get_node_or_null("Savannah") as Unit
	if savannah != null and savannah.health < savannah.max_health:
		await _play_demo_story_dialogue([
			{"speaker": "Tera", "text": "Savannah, hold on. The roots are still there."},
			{"speaker": "Tera", "text": "Give me a second and I can pull something living through the ash."}
		])
	else:
		await _play_demo_story_dialogue([
			{"speaker": "Tera", "text": "The roots are still there. If one of us gets hurt, I can force them through."}
		])

	if DemoDirector:
		DemoDirector.set_stage(DemoDirector.DemoStage.BLOOM_TUTORIAL)
		DemoDirector.show_context_prompt("battle_choose_bloom")
