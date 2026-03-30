extends Node2D

const TILE_SIZE = 32
const INTRO_ENTRY_PLAYER_POS := Vector2(1036, 1628)
const INTRO_ENTRY_PLAYER_STOP := Vector2(1038, 1488)
const INTRO_ENTRY_TERA_POS := Vector2(1096, 1628)
const INTRO_ENTRY_TERA_STOP := Vector2(1078, 1482)
const INTRO_TERA_WANDER_POS := Vector2(1142, 1362)
const INTRO_TERA_FIELD_POS := Vector2(1292, 734)
const INTRO_CHEST_APPROACH_POS := Vector2(1264, 812)
const INTRO_FOREST_RETURN_POS := Vector2(1086, 1452)
const INTRO_FOREST_TERA_POS := Vector2(1140, 1444)
const INTRO_FOREST_SILAS_POS := Vector2(1258, 1418)
const INTRO_MORNING_PLAYER_POS := Vector2(1452, 748)
const INTRO_MORNING_TERA_POS := Vector2(1508, 734)
const INTRO_MORNING_SILAS_POS := Vector2(1320, 730)
const INTRO_CAMP_TERA_POS := Vector2(1496, 670)
const INTRO_CAMP_SILAS_POS := Vector2(1576, 670)
const BANDIT_ENTRY_LEADER_POS := Vector2(1488, 1718)
const BANDIT_ENTRY_WARRIOR_POS := Vector2(1416, 1762)
const BANDIT_ENTRY_ARCHER_POS := Vector2(1562, 1786)
const BANDIT_STOP_LEADER_POS := Vector2(1482, 1104)
const BANDIT_STOP_WARRIOR_POS := Vector2(1412, 1170)
const BANDIT_STOP_ARCHER_POS := Vector2(1552, 1136)
const BANDIT_DEFENSE_PLAYER_POS := Vector2(1326, 724)
const BANDIT_DEFENSE_TERA_POS := Vector2(1426, 754)
const BANDIT_DEFENSE_SILAS_POS := Vector2(1514, 692)
const CUTSCENE_GROUP_ZOOM := Vector2(1.7, 1.7)
const CUTSCENE_CLOSE_ZOOM := Vector2(1.9, 1.9)

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
@onready var player_camera: Camera2D = $Objects/Player/Camera2D
@onready var cutscene_camera: Camera2D = $CutsceneCamera
@onready var story_markers: Node = $StoryMarkers
@onready var tera_actor = $Objects/TeraActor
@onready var silas_actor = $Objects/SilasActor
@onready var story_dialogue = $CanvasLayer/StoryDialogueBox
@onready var main_menu = $CanvasLayer/MainMenu
@onready var story_chest = $Objects/Chest
@onready var camp_fire = $Objects/CampFire

var plant_scene: PackedScene = preload("res://scenes/level/plant.tscn")
var _combat_scene_path := "res://scenes/level/day_two_battle.tscn"
var _bandit_tension_music_path := "res://audio/music/Music_Anxiety.wav"
var _bandit_tension_music: AudioStream = null
var _story_actor_scene: PackedScene = preload("res://scenes/level/story_actor.tscn")
var _bandit_leader_actor_scene: PackedScene = preload("res://scenes/battle/bandit_marauder_battle_actor.tscn")
var _bandit_warrior_actor_scene: PackedScene = preload("res://scenes/battle/bandit_warrior_battle_actor.tscn")
var _bandit_archer_actor_scene: PackedScene = preload("res://scenes/battle/bandit_archer_battle_actor.tscn")
@export var daytime_gradient: Gradient

@onready var tillable_layer = $World/Tillable
@onready var soil_layer = $SoilLayer
@onready var water_layer = $SoilWaterLayer

var pending_plant_pos: Vector2
var _day_timer_cycle_seconds := 0.0
var _grow_timer_cycle_seconds := 0.0
var _player_camera_default_zoom := Vector2(2, 2)
var _warning_ui_scene: PackedScene = preload("res://scenes/ui/warning_ui.tscn")
var _intro_state := IntroState.INACTIVE
var _intro_busy := false
var _forest_encounter_started := false
var _story_plants: Array[StaticBody2D] = []
var _story_seed_types_planted: Array[int] = []
var _recipe_scene_started := false
var _warning_sequence_started := false
var _suppress_battle_music_sync := true
var _intrusion_bandits: Array[Node2D] = []

