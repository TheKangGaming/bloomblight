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
const LOOP_ARRIVAL_PLAYER_ENTRY_POS := Vector2(922, 1688)
const LOOP_ARRIVAL_PLAYER_STOP := Vector2(922, 1416)
const LOOP_ARRIVAL_TERA_ENTRY_POS := Vector2(994, 1688)
const LOOP_ARRIVAL_TERA_STOP := Vector2(994, 1408)
const LOOP_ARRIVAL_TERA_GATE_POS := Vector2(960, 1300)
const LOOP_ARRIVAL_TERA_CABIN_APPROACH_POS := Vector2(960, 1200)
const LOOP_ARRIVAL_TERA_REST_POS := Vector2(960, 1120)
const BANDIT_ENTRY_LEADER_POS := Vector2(1488, 1718)
const BANDIT_ENTRY_WARRIOR_POS := Vector2(1416, 1762)
const BANDIT_ENTRY_ARCHER_POS := Vector2(1562, 1786)
const BANDIT_STOP_LEADER_POS := Vector2(1482, 1104)
const BANDIT_STOP_WARRIOR_POS := Vector2(1412, 1170)
const BANDIT_STOP_ARCHER_POS := Vector2(1552, 1136)
const BANDIT_DEFENSE_PLAYER_POS := Vector2(1326, 724)
const BANDIT_DEFENSE_TERA_POS := Vector2(1426, 754)
const BANDIT_DEFENSE_SILAS_POS := Vector2(1514, 692)
const CABIN_HOME_POS := Vector2(1488, 544)
const LOOP_CABIN_HOME_POS := Vector2(960, 744)
const CABIN_REBUILD_PLAYER_POS := Vector2(1392, 716)
const CABIN_REBUILD_TERA_POS := Vector2(1460, 706)
const CABIN_REBUILD_SILAS_POS := Vector2(1560, 696)
const CABIN_SLEEP_PLAYER_POS := Vector2(1478, 626)
const CABIN_SLEEP_TERA_POS := Vector2(1412, 666)
const CABIN_SLEEP_SILAS_POS := Vector2(1588, 654)
const MERCHANT_PLAYER_POS := Vector2(1422, 720)
const MERCHANT_TERA_POS := Vector2(1492, 710)
const MERCHANT_SILAS_POS := Vector2(1592, 700)
const MERCHANT_POS := Vector2(1236, 684)
const CUTSCENE_GROUP_ZOOM := Vector2(1.7, 1.7)
const CUTSCENE_CLOSE_ZOOM := Vector2(1.9, 1.9)
const LOOP_START_PLAYER_POS := Vector2(960, 1536)
const LOOP_CAMPFIRE_POS := Vector2(1064, 900)
const LOOP_BRIDGE_BATTLE_POS := Vector2(960, 1656)
const LOOP_PLOT_SIZE := Vector2(640.0, 480.0)
const LOOP_PURIFY_VFX_TEXTURE: Texture2D = preload("res://graphics/animations/ui/directional_sparkle_burst_002_large_green/spritesheet.png")
const LOOP_PURIFY_VFX_FRAME_COUNT := 26
const LOOP_PURIFY_SFX := preload("res://audio/sfx/Spell Impact 1.wav")
const LOOP_INTERACTION_RADIUS_PLOT := 96.0
const LOOP_INTERACTION_RADIUS_STRUCTURE := 88.0
const LOOP_INTERACTION_RADIUS_MERCHANT := 156.0
const LOOP_PLOT_INTERACTION_EDGE_MARGIN := 64.0
const LOOP_BRIDGE_BATTLE_SCENE := "res://scenes/level/forest_battle.tscn"
const LOOP_PLOT_MERCHANT := &"merchant"
const LOOP_PLOT_STARTING_FARM := &"starting_farm"
const LOOP_PLOT_FOREST := &"forest"
const LOOP_PLOT_GARDEN := &"garden_plus"
const LOOP_PLOT_CABIN := &"cabin"
const LOOP_PLOT_WORKSHOP := &"workshop"
const LOOP_PLOT_WATCHTOWER := &"watchtower"
const LOOP_PLOT_QUARRY := &"quarry"
const LOOP_PLOT_BLOOM_SHRINE := &"bloom_shrine"
const LOOP_MERCHANT_BUILD_WOOD_COST := 8
const LOOP_CABIN_REPAIR_WOOD_COST := Global.DEMO_CABIN_WOOD_REQUIRED
const LOOP_BATTLE_BP_REWARDS: Array[int] = [8, 10, 12, 14, 20]
const LOOP_BATTLE_GOLD_REWARDS: Array[int] = [4, 6, 8, 10, 14]
const LOOP_BATTLE_BP_BASE_REWARD := 8
const LOOP_BATTLE_GOLD_BASE_REWARD := 4
const LOOP_BATTLE_BP_STEP := 2
const LOOP_BATTLE_GOLD_STEP := 2
const LOOP_POST_BATTLE_GROWTH_TICKS := 2
const LOOP_RAID_LOSS_RATIO := 0.25
const LOOP_HUB_ENTRY_FADE_ALPHA := 0.54
const LOOP_HUB_ENTRY_FADE_DURATION := 0.4
const LOOP_HUB_ENTRY_HUD_DURATION := 0.24
const LOOP_HUB_ENTRY_HUD_DELAY := 0.11
const LOOP_HUB_ENTRY_MUSIC_DELAY := 0.09
const LOOP_HUB_ENTRY_MUSIC_FADE := 0.32
const LOOP_SEED_SHOP := {
	Global.Items.CARROT_SEED: {"cost": 3, "label": "Carrot Seeds x1"},
	Global.Items.PARSNIP_SEED: {"cost": 4, "label": "Parsnip Seeds x1"},
	Global.Items.POTATO_SEED: {"cost": 5, "label": "Potato Seeds x1"},
	Global.Items.GARLIC_SEED: {"cost": 6, "label": "Garlic Seeds x1"},
}
const LOOP_NIGHT_VENDOR_SEED_SHOP := {
	Global.Items.CAULIFLOWER_SEED: {"cost": 8, "label": "Cauliflower Seeds x1"},
	Global.Items.GREEN_BEANS_SEED: {"cost": 8, "label": "Green Bean Seeds x1"},
	Global.Items.STRAWBERRY_SEED: {"cost": 10, "label": "Strawberry Seeds x1"},
	Global.Items.COFFEE_BEAN_SEED: {"cost": 11, "label": "Coffee Beans x1"},
}
const LOOP_NIGHT_VENDOR_INGREDIENT_SHOP := {
	Global.Items.CAULIFLOWER: {"cost": 9, "label": "Cauliflower x1"},
	Global.Items.STRAWBERRY: {"cost": 10, "label": "Strawberries x1"},
	Global.Items.COFFEE_BEAN: {"cost": 8, "label": "Coffee Beans x1"},
	Global.Items.WATER: {"cost": 3, "label": "Fresh Water x1"},
}
const LOOP_SELL_PRICES := {
	Global.Items.CARROT: 4,
	Global.Items.PARSNIP: 4,
	Global.Items.POTATO: 6,
	Global.Items.GARLIC: 5,
}
const LOOP_MAX_FOREST_STAGE := 10
const LOOP_MERCHANT_GEAR_OFFERS := [
	{"stage": 2, "cost": 34, "item": preload("res://data/items/Weapons/SteelFalchion.tres"), "slot": "Weapon"},
	{"stage": 2, "cost": 34, "item": preload("res://data/items/Weapons/LonghunterBow.tres"), "slot": "Weapon"},
	{"stage": 2, "cost": 34, "item": preload("res://data/items/Weapons/EmberbranchStaff.tres"), "slot": "Weapon"},
	{"stage": 4, "cost": 30, "item": preload("res://data/items/Armor/GuardCoat.tres"), "slot": "Armor"},
	{"stage": 4, "cost": 30, "item": preload("res://data/items/Armor/RangerJerkin.tres"), "slot": "Armor"},
	{"stage": 4, "cost": 30, "item": preload("res://data/items/Armor/WardingCloak.tres"), "slot": "Armor"},
	{"stage": 6, "cost": 28, "item": preload("res://data/items/Accessories/DuelistCharm.tres"), "slot": "Accessory"},
	{"stage": 6, "cost": 28, "item": preload("res://data/items/Accessories/HawkeyeBand.tres"), "slot": "Accessory"},
	{"stage": 6, "cost": 28, "item": preload("res://data/items/Accessories/FocusCharm.tres"), "slot": "Accessory"},
	{"stage": 8, "cost": 48, "item": preload("res://data/items/Weapons/CaptainsEdge.tres"), "slot": "Weapon"},
	{"stage": 8, "cost": 52, "item": preload("res://data/items/Weapons/RangersLongbow.tres"), "slot": "Weapon"},
	{"stage": 8, "cost": 50, "item": preload("res://data/items/Weapons/SunfireScepter.tres"), "slot": "Weapon"},
	{"stage": 8, "cost": 40, "item": preload("res://data/items/Accessories/ForestCrest.tres"), "slot": "Accessory"},
]
const LOOP_PLOT_DEFS := {
	LOOP_PLOT_WATCHTOWER: {"rect": Rect2(Vector2(0, 0), LOOP_PLOT_SIZE), "unlock_cost": 8},
	LOOP_PLOT_QUARRY: {"rect": Rect2(Vector2(640, 0), LOOP_PLOT_SIZE), "unlock_cost": 7},
	LOOP_PLOT_BLOOM_SHRINE: {"rect": Rect2(Vector2(1280, 0), LOOP_PLOT_SIZE), "unlock_cost": 9},
	LOOP_PLOT_GARDEN: {"rect": Rect2(Vector2(0, 480), LOOP_PLOT_SIZE), "unlock_cost": 6},
	LOOP_PLOT_CABIN: {"rect": Rect2(Vector2(640, 480), LOOP_PLOT_SIZE), "unlock_cost": 0},
	LOOP_PLOT_WORKSHOP: {"rect": Rect2(Vector2(1280, 480), LOOP_PLOT_SIZE), "unlock_cost": 8},
	LOOP_PLOT_MERCHANT: {"rect": Rect2(Vector2(0, 960), LOOP_PLOT_SIZE), "unlock_cost": 10},
	LOOP_PLOT_STARTING_FARM: {"rect": Rect2(Vector2(640, 960), LOOP_PLOT_SIZE), "unlock_cost": 0},
	LOOP_PLOT_FOREST: {"rect": Rect2(Vector2(1280, 960), LOOP_PLOT_SIZE), "unlock_cost": 8},
}
const LOOP_INTERACTION_POINTS := {
	LOOP_PLOT_MERCHANT: Vector2(700, 1200),
	LOOP_PLOT_FOREST: Vector2(1220, 1200),
	&"bridge_battle": LOOP_BRIDGE_BATTLE_POS,
}
const LOOP_MERCHANT_STRUCTURE_POS := Vector2(360, 1216)
const LOOP_MERCHANT_NPC_POS := Vector2(374, 1288)
const LOOP_MERCHANT_INTERACTION_POS := Vector2(392, 1200)
const LOOP_NIGHT_VENDOR_POS := Vector2(1176, 756)
const LOOP_NIGHT_VENDOR_INTERACTION_POS := Vector2(1176, 816)
const LOOP_FOREST_SILAS_POS := Vector2(1404, 1220)
const LOOP_FOREST_TREE_POSITIONS := [
	Vector2(1520, 1296),
	Vector2(1560, 1258),
	Vector2(1600, 1320),
	Vector2(1640, 1280),
	Vector2(1588, 1360),
	Vector2(1504, 1356),
]
const LOOP_OBJECTIVE_FIGHT := "Fight for BP"
const LOOP_OBJECTIVE_PLANT := "Plant seeds before battle"
const LOOP_OBJECTIVE_HARVEST := "Harvest after combat"
const LOOP_OBJECTIVE_MERCHANT := "Purify Merchant"
const LOOP_OBJECTIVE_FOREST := "Unlock Forest"
const LOOP_OBJECTIVE_REPAIR := "Repair Cabin"
const LOOP_OBJECTIVE_CABIN := "Gather Wood for Cabin"
const LOOP_OBJECTIVE_SETTLE := "Sleep to begin a new day"
const LOOP_OBJECTIVE_NIGHT := "Night: harvest, prep, then sleep"
const LOOP_MERCHANT_KIND_WAGON := "wagon"
const LOOP_MERCHANT_KIND_NIGHT := "night"
const LOOP_MERCHANT_TAB_SWITCH_COOLDOWN_MS := 150
const WORLD_PICKUP_POPUP_SCRIPT := preload("res://scenes/ui/world_pickup_popup.gd")

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
@onready var objects_root: Node2D = $Objects
@onready var world_root: Node2D = $World
@onready var ruin_body_top: StaticBody2D = $World/Obstacles/StaticBody2D2
@onready var ruin_body_bottom: StaticBody2D = $World/Obstacles/StaticBody2D
@onready var ruin_sprite_elements_1: Sprite2D = $World/Obstacles/StaticBody2D2/AbandonedStructuresElements1
@onready var ruin_sprite_elements_2: Node2D = get_node_or_null("World/AbandonedStructuresElements2") as Node2D
@onready var ruin_sprite_elements_0: Node2D = get_node_or_null("World/AbandonedStructuresElements0") as Node2D

var plant_scene: PackedScene = preload("res://scenes/level/plant.tscn")
var _cabin_home_scene: PackedScene = preload("res://scenes/level/cabin_home.tscn")
var _merchant_actor_scene: PackedScene = preload("res://scenes/level/merchant_actor.tscn")
var _night_vendor_actor_scene: PackedScene = preload("res://scenes/level/wandering_merchant_actor.tscn")
var _merchant_wagon_naked_scene: PackedScene = preload("res://scenes/level/merchant_wagon_naked.tscn")
var _merchant_wagon_complete_scene: PackedScene = preload("res://scenes/level/merchant_wagon_complete.tscn")
var _overworld_burst_scene: PackedScene = preload("res://scenes/level/overworld_burst_vfx.tscn")
var _overworld_system_menu_scene: PackedScene = preload("res://scenes/ui/menus/overworld_system_menu.tscn")
var _combat_scene_path := "res://scenes/level/day_two_battle.tscn"
var _forest_scene_path := "res://scenes/level/forest.tscn"
var _bandit_tension_music: AudioStream = preload("res://audio/music/Music_Anxiety.wav")
var _rebuild_hit_a: AudioStream = preload("res://audio/sfx/axe.wav")
var _rebuild_hit_b: AudioStream = preload("res://audio/sfx/hoe.wav")
var _story_actor_scene: PackedScene = preload("res://scenes/level/story_actor.tscn")
var _bandit_leader_actor_scene: PackedScene = preload("res://scenes/battle/bandit_marauder_battle_actor.tscn")
var _bandit_warrior_actor_scene: PackedScene = preload("res://scenes/battle/bandit_warrior_battle_actor.tscn")
var _bandit_archer_actor_scene: PackedScene = preload("res://scenes/battle/bandit_archer_battle_actor.tscn")
@export var daytime_gradient: Gradient

