extends Node2D

const TILE_SIZE = 32
const INTRO_ENTRY_PLAYER_POS := Vector2(1036, 1610)
const INTRO_ENTRY_PLAYER_STOP := Vector2(1036, 1492)
const INTRO_ENTRY_TERA_POS := Vector2(1100, 1610)
const INTRO_ENTRY_TERA_STOP := Vector2(1136, 1492)
const INTRO_TERA_WANDER_POS := Vector2(1208, 1416)
const INTRO_TERA_FIELD_POS := Vector2(1276, 720)
const INTRO_CHEST_APPROACH_POS := Vector2(1264, 782)
const INTRO_FOREST_RETURN_POS := Vector2(1108, 1408)
const INTRO_FOREST_TERA_POS := Vector2(1156, 1404)
const INTRO_FOREST_SILAS_POS := Vector2(1278, 1392)
const INTRO_MORNING_PLAYER_POS := Vector2(1452, 700)
const INTRO_MORNING_TERA_POS := Vector2(1512, 700)
const INTRO_MORNING_SILAS_POS := Vector2(1332, 742)
const INTRO_CAMP_TERA_POS := Vector2(1512, 662)
const INTRO_CAMP_SILAS_POS := Vector2(1608, 662)

enum IntroState {
	INACTIVE,
	FIND_TERA,
	OPEN_CHEST,
	SEARCH_FOREST,
	PLANT_AND_WATER,
	MAGIC_REVEAL,
	MORNING_REVEAL,
	COMPLETE
}

@onready var player = $Objects/Player
@onready var tera_actor = $Objects/TeraActor
@onready var silas_actor = $Objects/SilasActor
@onready var story_dialogue = $CanvasLayer/StoryDialogueBox
@onready var story_chest = $Objects/Chest

var plant_scene: PackedScene = preload("res://scenes/level/plant.tscn")
@export var daytime_gradient: Gradient

@onready var tillable_layer = $World/Tillable
@onready var soil_layer = $SoilLayer
@onready var water_layer = $SoilWaterLayer

var pending_plant_pos: Vector2
var _day_timer_cycle_seconds := 0.0
var _grow_timer_cycle_seconds := 0.0
var _warning_ui_scene: PackedScene = preload("res://scenes/ui/warning_ui.tscn")
var _intro_state := IntroState.INACTIVE
var _intro_busy := false
var _forest_encounter_started := false
var _story_plants: Array[StaticBody2D] = []
var _story_seed_types_planted: Array[int] = []

func _ready() -> void:
	player.toggle_menu_requested.connect(_on_player_menu_requested)
	$CanvasLayer/SeedMenu.seed_chosen.connect(_on_seed_chosen_from_menu)
	$CanvasLayer/SeedMenu.menu_cancelled.connect(_on_seed_menu_cancelled)

	_day_timer_cycle_seconds = $DayTimer.wait_time
	_grow_timer_cycle_seconds = $GrowTimer.wait_time

	if story_chest and story_chest.has_signal("opened"):
		story_chest.opened.connect(_on_story_chest_opened)

	if Global.intro_sequence_complete:
		_setup_story_camp_state()
	else:
		call_deferred("_begin_intro_sequence")

func apply_combat_time_passage(elapsed_seconds: float) -> void:
	var day_timer = $DayTimer
	var grow_timer = $GrowTimer

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

	var remainder_grow = simulated_seconds - (ticks_to_simulate * grow_interval)
	var new_grow_time = grow_time_left - remainder_grow
	if new_grow_time <= 0:
		new_grow_time += grow_interval
	grow_timer.start(max(new_grow_time, 0.01))
	grow_timer.wait_time = _grow_timer_cycle_seconds

	var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
	if hud and hud.has_method("_update_view"):
		hud._update_view(true)

func _on_seed_menu_cancelled() -> void:
	player.can_move = true