func _ready() -> void:
	var seed_menu = $CanvasLayer/SeedMenu
	_bandit_tension_music = load(_bandit_tension_music_path) as AudioStream
	player.toggle_menu_requested.connect(_on_player_menu_requested)
	if seed_menu != null:
		seed_menu.seed_chosen.connect(_on_seed_chosen_from_menu)
		seed_menu.menu_cancelled.connect(_on_seed_menu_cancelled)

	_day_timer_cycle_seconds = $DayTimer.wait_time
	_grow_timer_cycle_seconds = $GrowTimer.wait_time
	if player_camera != null:
		_player_camera_default_zoom = player_camera.zoom

	if story_chest and story_chest.has_signal("opened"):
		story_chest.opened.connect(_on_story_chest_opened)
	if DemoDirector:
		if not DemoDirector.story_harvest_ready.is_connected(_on_story_harvest_ready):
			DemoDirector.story_harvest_ready.connect(_on_story_harvest_ready)
		if not DemoDirector.meal_eaten.is_connected(_on_demo_meal_eaten):
			DemoDirector.meal_eaten.connect(_on_demo_meal_eaten)
		DemoDirector.set_stage(DemoDirector.DemoStage.INTRO)

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

func _apply_story_time_passage(elapsed_seconds: float) -> void:
	var day_timer = $DayTimer
	var grow_timer = $GrowTimer
	var story_seconds := clampf(elapsed_seconds, 0.0, maxf(day_timer.time_left - 2.0, 0.0))
	if story_seconds <= 0.0:
		return

	var grow_time_left = max(grow_timer.time_left, 0.001)
	var grow_interval = _grow_timer_cycle_seconds
	var ticks_to_simulate := 0
	if story_seconds >= grow_time_left:
		ticks_to_simulate = 1 + int(floor((story_seconds - grow_time_left) / grow_interval))

	for _i in range(ticks_to_simulate):
		if has_method("_on_grow_timer_timeout"):
			_on_grow_timer_timeout()

	var new_day_time = day_timer.time_left - story_seconds
	day_timer.start(max(new_day_time, 1.0))
	day_timer.wait_time = _day_timer_cycle_seconds

	var remainder_grow = story_seconds - (ticks_to_simulate * grow_interval)
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

	if Global.intro_sequence_complete and _can_skip_day() and Input.is_action_just_pressed("time_skip"):
		if Global.tutorial_step == 8:
			Global.advance_tutorial()
		request_end_day()

func _can_skip_day() -> bool:
	if DemoDirector and DemoDirector.is_demo_active() and DemoDirector.current_stage != DemoDirector.DemoStage.DEMO_COMPLETE:
		return false
	return true

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
	var seed_menu = $CanvasLayer/SeedMenu

	if soil_layer.get_cell_source_id(grid_pos) != -1:
		for plant in get_tree().get_nodes_in_group("Plants"):
			if plant.grid_pos == grid_pos:
				_show_player_notice("That tile is occupied")
				return

		if seed_menu != null and seed_menu.has_method("has_available_seeds") and not seed_menu.has_available_seeds():
			_show_player_notice("No seeds available")
			return

		player.can_move = false
		pending_plant_pos = adjusted_pos

		var screen_pos = player.get_global_transform_with_canvas().origin
		seed_menu.open(screen_pos)
	else:
		_show_player_notice("Need tilled soil")

func is_tilled_soil_at(global_pos: Vector2) -> bool:
	var adjusted_pos = global_pos + Vector2(0, 24)
	var local_pos = soil_layer.to_local(adjusted_pos)
	var grid_pos = soil_layer.local_to_map(local_pos)
	return soil_layer.get_cell_source_id(grid_pos) != -1

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
		_show_player_notice("That seed is out of season")
		return null

	var local_pos = soil_layer.to_local(global_pos)
	var grid_pos = soil_layer.local_to_map(local_pos)

	for plant in get_tree().get_nodes_in_group("Plants"):
		if plant.grid_pos == grid_pos:
			_show_player_notice("That tile is occupied")
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
	player.global_position = _marker_pos(&"IntroEntryPlayer", INTRO_ENTRY_PLAYER_POS)
	tera_actor.visible = true
	tera_actor.global_position = _marker_pos(&"IntroEntryTera", INTRO_ENTRY_TERA_POS)
	tera_actor.face_down()
	tera_actor.play_idle()
	silas_actor.visible = false

	await _focus_cutscene_on_nodes([player, tera_actor], 0.35, CUTSCENE_GROUP_ZOOM)
	await _move_node(player, _marker_pos(&"IntroEntryPlayerStop", INTRO_ENTRY_PLAYER_STOP), 1.4)
	await _move_node(tera_actor, _marker_pos(&"IntroEntryTeraStop", INTRO_ENTRY_TERA_STOP), 1.4)
	await _play_story_dialogue([
		{"speaker": "Savannah", "text": "We made it out. I think."},
		{"speaker": "Tera", "text": "Yeah. But I've never been this far out before. I don't know where we are."},
		{"speaker": "Savannah", "text": "It's quiet. That's all that matters. We stop here."},
		{"speaker": "Tera", "text": "Wait. Look over there. By the treeline. Is that a roof?"}
	], [player, tera_actor], CUTSCENE_GROUP_ZOOM)

	await _focus_cutscene_on_nodes([tera_actor], 0.25, CUTSCENE_CLOSE_ZOOM)
	await _move_node(tera_actor, _marker_pos(&"TeraWander", INTRO_TERA_WANDER_POS), 0.7)
	await _move_node(tera_actor, _marker_pos(&"TeraField", INTRO_TERA_FIELD_POS), 0.9)
	tera_actor.face_down()

	_intro_state = IntroState.FIND_TERA
	_intro_busy = false
	player.can_move = true
	_restore_player_camera()
	if DemoDirector:
		DemoDirector.show_context_prompt("farm_find_tera")
		await DemoDirector.show_tutorial_card("farm_controls", $CanvasLayer)