@onready var tillable_layer = $World/Tillable
@onready var plowed_layer: TileMapLayer = get_node_or_null("World/Plowed") as TileMapLayer
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
var _overworld_system_menu: Control = null
var _cabin_home = null
var _merchant_actor = null
var _camera_fx = null
var _post_battle_aftermath_started := false
var _materials_run_started := false
var _merchant_sequence_started := false
var _loop_plot_cover_root: Node2D = null
var _loop_plot_cover_polygons: Dictionary = {}
var _loop_plot_cover_bodies: Dictionary = {}
var _loop_plot_outline_lines: Dictionary = {}
var _loop_merchant_structure_naked: StaticBody2D = null
var _loop_merchant_structure_complete: StaticBody2D = null
var _loop_merchant_menu: PanelContainer = null
var _loop_merchant_title_label: Label = null
var _loop_merchant_status: Label = null
var _loop_merchant_detail_label: Label = null
var _loop_merchant_tab_bar: HBoxContainer = null
var _loop_merchant_action_scroll: ScrollContainer = null
var _loop_merchant_actions: VBoxContainer = null
var _loop_merchant_tab_buttons: Dictionary = {}
var _loop_merchant_close_button: Button = null
var _loop_merchant_active_tab := "Seeds"
var _loop_active_merchant_kind := LOOP_MERCHANT_KIND_WAGON
var _loop_merchant_tab_switch_cooldown_until_msec := 0
var _loop_night_vendor_actor = null
var _loop_spawned_forest_nodes: Array[Node2D] = []
var _loop_hud_root: PanelContainer = null
var _loop_hud_stats_label: Label = null
var _loop_hud_perk_label: Label = null
var _loop_prompt_root: PanelContainer = null
var _loop_prompt_label: Label = null
var _loop_hub_entry_uses_transition_handoff: bool = false
var _loop_battle_launch_pending := false
var _loop_plant_tutorial_active := false
var _loop_battle_tutorial_active := false
var _loop_bloom_points_tutorial_active := false
var _loop_forest_tutorial_active := false
var _loop_cooking_tutorial_active := false
var _loop_night_tutorial_active := false
var _loop_sleep_tutorial_active := false

func _log_run_start(message: String) -> void:
	if OS.is_debug_build():
		print("[RunStart][Hub] %d %s" % [Time.get_ticks_msec(), message])

func _get_loop_stage() -> int:
	return clampi(maxi(Global.loop_battle_index, 1), 1, LOOP_MAX_FOREST_STAGE)

func _autosave_loop_run() -> void:
	if not Global.loop_hub_mode_active or SaveManager == null or not SaveManager.has_method("save_current_run"):
		return
	SaveManager.save_current_run(get_loop_run_save_state())

func get_loop_run_save_state() -> Dictionary:
	var crops: Array[Dictionary] = []
	for plant_variant in get_tree().get_nodes_in_group("Plants"):
		var plant := plant_variant as StaticBody2D
		if plant == null or not is_instance_valid(plant):
			continue
		var plant_type_value = plant.get("plant_type")
		var grid_pos_value = plant.get("grid_pos")
		var age_value = plant.get("age")
		if plant_type_value == null or grid_pos_value == null or age_value == null:
			continue
		var grid_pos: Vector2i = grid_pos_value
		crops.append({
			"seed_type": int(plant_type_value),
			"grid_x": grid_pos.x,
			"grid_y": grid_pos.y,
			"age": float(age_value),
		})

	return {
		"player_position": {"x": player.global_position.x, "y": player.global_position.y},
		"crops": crops,
	}

func apply_loop_run_save_state(save_data: Dictionary) -> void:
	if save_data.is_empty():
		return

	var player_position: Variant = save_data.get("player_position", {})
	if player_position is Dictionary:
		player.global_position = Vector2(
			float((player_position as Dictionary).get("x", player.global_position.x)),
			float((player_position as Dictionary).get("y", player.global_position.y))
		)

	_clear_loop_crops()
	for crop_variant in Array(save_data.get("crops", [])):
		if crop_variant is not Dictionary:
			continue
		var crop: Dictionary = crop_variant
		_restore_loop_crop(crop)
	_refresh_loop_phase_presentation(true)

func _apply_pending_loop_save_if_needed() -> void:
	if SaveManager == null or not SaveManager.has_method("has_pending_loop_state") or not SaveManager.has_pending_loop_state():
		return
	apply_loop_run_save_state(SaveManager.consume_pending_loop_state())

func _refresh_loop_phase_presentation(force := false) -> void:
	if not Global.loop_hub_mode_active:
		return
	$CanvasModulate.color = daytime_gradient.sample(0.8) if _is_loop_night() else daytime_gradient.sample(0.28)
	var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
	if hud != null and hud.has_method("_update_view"):
		hud._update_view(force)

func _clear_loop_crops() -> void:
	for plant_variant in get_tree().get_nodes_in_group("Plants"):
		if plant_variant != null and is_instance_valid(plant_variant):
			plant_variant.queue_free()

func _restore_loop_crop(crop: Dictionary) -> void:
	var seed_type := int(crop.get("seed_type", -1))
	if seed_type < 0:
		return

	var planting_layer := _get_active_planting_layer()
	if planting_layer == null:
		return

	var grid_pos := Vector2i(int(crop.get("grid_x", 0)), int(crop.get("grid_y", 0)))
	var plant_pos := planting_layer.map_to_local(grid_pos)
	plant_pos.y -= 8
	var plant := plant_scene.instantiate() as StaticBody2D
	if plant == null:
		return
	if plant.has_method("restore_state"):
		plant.restore_state(seed_type, grid_pos, float(crop.get("age", 1.0)))
	else:
		plant.setup(seed_type, grid_pos)
		if plant.get("age") != null:
			plant.age = float(crop.get("age", 1.0))
	objects_root.add_child(plant)
	plant.position = plant_pos

func _get_equipment_display_name(item: Resource) -> String:
	if item is WeaponData:
		return String((item as WeaponData).weapon_name)
	if item is ArmorData:
		return String((item as ArmorData).armor_name)
	if item is AccessoryData:
		return String((item as AccessoryData).accessory_name)
	return item.resource_name if item != null else "Item"

func _format_loop_item_name(item_type: int) -> String:
	var item_keys := Global.Items.keys()
	if item_type >= 0 and item_type < item_keys.size():
		return String(item_keys[item_type]).replace("_", " ").to_lower().capitalize()
	return "Item"

func _is_loop_night() -> bool:
	return Global.loop_hub_mode_active and Global.loop_time_phase == Global.LOOP_PHASE_NIGHT

func _is_loop_day() -> bool:
	return not _is_loop_night()

func _is_loop_cabin_repaired() -> bool:
	return Global.is_loop_structure_built(Global.LOOP_STRUCTURE_CABIN_REPAIRED)

func _should_play_loop_arrival_intro() -> bool:
	return Global.loop_hub_mode_active and Global.pending_loop_arrival_intro

func _is_loop_night_vendor_available() -> bool:
	return Global.loop_hub_mode_active and _is_loop_night() and _is_loop_cabin_repaired() and Global.loop_battle_index >= 3

func _get_active_cabin_home_pos() -> Vector2:
	return LOOP_CABIN_HOME_POS if Global.loop_hub_mode_active else CABIN_HOME_POS

func _get_loop_cabin_interaction_point() -> Vector2:
	var cabin_plot: Dictionary = LOOP_PLOT_DEFS.get(LOOP_PLOT_CABIN, {})
	var rect_variant: Variant = cabin_plot.get("rect", Rect2())
	var plot_center := Vector2(960, 720)
	if rect_variant is Rect2:
		var rect: Rect2 = rect_variant
		plot_center = rect.position + (rect.size * 0.5)
	if not _is_loop_cabin_repaired():
		return plot_center
	return _get_active_cabin_home_pos() + Vector2(0, -36)

func _set_body_collision_shapes_deferred(body: Node, disabled: bool) -> void:
	if body == null or not is_instance_valid(body):
		return
	for child in body.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", disabled)

func _set_area_collision_shapes_deferred(area: Node, disabled: bool) -> void:
	if area == null or not is_instance_valid(area):
		return
	for child in area.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", disabled)

func _sync_loop_campfire_state() -> void:
	if camp_fire == null or not is_instance_valid(camp_fire):
		return
	if not Global.loop_hub_mode_active:
		camp_fire.visible = true
		camp_fire.set_deferred("collision_layer", 1)
		_set_body_collision_shapes_deferred(camp_fire, false)
		var interact_area := camp_fire.get_node_or_null("InteractArea") as Area2D
		if interact_area != null:
			interact_area.set_deferred("collision_mask", 2)
			_set_area_collision_shapes_deferred(interact_area, false)
		return

	var campfire_available := _is_loop_cabin_repaired()
	camp_fire.global_position = LOOP_CAMPFIRE_POS
	camp_fire.visible = campfire_available
	camp_fire.set_deferred("collision_layer", 1 if campfire_available else 0)
	_set_body_collision_shapes_deferred(camp_fire, not campfire_available)
	var interact_area := camp_fire.get_node_or_null("InteractArea") as Area2D
	if interact_area != null:
		interact_area.set_deferred("collision_mask", 2 if campfire_available else 0)
		_set_area_collision_shapes_deferred(interact_area, not campfire_available)

func _set_structure_collision_state_deferred(structure: StaticBody2D, active: bool) -> void:
	if structure == null or not is_instance_valid(structure):
		return
	structure.set_deferred("collision_layer", 1 if active else 0)
	var shape := structure.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", not active)

func _get_active_loop_seed_shop() -> Dictionary:
	return LOOP_NIGHT_VENDOR_SEED_SHOP if _loop_active_merchant_kind == LOOP_MERCHANT_KIND_NIGHT else LOOP_SEED_SHOP

func _get_active_loop_merchant_tabs() -> PackedStringArray:
	if _loop_active_merchant_kind == LOOP_MERCHANT_KIND_NIGHT:
		return PackedStringArray(["Sell", "Rare Seeds", "Ingredients"])
	return PackedStringArray(["Sell", "Seeds", "Weapons", "Armor", "Accessories"])

func _set_loop_merchant_detail_text(text: String) -> void:
	if _loop_merchant_detail_label == null or not is_instance_valid(_loop_merchant_detail_label):
		return
	_loop_merchant_detail_label.text = text

func _build_loop_merchant_seed_description(seed_item: int, cost: int) -> String:
	var crop_name := "Crops"
	match seed_item:
		Global.Items.CARROT_SEED:
			crop_name = "Carrots"
		Global.Items.PARSNIP_SEED:
			crop_name = "Parsnips"
		Global.Items.POTATO_SEED:
			crop_name = "Potatoes"
		Global.Items.GARLIC_SEED:
			crop_name = "Garlic"
		Global.Items.CAULIFLOWER_SEED:
			crop_name = "Cauliflower"
		Global.Items.GREEN_BEANS_SEED:
			crop_name = "Green Beans"
		Global.Items.STRAWBERRY_SEED:
			crop_name = "Strawberries"
		Global.Items.COFFEE_BEAN_SEED:
			crop_name = "Coffee Beans"
	return "%d Gold\nPlant these on plowed soil before a battle. They keep growing while you fight and harvest into %s for cooking or selling." % [cost, crop_name]

func _build_loop_merchant_inventory_description(item_type: int, cost: int) -> String:
	return "%d Gold\n%s\nUseful for cooking, meal prep, or stocking up before dawn." % [
		cost,
		_format_loop_item_name(item_type)
	]

func _build_loop_merchant_item_description(item: Resource, cost: int) -> String:
	if item == null:
		return ""

	var lines: PackedStringArray = ["%d Gold" % cost, _get_equipment_display_name(item)]
	var description := String(item.get("description")).strip_edges()
	if not description.is_empty():
		lines.append(description)

	var bonuses: Variant = item.get("stat_bonuses")
	if bonuses is Dictionary:
		var bonus_parts: PackedStringArray = []
		var labels := {
			"max_health": "HP",
			"strength": "STR",
			"defense": "DEF",
			"magic_defense": "MDEF",
			"dexterity": "DEX",
			"intelligence": "INT",
			"speed": "SPD",
			"move_range": "MOV",
			"attack_range": "RNG",
		}
		for key in ["max_health", "strength", "defense", "magic_defense", "dexterity", "intelligence", "speed", "move_range", "attack_range"]:
			var value := int((bonuses as Dictionary).get(key, 0))
			if value != 0:
				bonus_parts.append("%s %+d" % [String(labels.get(key, key)), value])
		if not bonus_parts.is_empty():
			lines.append(", ".join(bonus_parts))

	if item is WeaponData:
		var weapon := item as WeaponData
		lines.append("Weapon type: %s" % String(weapon.weapon_type))
		lines.append("MT %d | Hit %d" % [weapon.might, weapon.hit_rate])
		lines.append(_build_loop_merchant_weapon_owner_hint(weapon))

	return "\n".join(lines)

func _build_loop_merchant_weapon_owner_hint(weapon: WeaponData) -> String:
	if weapon == null:
		return ""
	match String(weapon.weapon_type):
		"Sword":
			return "Savannah can equip this."
		"Bow":
			return "Silas can equip this."
		"Staff", "Tome":
			return "Tera can equip this."
		_:
			return "Open the party menu to see who can equip this."

func _get_loop_merchant_tabs() -> PackedStringArray:
	return _get_active_loop_merchant_tabs()

func _get_loop_merchant_tab_detail_text(tab_id: String) -> String:
	if _loop_active_merchant_kind == LOOP_MERCHANT_KIND_NIGHT:
		match tab_id:
			"Sell":
				return "Night is a good time to cash in the harvest and prepare for morning."
			"Rare Seeds":
				return "The night trader carries unusual seeds that can open stronger meal paths."
			"Ingredients":
				return "A few hard-to-find cooking supplies show up here after dark."
			_:
				return "Browse the night stock before you sleep."
	match tab_id:
		"Sell":
			return "Turn harvested crops into Gold so you can restock seeds and buy stronger gear."
		"Seeds":
			return "Plant seeds before battle so crops can grow while you fight."
		"Weapons":
			return "Weapon upgrades improve your party's damage and accuracy. Check the detail panel to see who can equip each one."
		"Armor":
			return "Armor adds durability and utility stats that help your front line and back line survive longer."
		"Accessories":
			return "Accessories provide small but meaningful stat boosts that round out a build."
		_:
			return "Browse stock to preview what each purchase does before you commit."

func _set_loop_merchant_tab(tab_id: String) -> void:
	if not _get_active_loop_merchant_tabs().has(tab_id):
		return
	if _loop_merchant_active_tab == tab_id:
		return
	_loop_merchant_active_tab = tab_id
	_refresh_loop_merchant_menu()
	_focus_first_loop_merchant_action_button()

func _refresh_loop_merchant_tab_buttons() -> void:
	if _loop_merchant_tab_bar == null or not is_instance_valid(_loop_merchant_tab_bar):
		return
	for child in _loop_merchant_tab_bar.get_children():
		var button := child as Button
		if button == null:
			continue
		var active := button.text == _loop_merchant_active_tab
		button.toggle_mode = true
		button.button_pressed = active
		button.modulate = Color(1.0, 0.95, 0.76, 1.0) if active else Color(1.0, 1.0, 1.0, 0.92)

func _get_loop_merchant_default_detail_text() -> String:
	return _get_loop_merchant_tab_detail_text(_loop_merchant_active_tab)

func _populate_loop_merchant_sell_tab() -> void:
	var sell_button := Button.new()
	sell_button.text = "Sell Harvest"
	sell_button.pressed.connect(_on_loop_sell_harvest_pressed)
	sell_button.focus_entered.connect(func() -> void:
		_set_loop_merchant_detail_text("Turn harvested crops into Gold so you can restock seeds, meals, and better gear.")
	)
	sell_button.mouse_entered.connect(func() -> void:
		_set_loop_merchant_detail_text("Turn harvested crops into Gold so you can restock seeds, meals, and better gear.")
	)
	_loop_merchant_actions.add_child(sell_button)

func _populate_loop_merchant_seed_tab() -> void:
	var seed_shop := _get_active_loop_seed_shop()
	for seed_item_variant in seed_shop.keys():
		var seed_item: int = int(seed_item_variant)
		var offer: Dictionary = seed_shop[seed_item]
		var cost := int(offer.get("cost", 0))
		var affordable := Global.loop_gold >= cost
		var button := Button.new()
		button.text = "%s (%d Gold)%s" % [String(offer.get("label", "Seeds")), cost, "" if affordable else " [Need More Gold]"]
		button.modulate = Color(1, 1, 1, 1) if affordable else Color(0.8, 0.8, 0.8, 0.88)
		button.pressed.connect(_on_loop_buy_seed_pressed.bind(seed_item))
		var seed_description := _build_loop_merchant_seed_description(seed_item, cost)
		button.focus_entered.connect(_set_loop_merchant_detail_text.bind(seed_description))
		button.mouse_entered.connect(_set_loop_merchant_detail_text.bind(seed_description))
		_loop_merchant_actions.add_child(button)