func _process(_delta: float) -> void:
	var daytime_point: float = 1.0 - ($DayTimer.time_left / _day_timer_cycle_seconds)
	$CanvasModulate.color = daytime_gradient.sample(daytime_point)

	_process_intro_progress()

	if Global.intro_sequence_complete and Input.is_action_just_pressed("time_skip"):
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
			if _intro_state == IntroState.PLANT_AND_WATER:
				_check_intro_water_state()

	if tool == Global.Tools.AXE:
		for tree in get_tree().get_nodes_in_group("Trees"):
			var trunk_pos = tree.global_position + Vector2(0, -77)
			if trunk_pos.distance_squared_to(global_pos) < 2025:
				tree.hit()
				break

func _on_player_menu_requested(target_pos: Vector2) -> void:
	var adjusted_pos = target_pos + Vector2(0, 24)
	var local_pos = soil_layer.to_local(adjusted_pos)
	var grid_pos = soil_layer.local_to_map(local_pos)

	if soil_layer.get_cell_source_id(grid_pos) != -1:
		for plant in get_tree().get_nodes_in_group("Plants"):
			if plant.grid_pos == grid_pos:
				return

		player.can_move = false
		pending_plant_pos = adjusted_pos

		var screen_pos = player.get_global_transform_with_canvas().origin
		$CanvasLayer/SeedMenu.open(screen_pos)
	else:
		print("You can only plant on tilled soil!")

func _on_seed_chosen_from_menu(seed_type: int) -> void:
	player.can_move = true

	var planted_plant := _on_player_seed_use(seed_type, pending_plant_pos)
	if planted_plant == null:
		return

	if Global.tutorial_step == 5:
		Global.advance_tutorial()
	Global.inventory[seed_type] -= 1
	Global.inventory_updated.emit()
	_register_intro_plant(seed_type, planted_plant)

func _on_player_seed_use(seed_enum: int, global_pos: Vector2) -> StaticBody2D:
	var season := CalendarService.get_current_season()
	if not Global.is_seed_in_season(seed_enum, season):
		print("%s cannot be planted during %s." % [Global.Items.keys()[seed_enum], String(season).capitalize()])
		return null

	var local_pos = soil_layer.to_local(global_pos)
	var grid_pos = soil_layer.local_to_map(local_pos)

	for plant in get_tree().get_nodes_in_group("Plants"):
		if plant.grid_pos == grid_pos:
			print("Tile is occupied")
			return null

	if soil_layer.get_cell_source_id(grid_pos) == -1:
		return null

	var plant_pos = soil_layer.map_to_local(grid_pos)
	plant_pos.y -= 8
	var plant = plant_scene.instantiate() as StaticBody2D
	plant.setup(seed_enum, grid_pos)
	$Objects.add_child(plant)
	plant.position = plant_pos
	return plant

func request_end_day() -> void:
	if Global.pending_day_transition:
		return
	Global.pending_day_transition = true

	var tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, "modulate:a", 1.0, 1.0)
	tween.tween_callback(_process_night_transition)

func _process_night_transition() -> void:
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
		tween.tween_property($CanvasLayer/ColorRect, "modulate:a", 0.0, 1.0)
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

func level_reset() -> void:
	var remaining_time = $DayTimer.time_left
	var tick_duration = _grow_timer_cycle_seconds
	var ticks_to_simulate = int(ceil(remaining_time / tick_duration))

	for _i in range(ticks_to_simulate):
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
	for plant in get_tree().get_nodes_in_group("Plants"):
		var is_watered = water_layer.get_cell_source_id(plant.grid_pos) != -1
		plant.grow(is_watered)

func _begin_intro_sequence() -> void:
	_intro_busy = true
	Global.tutorial_enabled = false
	Global.show_tutorial_text("")
	player.can_move = false
	player.direction = Vector2.ZERO
	player.global_position = INTRO_ENTRY_PLAYER_POS
	tera_actor.visible = true
	tera_actor.global_position = INTRO_ENTRY_TERA_POS
	silas_actor.visible = false

	await _move_node(player, INTRO_ENTRY_PLAYER_STOP, 1.4)
	await _move_node(tera_actor, INTRO_ENTRY_TERA_STOP, 1.4)
	await _play_story_dialogue([
		{"speaker": "Savannah", "text": "We made it out... somehow."},
		{"speaker": "Tera", "text": "Yeah. But where exactly did we end up?"},
		{"speaker": "Savannah", "text": "I don't know yet. Stay close."},
		{"speaker": "Tera", "text": "I will. Mostly."}
	])
	await _move_node(tera_actor, INTRO_TERA_WANDER_POS, 0.7)
	await _play_story_dialogue([
		{"speaker": "Tera", "text": "Wait. Savannah... I see something."}
	])
	await _move_node(tera_actor, INTRO_TERA_FIELD_POS, 0.9)

	_intro_state = IntroState.FIND_TERA
	_intro_busy = false
	player.can_move = true
	Global.show_tutorial_text("Objective: Find Tera.")