func _process_intro_progress() -> void:
	if Global.intro_sequence_complete or _intro_busy:
		return

	if _intro_state == IntroState.FIND_TERA and player.global_position.distance_to(tera_actor.global_position) < 96.0:
		call_deferred("_on_player_found_tera")

func _on_player_found_tera() -> void:
	if _intro_busy or _intro_state != IntroState.FIND_TERA:
		return

	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO
	tera_actor.face_down()

	await _play_story_dialogue([
		{"speaker": "Tera", "text": "A farm. Or what's left of one."},
		{"speaker": "Savannah", "text": "The roof looks solid enough. And the soil... it isn't just ash. We might actually be able to work with this."},
		{"speaker": "Tera", "text": "If they left in a hurry, they might've left gear behind. Let's check the house."}
	], [player, tera_actor, story_chest], CUTSCENE_GROUP_ZOOM)

	_intro_state = IntroState.OPEN_CHEST
	_intro_busy = false
	player.can_move = true
	_restore_player_camera()
	if DemoDirector:
		DemoDirector.show_context_prompt("farm_open_chest")

func _on_story_chest_opened() -> void:
	if _intro_busy or _intro_state != IntroState.OPEN_CHEST:
		return
	call_deferred("_run_post_chest_sequence")

func _run_post_chest_sequence() -> void:
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO
	tera_actor.face_side(true)

	await _play_story_dialogue([
		{"speaker": "Tera", "text": "Chest is rusted shut."},
		{"speaker": "Savannah", "text": "Got it. Spades... shears... The wood is pretty much rot, but the iron's still good. I can make these work."},
		{"speaker": "Tera", "text": "Good. Now we just need seeds."},
		{"speaker": "Savannah", "text": "And we need 'em fast. Sun's going down. Let's check the edge of the woods."}
	], [player, tera_actor, story_chest], CUTSCENE_GROUP_ZOOM)

	_intro_state = IntroState.SEARCH_FOREST
	_intro_busy = false
	if DemoDirector:
		DemoDirector.show_context_prompt("farm_search_forest")
	await _show_forest_edge_camera_hint()

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
	player.global_position = _marker_pos(&"ForestReturn", INTRO_FOREST_RETURN_POS)
	tera_actor.visible = true
	tera_actor.global_position = _marker_pos(&"ForestTera", INTRO_FOREST_TERA_POS)
	tera_actor.face_side(true)
	silas_actor.visible = true
	silas_actor.global_position = _marker_pos(&"ForestSilas", INTRO_FOREST_SILAS_POS)
	silas_actor.face_side(false)
	await _fade_from_black(0.25)
	if player.has_method("play_cutscene_shock"):
		player.play_cutscene_shock(Vector2.RIGHT)
	if tera_actor.has_method("play_shocked"):
		tera_actor.play_shocked()
	if silas_actor.has_method("play_bow_aim"):
		silas_actor.play_bow_aim()
	elif silas_actor.has_method("play_attack"):
		silas_actor.play_attack()
	await get_tree().create_timer(0.2).timeout

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "Don't move. I'm not a fan of company."},
		{"speaker": "Savannah", "text": "Easy. We aren't looking for a fight. Lower the bow."},
		{"speaker": "Tera", "text": "We found the old farmstead. We're just looking for seeds."},
	], [player, tera_actor, silas_actor], Vector2(1.62, 1.62))

	if silas_actor.has_method("play_idle"):
		silas_actor.play_idle()
	if player.has_method("play_cutscene_idle"):
		player.play_cutscene_idle(Vector2.RIGHT)
	if tera_actor.has_method("play_idle"):
		tera_actor.play_idle()

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "The farm? You're either crazy or you've got a death wish. That soil's been dead for years."},
		{"speaker": "Tera", "text": "We're hungry. We'll take our chances."},
		{"speaker": "Silas", "text": "I've been through these woods every day this month. There's nothing left to grow."},
		{"speaker": "Savannah", "text": "Then you missed a spot."}
	], [player, tera_actor, silas_actor], Vector2(1.62, 1.62))

	if silas_actor.has_method("play_impatient"):
		silas_actor.play_impatient()

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "Fine. Take 'em. Ripped those off a dead caravan, they're likely too dry to sprout, anyway. Bury 'em, eat 'em, I don't care. Just get out of my woods."}
	], [player, tera_actor, silas_actor], Vector2(1.62, 1.62))

	Global.add_item(Global.Items.CARROT_SEED, 1)
	Global.add_item(Global.Items.PARSNIP_SEED, 1)

	await _fade_to_black(0.25)
	player.global_position = _marker_pos(&"ChestApproach", INTRO_CHEST_APPROACH_POS)
	tera_actor.global_position = _marker_pos(&"TeraField", INTRO_TERA_FIELD_POS)
	tera_actor.face_down()
	silas_actor.visible = false
	await _fade_from_black(0.25)

	_intro_state = IntroState.PLANT_AND_WATER
	if DemoDirector:
		DemoDirector.show_context_prompt("farm_plant_and_water")
		await DemoDirector.show_tutorial_card("farm_farming", $CanvasLayer)
	_intro_busy = false
	player.can_move = true
	_restore_player_camera(false)

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
		if DemoDirector:
			DemoDirector.show_context_prompt("farm_water_both")

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
	tera_actor.face_down()

	await _play_story_dialogue([
		{"speaker": "Savannah", "text": "Seeds are in. Your turn."},
		{"speaker": "Tera", "text": "Just watch."},
		{"speaker": "Savannah", "text": "Tera... keep it down. No telling who's watching."},
		{"speaker": "Tera", "text": "I've got it. Just... give me a moment."}
	], [player, tera_actor], CUTSCENE_GROUP_ZOOM)

	await _fade_to_black(0.85)
	_apply_story_time_passage(_day_timer_cycle_seconds * 0.28)

	for plant in _story_plants:
		if is_instance_valid(plant) and plant.has_method("force_mature"):
			plant.force_mature()
			await get_tree().create_timer(0.12).timeout

	await _fade_from_black(0.85)

	var reveal_targets: Array[Node2D] = [tera_actor]
	for plant in _story_plants:
		if is_instance_valid(plant):
			reveal_targets.append(plant)
	await _focus_cutscene_on_nodes(reveal_targets, 0.3, CUTSCENE_CLOSE_ZOOM)

	await _play_story_dialogue([
		{"speaker": "Savannah", "text": "That used to take months. You're getting faster."},
		{"speaker": "Tera", "text": "Let's not talk about it. Not until we know if we can trust that hunter."},
		{"speaker": "Savannah", "text": "Fine. Inside. Before someone sees it."}
	], reveal_targets, CUTSCENE_CLOSE_ZOOM)

	await _advance_intro_day()
	await _run_morning_reveal()