func _populate_loop_night_vendor_ingredients_tab() -> void:
	for item_variant in LOOP_NIGHT_VENDOR_INGREDIENT_SHOP.keys():
		var item_type := int(item_variant)
		var offer: Dictionary = LOOP_NIGHT_VENDOR_INGREDIENT_SHOP[item_type]
		var cost := int(offer.get("cost", 0))
		var affordable := Global.loop_gold >= cost
		var button := Button.new()
		button.text = "%s (%d Gold)%s" % [
			String(offer.get("label", _format_loop_item_name(item_type))),
			cost,
			"" if affordable else " [Need More Gold]"
		]
		button.modulate = Color(1, 1, 1, 1) if affordable else Color(0.8, 0.8, 0.8, 0.88)
		button.pressed.connect(_on_loop_buy_inventory_item_pressed.bind(item_type, cost))
		var description := _build_loop_merchant_inventory_description(item_type, cost)
		button.focus_entered.connect(_set_loop_merchant_detail_text.bind(description))
		button.mouse_entered.connect(_set_loop_merchant_detail_text.bind(description))
		_loop_merchant_actions.add_child(button)

func _populate_loop_merchant_equipment_tab(slot_name: String) -> void:
	var unlocked_gear := _get_loop_merchant_equipment_offers()
	var slot_offers: Array[Dictionary] = []
	for offer_variant in unlocked_gear:
		var offer: Dictionary = offer_variant
		if String(offer.get("slot", "")) == slot_name:
			slot_offers.append(offer)

	if slot_offers.is_empty():
		var locked_label := Label.new()
		var slot_label := "accessories" if slot_name == "Accessory" else slot_name.to_lower()
		locked_label.text = "Clear more stages to unlock more %s." % slot_label
		locked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_loop_merchant_actions.add_child(locked_label)
		return

	for offer in slot_offers:
		var item: Resource = offer.get("item", null)
		if item == null:
			continue
		var owned_items: Array = ProgressionService.get_owned_equipment(String(offer.get("slot", ""))) if ProgressionService != null and ProgressionService.has_method("get_owned_equipment") else []
		var item_name := _get_equipment_display_name(item)
		var already_owned := owned_items.has(item)
		var cost := int(offer.get("cost", 0))
		var affordable := Global.loop_gold >= cost
		var button := Button.new()
		var state_suffix := ""
		if already_owned:
			state_suffix = " [Owned]"
		elif not affordable:
			state_suffix = " [Need More Gold]"
		button.text = "%s (%d Gold)%s" % [item_name, cost, state_suffix]
		button.modulate = Color(1, 1, 1, 1) if not already_owned and affordable else Color(0.8, 0.8, 0.8, 0.88)
		button.pressed.connect(_on_loop_buy_equipment_pressed.bind(item, cost))
		var gear_description := _build_loop_merchant_item_description(item, cost)
		button.focus_entered.connect(_set_loop_merchant_detail_text.bind(gear_description))
		button.mouse_entered.connect(_set_loop_merchant_detail_text.bind(gear_description))
		_loop_merchant_actions.add_child(button)

func _focus_first_loop_merchant_action_button() -> void:
	if _loop_merchant_actions == null or not is_instance_valid(_loop_merchant_actions):
		return
	for child in _loop_merchant_actions.get_children():
		if child is Button and (child as Button).visible and not (child as Button).disabled:
			(child as Button).grab_focus()
			return
	_focus_loop_merchant_tab_button(_loop_merchant_active_tab)

func _focus_loop_merchant_tab_button(tab_id: String) -> void:
	var button := _loop_merchant_tab_buttons.get(tab_id, null) as Button
	if button != null and is_instance_valid(button) and button.visible:
		button.grab_focus()

func _get_loop_merchant_action_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	if _loop_merchant_actions == null or not is_instance_valid(_loop_merchant_actions):
		return buttons
	for child in _loop_merchant_actions.get_children():
		var button := child as Button
		if button == null or not button.visible or button.disabled:
			continue
		buttons.append(button)
	return buttons

func _configure_loop_merchant_focus_graph() -> void:
	if _loop_merchant_tab_bar == null or not is_instance_valid(_loop_merchant_tab_bar):
		return

	var action_buttons := _get_loop_merchant_action_buttons()
	var active_tab_button := _loop_merchant_tab_buttons.get(_loop_merchant_active_tab, null) as Button
	var first_action: Button = action_buttons[0] if not action_buttons.is_empty() else null
	var last_action: Button = action_buttons[action_buttons.size() - 1] if not action_buttons.is_empty() else null

	var tab_buttons: Array[Button] = []
	for child in _loop_merchant_tab_bar.get_children():
		var tab_button := child as Button
		if tab_button == null:
			continue
		tab_buttons.append(tab_button)

	for index in range(tab_buttons.size()):
		var button := tab_buttons[index]
		var left_button := tab_buttons[maxi(index - 1, 0)]
		var right_button := tab_buttons[mini(index + 1, tab_buttons.size() - 1)]
		button.focus_neighbor_left = button.get_path_to(left_button)
		button.focus_neighbor_right = button.get_path_to(right_button)
		if first_action != null:
			button.focus_neighbor_bottom = button.get_path_to(first_action)
		elif _loop_merchant_close_button != null and is_instance_valid(_loop_merchant_close_button):
			button.focus_neighbor_bottom = button.get_path_to(_loop_merchant_close_button)
		else:
			button.focus_neighbor_bottom = NodePath("")

	if active_tab_button != null and is_instance_valid(active_tab_button):
		if first_action != null:
			active_tab_button.focus_neighbor_bottom = active_tab_button.get_path_to(first_action)
		elif _loop_merchant_close_button != null and is_instance_valid(_loop_merchant_close_button):
			active_tab_button.focus_neighbor_bottom = active_tab_button.get_path_to(_loop_merchant_close_button)
		else:
			active_tab_button.focus_neighbor_bottom = NodePath("")

	for index in range(action_buttons.size()):
		var action_button := action_buttons[index]
		var previous_button := action_buttons[maxi(index - 1, 0)]
		var next_button := action_buttons[mini(index + 1, action_buttons.size() - 1)]
		action_button.focus_neighbor_top = action_button.get_path_to(active_tab_button) if index == 0 and active_tab_button != null else action_button.get_path_to(previous_button)
		action_button.focus_neighbor_bottom = action_button.get_path_to(_loop_merchant_close_button) if index == action_buttons.size() - 1 and _loop_merchant_close_button != null else action_button.get_path_to(next_button)

	if _loop_merchant_close_button != null and is_instance_valid(_loop_merchant_close_button):
		if last_action != null:
			_loop_merchant_close_button.focus_neighbor_top = _loop_merchant_close_button.get_path_to(last_action)
		elif active_tab_button != null:
			_loop_merchant_close_button.focus_neighbor_top = _loop_merchant_close_button.get_path_to(active_tab_button)

func _cycle_loop_merchant_tab(direction: int) -> void:
	var tab_ids := _get_loop_merchant_tabs()
	if tab_ids.is_empty():
		return
	var current_index := tab_ids.find(_loop_merchant_active_tab)
	if current_index == -1:
		current_index = 0
	var next_index := posmod(current_index + direction, tab_ids.size())
	_set_loop_merchant_tab(String(tab_ids[next_index]))

func _can_switch_loop_merchant_tabs() -> bool:
	var now := Time.get_ticks_msec()
	if now < _loop_merchant_tab_switch_cooldown_until_msec:
		return false
	_loop_merchant_tab_switch_cooldown_until_msec = now + LOOP_MERCHANT_TAB_SWITCH_COOLDOWN_MS
	return true

func _get_loop_merchant_equipment_offers() -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	var current_stage := _get_loop_stage()
	for offer_variant in LOOP_MERCHANT_GEAR_OFFERS:
		var offer: Dictionary = offer_variant
		if int(offer.get("stage", 99)) <= current_stage:
			offers.append(offer)
	return offers

func _ready() -> void:
	var seed_menu = $CanvasLayer/SeedMenu
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

	_spawn_overworld_system_menu()

	if Global.loop_hub_mode_active:
		player.visible = false
		var color_rect := get_node_or_null("CanvasLayer/ColorRect") as ColorRect
		if color_rect != null:
			color_rect.modulate.a = 1.0
		call_deferred("_setup_loop_hub_mode")
		return

	_restore_intro_forest_day_time()
	if DemoDirector:
		if not DemoDirector.story_harvest_ready.is_connected(_on_story_harvest_ready):
			DemoDirector.story_harvest_ready.connect(_on_story_harvest_ready)
		if not DemoDirector.meal_eaten.is_connected(_on_demo_meal_eaten):
			DemoDirector.meal_eaten.connect(_on_demo_meal_eaten)
		if not Global.intro_sequence_complete and not Global.pending_intro_forest_return and not Global.pending_materials_forest_return:
			DemoDirector.set_stage(DemoDirector.DemoStage.INTRO)

	_ensure_story_setpieces()
	_sync_shelter_state()

	if Global.pending_materials_forest_return:
		Global.pending_materials_forest_return = false
		call_deferred("_resume_after_materials_forest_return")
	elif Global.intro_sequence_complete:
		_setup_story_camp_state()
	elif Global.pending_intro_forest_return:
		Global.pending_intro_forest_return = false
		call_deferred("_resume_intro_after_forest_return")
	else:
		call_deferred("_begin_intro_sequence")

func _setup_loop_hub_mode() -> void:
	_log_run_start("Loop hub setup begin")
	_intro_busy = false
	_intro_state = IntroState.INACTIVE
	Global.tutorial_enabled = false
	Global.intro_sequence_complete = false
	Global.pending_day_transition = false
	if story_markers != null:
		story_markers.visible = false
	if story_chest != null:
		story_chest.queue_free()
		story_chest = null
	if tera_actor != null:
		tera_actor.visible = true
		tera_actor.global_position = LOOP_ARRIVAL_TERA_REST_POS
		tera_actor.face_down()
		tera_actor.play_idle()
	if silas_actor != null:
		silas_actor.visible = false
	if _merchant_actor != null and is_instance_valid(_merchant_actor):
		_merchant_actor.queue_free()
	_merchant_actor = null
	if _loop_night_vendor_actor != null and is_instance_valid(_loop_night_vendor_actor):
		_loop_night_vendor_actor.queue_free()
	_loop_night_vendor_actor = null
	if _cabin_home != null and is_instance_valid(_cabin_home):
		_cabin_home.queue_free()
	_cabin_home = null

	player.can_move = true
	player.direction = Vector2.ZERO
	player.visible = not _should_play_loop_arrival_intro()
	player.global_position = LOOP_START_PLAYER_POS
	_sync_loop_campfire_state()

	$DayTimer.stop()
	$GrowTimer.start()
	$GrowTimer.wait_time = _grow_timer_cycle_seconds
	water_layer.clear()
	_restore_player_camera()
	_ensure_story_setpieces()
	_ensure_loop_plot_covers()
	_ensure_loop_merchant_nodes()
	_ensure_loop_hud()
	_ensure_loop_prompt()
	_spawn_loop_forest_content()
	_apply_pending_loop_save_if_needed()
	_sync_shelter_state()
	_refresh_loop_phase_presentation(true)
	_refresh_loop_plot_visuals()
	_refresh_loop_merchant_visuals()
	_refresh_loop_objective()
	_refresh_loop_hud()
	_prepare_loop_hub_entry_transition()
	var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
	if hud != null:
		hud.visible = false
	if not Global.inventory_updated.is_connected(_on_loop_state_ui_changed):
		Global.inventory_updated.connect(_on_loop_state_ui_changed)
	if not Global.loop_state_changed.is_connected(_on_loop_state_ui_changed):
		Global.loop_state_changed.connect(_on_loop_state_ui_changed)
	_log_run_start("Loop hub setup end")
	call_deferred("_play_loop_hub_entry_transition")

func _prepare_loop_hub_entry_transition() -> void:
	player.can_move = false
	_loop_hub_entry_uses_transition_handoff = false
	if TransitionManager != null and TransitionManager.has_method("has_active_scene_handoff"):
		_loop_hub_entry_uses_transition_handoff = TransitionManager.has_active_scene_handoff()
	var color_rect := get_node_or_null("CanvasLayer/ColorRect") as ColorRect
	if color_rect != null:
		color_rect.modulate.a = 0.0 if _loop_hub_entry_uses_transition_handoff else LOOP_HUB_ENTRY_FADE_ALPHA
	if _loop_hud_root != null and is_instance_valid(_loop_hud_root):
		_loop_hud_root.modulate.a = 0.0