func _process_intro_progress() -> void:
	if Global.intro_sequence_complete or _intro_busy:
		return

	if _intro_state == IntroState.FIND_TERA and player.global_position.distance_to(tera_actor.global_position) < 92.0:
		call_deferred("_on_player_found_tera")

func _on_player_found_tera() -> void:
	if _intro_busy or _intro_state != IntroState.FIND_TERA:
		return

	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO

	await _play_story_dialogue([
		{"speaker": "Tera", "text": "Savannah! Over here!"},
		{"speaker": "Tera", "text": "Looks like this used to be a farm."},
		{"speaker": "Savannah", "text": "If the soil still turns, this could keep us alive."},
		{"speaker": "Tera", "text": "Then let's see if whoever lived here left anything useful behind."}
	])

	_intro_state = IntroState.OPEN_CHEST
	_intro_busy = false
	player.can_move = true
	Global.show_tutorial_text("Objective: Open the old chest by the ruined field.")

func _on_story_chest_opened() -> void:
	if _intro_busy or _intro_state != IntroState.OPEN_CHEST:
		return
	call_deferred("_run_post_chest_sequence")

func _run_post_chest_sequence() -> void:
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO

	await _play_story_dialogue([
		{"speaker": "Tera", "text": "Old farming tools. You still know how to use these, right?"},
		{"speaker": "Savannah", "text": "Yeah. If we can find seed, we might not starve."},
		{"speaker": "Tera", "text": "Then let's try the tree line. Maybe something survived out there."}
	])

	_intro_state = IntroState.SEARCH_FOREST
	_intro_busy = false
	player.can_move = true
	Global.show_tutorial_text("Objective: Search the forest edge for seeds.")

func _on_forest_exit_trigger_body_entered(body: Node) -> void:
	if body != player:
		return
	if _forest_encounter_started or _intro_busy or _intro_state != IntroState.SEARCH_FOREST:
		return

	_forest_encounter_started = true
	call_deferred("_run_forest_encounter")

func _run_forest_encounter() -> void:
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO

	await _fade_to_black(0.25)
	player.global_position = INTRO_FOREST_RETURN_POS
	tera_actor.visible = true
	tera_actor.global_position = INTRO_FOREST_TERA_POS
	silas_actor.visible = true
	silas_actor.global_position = INTRO_FOREST_SILAS_POS
	await _fade_from_black(0.25)

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "Stop there. Who are you, and what are you doing out here?"},
		{"speaker": "Savannah", "text": "Looking for supplies. We found an abandoned farm nearby."},
		{"speaker": "Tera", "text": "We need something to plant before our luck runs out."},
		{"speaker": "Silas", "text": "There isn't any usable land left in these woods."},
		{"speaker": "Tera", "text": "There is. We found it."},
		{"speaker": "Silas", "text": "Then prove it. I pulled a carrot seed and a parsnip seed off a dead caravan. Dried out. Probably useless."},
		{"speaker": "Silas", "text": "Make them grow, and I'll believe you."}
	])

	Global.add_item(Global.Items.CARROT_SEED, 1)
	Global.add_item(Global.Items.PARSNIP_SEED, 1)

	await _fade_to_black(0.25)
	player.global_position = INTRO_CHEST_APPROACH_POS
	tera_actor.global_position = INTRO_TERA_FIELD_POS
	silas_actor.visible = false
	await _fade_from_black(0.25)

	_intro_state = IntroState.PLANT_AND_WATER
	_intro_busy = false
	player.can_move = true
	Global.show_tutorial_text("Objective: Plant the carrot and parsnip seeds, then water them.")