func _advance_intro_day() -> void:
	player.can_move = false
	if MusicManager and MusicManager.has_method("fade_to_silence"):
		MusicManager.fade_to_silence(1.0)
	await _fade_to_black(1.15)
	await get_tree().create_timer(0.45).timeout

	Global.pending_day_transition = true
	Global.current_day += 1
	level_reset()
	Global.pending_day_transition = false

	player.global_position = _marker_pos(&"MorningPlayer", INTRO_MORNING_PLAYER_POS)
	tera_actor.global_position = _marker_pos(&"MorningTera", INTRO_MORNING_TERA_POS)
	tera_actor.face_side(false)
	silas_actor.visible = true
	silas_actor.global_position = _marker_pos(&"MorningSilas", INTRO_MORNING_SILAS_POS)
	silas_actor.face_side(true)
	await _focus_cutscene_on_nodes([player, tera_actor, silas_actor], 0.45, CUTSCENE_GROUP_ZOOM)

	var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
	if hud and hud.has_method("_update_view"):
		hud._update_view(true)

	if hud and "day_music" in hud and hud.day_music and MusicManager and MusicManager.has_method("crossfade_to"):
		MusicManager.crossfade_to(hud.day_music, 0.55, -4.0)

	await get_tree().create_timer(0.35).timeout

func _run_morning_reveal() -> void:
	_intro_state = IntroState.MORNING_REVEAL
	await _fade_from_black(1.05)

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "I expected to find two frozen corpses. Not... this."},
		{"speaker": "Silas", "text": "How? That soil was poison yesterday."},
		{"speaker": "Tera", "text": "Help us keep this place standing, and maybe I'll tell you."},
		{"speaker": "Silas", "text": "...Fine. I'm staying. You clearly don't know the first thing about keeping a perimeter."},
		{"speaker": "Silas", "text": "Name's Silas. Since we're being polite."},
		{"speaker": "Tera", "text": "Tera. That's Savannah."},
		{"speaker": "Savannah", "text": "Nice to meet you, Silas. Now help us get these inside before the smell brings company."}
	], [player, tera_actor, silas_actor], CUTSCENE_GROUP_ZOOM)

	_complete_intro()