func _play_loop_hub_entry_transition() -> void:
	var reveal_tween: Tween = null
	if _loop_hub_entry_uses_transition_handoff and TransitionManager != null and TransitionManager.has_method("finish_scene_handoff"):
		reveal_tween = TransitionManager.finish_scene_handoff(LOOP_HUB_ENTRY_FADE_DURATION, 0.0)
	else:
		var color_rect := get_node_or_null("CanvasLayer/ColorRect") as ColorRect
		reveal_tween = create_tween()
		if color_rect != null:
			reveal_tween.tween_property(color_rect, "modulate:a", 0.0, LOOP_HUB_ENTRY_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		else:
			reveal_tween.tween_interval(LOOP_HUB_ENTRY_FADE_DURATION)

	var hud_tween := create_tween()
	if _loop_hud_root != null and is_instance_valid(_loop_hud_root):
		hud_tween.tween_interval(LOOP_HUB_ENTRY_HUD_DELAY)
		hud_tween.tween_property(_loop_hud_root, "modulate:a", 1.0, LOOP_HUB_ENTRY_HUD_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
	if hud != null and "day_music" in hud and hud.day_music and MusicManager and MusicManager.has_method("crossfade_to"):
		var music_tween := create_tween()
		music_tween.tween_interval(LOOP_HUB_ENTRY_MUSIC_DELAY)
		music_tween.tween_callback(func():
			MusicManager.crossfade_to(hud.day_music, LOOP_HUB_ENTRY_MUSIC_FADE, -4.0)
		)

	if reveal_tween != null:
		await reveal_tween.finished
	if _should_play_loop_arrival_intro():
		call_deferred("_run_loop_arrival_intro")
		return
	player.can_move = true
	_log_run_start("Control returned")

func _ensure_loop_plot_covers() -> void:
	if _loop_plot_cover_root != null and is_instance_valid(_loop_plot_cover_root):
		return
	_loop_plot_cover_root = Node2D.new()
	_loop_plot_cover_root.name = "LoopPlotCovers"
	_loop_plot_cover_root.z_index = 4
	world_root.add_child(_loop_plot_cover_root)

	for plot_id_variant in LOOP_PLOT_DEFS.keys():
		var plot_id := StringName(plot_id_variant)
		if plot_id == LOOP_PLOT_STARTING_FARM:
			continue
		var rect: Rect2 = LOOP_PLOT_DEFS[plot_id].get("rect", Rect2())
		var cover := Polygon2D.new()
		cover.name = "%sCover" % String(plot_id)
		cover.color = Color(0.18, 0.15, 0.2, 0.82)
		cover.polygon = PackedVector2Array([
			rect.position,
			rect.position + Vector2(rect.size.x, 0),
			rect.position + rect.size,
			rect.position + Vector2(0, rect.size.y),
		])
		cover.z_index = 4
		_loop_plot_cover_root.add_child(cover)
		_loop_plot_cover_polygons[String(plot_id)] = cover

		var outline := Line2D.new()
		outline.name = "%sOutline" % String(plot_id)
		outline.width = 6.0
		outline.default_color = Color(0.72, 1.0, 0.72, 0.85)
		outline.closed = true
		outline.points = PackedVector2Array([
			rect.position,
			rect.position + Vector2(rect.size.x, 0),
			rect.position + rect.size,
			rect.position + Vector2(0, rect.size.y),
		])
		outline.visible = false
		outline.z_index = 5
		_loop_plot_cover_root.add_child(outline)
		_loop_plot_outline_lines[String(plot_id)] = outline

		var blocker_body := StaticBody2D.new()
		blocker_body.name = "%sBlocker" % String(plot_id)
		var blocker_shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		blocker_shape.shape = rectangle
		blocker_shape.position = rect.position + (rect.size * 0.5)
		blocker_body.add_child(blocker_shape)
		blocker_body.collision_layer = 1
		blocker_body.collision_mask = 0
		_loop_plot_cover_root.add_child(blocker_body)
		_loop_plot_cover_bodies[String(plot_id)] = blocker_body

func _ensure_loop_merchant_nodes() -> void:
	if (_loop_merchant_structure_naked == null or not is_instance_valid(_loop_merchant_structure_naked)) and _merchant_wagon_naked_scene != null:
		_loop_merchant_structure_naked = _merchant_wagon_naked_scene.instantiate() as StaticBody2D
		_loop_merchant_structure_naked.name = "MerchantStructureNaked"
		_loop_merchant_structure_naked.position = LOOP_MERCHANT_STRUCTURE_POS
		_loop_merchant_structure_naked.visible = false
		objects_root.add_child(_loop_merchant_structure_naked)

	if (_loop_merchant_structure_complete == null or not is_instance_valid(_loop_merchant_structure_complete)) and _merchant_wagon_complete_scene != null:
		_loop_merchant_structure_complete = _merchant_wagon_complete_scene.instantiate() as StaticBody2D
		_loop_merchant_structure_complete.name = "MerchantStructureComplete"
		_loop_merchant_structure_complete.position = LOOP_MERCHANT_STRUCTURE_POS
		_loop_merchant_structure_complete.visible = false
		objects_root.add_child(_loop_merchant_structure_complete)

	if (_merchant_actor == null or not is_instance_valid(_merchant_actor)) and _merchant_actor_scene != null:
		_merchant_actor = _merchant_actor_scene.instantiate() as Node2D
		_merchant_actor.name = "MerchantActor"
		_merchant_actor.position = LOOP_MERCHANT_NPC_POS
		_merchant_actor.z_index = 2
		_merchant_actor.visible = false
		objects_root.add_child(_merchant_actor)

	if (_loop_night_vendor_actor == null or not is_instance_valid(_loop_night_vendor_actor)) and _night_vendor_actor_scene != null:
		_loop_night_vendor_actor = _night_vendor_actor_scene.instantiate() as Node2D
		_loop_night_vendor_actor.name = "NightVendorActor"
		_loop_night_vendor_actor.position = LOOP_NIGHT_VENDOR_POS
		_loop_night_vendor_actor.z_index = 3
		_loop_night_vendor_actor.visible = false
		objects_root.add_child(_loop_night_vendor_actor)

func _ensure_loop_hud() -> void:
	if _loop_hud_root != null and is_instance_valid(_loop_hud_root):
		return
	var canvas_layer := get_node_or_null("CanvasLayer")
	if canvas_layer == null:
		return

	var panel := PanelContainer.new()
	panel.name = "LoopHud"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -280
	panel.offset_right = 280
	panel.offset_top = 16
	panel.offset_bottom = 88
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.08, 0.92)
	style.border_color = Color(0.72, 0.86, 0.7, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)

	_loop_hud_stats_label = Label.new()
	_loop_hud_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loop_hud_stats_label.add_theme_font_size_override("font_size", 22)
	layout.add_child(_loop_hud_stats_label)

	_loop_hud_perk_label = Label.new()
	_loop_hud_perk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loop_hud_perk_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_loop_hud_perk_label)

	canvas_layer.add_child(panel)
	_loop_hud_root = panel

func _ensure_loop_prompt() -> void:
	if _loop_prompt_root != null and is_instance_valid(_loop_prompt_root):
		return
	var canvas_layer := get_node_or_null("CanvasLayer")
	if canvas_layer == null:
		return

	var panel := PanelContainer.new()
	panel.name = "LoopInteractionPrompt"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.07, 0.94)
	style.border_color = Color(0.84, 0.92, 0.7, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	margin.add_child(label)

	canvas_layer.add_child(panel)
	_loop_prompt_root = panel
	_loop_prompt_label = label

func _on_loop_state_ui_changed() -> void:
	_refresh_loop_merchant_menu()
	_refresh_loop_objective()
	_refresh_loop_hud()
	call_deferred("_refresh_loop_world_state_from_global")

func _refresh_loop_world_state_from_global() -> void:
	_sync_shelter_state()
	_refresh_loop_phase_presentation()
	_refresh_loop_merchant_visuals()

func _build_loop_merchant_menu() -> void:
	var canvas_layer := get_node_or_null("CanvasLayer")
	if canvas_layer == null:
		return

	var panel := PanelContainer.new()
	panel.name = "LoopMerchantMenu"
	panel.visible = false
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -460
	panel.offset_right = 460
	panel.offset_top = -270
	panel.offset_bottom = 270
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.78, 0.72, 0.54, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var root_row := HBoxContainer.new()
	root_row.add_theme_constant_override("separation", 14)
	margin.add_child(root_row)

	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 10)
	root_row.add_child(left_column)

	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(300, 0)
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color(0.11, 0.12, 0.16, 0.98)
	detail_style.border_width_left = 2
	detail_style.border_width_top = 2
	detail_style.border_width_right = 2
	detail_style.border_width_bottom = 2
	detail_style.border_color = Color(0.62, 0.76, 0.68, 0.9)
	detail_style.corner_radius_top_left = 10
	detail_style.corner_radius_top_right = 10
	detail_style.corner_radius_bottom_left = 10
	detail_style.corner_radius_bottom_right = 10
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	root_row.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 14)
	detail_margin.add_theme_constant_override("margin_right", 14)
	detail_margin.add_theme_constant_override("margin_top", 12)
	detail_margin.add_theme_constant_override("margin_bottom", 12)
	detail_panel.add_child(detail_margin)

	var detail_layout := VBoxContainer.new()
	detail_layout.add_theme_constant_override("separation", 8)
	detail_margin.add_child(detail_layout)

	_loop_merchant_title_label = Label.new()
	_loop_merchant_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loop_merchant_title_label.add_theme_font_size_override("font_size", 24)
	left_column.add_child(_loop_merchant_title_label)

	_loop_merchant_status = Label.new()
	_loop_merchant_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loop_merchant_status.add_theme_font_size_override("font_size", 18)
	left_column.add_child(_loop_merchant_status)

	_loop_merchant_tab_bar = HBoxContainer.new()
	_loop_merchant_tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_loop_merchant_tab_bar.add_theme_constant_override("separation", 8)
	left_column.add_child(_loop_merchant_tab_bar)
	_loop_merchant_detail_label = Label.new()
	_loop_merchant_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loop_merchant_detail_label.custom_minimum_size = Vector2(0, 220)
	_loop_merchant_detail_label.add_theme_font_size_override("font_size", 17)
	_loop_merchant_detail_label.modulate = Color(0.94, 0.96, 0.88, 0.96)
	detail_layout.add_child(_loop_merchant_detail_label)

	var detail_title := Label.new()
	detail_title.text = "Details"
	detail_title.add_theme_font_size_override("font_size", 20)
	detail_layout.add_child(detail_title)
	detail_layout.move_child(detail_title, 0)

	_loop_merchant_action_scroll = ScrollContainer.new()
	_loop_merchant_action_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_loop_merchant_action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_loop_merchant_action_scroll.custom_minimum_size = Vector2(0, 300)
	_loop_merchant_action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_column.add_child(_loop_merchant_action_scroll)

	_loop_merchant_actions = VBoxContainer.new()
	_loop_merchant_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_loop_merchant_actions.add_theme_constant_override("separation", 6)
	_loop_merchant_action_scroll.add_child(_loop_merchant_actions)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.focus_entered.connect(func() -> void:
		_set_loop_merchant_detail_text(_get_loop_merchant_default_detail_text())
	)
	close_button.pressed.connect(_close_loop_merchant_menu)
	left_column.add_child(close_button)
	_loop_merchant_close_button = close_button

	var close_hint := Label.new()
	close_hint.text = "Press Cancel to close"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_column.add_child(close_hint)

	canvas_layer.add_child(panel)
	_loop_merchant_menu = panel
	_refresh_loop_merchant_menu()

func _rebuild_loop_merchant_tab_bar() -> void:
	if _loop_merchant_tab_bar == null or not is_instance_valid(_loop_merchant_tab_bar):
		return
	for child in _loop_merchant_tab_bar.get_children():
		_loop_merchant_tab_bar.remove_child(child)
		child.queue_free()
	_loop_merchant_tab_buttons.clear()
	var active_tabs := _get_active_loop_merchant_tabs()
	if not active_tabs.has(_loop_merchant_active_tab):
		_loop_merchant_active_tab = String(active_tabs[0]) if not active_tabs.is_empty() else ""
	for tab_id_variant in active_tabs:
		var tab_id := String(tab_id_variant)
		var tab_button := Button.new()
		tab_button.text = tab_id
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_button.pressed.connect(_set_loop_merchant_tab.bind(tab_id))
		tab_button.focus_entered.connect(_set_loop_merchant_detail_text.bind(_get_loop_merchant_tab_detail_text(tab_id)))
		tab_button.mouse_entered.connect(_set_loop_merchant_detail_text.bind(_get_loop_merchant_tab_detail_text(tab_id)))
		_loop_merchant_tab_bar.add_child(tab_button)
		_loop_merchant_tab_buttons[tab_id] = tab_button

func _refresh_loop_merchant_menu() -> void:
	if _loop_merchant_menu == null or not is_instance_valid(_loop_merchant_menu):
		return
	if _loop_merchant_status == null or _loop_merchant_actions == null:
		return
	if _loop_merchant_title_label != null and is_instance_valid(_loop_merchant_title_label):
		_loop_merchant_title_label.text = "Night Trader" if _loop_active_merchant_kind == LOOP_MERCHANT_KIND_NIGHT else "Merchant Wagon"
	_rebuild_loop_merchant_tab_bar()

	var current_stage := _get_loop_stage()
	_loop_merchant_status.text = "Stage %d/%d   Gold: %d   Bloom Points: %d\nWood: %d   Stone: %d   Perk: %s" % [
		current_stage,
		LOOP_MAX_FOREST_STAGE,
		Global.loop_gold,
		Global.loop_bloom_points,
		int(Global.inventory.get(Global.Items.WOOD, 0)),
		int(Global.inventory.get(Global.Items.STONE, 0)),
		Global.get_loop_equipped_perk_label()
	]
	_refresh_loop_merchant_tab_buttons()
	_set_loop_merchant_detail_text(_get_loop_merchant_default_detail_text())

	for child in _loop_merchant_actions.get_children():
		_loop_merchant_actions.remove_child(child)
		child.queue_free()

	match _loop_merchant_active_tab:
		"Sell":
			_populate_loop_merchant_sell_tab()
		"Seeds", "Rare Seeds":
			_populate_loop_merchant_seed_tab()
		"Ingredients":
			_populate_loop_night_vendor_ingredients_tab()
		"Weapons":
			_populate_loop_merchant_equipment_tab("Weapon")
		"Armor":
			_populate_loop_merchant_equipment_tab("Armor")
		"Accessories":
			_populate_loop_merchant_equipment_tab("Accessory")
		_:
			_populate_loop_merchant_seed_tab()

	_configure_loop_merchant_focus_graph()

func _spawn_loop_forest_content() -> void:
	for node in _loop_spawned_forest_nodes:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_loop_spawned_forest_nodes.clear()

	if not Global.has_loop_plot(LOOP_PLOT_FOREST):
		if silas_actor != null:
			silas_actor.visible = false
		return

	for tree_pos_variant in LOOP_FOREST_TREE_POSITIONS:
		var tree_pos: Vector2 = tree_pos_variant
		var tree = preload("res://scenes/level/tree.tscn").instantiate() as Node2D
		tree.position = tree_pos
		objects_root.add_child(tree)
		_loop_spawned_forest_nodes.append(tree)

	if silas_actor != null:
		silas_actor.visible = true
		silas_actor.global_position = LOOP_FOREST_SILAS_POS
		silas_actor.y_sort_enabled = true
		silas_actor.z_index = 0
		silas_actor.face_side(false)
		silas_actor.play_idle()

func _refresh_loop_plot_visuals() -> void:
	for plot_id_variant in LOOP_PLOT_DEFS.keys():
		var plot_id := String(plot_id_variant)
		if plot_id == String(LOOP_PLOT_STARTING_FARM):
			continue
		var unlocked := Global.has_loop_plot(StringName(plot_id))
		var cover = _loop_plot_cover_polygons.get(plot_id, null)
		if cover != null and is_instance_valid(cover):
			cover.visible = not unlocked
		var body = _loop_plot_cover_bodies.get(plot_id, null)
		if body != null and is_instance_valid(body):
			body.visible = not unlocked
			for child in body.get_children():
				if child is CollisionShape2D:
					(child as CollisionShape2D).disabled = unlocked

func _refresh_loop_merchant_visuals() -> void:
	var merchant_unlocked := Global.has_loop_plot(LOOP_PLOT_MERCHANT)
	var merchant_built := Global.is_loop_structure_built(Global.LOOP_STRUCTURE_MERCHANT_WAGON)
	var night_vendor_visible := _is_loop_night_vendor_available()
	if _loop_merchant_structure_naked != null and is_instance_valid(_loop_merchant_structure_naked):
		_loop_merchant_structure_naked.visible = merchant_unlocked and not merchant_built
		_set_structure_collision_state_deferred(_loop_merchant_structure_naked, merchant_unlocked and not merchant_built)
	if _loop_merchant_structure_complete != null and is_instance_valid(_loop_merchant_structure_complete):
		_loop_merchant_structure_complete.visible = merchant_unlocked and merchant_built
		_set_structure_collision_state_deferred(_loop_merchant_structure_complete, merchant_unlocked and merchant_built)
	if _merchant_actor != null and is_instance_valid(_merchant_actor):
		_merchant_actor.global_position = LOOP_MERCHANT_NPC_POS
		_merchant_actor.z_index = 2
		_merchant_actor.visible = merchant_unlocked and merchant_built
		_merchant_actor.modulate = Color.WHITE
		if _merchant_actor.visible and _merchant_actor.has_method("face_side"):
			_merchant_actor.face_side(true)
		if _merchant_actor.visible and _merchant_actor.has_method("play_idle"):
			_merchant_actor.play_idle()
	if _loop_night_vendor_actor != null and is_instance_valid(_loop_night_vendor_actor):
		_loop_night_vendor_actor.global_position = LOOP_NIGHT_VENDOR_POS
		_loop_night_vendor_actor.z_index = 3
		_loop_night_vendor_actor.visible = night_vendor_visible
		_loop_night_vendor_actor.modulate = Color(0.88, 0.94, 1.0, 1.0)
		if _loop_night_vendor_actor.visible and _loop_night_vendor_actor.has_method("face_side"):
			_loop_night_vendor_actor.face_side(false)
		if _loop_night_vendor_actor.visible and _loop_night_vendor_actor.has_method("play_idle"):
			_loop_night_vendor_actor.play_idle()
	_refresh_loop_merchant_menu()

func _refresh_loop_hud() -> void:
	if _loop_hud_root == null or not is_instance_valid(_loop_hud_root):
		return
	if _loop_hud_stats_label != null:
		_loop_hud_stats_label.text = "BP %d    Gold %d    Wood %d    Stone %d" % [
			Global.loop_bloom_points,
			Global.loop_gold,
			int(Global.inventory.get(Global.Items.WOOD, 0)),
			int(Global.inventory.get(Global.Items.STONE, 0))
		]
	if _loop_hud_perk_label != null:
		var phase_label := "Night" if _is_loop_night() else "Day"
		_loop_hud_perk_label.text = "%s Phase   Next Battle Perk: %s" % [phase_label, Global.get_loop_equipped_perk_label()]

func _get_loop_wood_count() -> int:
	return int(Global.inventory.get(Global.Items.WOOD, 0))

