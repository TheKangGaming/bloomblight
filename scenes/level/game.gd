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
		{"speaker": "Savannah", "text": "We made it out. Barely."},
		{"speaker": "Tera", "text": "I know. I just... don't know where we are."},
		{"speaker": "Savannah", "text": "It's quiet. That's enough for now."},
		{"speaker": "Tera", "text": "Wait. There. I think I found something."}
	], [player, tera_actor], CUTSCENE_GROUP_ZOOM)

	await _focus_cutscene_on_nodes([tera_actor], 0.25, CUTSCENE_CLOSE_ZOOM)
	await _move_node(tera_actor, _marker_pos(&"TeraWander", INTRO_TERA_WANDER_POS), 0.7)
	await _move_node(tera_actor, _marker_pos(&"TeraField", INTRO_TERA_FIELD_POS), 0.9)
	tera_actor.face_down()

	_intro_state = IntroState.FIND_TERA
	_intro_busy = false
	player.can_move = true
	_restore_player_camera()
	Global.show_tutorial_text("Objective: Find Tera.")

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
		{"speaker": "Tera", "text": "Savannah, look."},
		{"speaker": "Tera", "text": "An old farm. Or what's left of one."},
		{"speaker": "Savannah", "text": "Roof, soil, space to work. That's more than we had a minute ago."},
		{"speaker": "Tera", "text": "If the owners ran when the blight hit, maybe they left something behind."}
	], [player, tera_actor, story_chest], CUTSCENE_GROUP_ZOOM)

	_intro_state = IntroState.OPEN_CHEST
	_intro_busy = false
	player.can_move = true
	_restore_player_camera()
	Global.show_tutorial_text("Objective: Open the old chest by the ruined field.")

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
		{"speaker": "Tera", "text": "An old chest. Rusted shut."},
		{"speaker": "Savannah", "text": "Steel spades. Shears. The handles are rotting, but the iron is still good."},
		{"speaker": "Tera", "text": "Can you use them?"},
		{"speaker": "Savannah", "text": "If we find seeds. We should move before the light goes."}
	], [player, tera_actor, story_chest], CUTSCENE_GROUP_ZOOM)

	_intro_state = IntroState.SEARCH_FOREST
	_intro_busy = false
	player.can_move = true
	_restore_player_camera()
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
	player.global_position = _marker_pos(&"ForestReturn", INTRO_FOREST_RETURN_POS)
	tera_actor.visible = true
	tera_actor.global_position = _marker_pos(&"ForestTera", INTRO_FOREST_TERA_POS)
	tera_actor.face_side(true)
	silas_actor.visible = true
	silas_actor.global_position = _marker_pos(&"ForestSilas", INTRO_FOREST_SILAS_POS)
	silas_actor.face_side(false)
	await _fade_from_black(0.25)

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "Stop. One more step and I loose the arrow."},
		{"speaker": "Savannah", "text": "We're not looking for trouble."},
		{"speaker": "Tera", "text": "We found an abandoned farm nearby. We need seed."},
		{"speaker": "Silas", "text": "Then you're desperate, or stupid."},
		{"speaker": "Tera", "text": "Hungry. There's a difference."},
		{"speaker": "Silas", "text": "I walk these woods every week. There's no land out here worth claiming."},
		{"speaker": "Savannah", "text": "There is. We saw it."},
		{"speaker": "Silas", "text": "Then take these and waste your evening. I ripped them off a dead caravan. Dry as bone."},
		{"speaker": "Silas", "text": "Bury them in the dirt, eat them raw, I don't care. Just get out of my woods."}
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
	_intro_busy = false
	player.can_move = true
	_restore_player_camera()
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
	tera_actor.face_down()

	await _play_story_dialogue([
		{"speaker": "Savannah", "text": "Water's done."},
		{"speaker": "Tera", "text": "Good. Then watch the soil."},
		{"speaker": "Savannah", "text": "Tera. Keep it controlled."},
		{"speaker": "Tera", "text": "I am."}
	], [player, tera_actor], CUTSCENE_GROUP_ZOOM)

	var reveal_targets: Array[Node2D] = [tera_actor]
	for plant in _story_plants:
		if is_instance_valid(plant):
			reveal_targets.append(plant)
	await _focus_cutscene_on_nodes(reveal_targets, 0.25, CUTSCENE_CLOSE_ZOOM)

	for plant in _story_plants:
		if is_instance_valid(plant) and plant.has_method("force_mature"):
			plant.force_mature()
			await get_tree().create_timer(0.25).timeout

	await _play_story_dialogue([
		{"speaker": "Savannah", "text": "One day. That's all it took."},
		{"speaker": "Tera", "text": "Not a word to anyone until we know we can trust them."},
		{"speaker": "Savannah", "text": "Then inside. Before someone starts asking questions."}
	], reveal_targets, CUTSCENE_CLOSE_ZOOM)

	await _advance_intro_day()
	await _run_morning_reveal()

func _advance_intro_day() -> void:
	player.can_move = false
	await _fade_to_black(0.8)

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

	var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
	if hud and hud.has_method("_update_view"):
		hud._update_view(true)

func _run_morning_reveal() -> void:
	_intro_state = IntroState.MORNING_REVEAL
	await _fade_from_black(0.8)

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "I expected dead seeds. Maybe dead girls. Not this."},
		{"speaker": "Silas", "text": "How did you grow them overnight?"},
		{"speaker": "Tera", "text": "Help us hold this place together, and maybe you earn that answer."},
		{"speaker": "Silas", "text": "...Fine. I'm in."},
		{"speaker": "Silas", "text": "Silas. Since we're pretending to be civilized."},
		{"speaker": "Tera", "text": "Nice to meet you, Silas."},
		{"speaker": "Savannah", "text": "Then let's harvest these before anything else goes wrong."}
	], [player, tera_actor, silas_actor], CUTSCENE_GROUP_ZOOM)

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
	_restore_player_camera()

func _setup_story_camp_state() -> void:
	tera_actor.visible = true
	tera_actor.global_position = _marker_pos(&"CampTera", INTRO_CAMP_TERA_POS)
	tera_actor.face_down()
	silas_actor.visible = true
	silas_actor.global_position = _marker_pos(&"CampSilas", INTRO_CAMP_SILAS_POS)
	silas_actor.face_side(false)

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
	for position in positions:
		target += position
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

func _restore_player_camera() -> void:
	if player and player.has_method("clear_cutscene_animation"):
		player.clear_cutscene_animation()
	if player_camera:
		if player_camera.has_method("reset_smoothing"):
			player_camera.reset_smoothing()
		player_camera.make_current()

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