func _complete_intro() -> void:
	Global.intro_sequence_complete = true
	Global.tutorial_enabled = false
	_intro_state = IntroState.COMPLETE
	_intro_busy = false
	player.can_move = true
	player.direction = Vector2.ZERO
	_setup_story_camp_state()
	_restore_player_camera()
	if DemoDirector:
		DemoDirector.notify_intro_complete()

func _setup_story_camp_state() -> void:
	tera_actor.visible = true
	tera_actor.global_position = _marker_pos(&"CampTera", INTRO_CAMP_TERA_POS)
	tera_actor.face_down()
	silas_actor.visible = true
	silas_actor.global_position = _marker_pos(&"CampSilas", INTRO_CAMP_SILAS_POS)
	silas_actor.face_side(false)

func _on_story_harvest_ready() -> void:
	if _recipe_scene_started or not Global.intro_sequence_complete:
		return
	call_deferred("_run_recipe_scene")

func _run_recipe_scene() -> void:
	if _recipe_scene_started or _intro_busy:
		return

	_recipe_scene_started = true
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO
	_setup_story_camp_state()
	tera_actor.face_side(true)
	silas_actor.face_side(false)

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "You can't live on raw roots and spite."},
		{"speaker": "Silas", "text": "Found some syrup in the cellar. Toss the carrots in the pan, char 'em over the fire."},
		{"speaker": "Silas", "text": "Nobles call it 'Glazed Carrots.' Out here, it's just fuel."},
		{"speaker": "Savannah", "text": "Fuel works for me. Let's get the fire started."},
		{"speaker": "Tera", "text": "Hurry up. The shadows are getting long... I don't like the look of things out there today."}
	], [player, tera_actor, silas_actor, camp_fire], CUTSCENE_GROUP_ZOOM)

	Global.learn_recipe(Global.Items.GLAZED_CARROTS)
	if DemoDirector:
		DemoDirector.notify_recipe_learned(Global.Items.GLAZED_CARROTS)

	await _release_overworld_control()

func _on_demo_meal_eaten(_item_type: int) -> void:
	if _warning_sequence_started or not Global.intro_sequence_complete:
		return
	call_deferred("_run_post_meal_warning_sequence")

func _run_post_meal_warning_sequence() -> void:
	if _warning_sequence_started or _intro_busy:
		return

	_warning_sequence_started = true
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO
	_setup_story_camp_state()

	await _play_story_dialogue([
		{"speaker": "Savannah", "text": "That's actually... really good, Silas. You've got a knack for this."},
		{"speaker": "Silas", "text": "Don't get used to it. We have compa-"}
	], [player, tera_actor, silas_actor, camp_fire], CUTSCENE_GROUP_ZOOM)

	if DemoDirector:
		await DemoDirector.show_tutorial_card("meal_buff", $CanvasLayer)
	if main_menu and main_menu.has_method("set_status_tab_highlight"):
		main_menu.set_status_tab_highlight(true)
	if DemoDirector:
		DemoDirector.refresh_current_prompt()
	_intro_busy = false
	player.can_move = true
	player.direction = Vector2.ZERO
	_restore_player_camera()
	if main_menu and main_menu.has_signal("status_tab_viewed"):
		await main_menu.status_tab_viewed
	if main_menu and main_menu.has_signal("menu_closed"):
		await main_menu.menu_closed
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO
	_setup_story_camp_state()

	if DemoDirector and DemoDirector.current_stage == DemoDirector.DemoStage.MEAL_REVIEW:
		DemoDirector.set_stage(DemoDirector.DemoStage.WARNING_BEAT)
	else:
		DemoDirector.clear_prompt()

	await _run_bandit_intrusion_cutscene()
	await _launch_direct_combat_scene(_combat_scene_path)

func _launch_direct_combat_scene(combat_scene_path: String) -> void:
	if not ResourceLoader.exists(combat_scene_path):
		push_error("Combat map path is invalid: %s" % combat_scene_path)
		_intro_busy = false
		player.can_move = true
		_restore_player_camera()
		return

	if DemoDirector:
		DemoDirector.prepare_day_two_battle_intro()

	var scene_tree := get_tree()
	Global.saved_farm_scene = self
	Global.begin_combat_transition()

	var transition_layer := CanvasLayer.new()
	transition_layer.layer = 100
	scene_tree.root.add_child(transition_layer)

	var fade_rect := ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_rect.color = Color(0, 0, 0, 1)
	transition_layer.add_child(fade_rect)

	var combat_scene = load(combat_scene_path).instantiate()
	combat_scene.set_meta("skip_scene_music_sync", _suppress_battle_music_sync)
	var combat_music: AudioStreamPlayer = combat_scene.get_node_or_null("AudioStreamPlayer")
	if is_instance_valid(combat_music):
		combat_music.autoplay = false
		combat_music.stop()

	scene_tree.root.add_child(combat_scene)
	scene_tree.current_scene = combat_scene
	scene_tree.root.remove_child(self)

	await scene_tree.process_frame

	if is_instance_valid(combat_music) and combat_music.stream != null and MusicManager and MusicManager.has_method("crossfade_to"):
		MusicManager.crossfade_to(combat_music.stream, 0.2, combat_music.volume_db)

	var savannah: Node = combat_scene.get_node_or_null("GameBoard/Savannah")
	var cursor: Node = combat_scene.get_node_or_null("GameBoard/Cursor")
	if savannah != null and cursor != null and "cell" in savannah and "cell" in cursor:
		cursor.cell = savannah.cell.round()
		if "is_active" in cursor:
			cursor.is_active = true

	var reveal := scene_tree.create_tween()
	reveal.set_ease(Tween.EASE_IN_OUT)
	reveal.set_trans(Tween.TRANS_SINE)
	reveal.tween_interval(0.1)
	reveal.tween_property(fade_rect, "color:a", 0.0, 0.85)
	await reveal.finished

	if is_instance_valid(transition_layer):
		transition_layer.queue_free()