func _refresh_loop_objective() -> void:
	var forest_open := Global.has_loop_plot(LOOP_PLOT_FOREST)
	var merchant_open := Global.has_loop_plot(LOOP_PLOT_MERCHANT)
	var merchant_built := Global.is_loop_structure_built(Global.LOOP_STRUCTURE_MERCHANT_WAGON)
	var cabin_repaired := _is_loop_cabin_repaired()
	var ready_crops := _has_ready_loop_crops()
	var wood_count := _get_loop_wood_count()
	var objective := LOOP_OBJECTIVE_FIGHT

	if _is_loop_night():
		if not forest_open:
			objective = "Night: unlock the forest with Bloom Points"
		elif not cabin_repaired and wood_count < LOOP_CABIN_REPAIR_WOOD_COST:
			objective = "Night: gather wood, repair the cabin, then sleep"
		elif not cabin_repaired:
			objective = "Night: repair the cabin, then sleep"
		elif ready_crops:
			objective = LOOP_OBJECTIVE_NIGHT
		else:
			objective = LOOP_OBJECTIVE_SETTLE
	else:
		if not _has_any_loop_crops():
			objective = LOOP_OBJECTIVE_PLANT
		elif ready_crops:
			objective = LOOP_OBJECTIVE_HARVEST
		elif not forest_open:
			objective = LOOP_OBJECTIVE_FIGHT if Global.loop_bloom_points < int(LOOP_PLOT_DEFS[LOOP_PLOT_FOREST].get("unlock_cost", 0)) else LOOP_OBJECTIVE_FOREST
		elif not cabin_repaired and wood_count < LOOP_CABIN_REPAIR_WOOD_COST:
			objective = LOOP_OBJECTIVE_CABIN
		elif not cabin_repaired:
			objective = LOOP_OBJECTIVE_REPAIR
		elif not merchant_open:
			objective = LOOP_OBJECTIVE_FIGHT if Global.loop_bloom_points < int(LOOP_PLOT_DEFS[LOOP_PLOT_MERCHANT].get("unlock_cost", 0)) else LOOP_OBJECTIVE_MERCHANT
		elif merchant_open and not merchant_built:
			objective = "Build Wagon" if wood_count >= LOOP_MERCHANT_BUILD_WOOD_COST else "Gather Wood for Wagon"
		else:
			objective = LOOP_OBJECTIVE_FIGHT
	Global.show_tutorial_text(objective)

func _has_any_loop_crops() -> bool:
	for plant in get_tree().get_nodes_in_group("Plants"):
		if is_instance_valid(plant):
			return true
	return false

func _has_ready_loop_crops() -> bool:
	for plant in get_tree().get_nodes_in_group("Plants"):
		if not is_instance_valid(plant):
			continue
		if plant.has_method("is_ready_to_harvest") and plant.is_ready_to_harvest():
			return true
	return false

func _maybe_show_loop_planting_tutorial(seed_menu: Control, screen_pos: Vector2) -> bool:
	if not Global.loop_hub_mode_active or DemoDirector == null:
		return false
	if DemoDirector.has_seen_tutorial("loop_planting"):
		return false
	_loop_plant_tutorial_active = true
	player.can_move = false
	call_deferred("_show_loop_planting_tutorial_then_open_seed_menu", seed_menu, screen_pos)
	return true

func _show_loop_planting_tutorial_then_open_seed_menu(seed_menu: Control, screen_pos: Vector2) -> void:
	if DemoDirector != null:
		await DemoDirector.show_tutorial_card("loop_planting", self)
	_loop_plant_tutorial_active = false
	if seed_menu != null and is_instance_valid(seed_menu):
		player.can_move = false
		seed_menu.open(screen_pos)
	else:
		player.can_move = true

func _maybe_show_loop_planting_tutorial_auto() -> void:
	if not Global.loop_hub_mode_active or DemoDirector == null:
		return
	if _loop_plant_tutorial_active or DemoDirector.has_seen_tutorial("loop_planting"):
		return
	if _loop_battle_launch_pending or not player.can_move:
		return
	if not is_tilled_soil_at(player.global_position):
		return

	_loop_plant_tutorial_active = true
	player.can_move = false
	call_deferred("_show_loop_planting_tutorial_auto_card")

func _show_loop_planting_tutorial_auto_card() -> void:
	if DemoDirector != null:
		await DemoDirector.show_tutorial_card("loop_planting", self)
	player.can_move = true
	_loop_plant_tutorial_active = false

func _maybe_show_loop_battle_tutorial_after_planting() -> void:
	if not Global.loop_hub_mode_active or DemoDirector == null:
		return
	if _loop_battle_tutorial_active or DemoDirector.has_seen_tutorial("loop_battle"):
		return
	_loop_battle_tutorial_active = true
	player.can_move = false
	call_deferred("_show_loop_battle_tutorial_after_planting_card")

func _show_loop_battle_tutorial_after_planting_card() -> void:
	if DemoDirector != null:
		await DemoDirector.show_tutorial_card("loop_battle", self)
	_loop_battle_tutorial_active = false
	player.can_move = true

func _maybe_show_loop_bloom_points_tutorial() -> void:
	if not Global.loop_hub_mode_active or DemoDirector == null:
		return
	if _loop_bloom_points_tutorial_active or DemoDirector.has_seen_tutorial("loop_bloom_points"):
		return
	_loop_bloom_points_tutorial_active = true
	player.can_move = false
	await DemoDirector.show_tutorial_card("loop_bloom_points", self)
	_loop_bloom_points_tutorial_active = false
	player.can_move = true

func _maybe_show_loop_first_night_tutorial() -> void:
	if not Global.loop_hub_mode_active or DemoDirector == null:
		return
	if _loop_night_tutorial_active or DemoDirector.has_seen_tutorial("loop_first_night"):
		return
	_loop_night_tutorial_active = true
	player.can_move = false
	await DemoDirector.show_tutorial_card("loop_first_night", self)
	_loop_night_tutorial_active = false
	player.can_move = true

func _maybe_show_loop_sleep_tutorial() -> void:
	if not Global.loop_hub_mode_active or DemoDirector == null:
		return
	if _loop_sleep_tutorial_active or DemoDirector.has_seen_tutorial("loop_sleep"):
		return
	_loop_sleep_tutorial_active = true
	player.can_move = false
	await DemoDirector.show_tutorial_card("loop_sleep", self)
	_loop_sleep_tutorial_active = false
	player.can_move = true

func _maybe_show_loop_forest_unlock_tutorials() -> void:
	if not Global.loop_hub_mode_active or DemoDirector == null:
		return
	if _loop_forest_tutorial_active:
		return
	if DemoDirector.has_seen_tutorial("loop_forest_join") and DemoDirector.has_seen_tutorial("loop_forest_wood"):
		return
	_loop_forest_tutorial_active = true
	player.can_move = false
	call_deferred("_show_loop_forest_unlock_tutorials")

func _show_loop_forest_unlock_tutorials() -> void:
	if DemoDirector != null and not DemoDirector.has_seen_tutorial("loop_forest_join"):
		await DemoDirector.show_tutorial_card("loop_forest_join", self)
	if DemoDirector != null and not DemoDirector.has_seen_tutorial("loop_forest_wood"):
		await DemoDirector.show_tutorial_card("loop_forest_wood", self)
	_loop_forest_tutorial_active = false
	player.can_move = true

func _on_loop_crop_harvested(_harvested_item: int) -> void:
	_autosave_loop_run()
	if not Global.loop_hub_mode_active or DemoDirector == null:
		return
	if _loop_cooking_tutorial_active or DemoDirector.has_seen_tutorial("loop_cooking"):
		return
	_loop_cooking_tutorial_active = true
	player.can_move = false
	await DemoDirector.show_tutorial_card("loop_cooking", self)
	_loop_cooking_tutorial_active = false
	player.can_move = true

func _restore_intro_forest_day_time() -> void:
	if Global.intro_forest_day_time_left <= 0.0:
		return

	var restored_time_left := clampf(Global.intro_forest_day_time_left, 1.0, _day_timer_cycle_seconds)
	$DayTimer.start(restored_time_left)
	$DayTimer.wait_time = _day_timer_cycle_seconds
	Global.intro_forest_day_time_left = 0.0

	var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
	if hud and hud.has_method("_update_view"):
		hud._update_view(true)

func _ensure_story_setpieces() -> void:
	if _camera_fx == null or not is_instance_valid(_camera_fx):
		_camera_fx = OverworldCameraFx.new()
		_camera_fx.name = "OverworldCameraFx"
		add_child(_camera_fx)

	if (_cabin_home == null or not is_instance_valid(_cabin_home)) and _cabin_home_scene != null:
		_cabin_home = _cabin_home_scene.instantiate() as Node2D
		_cabin_home.name = "CabinHome"
		objects_root.add_child(_cabin_home)
		_cabin_home.global_position = _get_active_cabin_home_pos()

	if (_merchant_actor == null or not is_instance_valid(_merchant_actor)) and _merchant_actor_scene != null:
		_merchant_actor = _merchant_actor_scene.instantiate() as Node2D
		_merchant_actor.name = "MerchantActor"
		_merchant_actor.visible = false
		objects_root.add_child(_merchant_actor)

func _sync_shelter_state() -> void:
	var cabin_built := Global.demo_cabin_built
	if Global.loop_hub_mode_active:
		cabin_built = _is_loop_cabin_repaired()
	var ruin_visible := not cabin_built
	if ruin_body_top != null:
		ruin_body_top.visible = ruin_visible
		_set_body_collision_shapes_deferred(ruin_body_top, not ruin_visible)
	if ruin_body_bottom != null:
		ruin_body_bottom.visible = ruin_visible
		_set_body_collision_shapes_deferred(ruin_body_bottom, not ruin_visible)
	if ruin_sprite_elements_1 != null:
		ruin_sprite_elements_1.visible = ruin_visible
	if ruin_sprite_elements_2 != null:
		ruin_sprite_elements_2.visible = ruin_visible
	if ruin_sprite_elements_0 != null:
		ruin_sprite_elements_0.visible = ruin_visible
	if _cabin_home != null and is_instance_valid(_cabin_home) and _cabin_home.has_method("set_built"):
		_cabin_home.global_position = _get_active_cabin_home_pos()
		_cabin_home.call_deferred("set_built", cabin_built)
	_sync_loop_campfire_state()

func spawn_overworld_burst(
	global_position_value: Vector2,
	texture: Texture2D,
	frame_size: Vector2i,
	frame_count: int,
	fps: float = 16.0,
	scale_value: Vector2 = Vector2.ONE
) -> void:
	if _overworld_burst_scene == null:
		return
	var burst = _overworld_burst_scene.instantiate()
	objects_root.add_child(burst)
	if burst is Node2D:
		var burst_node := burst as Node2D
		burst_node.top_level = true
		burst_node.z_as_relative = false
		burst_node.z_index = 250
	burst.global_position = global_position_value
	if burst.has_method("configure"):
		burst.configure(texture, frame_size, frame_count, fps, scale_value)
	if burst.has_method("play_now"):
		burst.play_now()

func play_overworld_camera_shake(intensity: float = 4.0, duration: float = 0.16) -> void:
	if _camera_fx == null or not is_instance_valid(_camera_fx):
		return
	var active_camera: Camera2D = player_camera if player_camera != null and player_camera.is_current() else cutscene_camera
	_camera_fx.play_shake(active_camera, intensity, duration)

func show_world_pickup_popup(item_type: int, amount: int = 1, world_anchor: Variant = null) -> void:
	var canvas_layer := get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas_layer == null or WORLD_PICKUP_POPUP_SCRIPT == null:
		return

	var anchor_position: Vector2 = player.global_position if player != null and is_instance_valid(player) else Vector2.ZERO
	if world_anchor is Vector2:
		anchor_position = world_anchor

	var popup := WORLD_PICKUP_POPUP_SCRIPT.new()
	if popup == null:
		return
	canvas_layer.add_child(popup)
	if popup.has_method("setup"):
		popup.setup(item_type, amount)
	var screen_anchor := (get_viewport().get_canvas_transform() * anchor_position) + Vector2(0, -54)
	if popup.has_method("play_at"):
		popup.play_at(screen_anchor)

func _play_one_shot_world_sfx(stream: AudioStream, at_position: Vector2) -> void:
	if stream == null:
		return
	var player_sfx := AudioStreamPlayer2D.new()
	player_sfx.stream = stream
	player_sfx.global_position = at_position
	add_child(player_sfx)
	player_sfx.finished.connect(player_sfx.queue_free)
	player_sfx.play()

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
	if Global.loop_hub_mode_active:
		_refresh_loop_phase_presentation()
		_update_loop_interaction_ui()
		_maybe_show_loop_planting_tutorial_auto()
		return

	var daytime_point: float = 1.0 - ($DayTimer.time_left / _day_timer_cycle_seconds)
	$CanvasModulate.color = daytime_gradient.sample(daytime_point)

	_process_intro_progress()

	if Global.intro_sequence_complete and _can_skip_day() and Input.is_action_just_pressed("time_skip"):
		if Global.tutorial_step == 8:
			Global.advance_tutorial()
		request_end_day()

func _can_skip_day() -> bool:
	if Global.loop_hub_mode_active:
		return false
	if DemoDirector and DemoDirector.is_demo_active():
		if DemoDirector.current_stage == DemoDirector.DemoStage.CABIN_COMPLETE:
			return true
		if DemoDirector.current_stage != DemoDirector.DemoStage.DEMO_COMPLETE:
			return false
	return true

func _on_player_tool_use(tool: Global.Tools, global_pos: Vector2) -> void:
	if Global.loop_hub_mode_active and tool != Global.Tools.AXE:
		return
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
		var player_ground_y: float = global_pos.y
		if player != null:
			player_ground_y = player.global_position.y
		for tree in get_tree().get_nodes_in_group("Trees"):
			if not tree.has_method("get_interaction_anchor_global_position"):
				continue
			if absf(tree.global_position.y - player_ground_y) > 48.0:
				continue
			var interaction_anchor: Vector2 = tree.get_interaction_anchor_global_position()
			if interaction_anchor.distance_squared_to(global_pos) < 2025.0:
				tree.hit()
				break

func _on_player_menu_requested(target_pos: Vector2) -> void:
	var adjusted_pos = target_pos + Vector2(0, 24)
	var planting_layer := _get_active_planting_layer()
	if planting_layer == null:
		return
	var local_pos = planting_layer.to_local(adjusted_pos)
	var grid_pos = planting_layer.local_to_map(local_pos)
	var seed_menu = $CanvasLayer/SeedMenu

	if planting_layer.get_cell_source_id(grid_pos) != -1:
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
		if _maybe_show_loop_planting_tutorial(seed_menu, screen_pos):
			return
		seed_menu.open(screen_pos)
	else:
		_show_player_notice("Need plowed soil" if Global.loop_hub_mode_active else "Need tilled soil")

func is_tilled_soil_at(global_pos: Vector2) -> bool:
	var adjusted_pos = global_pos + Vector2(0, 24)
	var planting_layer := _get_active_planting_layer()
	if planting_layer == null:
		return false
	var local_pos = planting_layer.to_local(adjusted_pos)
	var grid_pos = planting_layer.local_to_map(local_pos)
	return planting_layer.get_cell_source_id(grid_pos) != -1

func _on_seed_chosen_from_menu(seed_type: int) -> void:
	player.can_move = true

	var planted_plant := _on_player_seed_use(seed_type, pending_plant_pos)
	if planted_plant == null:
		return

	if Global.tutorial_step == 5:
		Global.advance_tutorial()
	if not Global.remove_item(seed_type, 1):
		return
	_register_intro_plant(seed_type, planted_plant)
	if Global.loop_hub_mode_active:
		_refresh_loop_objective()
		_maybe_show_loop_battle_tutorial_after_planting()
		_autosave_loop_run()