func _register_intro_plant(seed_type: int, plant: StaticBody2D) -> void:
	if plant == null:
		return
	if _intro_state != IntroState.PLANT_AND_WATER:
		return
	if seed_type not in [Global.Items.CARROT_SEED, Global.Items.PARSNIP_SEED]:
		return
	if seed_type in _story_seed_types_planted:
		return

	_story_plants.append(plant)
	_story_seed_types_planted.append(seed_type)
	if _story_seed_types_planted.size() >= 2:
		Global.show_tutorial_text("Objective: Water both planted seeds.")

func _check_intro_water_state() -> void:
	if _intro_busy or _story_plants.size() < 2:
		return

	for plant in _story_plants:
		if not is_instance_valid(plant):
			return
		if water_layer.get_cell_source_id(plant.grid_pos) == -1:
			return

	call_deferred("_run_magic_reveal")

func _run_magic_reveal() -> void:
	if _intro_busy or _intro_state != IntroState.PLANT_AND_WATER:
		return

	_intro_busy = true
	_intro_state = IntroState.MAGIC_REVEAL
	player.can_move = false
	player.direction = Vector2.ZERO

	await _play_story_dialogue([
		{"speaker": "Savannah", "text": "That's the last of the water."},
		{"speaker": "Tera", "text": "Good. Then let me try something."},
		{"speaker": "Savannah", "text": "Tera... not too much."},
		{"speaker": "Tera", "text": "Just enough to keep us alive."}
	])

	for plant in _story_plants:
		if is_instance_valid(plant) and plant.has_method("force_mature"):
			plant.force_mature()
			await get_tree().create_timer(0.25).timeout

	await _play_story_dialogue([
		{"speaker": "Savannah", "text": "They actually grew."},
		{"speaker": "Tera", "text": "Please don't make me explain that to strangers yet."},
		{"speaker": "Savannah", "text": "Then we rest, and we deal with tomorrow in the morning."}
	])

	await _advance_intro_day()
	await _run_morning_reveal()

func _advance_intro_day() -> void:
	player.can_move = false
	await _fade_to_black(0.8)

	Global.pending_day_transition = true
	Global.current_day += 1
	level_reset()
	Global.pending_day_transition = false

	player.global_position = INTRO_MORNING_PLAYER_POS
	tera_actor.global_position = INTRO_MORNING_TERA_POS
	silas_actor.visible = true
	silas_actor.global_position = INTRO_MORNING_SILAS_POS

	var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
	if hud and hud.has_method("_update_view"):
		hud._update_view(true)

func _run_morning_reveal() -> void:
	_intro_state = IntroState.MORNING_REVEAL
	await _fade_from_black(0.8)

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "I came back for my seeds. Instead I find this."},
		{"speaker": "Silas", "text": "How did you grow them in one night?"},
		{"speaker": "Tera", "text": "Help us keep this place alive, and maybe I'll tell you."},
		{"speaker": "Silas", "text": "...Fine. I'll stay. Name's Silas."},
		{"speaker": "Tera", "text": "Nice to meet you, Silas."},
		{"speaker": "Savannah", "text": "Then let's get to work."}
	])

	_complete_intro()

func _complete_intro() -> void:
	Global.intro_sequence_complete = true
	Global.tutorial_enabled = true
	Global.set_tutorial_step(9)
	_intro_state = IntroState.COMPLETE
	_intro_busy = false
	player.can_move = true
	player.direction = Vector2.ZERO
	_setup_story_camp_state()

func _setup_story_camp_state() -> void:
	tera_actor.visible = true
	tera_actor.global_position = INTRO_CAMP_TERA_POS
	silas_actor.visible = true
	silas_actor.global_position = INTRO_CAMP_SILAS_POS

func _play_story_dialogue(lines: Array[Dictionary]) -> void:
	story_dialogue.play(lines)
	await story_dialogue.dialogue_finished

func _move_node(node: Node2D, destination: Vector2, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(node, "global_position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _fade_to_black(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, "modulate:a", 1.0, duration)
	await tween.finished

func _fade_from_black(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, "modulate:a", 0.0, duration)
	await tween.finished