func resume_after_combat() -> void:
	_clear_intrusion_bandits()
	_intro_busy = false
	player.can_move = true
	player.direction = Vector2.ZERO
	_restore_player_camera()

func _release_overworld_control(delay_frames: int = 1) -> void:
	for _i in range(maxi(delay_frames, 0)):
		await get_tree().process_frame

	if camp_fire != null and is_instance_valid(camp_fire):
		var cooking_menu = null
		if camp_fire.has_method("get_cooking_menu"):
			cooking_menu = camp_fire.get_cooking_menu()
		if cooking_menu != null and is_instance_valid(cooking_menu) and cooking_menu.visible and cooking_menu.has_method("close_menu"):
			cooking_menu.close_menu()
		if camp_fire.has_method("block_interaction_for"):
			camp_fire.block_interaction_for(0.2)

	_intro_busy = false
	player.can_move = true
	player.direction = Vector2.ZERO
	_restore_player_camera()

func _show_player_notice(text: String, duration := 1.4) -> void:
	var overlay := get_node_or_null("CanvasLayer/Overlay")
	if overlay != null and overlay.has_method("show_notice"):
		overlay.show_notice(text, duration)

func _play_story_dialogue(lines: Array[Dictionary], focus_nodes: Array[Node2D] = [], zoom: Vector2 = CUTSCENE_GROUP_ZOOM) -> void:
	if not focus_nodes.is_empty():
		await _focus_cutscene_on_nodes(focus_nodes, 0.3, zoom)
	story_dialogue.play(lines)
	await story_dialogue.dialogue_finished