func _on_player_seed_use(seed_enum: int, global_pos: Vector2) -> StaticBody2D:
	var season := CalendarService.get_current_season()
	if not Global.is_seed_in_season(seed_enum, season):
		_show_player_notice("That seed is out of season")
		return null

	var planting_layer := _get_active_planting_layer()
	if planting_layer == null:
		return null
	var local_pos = planting_layer.to_local(global_pos)
	var grid_pos = planting_layer.local_to_map(local_pos)

	for plant in get_tree().get_nodes_in_group("Plants"):
		if plant.grid_pos == grid_pos:
			_show_player_notice("That tile is occupied")
			return null

	if planting_layer.get_cell_source_id(grid_pos) == -1:
		return null

	var plant_pos = planting_layer.map_to_local(grid_pos)
	plant_pos.y -= 8
	var plant = plant_scene.instantiate() as StaticBody2D
	plant.setup(seed_enum, grid_pos)
	$Objects.add_child(plant)
	plant.position = plant_pos
	return plant

func request_end_day() -> void:
	if Global.pending_day_transition:
		return
	if DemoDirector and DemoDirector.current_stage == DemoDirector.DemoStage.CABIN_COMPLETE:
		call_deferred("_run_cabin_sleep_sequence")
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
		if Global.loop_hub_mode_active:
			if plant.has_method("advance_growth"):
				plant.advance_growth()
			else:
				plant.grow(true)
			continue
		var is_watered = water_layer.get_cell_source_id(plant.grid_pos) != -1
		plant.grow(is_watered)

func _unhandled_input(event: InputEvent) -> void:
	if not Global.loop_hub_mode_active:
		return
	if _loop_merchant_menu != null and is_instance_valid(_loop_merchant_menu) and _loop_merchant_menu.visible:
		if event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
			_close_loop_merchant_menu()
			get_viewport().set_input_as_handled()
		return
	if not player.can_move:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if _try_handle_loop_plot_interaction():
			get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not Global.loop_hub_mode_active:
		return
	if _loop_merchant_menu == null or not is_instance_valid(_loop_merchant_menu) or not _loop_merchant_menu.visible:
		return
	if event.is_action_pressed("tool_backward") and _can_switch_loop_merchant_tabs():
		_cycle_loop_merchant_tab(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("tool_forward") and _can_switch_loop_merchant_tabs():
		_cycle_loop_merchant_tab(1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
		_close_loop_merchant_menu()
		get_viewport().set_input_as_handled()

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
		{"speaker": "Savannah", "text": "The roof is mostly holes and the walls are rot, but it'll keep the wind off us for one night. That's more than we've had."},
		{"speaker": "Tera", "text": "If they left in a hurry, they might've left gear behind. Let's check the house."}
	], [player, tera_actor, story_chest], CUTSCENE_GROUP_ZOOM)

	_intro_state = IntroState.OPEN_CHEST
	_intro_busy = false
	player.can_move = true
	_restore_player_camera()
	if story_chest != null and is_instance_valid(story_chest) and bool(story_chest.get("is_open")):
		call_deferred("_run_post_chest_sequence")
	elif DemoDirector:
		DemoDirector.show_context_prompt("farm_open_chest")

func can_open_chest(chest: Node) -> bool:
	if chest != story_chest:
		return true
	if Global.intro_sequence_complete:
		return true
	return _intro_state == IntroState.OPEN_CHEST

func get_chest_locked_message(chest: Node) -> String:
	if chest == story_chest and not Global.intro_sequence_complete and _intro_state != IntroState.OPEN_CHEST:
		return "Tera wanted to check the house together first."
	return ""

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
		{"speaker": "Savannah", "text": "And we need 'em fast. Sun's going down. Let's head into the forest before it gets too dark."}
	], [player, tera_actor, story_chest], CUTSCENE_GROUP_ZOOM)

	_intro_state = IntroState.SEARCH_FOREST
	_intro_busy = false
	if DemoDirector:
		DemoDirector.show_context_prompt("farm_search_forest")
	await _show_forest_edge_camera_hint()

func _on_forest_exit_trigger_body_entered(body: Node) -> void:
	if body != player:
		return
	if _intro_busy:
		return
	if _intro_state == IntroState.SEARCH_FOREST:
		if _forest_encounter_started:
			return
		_forest_encounter_started = true
		call_deferred("_enter_intro_forest")
		return
	if DemoDirector and DemoDirector.current_stage == DemoDirector.DemoStage.GATHER_MATERIALS and not _materials_run_started:
		_materials_run_started = true
		call_deferred("_enter_materials_forest")

func _enter_materials_forest() -> void:
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO
	Global.pending_materials_forest_visit = true
	Global.intro_forest_day_time_left = $DayTimer.time_left
	TransitionManager.change_scene_path(_forest_scene_path, 0.45)

func _enter_intro_forest() -> void:
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO
	Global.pending_intro_forest_visit = true
	Global.intro_forest_day_time_left = $DayTimer.time_left
	TransitionManager.change_scene_path(_forest_scene_path, 0.45)

func _resume_intro_after_forest_return() -> void:
	_intro_busy = true
	Global.tutorial_enabled = false
	Global.show_tutorial_text("")
	player.can_move = false
	player.direction = Vector2.ZERO
	player.global_position = _marker_pos(&"ChestApproach", INTRO_CHEST_APPROACH_POS)
	tera_actor.visible = true
	tera_actor.global_position = _marker_pos(&"TeraField", INTRO_TERA_FIELD_POS)
	tera_actor.face_down()
	tera_actor.play_idle()
	silas_actor.visible = false
	await _begin_plant_and_water_intro_step()

func _begin_plant_and_water_intro_step() -> void:
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
			await plant.force_mature()

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
	if ProgressionService != null and ProgressionService.has_method("ensure_party_member"):
		ProgressionService.ensure_party_member("Silas")
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
	if main_menu and main_menu.visible and main_menu.has_signal("menu_closed"):
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

	if DemoDirector and not Global.loop_hub_mode_active:
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

	var combat_scene_packed: PackedScene = Global.get_preloaded_launch_scene(combat_scene_path)
	if combat_scene_packed == null:
		combat_scene_packed = load(combat_scene_path) as PackedScene
	if combat_scene_packed == null:
		push_error("Combat scene failed to load: %s" % combat_scene_path)
		_intro_busy = false
		player.can_move = true
		_restore_player_camera()
		return

	var combat_scene = combat_scene_packed.instantiate()
	var combat_root := _resolve_combat_scene_root(combat_scene)
	combat_scene.set_meta("skip_scene_music_sync", _suppress_battle_music_sync)
	if combat_root != combat_scene:
		combat_root.set_meta("skip_scene_music_sync", _suppress_battle_music_sync)
	if ProgressionService != null and ProgressionService.has_method("sync_runtime_party_to_scene"):
		ProgressionService.sync_runtime_party_to_scene(combat_root)
	var combat_music: AudioStreamPlayer = combat_root.get_node_or_null("AudioStreamPlayer")
	if is_instance_valid(combat_music):
		combat_music.autoplay = false
		combat_music.stop()

	scene_tree.root.add_child(combat_scene)
	scene_tree.current_scene = combat_scene
	scene_tree.root.remove_child(self)

	await scene_tree.process_frame

	if is_instance_valid(combat_music) and combat_music.stream != null and MusicManager and MusicManager.has_method("crossfade_to"):
		MusicManager.crossfade_to(combat_music.stream, 0.2, combat_music.volume_db)

	var savannah: Node = combat_root.get_node_or_null("GameBoard/Savannah")
	var cursor: Node = combat_root.get_node_or_null("GameBoard/Cursor")
	if savannah != null and cursor != null and "cell" in savannah and "cell" in cursor:
		cursor.cell = savannah.cell.round()
		if "is_active" in cursor:
			cursor.is_active = true

	var reveal := scene_tree.create_tween()
	reveal.set_ease(Tween.EASE_IN_OUT)
	reveal.set_trans(Tween.TRANS_SINE)
	reveal.tween_interval(0.03)
	reveal.tween_property(fade_rect, "color:a", 0.0, 0.35)
	await reveal.finished

	if is_instance_valid(transition_layer):
		transition_layer.queue_free()

func _resolve_combat_scene_root(combat_scene: Node) -> Node:
	if combat_scene == null:
		return null

	var battle_root := combat_scene.get_node_or_null("BattleRoot")
	return battle_root if battle_root != null else combat_scene

func resume_after_combat() -> void:
	_clear_intrusion_bandits()
	_intro_busy = false
	player.can_move = true
	player.direction = Vector2.ZERO
	_restore_player_camera()

func handle_demo_battle_victory() -> bool:
	if not Global.intro_sequence_complete or Global.demo_cabin_built:
		return false
	if _post_battle_aftermath_started:
		return true
	await _run_post_battle_aftermath_sequence()
	return true

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

func _run_loop_arrival_intro() -> void:
	if not _should_play_loop_arrival_intro():
		player.visible = true
		player.can_move = true
		_log_run_start("Control returned")
		return

	Global.pending_loop_arrival_intro = false
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO
	player.visible = true
	Global.show_tutorial_text("")

	player.global_position = LOOP_ARRIVAL_PLAYER_ENTRY_POS
	if player.has_method("play_cutscene_idle"):
		player.play_cutscene_idle(Vector2.UP)

	if tera_actor != null:
		tera_actor.visible = true
		tera_actor.global_position = LOOP_ARRIVAL_TERA_ENTRY_POS
		tera_actor.face_up()
		tera_actor.play_idle()
	if silas_actor != null:
		silas_actor.visible = false

	var intro_cam_target := (LOOP_ARRIVAL_PLAYER_STOP + LOOP_ARRIVAL_TERA_STOP) / 2.0
	cutscene_camera.position_smoothing_enabled = false
	cutscene_camera.global_position = intro_cam_target
	cutscene_camera.zoom = CUTSCENE_GROUP_ZOOM
	cutscene_camera.make_current()
	if cutscene_camera.has_method("reset_smoothing"):
		cutscene_camera.reset_smoothing()
	cutscene_camera.position_smoothing_enabled = true

	await _focus_cutscene_on_positions([LOOP_ARRIVAL_PLAYER_STOP, LOOP_ARRIVAL_TERA_STOP], 0.35, CUTSCENE_GROUP_ZOOM)
	await _move_story_group(
		[player, tera_actor],
		[LOOP_ARRIVAL_PLAYER_STOP, LOOP_ARRIVAL_TERA_STOP],
		1.55
	)
	await _play_story_dialogue([
		{"speaker": "Tera", "text": "We actually made it out. I didn't think..."},
		{"speaker": "Savannah", "text": "Keep your voice down. Deserting is one thing, but getting caught is another. The search parties won't be far behind."},
		{"speaker": "Tera", "text": "I know. It's just... wait. Savannah, look. By the treeline."}
	], [player, tera_actor], CUTSCENE_GROUP_ZOOM)

	await _focus_cutscene_on_positions([LOOP_ARRIVAL_TERA_CABIN_APPROACH_POS, _get_active_cabin_home_pos()], 0.25, CUTSCENE_CLOSE_ZOOM)
	await _move_node(tera_actor, LOOP_ARRIVAL_TERA_GATE_POS, 0.4)
	await _move_node(tera_actor, LOOP_ARRIVAL_TERA_CABIN_APPROACH_POS, 0.4)
	await _move_node(tera_actor, LOOP_ARRIVAL_TERA_REST_POS, 0.3)
	tera_actor.face_down()
	tera_actor.play_idle()
	await _play_story_dialogue([
		{"speaker": "Tera", "text": "A farmhouse. Or what's left of one."},
		{"speaker": "Savannah", "text": "The roof is mostly rot, but the walls still stand. It'll keep the wind off us for tonight."},
		{"speaker": "Tera", "text": "If I can gather enough strength, I can push the Blight back. We might find timber or salvage in the brush."},
		{"speaker": "Savannah", "text": "One step at a time. Just focus on resting."},
		{"speaker": "Tera", "text": "Wait—take these. I grabbed a pouch of seeds from the village before... well, before everything. If this is a farm, we should use it. We can’t run on an empty stomach."},
		{"speaker": "Savannah", "text": "It's been a long time since I held a spade instead of a sword."},
		{"speaker": "Tera", "text": "You haven't forgotten how to use one, have you?"},
		{"speaker": "Savannah", "text": "I’ll manage. Get some rest, Tera."}
	], [player, tera_actor], CUTSCENE_GROUP_ZOOM)

	_refresh_loop_objective()
	await _release_overworld_control()
	_log_run_start("Control returned")

func _get_active_planting_layer() -> TileMapLayer:
	if Global.loop_hub_mode_active and plowed_layer != null:
		return plowed_layer
	return soil_layer

func _try_handle_loop_plot_interaction() -> bool:
	var interaction := _get_current_loop_interaction()
	if interaction.is_empty():
		return false

	match String(interaction.get("target", "")):
		"merchant":
			return _handle_loop_merchant_interaction()
		"night_vendor":
			return _handle_loop_night_vendor_interaction()
		"forest":
			return _handle_loop_forest_interaction()
		"cabin":
			return _handle_loop_cabin_interaction()
		"bridge_battle":
			return _handle_loop_bridge_battle_interaction()
	return false

func _get_current_loop_interaction() -> Dictionary:
	var player_pos: Vector2 = player.global_position
	var merchant_target_pos := LOOP_INTERACTION_POINTS[LOOP_PLOT_MERCHANT]
	var merchant_radius := LOOP_INTERACTION_RADIUS_PLOT
	if Global.has_loop_plot(LOOP_PLOT_MERCHANT):
		merchant_target_pos = LOOP_MERCHANT_INTERACTION_POS
		merchant_radius = LOOP_INTERACTION_RADIUS_MERCHANT
		if Global.is_loop_structure_built(Global.LOOP_STRUCTURE_MERCHANT_WAGON):
			merchant_target_pos = LOOP_MERCHANT_INTERACTION_POS

	var interactions := [
		{
			"target": "merchant",
			"point": merchant_target_pos,
			"segment_start": _get_loop_plot_interaction_edge(LOOP_PLOT_MERCHANT).get("start", Vector2.ZERO) if not Global.has_loop_plot(LOOP_PLOT_MERCHANT) else Vector2.ZERO,
			"segment_end": _get_loop_plot_interaction_edge(LOOP_PLOT_MERCHANT).get("end", Vector2.ZERO) if not Global.has_loop_plot(LOOP_PLOT_MERCHANT) else Vector2.ZERO,
			"radius": merchant_radius,
			"label": _build_loop_merchant_prompt(),
			"highlight_plot": String(LOOP_PLOT_MERCHANT) if not Global.has_loop_plot(LOOP_PLOT_MERCHANT) else "",
			"highlight_sprite": "merchant"
		},
		{
			"target": "night_vendor",
			"point": LOOP_NIGHT_VENDOR_INTERACTION_POS,
			"radius": LOOP_INTERACTION_RADIUS_STRUCTURE,
			"label": _build_loop_night_vendor_prompt(),
			"highlight_sprite": "night_vendor"
		},
		{
			"target": "forest",
			"point": LOOP_INTERACTION_POINTS[LOOP_PLOT_FOREST],
			"segment_start": _get_loop_plot_interaction_edge(LOOP_PLOT_FOREST).get("start", Vector2.ZERO),
			"segment_end": _get_loop_plot_interaction_edge(LOOP_PLOT_FOREST).get("end", Vector2.ZERO),
			"radius": LOOP_INTERACTION_RADIUS_PLOT,
			"label": _build_loop_forest_prompt(),
			"highlight_plot": String(LOOP_PLOT_FOREST) if not Global.has_loop_plot(LOOP_PLOT_FOREST) else ""
		},
		{
			"target": "cabin",
			"point": _get_loop_cabin_interaction_point(),
			"radius": LOOP_INTERACTION_RADIUS_PLOT,
			"label": _build_loop_cabin_prompt(),
			"highlight_plot": String(LOOP_PLOT_CABIN) if not Global.has_loop_plot(LOOP_PLOT_CABIN) else ""
		},
		{
			"target": "bridge_battle",
			"point": LOOP_INTERACTION_POINTS[&"bridge_battle"],
			"radius": 110.0,
			"label": _build_loop_bridge_prompt()
		}
	]

	var best_match: Dictionary = {}
	var best_distance := INF
	for interaction_variant in interactions:
		var interaction: Dictionary = interaction_variant
		var label := String(interaction.get("label", ""))
		if label.is_empty():
			continue
		var point: Vector2 = _get_loop_interaction_focus_point(interaction, player_pos)
		var radius := float(interaction.get("radius", LOOP_INTERACTION_RADIUS_PLOT))
		var distance := _get_loop_interaction_distance(interaction, player_pos)
		if distance > radius or distance >= best_distance:
			continue
		best_distance = distance
		interaction["point"] = point
		best_match = interaction

	return best_match

func _get_loop_plot_interaction_edge(plot_id: StringName) -> Dictionary:
	var rect_variant = LOOP_PLOT_DEFS.get(plot_id, {}).get("rect", Rect2())
	if not (rect_variant is Rect2):
		return {}

	var rect: Rect2 = rect_variant
	var margin := LOOP_PLOT_INTERACTION_EDGE_MARGIN
	match plot_id:
		LOOP_PLOT_MERCHANT:
			return {
				"start": Vector2(rect.position.x + rect.size.x, rect.position.y + margin),
				"end": Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y - margin)
			}
		LOOP_PLOT_FOREST:
			return {
				"start": Vector2(rect.position.x, rect.position.y + margin),
				"end": Vector2(rect.position.x, rect.position.y + rect.size.y - margin)
			}
		LOOP_PLOT_CABIN:
			return {
				"start": Vector2(rect.position.x + margin, rect.position.y + rect.size.y),
				"end": Vector2(rect.position.x + rect.size.x - margin, rect.position.y + rect.size.y)
			}
		_:
			return {}

func _get_loop_interaction_focus_point(interaction: Dictionary, player_pos: Vector2) -> Vector2:
	var segment_start: Vector2 = interaction.get("segment_start", Vector2.ZERO)
	var segment_end: Vector2 = interaction.get("segment_end", Vector2.ZERO)
	if segment_start != Vector2.ZERO or segment_end != Vector2.ZERO:
		return Geometry2D.get_closest_point_to_segment(player_pos, segment_start, segment_end)
	return interaction.get("point", Vector2.ZERO)

func _get_loop_interaction_distance(interaction: Dictionary, player_pos: Vector2) -> float:
	return player_pos.distance_to(_get_loop_interaction_focus_point(interaction, player_pos))

func _build_loop_merchant_prompt() -> String:
	var confirm_label := _get_loop_confirm_label()
	if not Global.has_loop_plot(LOOP_PLOT_MERCHANT):
		return "%s  Purify Merchant Plot (%d BP)" % [confirm_label, int(LOOP_PLOT_DEFS[LOOP_PLOT_MERCHANT].get("unlock_cost", 0))]
	if not Global.is_loop_structure_built(Global.LOOP_STRUCTURE_MERCHANT_WAGON):
		return "%s  Build Wagon (%d Wood)" % [confirm_label, LOOP_MERCHANT_BUILD_WOOD_COST]
	return "%s  Trade" % confirm_label

func _build_loop_night_vendor_prompt() -> String:
	if not _is_loop_night_vendor_available():
		return ""
	return "%s  Night Trade" % _get_loop_confirm_label()

func _build_loop_forest_prompt() -> String:
	var confirm_label := _get_loop_confirm_label()
	if Global.has_loop_plot(LOOP_PLOT_FOREST):
		return ""
	return "%s  Purify Forest (%d BP)" % [confirm_label, int(LOOP_PLOT_DEFS[LOOP_PLOT_FOREST].get("unlock_cost", 0))]

func _build_loop_cabin_prompt() -> String:
	var confirm_label := _get_loop_confirm_label()
	if not Global.has_loop_plot(LOOP_PLOT_CABIN):
		return "%s  Reclaim Cabin" % confirm_label
	if not _is_loop_cabin_repaired():
		return "%s  Repair Cabin (%d Wood)" % [confirm_label, LOOP_CABIN_REPAIR_WOOD_COST]
	if _is_loop_night():
		return "%s  Sleep" % confirm_label
	return ""

func _build_loop_bridge_prompt() -> String:
	var confirm_label := _get_loop_confirm_label()
	if _is_loop_night():
		return "%s  Sleep to begin a new day" % confirm_label
	return "%s  To Battle" % confirm_label

func _get_loop_confirm_label() -> String:
	if DemoDirector != null:
		return DemoDirector.get_confirm_label()
	return "E"

func _update_loop_interaction_ui() -> void:
	if not player.can_move:
		for outline_variant in _loop_plot_outline_lines.keys():
			var frozen_outline = _loop_plot_outline_lines.get(outline_variant, null)
			if frozen_outline != null and is_instance_valid(frozen_outline):
				frozen_outline.visible = false
		if _loop_prompt_root != null and is_instance_valid(_loop_prompt_root):
			_loop_prompt_root.visible = false
		return

	if _loop_merchant_menu != null and is_instance_valid(_loop_merchant_menu) and _loop_merchant_menu.visible:
		for outline_variant in _loop_plot_outline_lines.keys():
			var outline = _loop_plot_outline_lines.get(outline_variant, null)
			if outline != null and is_instance_valid(outline):
				outline.visible = false
		if _loop_prompt_root != null and is_instance_valid(_loop_prompt_root):
			_loop_prompt_root.visible = false
		return

	var interaction := _get_current_loop_interaction()
	var active_target := String(interaction.get("target", ""))

	for outline_variant in _loop_plot_outline_lines.keys():
		var outline = _loop_plot_outline_lines.get(outline_variant, null)
		if outline != null and is_instance_valid(outline):
			outline.visible = String(interaction.get("highlight_plot", "")) == String(outline_variant)

	_set_loop_merchant_structure_highlight(_loop_merchant_structure_naked, active_target == "merchant")
	_set_loop_merchant_structure_highlight(_loop_merchant_structure_complete, active_target == "merchant")
	if _merchant_actor != null and is_instance_valid(_merchant_actor):
		_merchant_actor.modulate = Color(1.15, 1.15, 1.15) if active_target == "merchant" else Color(1, 1, 1)
	if _loop_night_vendor_actor != null and is_instance_valid(_loop_night_vendor_actor):
		_loop_night_vendor_actor.modulate = Color(1.08, 1.12, 1.2, 1.0) if active_target == "night_vendor" else Color(0.88, 0.94, 1.0, 1.0)

	if _loop_prompt_root == null or not is_instance_valid(_loop_prompt_root) or _loop_prompt_label == null:
		return
	if interaction.is_empty():
		_loop_prompt_root.visible = false
		return

	_loop_prompt_label.text = String(interaction.get("label", ""))
	_loop_prompt_root.reset_size()
	var focus_point: Vector2 = interaction.get("point", player.global_position)
	var canvas_transform := get_viewport().get_canvas_transform()
	var screen_point := canvas_transform * (focus_point + Vector2(0, -56))
	_loop_prompt_root.position = screen_point - (_loop_prompt_root.size * 0.5)
	_loop_prompt_root.visible = true

func _set_loop_merchant_structure_highlight(structure: Node2D, highlighted: bool) -> void:
	if structure == null or not is_instance_valid(structure):
		return
	var sprite := structure.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.self_modulate = Color(1.18, 1.18, 1.18) if highlighted else Color(1, 1, 1)

func _handle_loop_merchant_interaction() -> bool:
	if not Global.has_loop_plot(LOOP_PLOT_MERCHANT):
		var bloom_cost := int(LOOP_PLOT_DEFS[LOOP_PLOT_MERCHANT].get("unlock_cost", 0))
		if Global.loop_bloom_points < bloom_cost:
			_show_player_notice("Need %d BP to purify the merchant plot." % bloom_cost)
			return true
		Global.spend_loop_bloom_points(bloom_cost)
		Global.unlock_loop_plot(LOOP_PLOT_MERCHANT)
		_run_loop_plot_purified_feedback(LOOP_PLOT_MERCHANT)
		_show_player_notice("A wagon frame emerges from the ash.")
		_refresh_loop_plot_visuals()
		_refresh_loop_merchant_visuals()
		_refresh_loop_objective()
		_autosave_loop_run()
		return true

	if not Global.is_loop_structure_built(Global.LOOP_STRUCTURE_MERCHANT_WAGON):
		if int(Global.inventory.get(Global.Items.WOOD, 0)) < LOOP_MERCHANT_BUILD_WOOD_COST:
			_show_player_notice("Need %d Wood to build the wagon." % LOOP_MERCHANT_BUILD_WOOD_COST)
			return true
		Global.remove_item(Global.Items.WOOD, LOOP_MERCHANT_BUILD_WOOD_COST)
		Global.build_loop_structure(Global.LOOP_STRUCTURE_MERCHANT_WAGON)
		if _merchant_actor != null and is_instance_valid(_merchant_actor):
			_merchant_actor.global_position = LOOP_MERCHANT_NPC_POS
			_merchant_actor.z_index = 2
			_merchant_actor.visible = true
			_merchant_actor.modulate = Color.WHITE
			if _merchant_actor.has_method("face_side"):
				_merchant_actor.face_side(true)
			if _merchant_actor.has_method("play_idle"):
				_merchant_actor.play_idle()
		_show_player_notice("The merchant wagon is ready for trade.")
		_refresh_loop_merchant_visuals()
		_refresh_loop_objective()
		_autosave_loop_run()
		return true

	_open_loop_merchant_menu()
	return true

func _handle_loop_night_vendor_interaction() -> bool:
	if not _is_loop_night_vendor_available():
		return false
	_open_loop_merchant_menu(LOOP_MERCHANT_KIND_NIGHT)
	return true

func _handle_loop_forest_interaction() -> bool:
	if Global.has_loop_plot(LOOP_PLOT_FOREST):
		_show_player_notice("The forest path is open. Silas watches the tree line.")
		return true

	var bloom_cost := int(LOOP_PLOT_DEFS[LOOP_PLOT_FOREST].get("unlock_cost", 0))
	if Global.loop_bloom_points < bloom_cost:
		_show_player_notice("Need %d BP to purify the forest plot." % bloom_cost)
		return true

	Global.spend_loop_bloom_points(bloom_cost)
	Global.unlock_loop_plot(LOOP_PLOT_FOREST)
	if ProgressionService != null and ProgressionService.has_method("ensure_party_member"):
		ProgressionService.ensure_party_member("Silas")
	_spawn_loop_forest_content()
	_run_loop_plot_purified_feedback(LOOP_PLOT_FOREST)
	_maybe_show_loop_forest_unlock_tutorials()
	_refresh_loop_plot_visuals()
	_refresh_loop_objective()
	_autosave_loop_run()
	return true

func _handle_loop_cabin_interaction() -> bool:
	if not Global.has_loop_plot(LOOP_PLOT_CABIN):
		Global.unlock_loop_plot(LOOP_PLOT_CABIN)
		_refresh_loop_plot_visuals()

	if not _is_loop_cabin_repaired():
		if not Global.has_loop_plot(LOOP_PLOT_FOREST):
			_show_player_notice("Unlock the forest first. You need wood before anyone can sleep here.")
			return true
		if _get_loop_wood_count() < LOOP_CABIN_REPAIR_WOOD_COST:
			_show_player_notice("Need %d Wood to repair the cabin." % LOOP_CABIN_REPAIR_WOOD_COST)
			return true
		Global.remove_item(Global.Items.WOOD, LOOP_CABIN_REPAIR_WOOD_COST)
		Global.build_loop_structure(Global.LOOP_STRUCTURE_CABIN_REPAIRED)
		_sync_shelter_state()
		_show_player_notice("The cabin is repaired. Sleep here at night to start the next day.")
		_refresh_loop_objective()
		_autosave_loop_run()
		call_deferred("_show_loop_sleep_tutorial_after_repair")
		return true

	if not _is_loop_night():
		_show_player_notice("Sleep comes after battle. Use the day to plant, expand, and prepare.")
		return true

	player.can_move = false
	call_deferred("_run_loop_sleep_transition")
	return true

func _handle_loop_bridge_battle_interaction() -> bool:
	_close_loop_merchant_menu()
	if _is_loop_night():
		_show_player_notice("Night is for prep. Sleep in the cabin when you're ready for the next battle.")
		return true
	if _loop_battle_launch_pending:
		return true
	_loop_battle_launch_pending = true
	player.can_move = false
	player.direction = Vector2.ZERO
	_show_player_notice("Crossing the bridge into the next fight...")
	call_deferred("_start_loop_battle")
	return true

func _start_loop_battle() -> void:
	await get_tree().create_timer(0.08, true).timeout
	_loop_battle_launch_pending = false
	await _launch_direct_combat_scene(LOOP_BRIDGE_BATTLE_SCENE)

func _get_loop_battle_reward(reward_table: Array[int], fallback_base: int, fallback_step: int) -> int:
	var battle_offset := maxi(Global.loop_battle_index - 1, 0)
	if battle_offset < reward_table.size():
		return reward_table[battle_offset]

	var overflow_offset := battle_offset - reward_table.size() + 1
	return reward_table.back() + (overflow_offset * fallback_step) if not reward_table.is_empty() else fallback_base + (battle_offset * fallback_step)

func handle_loop_battle_result(is_victory: bool, enemies_defeated: int) -> void:
	player.can_move = false
	player.direction = Vector2.ZERO
	_close_loop_merchant_menu()
	Global.set_loop_time_phase(Global.LOOP_PHASE_NIGHT)
	_refresh_loop_phase_presentation(true)
	_refresh_loop_plot_visuals()
	if is_victory:
		var bp_reward := _get_loop_battle_reward(LOOP_BATTLE_BP_REWARDS, LOOP_BATTLE_BP_BASE_REWARD, LOOP_BATTLE_BP_STEP)
		var gold_reward := _get_loop_battle_reward(LOOP_BATTLE_GOLD_REWARDS, LOOP_BATTLE_GOLD_BASE_REWARD, LOOP_BATTLE_GOLD_STEP) + (enemies_defeated * 2)
		Global.add_loop_bloom_points(bp_reward)
		Global.add_loop_gold(gold_reward)
		Global.apply_player_auto_levels(1)
		Global.loop_battle_index += 1
		Global.stats_updated.emit()
		Global.loop_state_changed.emit()
		if ProgressionService != null:
			ProgressionService.party_roster_changed.emit()
		_mature_loop_crops_after_battle()
		if Global.has_loop_plot(LOOP_PLOT_FOREST):
			_spawn_loop_forest_content()
		var reward_label := "Bloom Points" if DemoDirector != null and not DemoDirector.has_seen_tutorial("loop_bloom_points") else "BP"
		_show_player_notice("Victory. +%d %s, +%d Gold." % [bp_reward, reward_label, gold_reward], 1.8)
	else:
		var lost_gold := mini(int(ceil(float(Global.loop_gold) * LOOP_RAID_LOSS_RATIO)), Global.loop_gold)
		var lost_wood := mini(int(ceil(float(int(Global.inventory.get(Global.Items.WOOD, 0))) * LOOP_RAID_LOSS_RATIO)), int(Global.inventory.get(Global.Items.WOOD, 0)))
		var lost_stone := mini(int(ceil(float(int(Global.inventory.get(Global.Items.STONE, 0))) * LOOP_RAID_LOSS_RATIO)), int(Global.inventory.get(Global.Items.STONE, 0)))
		Global.add_loop_gold(-lost_gold)
		if lost_wood > 0:
			Global.remove_item(Global.Items.WOOD, lost_wood)
		if lost_stone > 0:
			Global.remove_item(Global.Items.STONE, lost_stone)
		_show_player_notice("Driven back. Raiders stole %d Gold, %d Wood, and %d Stone." % [lost_gold, lost_wood, lost_stone], 2.0)
	_refresh_loop_merchant_visuals()
	await _maybe_show_loop_first_night_tutorial()
	if is_victory and Global.loop_hub_mode_active and DemoDirector != null and not DemoDirector.has_seen_tutorial("loop_bloom_points"):
		await _maybe_show_loop_bloom_points_tutorial()
	_autosave_loop_run()
	player.can_move = true
	_refresh_loop_hud()
	_refresh_loop_objective()