func _move_node(node: Node2D, destination: Vector2, duration: float) -> void:
	var travel := destination - node.global_position
	_play_cutscene_move(node, travel)
	var tween = create_tween()
	tween.tween_property(node, "global_position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_play_cutscene_idle(node, travel)

func _fade_to_black(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, "modulate:a", 1.0, duration)
	await tween.finished

func _fade_from_black(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property($CanvasLayer/ColorRect, "modulate:a", 0.0, duration)
	await tween.finished

func _focus_cutscene_on_nodes(nodes: Array[Node2D], duration: float, zoom: Vector2) -> void:
	var positions: Array[Vector2] = []
	for node in nodes:
		if node != null and is_instance_valid(node):
			positions.append(node.global_position)
	await _focus_cutscene_on_positions(positions, duration, zoom)

func _focus_cutscene_on_positions(positions: Array[Vector2], duration: float, zoom: Vector2) -> void:
	if positions.is_empty():
		return

	var target := Vector2.ZERO
	for point in positions:
		target += point
	target /= float(positions.size())

	if not cutscene_camera.is_current():
		cutscene_camera.position_smoothing_enabled = false
		cutscene_camera.global_position = _get_current_camera_center()
		cutscene_camera.zoom = player_camera.zoom
		if cutscene_camera.has_method("reset_smoothing"):
			cutscene_camera.reset_smoothing()
	cutscene_camera.make_current()
	cutscene_camera.position_smoothing_enabled = true

	var tween = create_tween()
	tween.parallel().tween_property(cutscene_camera, "global_position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(cutscene_camera, "zoom", zoom, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _restore_player_camera(sync_to_cutscene: bool = false) -> void:
	if player and player.has_method("clear_cutscene_animation"):
		player.clear_cutscene_animation()
	if player_camera:
		if sync_to_cutscene and is_instance_valid(cutscene_camera):
			player_camera.position_smoothing_enabled = false
			player_camera.global_position = cutscene_camera.global_position
			player_camera.zoom = cutscene_camera.zoom
		else:
			player_camera.position_smoothing_enabled = false
			player_camera.global_position = player.global_position
			player_camera.zoom = _player_camera_default_zoom
		if player_camera.has_method("reset_smoothing"):
			player_camera.reset_smoothing()
		player_camera.make_current()
		player_camera.position_smoothing_enabled = true
		player_camera.position_smoothing_speed = 8.0

func _marker_pos(marker_name: StringName, fallback: Vector2) -> Vector2:
	if story_markers == null:
		return fallback
	var marker := story_markers.get_node_or_null(String(marker_name)) as Node2D
	if marker == null:
		return fallback
	return marker.global_position

func _get_current_camera_center() -> Vector2:
	if player_camera and player_camera.is_inside_tree():
		return player_camera.get_screen_center_position()
	return player.global_position

func _play_cutscene_move(node: Node2D, travel: Vector2) -> void:
	var direction := _cardinalize_direction(travel)
	if node == player and player.has_method("play_cutscene_move"):
		player.play_cutscene_move(direction)
		return
	if node.has_method("face_up") and node.has_method("face_down") and node.has_method("face_side"):
		_face_story_actor(node, direction)
	if node.has_method("play_walk"):
		node.play_walk()

func _play_cutscene_idle(node: Node2D, travel: Vector2) -> void:
	var direction := _cardinalize_direction(travel)
	if node == player and player.has_method("play_cutscene_idle"):
		player.play_cutscene_idle(direction)
		return
	if node.has_method("face_up") and node.has_method("face_down") and node.has_method("face_side"):
		_face_story_actor(node, direction)
	if node.has_method("play_idle"):
		node.play_idle()

func _face_story_actor(node: Node, direction: Vector2) -> void:
	if direction == Vector2.UP and node.has_method("face_up"):
		node.face_up()
	elif direction == Vector2.DOWN and node.has_method("face_down"):
		node.face_down()
	elif node.has_method("face_side"):
		node.face_side(direction != Vector2.LEFT)

func _cardinalize_direction(direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.DOWN
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP

func _show_forest_edge_camera_hint() -> void:
	if _intro_state != IntroState.SEARCH_FOREST:
		return

	var trigger := get_node_or_null("ForestExitTrigger") as Area2D
	if trigger == null:
		return

	var forest_edge_focus := trigger.global_position + Vector2(0.0, -132.0)
	player.can_move = false
	await _focus_cutscene_on_positions([forest_edge_focus], 0.95, Vector2(1.55, 1.55))
	await get_tree().create_timer(0.8).timeout
	await _focus_cutscene_on_nodes([player], 0.9, CUTSCENE_GROUP_ZOOM)
	_restore_player_camera(false)
	player.can_move = true

func _run_bandit_intrusion_cutscene() -> void:
	_clear_intrusion_bandits()
	_setup_story_camp_state()
	var bandit_entry_leader := _marker_pos(&"BanditEntryLeader", BANDIT_ENTRY_LEADER_POS)
	var bandit_entry_warrior := _marker_pos(&"BanditEntryWarrior", BANDIT_ENTRY_WARRIOR_POS)
	var bandit_entry_archer := _marker_pos(&"BanditEntryArcher", BANDIT_ENTRY_ARCHER_POS)
	var bandit_stop_leader := _marker_pos(&"BanditStopLeader", BANDIT_STOP_LEADER_POS)
	var bandit_stop_warrior := _marker_pos(&"BanditStopWarrior", BANDIT_STOP_WARRIOR_POS)
	var bandit_stop_archer := _marker_pos(&"BanditStopArcher", BANDIT_STOP_ARCHER_POS)
	var bandit_defense_player := _marker_pos(&"BanditDefensePlayer", BANDIT_DEFENSE_PLAYER_POS)
	var bandit_defense_tera := _marker_pos(&"BanditDefenseTera", BANDIT_DEFENSE_TERA_POS)
	var bandit_defense_silas := _marker_pos(&"BanditDefenseSilas", BANDIT_DEFENSE_SILAS_POS)
	var party_entry_player := bandit_defense_player + Vector2(-10.0, -176.0)
	var party_entry_tera := bandit_defense_tera + Vector2(0.0, -148.0)
	var party_entry_silas := bandit_defense_silas + Vector2(10.0, -164.0)

	player.global_position = party_entry_player
	tera_actor.global_position = party_entry_tera
	silas_actor.global_position = party_entry_silas
	if player.has_method("play_cutscene_idle"):
		player.play_cutscene_idle(Vector2.DOWN)
	if tera_actor.has_method("face_down"):
		tera_actor.face_down()
	if silas_actor.has_method("face_down"):
		silas_actor.face_down()

	var bandit_leader := _spawn_intrusion_bandit("BanditLeader", _bandit_leader_actor_scene, bandit_entry_leader, true)
	var bandit_warrior := _spawn_intrusion_bandit("BanditWarrior", _bandit_warrior_actor_scene, bandit_entry_warrior, true)
	var bandit_archer := _spawn_intrusion_bandit("BanditArcher", _bandit_archer_actor_scene, bandit_entry_archer, true)

	if _bandit_tension_music != null and MusicManager and MusicManager.has_method("crossfade_to"):
		MusicManager.crossfade_to(_bandit_tension_music, 0.75, -4.0)

	await _focus_cutscene_on_positions([
		bandit_entry_leader,
		bandit_entry_warrior,
		bandit_entry_archer
	], 0.55, Vector2(1.8, 1.8))
	await _move_story_group(
		[bandit_leader, bandit_warrior, bandit_archer],
		[bandit_stop_leader, bandit_stop_warrior, bandit_stop_archer],
		0.95
	)

	await _play_story_dialogue([
		{"speaker": "Bandit Leader", "text": "Quiet little place. Almost missed the smoke."}
	], [bandit_leader, bandit_warrior, bandit_archer], Vector2(1.78, 1.78))

	await _move_story_group(
		[player, tera_actor, silas_actor],
		[bandit_defense_player, bandit_defense_tera, bandit_defense_silas],
		0.9
	)
	if player.has_method("play_cutscene_idle"):
		player.play_cutscene_idle(Vector2.DOWN)
	if tera_actor.has_method("face_down"):
		tera_actor.face_down()
	if tera_actor.has_method("play_idle"):
		tera_actor.play_idle()
	if silas_actor.has_method("face_down"):
		silas_actor.face_down()
	if silas_actor.has_method("play_idle"):
		silas_actor.play_idle()
	if bandit_leader.has_method("play_shocked"):
		bandit_leader.play_shocked()
	if bandit_warrior.has_method("play_shocked"):
		bandit_warrior.play_shocked()
	if bandit_archer.has_method("play_shocked"):
		bandit_archer.play_shocked()
	await get_tree().create_timer(0.2).timeout

	await _play_story_dialogue([
		{"speaker": "Bandit Leader", "text": "Well. The forest rat. Didn't know you had company."},
		{"speaker": "Silas", "text": "Didn't know you were stupid enough to come this close."},
		{"speaker": "Bandit Leader", "text": "We saw green in the ash and figured somebody here had more than they needed."},
		{"speaker": "Silas", "text": "Ladies, look alive. I know these men. They don't talk unless they're counting what they can steal."},
		{"speaker": "Silas", "text": "Savannah, I hope that sword's sharp."},
		{"speaker": "Savannah", "text": "It is."},
		{"speaker": "Tera", "text": "They're not touching this place."}
	], [player, tera_actor, silas_actor, bandit_leader, bandit_warrior, bandit_archer], Vector2(1.72, 1.72))

	await _play_story_dialogue([
		{"speaker": "Bandit Leader", "text": "Then stop us."}
	], [player, tera_actor, silas_actor, bandit_leader, bandit_warrior, bandit_archer], Vector2(1.72, 1.72))

	if MusicManager and MusicManager.has_method("fade_to_silence"):
		MusicManager.fade_to_silence(0.55)

	await _play_story_dialogue([
		{"speaker": "Bandit Leader", "text": "Get 'em, boys."}
	], [player, tera_actor, silas_actor, bandit_leader, bandit_warrior, bandit_archer], Vector2(1.72, 1.72))

	await _fade_to_black(0.55)
	_clear_intrusion_bandits()

func _spawn_intrusion_bandit(actor_name: String, actor_scene: PackedScene, start_pos: Vector2, face_right: bool) -> Node2D:
	var actor := _story_actor_scene.instantiate() as Node2D
	actor.name = actor_name
	actor.set("actor_scene", actor_scene)
	actor.set("actor_scale", Vector2(1.35, 1.35))
	actor.set("visual_offset", Vector2(0.0, -22.0))
	$Objects.add_child(actor)
	actor.global_position = start_pos
	if actor.has_method("face_side"):
		actor.face_side(face_right)
	if actor.has_method("play_idle"):
		actor.play_idle()
	_intrusion_bandits.append(actor)
	return actor

func _move_story_group(actors: Array[Node2D], destinations: Array[Vector2], duration: float) -> void:
	if actors.size() != destinations.size() or actors.is_empty():
		return

	var tween := create_tween()
	tween.set_parallel(true)
	var travel_directions: Array[Vector2] = []
	for index in range(actors.size()):
		var actor := actors[index]
		var destination := destinations[index]
		travel_directions.append(Vector2.ZERO)
		if actor == null or not is_instance_valid(actor):
			continue

		var travel := destination - actor.global_position
		travel_directions[index] = travel
		_play_cutscene_move(actor, travel)
		tween.tween_property(actor, "global_position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	for index in range(actors.size()):
		var actor := actors[index]
		if actor == null or not is_instance_valid(actor):
			continue
		_play_cutscene_idle(actor, travel_directions[index])

func _clear_intrusion_bandits() -> void:
	for actor in _intrusion_bandits:
		if actor != null and is_instance_valid(actor):
			actor.queue_free()
	_intrusion_bandits.clear()