func _advance_loop_crop_growth(ticks: int) -> void:
	for _i in range(maxi(ticks, 0)):
		_on_grow_timer_timeout()


func _mature_loop_crops_after_battle() -> void:
	for plant in get_tree().get_nodes_in_group("Plants"):
		if plant == null or not is_instance_valid(plant):
			continue
		if plant.has_method("mature_immediately"):
			plant.mature_immediately()
		elif plant.has_method("force_mature"):
			plant.force_mature()
		elif plant.has_method("advance_growth"):
			for _i in range(maxi(LOOP_POST_BATTLE_GROWTH_TICKS, 0)):
				plant.advance_growth()

func _run_loop_plot_purified_feedback(plot_id: StringName) -> void:
	var burst_position: Vector2 = LOOP_INTERACTION_POINTS.get(plot_id, player.global_position)
	var plot_def: Dictionary = LOOP_PLOT_DEFS.get(plot_id, {})
	if plot_def.has("rect"):
		var plot_rect: Rect2 = plot_def.get("rect", Rect2())
		burst_position = plot_rect.get_center()
	spawn_overworld_burst(burst_position, LOOP_PURIFY_VFX_TEXTURE, Vector2i(128, 128), LOOP_PURIFY_VFX_FRAME_COUNT, 24.0, Vector2(1.45, 1.45))
	play_overworld_camera_shake(3.0, 0.12)
	_play_loop_world_sfx(LOOP_PURIFY_SFX, burst_position)

func _show_loop_sleep_tutorial_after_repair() -> void:
	await _maybe_show_loop_sleep_tutorial()

func _run_loop_sleep_transition() -> void:
	_close_loop_merchant_menu()
	player.can_move = false
	player.direction = Vector2.ZERO
	if _cabin_home != null and is_instance_valid(_cabin_home) and _cabin_home.has_method("open_for_entry"):
		await _cabin_home.open_for_entry()
	await _fade_to_black(0.32)
	Global.current_day += 1
	Global.day_changed.emit(Global.current_day)
	Global.set_loop_time_phase(Global.LOOP_PHASE_DAY)
	if _cabin_home != null and is_instance_valid(_cabin_home) and _cabin_home.has_method("close_for_exit") and _cabin_home.has_method("is_open") and bool(_cabin_home.call("is_open")):
		await _cabin_home.close_for_exit()
	await _fade_from_black(0.38)
	_show_player_notice("Dawn breaks over the farm.")
	player.can_move = true
	_refresh_loop_objective()
	_autosave_loop_run()

func _open_loop_merchant_menu(kind: String = LOOP_MERCHANT_KIND_WAGON) -> void:
	if _loop_merchant_menu == null or not is_instance_valid(_loop_merchant_menu):
		_build_loop_merchant_menu()
	if _loop_merchant_menu == null or not is_instance_valid(_loop_merchant_menu):
		return
	_loop_active_merchant_kind = kind if kind in [LOOP_MERCHANT_KIND_WAGON, LOOP_MERCHANT_KIND_NIGHT] else LOOP_MERCHANT_KIND_WAGON
	if not _get_active_loop_merchant_tabs().has(_loop_merchant_active_tab):
		var available_tabs := _get_active_loop_merchant_tabs()
		_loop_merchant_active_tab = String(available_tabs[0]) if not available_tabs.is_empty() else ""
	_refresh_loop_merchant_menu()
	_loop_merchant_menu.visible = true
	player.can_move = false
	_loop_merchant_tab_switch_cooldown_until_msec = 0
	_focus_first_loop_merchant_action_button()

func _close_loop_merchant_menu() -> void:
	if _loop_merchant_menu == null or not is_instance_valid(_loop_merchant_menu):
		return
	_loop_merchant_menu.visible = false
	player.can_move = true

func _on_loop_sell_harvest_pressed() -> void:
	var total_gold := 0
	for item_variant in LOOP_SELL_PRICES.keys():
		var item_type: int = int(item_variant)
		var count := int(Global.inventory.get(item_type, 0))
		if count <= 0:
			continue
		total_gold += count * int(LOOP_SELL_PRICES[item_type])
		Global.inventory[item_type] = 0
	if total_gold <= 0:
		_show_player_notice("Nothing to sell yet.")
		return
	Global.add_loop_gold(total_gold)
	Global.inventory_updated.emit()
	_refresh_loop_merchant_menu()
	_refresh_loop_objective()
	_show_player_notice("Sold the harvest for %d Gold." % total_gold)
	_autosave_loop_run()

func _on_loop_buy_seed_pressed(seed_item: int) -> void:
	var seed_shop := _get_active_loop_seed_shop()
	var offer: Dictionary = seed_shop.get(seed_item, {})
	var cost := int(offer.get("cost", 0))
	if Global.loop_gold < cost:
		_show_player_notice("Not enough Gold.")
		return
	Global.spend_loop_gold(cost)
	Global.add_item(seed_item, 1)
	_refresh_loop_merchant_menu()
	_refresh_loop_objective()
	_show_player_notice("Purchased %s." % String(offer.get("label", "seed bundle")))
	_autosave_loop_run()

func _on_loop_buy_inventory_item_pressed(item_type: int, cost: int) -> void:
	if Global.loop_gold < cost:
		_show_player_notice("Not enough Gold.")
		return
	Global.spend_loop_gold(cost)
	Global.add_item(item_type, 1)
	_refresh_loop_merchant_menu()
	_refresh_loop_objective()
	_show_player_notice("Purchased %s." % _format_loop_item_name(item_type))
	_autosave_loop_run()

func _on_loop_buy_equipment_pressed(item: Resource, cost: int) -> void:
	if item == null:
		return
	if Global.loop_gold < cost:
		_show_player_notice("Not enough Gold.")
		return
	if ProgressionService == null or not ProgressionService.has_method("add_owned_equipment"):
		_show_player_notice("Merchant stock is unavailable right now.")
		return
	if not ProgressionService.add_owned_equipment(item):
		_show_player_notice("You already own %s." % _get_equipment_display_name(item))
		return

	Global.spend_loop_gold(cost)
	_refresh_loop_merchant_menu()
	_refresh_loop_hud()
	_show_player_notice("Purchased %s." % _get_equipment_display_name(item))
	_autosave_loop_run()

func _play_loop_world_sfx(stream: AudioStream, at_global_position: Vector2) -> void:
	if stream == null:
		return
	var sfx_player := AudioStreamPlayer2D.new()
	sfx_player.stream = stream
	sfx_player.global_position = at_global_position
	add_child(sfx_player)
	sfx_player.finished.connect(sfx_player.queue_free)
	sfx_player.play()

func _show_player_notice(text: String, duration := 1.4) -> void:
	var overlay := get_node_or_null("CanvasLayer/Overlay")
	if overlay != null and overlay.has_method("show_notice"):
		overlay.show_notice(text, duration)

func _spawn_overworld_system_menu() -> void:
	if _overworld_system_menu != null and is_instance_valid(_overworld_system_menu):
		return
	var canvas_layer := get_node_or_null("CanvasLayer")
	if canvas_layer == null:
		return
	_overworld_system_menu = _overworld_system_menu_scene.instantiate()
	canvas_layer.add_child(_overworld_system_menu)
	if _overworld_system_menu.has_method("setup"):
		_overworld_system_menu.call("setup", main_menu)

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

func _run_post_battle_aftermath_sequence() -> void:
	_post_battle_aftermath_started = true
	_materials_run_started = false
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO
	_setup_story_camp_state()
	player.global_position = _marker_pos(&"BanditDefensePlayer", BANDIT_DEFENSE_PLAYER_POS)
	tera_actor.global_position = _marker_pos(&"BanditDefenseTera", BANDIT_DEFENSE_TERA_POS)
	silas_actor.global_position = _marker_pos(&"BanditDefenseSilas", BANDIT_DEFENSE_SILAS_POS)
	if player.has_method("play_cutscene_idle"):
		player.play_cutscene_idle(Vector2.DOWN)
	tera_actor.face_down()
	tera_actor.play_idle()
	silas_actor.face_down()
	silas_actor.play_idle()

	await _run_bandit_retreat_cutscene()
	await _play_story_dialogue([
		{"speaker": "Silas", "text": "They're gone. For now. But once word gets out that someone is actually growing food in the ash, they'll be back with more men."},
		{"speaker": "Savannah", "text": "He's right. This ruin won't hold if they come back in force. The roof is rot and the walls are paper."},
		{"speaker": "Tera", "text": "The forest still has stone and timber. If we move fast, we can turn this place into a real shelter."},
		{"speaker": "Savannah", "text": "I know how to brace a perimeter. I just need solid wood and enough stone to keep it standing."},
		{"speaker": "Silas", "text": "I know a spot. Follow the treeline back in and keep your eyes open."}
	], [player, tera_actor, silas_actor], CUTSCENE_GROUP_ZOOM)

	if DemoDirector:
		DemoDirector.set_stage(DemoDirector.DemoStage.GATHER_MATERIALS)
		DemoDirector.show_context_prompt("farm_gather_materials")
	await _release_overworld_control()

func _run_bandit_retreat_cutscene() -> void:
	_clear_intrusion_bandits()
	var bandit_leader := _spawn_intrusion_bandit("BanditLeaderRetreat", _bandit_leader_actor_scene, _marker_pos(&"BanditStopLeader", BANDIT_STOP_LEADER_POS), false)
	var bandit_warrior := _spawn_intrusion_bandit("BanditWarriorRetreat", _bandit_warrior_actor_scene, _marker_pos(&"BanditStopWarrior", BANDIT_STOP_WARRIOR_POS), false)
	var bandit_archer := _spawn_intrusion_bandit("BanditArcherRetreat", _bandit_archer_actor_scene, _marker_pos(&"BanditStopArcher", BANDIT_STOP_ARCHER_POS), false)
	for actor in [bandit_leader, bandit_warrior, bandit_archer]:
		if actor != null and actor.has_method("face_down"):
			actor.face_down()

	await _play_story_dialogue([
		{"speaker": "Bandit Leader", "text": "Fall back!"}
	], [bandit_leader, bandit_warrior, bandit_archer], Vector2(1.75, 1.75))

	await _move_story_group(
		[bandit_leader, bandit_warrior, bandit_archer],
		[
			_marker_pos(&"BanditEntryLeader", BANDIT_ENTRY_LEADER_POS),
			_marker_pos(&"BanditEntryWarrior", BANDIT_ENTRY_WARRIOR_POS),
			_marker_pos(&"BanditEntryArcher", BANDIT_ENTRY_ARCHER_POS),
		],
		1.0
	)
	_clear_intrusion_bandits()

func _resume_after_materials_forest_return() -> void:
	_intro_busy = true
	player.can_move = false
	player.direction = Vector2.ZERO
	_setup_story_camp_state()
	player.global_position = CABIN_REBUILD_PLAYER_POS
	tera_actor.global_position = CABIN_REBUILD_TERA_POS
	silas_actor.global_position = CABIN_REBUILD_SILAS_POS
	if player.has_method("play_cutscene_idle"):
		player.play_cutscene_idle(Vector2.DOWN)
	tera_actor.face_side(true)
	tera_actor.play_idle()
	silas_actor.face_side(false)
	silas_actor.play_idle()
	await _run_cabin_rebuild_sequence()

func _run_cabin_rebuild_sequence() -> void:
	Global.remove_item(Global.Items.WOOD, Global.DEMO_CABIN_WOOD_REQUIRED)
	Global.remove_item(Global.Items.STONE, Global.DEMO_CABIN_STONE_REQUIRED)
	await _focus_cutscene_on_positions([CABIN_HOME_POS], 0.35, Vector2(1.58, 1.58))
	await _fade_to_black(0.8)
	_play_one_shot_world_sfx(_rebuild_hit_a, CABIN_HOME_POS + Vector2(-16, 12))
	await get_tree().create_timer(0.16, true).timeout
	_play_one_shot_world_sfx(_rebuild_hit_b, CABIN_HOME_POS + Vector2(18, -6))
	await get_tree().create_timer(0.2, true).timeout
	_play_one_shot_world_sfx(_rebuild_hit_a, CABIN_HOME_POS + Vector2(4, 10))
	Global.demo_cabin_built = true
	_sync_shelter_state()
	await _fade_from_black(0.95)
	await _play_story_dialogue([
		{"speaker": "Savannah", "text": "It's not a palace, but the beams are braced and the door actually shuts. It'll hold."},
		{"speaker": "Tera", "text": "It feels... like a home."},
		{"speaker": "Silas", "text": "It feels like a place worth defending. Try the door. Then get some sleep."}
	], [player, tera_actor, silas_actor, _cabin_home], CUTSCENE_GROUP_ZOOM)
	if DemoDirector:
		DemoDirector.set_stage(DemoDirector.DemoStage.CABIN_COMPLETE)
		DemoDirector.show_context_prompt("farm_sleep_in_cabin")
	await _release_overworld_control()

func _run_cabin_sleep_sequence() -> void:
	if _merchant_sequence_started:
		return
	_merchant_sequence_started = true
	_intro_busy = true
	Global.pending_day_transition = true
	player.can_move = false
	player.direction = Vector2.ZERO
	_setup_story_camp_state()
	player.global_position = CABIN_SLEEP_PLAYER_POS
	tera_actor.global_position = CABIN_SLEEP_TERA_POS
	silas_actor.global_position = CABIN_SLEEP_SILAS_POS
	if _cabin_home != null and _cabin_home.has_method("open_for_entry"):
		await _cabin_home.open_for_entry()
	await _fade_to_black(0.8)
	Global.current_day += 1
	level_reset()
	if _cabin_home != null and _cabin_home.has_method("close_for_exit") and _cabin_home.has_method("is_open") and bool(_cabin_home.call("is_open")):
		await _cabin_home.close_for_exit()
	Global.pending_day_transition = false
	player.global_position = MERCHANT_PLAYER_POS
	tera_actor.global_position = MERCHANT_TERA_POS
	silas_actor.global_position = MERCHANT_SILAS_POS
	if player.has_method("play_cutscene_idle"):
		player.play_cutscene_idle(Vector2.LEFT)
	tera_actor.face_side(false)
	tera_actor.play_idle()
	silas_actor.face_side(false)
	silas_actor.play_idle()
	if _merchant_actor != null:
		_merchant_actor.visible = true
		_merchant_actor.global_position = MERCHANT_POS
		if _merchant_actor.has_method("face_side"):
			_merchant_actor.face_side(true)
		if _merchant_actor.has_method("play_entry"):
			_merchant_actor.play_entry()
	await _focus_cutscene_on_positions([MERCHANT_PLAYER_POS, MERCHANT_POS], 0.2, Vector2(1.62, 1.62))
	await _fade_from_black(1.0)
	await get_tree().create_timer(0.2, true).timeout
	if _merchant_actor != null and _merchant_actor.has_method("play_talk_loop"):
		_merchant_actor.play_talk_loop()
	await _play_story_dialogue([
		{"speaker": "Merchant", "text": "Easy there. I'm just a traveler with a heavy pack and a nose for news."},
		{"speaker": "Savannah", "text": "We aren't looking for trouble."},
		{"speaker": "Merchant", "text": "Good thing. I heard the bandits on the north road were dealt with. Safer roads mean bolder feet."},
		{"speaker": "Merchant", "text": "Name's Oryn. I move seeds, iron, recipes, and gossip. Keep this farm breathing, and we'll do business soon."}
	], [player, tera_actor, silas_actor, _merchant_actor], CUTSCENE_GROUP_ZOOM)
	Global.demo_merchant_intro_seen = true
	if _merchant_actor != null and _merchant_actor.has_method("play_rest"):
		_merchant_actor.play_rest()
	await get_tree().process_frame
	var card_parent: Node = get_node_or_null("CanvasLayer")
	if card_parent == null:
		card_parent = self
	DemoDirector.show_demo_complete_card(card_parent)

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
