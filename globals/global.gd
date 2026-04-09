extends Node

func _ready() -> void:
	reset_known_recipes_to_defaults()
	ensure_player_stat_formats()
	_validate_early_food_balance()
	
	if player_level <= 0:
		if ProgressionService and ProgressionService.has_method("get_starting_player_level"):
			player_level = ProgressionService.get_starting_player_level()
		else:
			player_level = 1
	# Older saves can still come through with the placeholder class name.
	if player_class_name == "Deserter" or player_class_name == "":
		if ProgressionService and ProgressionService.has_method("get_player_character_data"):
			var player_data = ProgressionService.get_player_character_data()
			if player_data != null and player_data.class_data != null:
				player_class_name = String(player_data.class_data.metadata_name).strip_edges()
				
func _validate_early_food_balance() -> void:
	for meal_item in food_stats.keys():
		var meal_stats: Dictionary = food_stats[meal_item]
		var movement_bonus := int(meal_stats.get("MOV", 0))
		if movement_bonus > EARLY_FOOD_MOVEMENT_CAP:
			push_warning("%s exceeds early MOV cap (%d > %d)." % [Items.keys()[meal_item], movement_bonus, EARLY_FOOD_MOVEMENT_CAP])

		var total_points := 0
		for stat_name in ["VIT", "STR", "DEF", "DEX", "INT", "SPD", "MOV"]:
			total_points += int(meal_stats.get(stat_name, 0))

		if total_points != EARLY_FOOD_TOTAL_POWER_POINTS:
			push_warning("%s is off early food budget (%d != %d)." % [Items.keys()[meal_item], total_points, EARLY_FOOD_TOTAL_POWER_POINTS])

signal inventory_updated
signal recipe_knowledge_updated
@warning_ignore('unused_signal')
signal stats_updated
signal loop_state_changed
var saved_farm_scene: Node = null


var returning_from_combat: bool = false
var loop_hub_mode_active := false
var loop_gold := 0
var loop_bloom_points := 0
var loop_battle_index := 1
var loop_unlocked_plots: Dictionary = {}
var loop_built_structures: Dictionary = {}
var loop_equipped_perk_item: int = -1
var pending_intro_forest_visit := false
var pending_intro_forest_return := false
var intro_forest_day_time_left := 0.0
var pending_materials_forest_visit := false
var pending_materials_forest_return := false
var demo_cabin_built := false
var demo_merchant_intro_seen := false
var player_level: int
var player_class_name: String = "Deserter"
var last_battle_result := {
	"victory": false,
	"enemies_defeated": 0,
	"returned_at_unix": 0
}

@warning_ignore("unused_signal")
signal day_changed(new_day: int)

var current_day: int = 1
var pending_day_transition: bool = false
var resolved_encounters: Array = [] 
var pending_combat_scene_path: String = ""

signal tutorial_updated(text: String)
var tutorial_step: int = 0
const MAX_TUTORIAL_STEP := 15
var tutorial_enabled := true
var intro_sequence_complete := false
const DEMO_CABIN_WOOD_REQUIRED := 10
const DEMO_CABIN_STONE_REQUIRED := 10
const LOOP_PLOT_STARTING_FARM := &"starting_farm"
const LOOP_PLOT_MERCHANT := &"merchant"
const LOOP_PLOT_FOREST := &"forest"
const LOOP_PLOT_CABIN := &"cabin"
const LOOP_STRUCTURE_MERCHANT_WAGON := &"merchant_wagon"

# Warm the launch path before the title screen becomes interactive so Start never races scene loading.
const LAUNCH_GAME_SCENE: PackedScene = preload("res://scenes/level/game.tscn")
const LAUNCH_FOREST_BATTLE_SCENE: PackedScene = preload("res://scenes/level/forest_battle.tscn")
const LAUNCH_DAY_TWO_BATTLE_SCENE: PackedScene = preload("res://scenes/level/day_two_battle.tscn")

func get_preloaded_launch_scene(scene_path: String) -> PackedScene:
	match scene_path:
		"res://scenes/level/game.tscn":
			return LAUNCH_GAME_SCENE
		"res://scenes/level/forest_battle.tscn":
			return LAUNCH_FOREST_BATTLE_SCENE
		"res://scenes/level/day_two_battle.tscn":
			return LAUNCH_DAY_TWO_BATTLE_SCENE
		_:
			return null

func advance_tutorial() -> void:
	if not tutorial_enabled:
		return
	tutorial_step = min(tutorial_step + 1, MAX_TUTORIAL_STEP)
	update_tutorial_ui()

func set_tutorial_step(step: int) -> void:
	tutorial_step = clampi(step, 0, MAX_TUTORIAL_STEP)
	update_tutorial_ui()

func show_tutorial_text(text: String) -> void:
	tutorial_updated.emit(text)

func update_tutorial_ui() -> void:
	if DemoDirector and DemoDirector.is_demo_active():
		DemoDirector.refresh_current_prompt()
		return

	if not tutorial_enabled:
		tutorial_updated.emit("")
		return

	match tutorial_step:
		0: tutorial_updated.emit("Quest: Use W, A, S, D to move around.")
		1: tutorial_updated.emit("Quest: Walk up to the sign and read it. (Press E)")
		2: tutorial_updated.emit("Quest: Open the nearby chest. Follow the signs!")
		3: tutorial_updated.emit("Quest: Equip your Hoe (Scroll Mouse Wheel or Press 1).")
		4: tutorial_updated.emit("Quest: Plow some soil (Press Space on the dirt).")
		5: tutorial_updated.emit("Quest: Plant a seed (Press E near plowed soil).")
		6: tutorial_updated.emit("Quest: Equip your Watering Can and water the seed!")
		7: tutorial_updated.emit("Quest: Equip your Axe and chop a tree for Wood.")
		8: tutorial_updated.emit("Quest: Press T to skip to the next day.")
		9: tutorial_updated.emit("Quest: Harvest your fully grown crop (Walk over it).")
		10: tutorial_updated.emit("Quest: Walk up to the Campfire, then press Interact/Confirm to light it.")
		11: tutorial_updated.emit("Quest: Cook a meal using your harvested crop!")
		12: tutorial_updated.emit("Quest: Open inventory (Tab) and eat the meal.")
		13: tutorial_updated.emit("Quest: Sleep to trigger the battle warning, then press Defend the Sanctuary!")
		14: tutorial_updated.emit("Quest: Defeat the enemy and return to the farm!")
		15: tutorial_updated.emit("")
		_:
			tutorial_updated.emit("")

var combat_transition := {
	"started_at_unix": 0.0
}


func begin_combat_transition() -> void:
	combat_transition.started_at_unix = Time.get_unix_time_from_system()

func consume_combat_elapsed_seconds() -> float:
	if combat_transition.started_at_unix <= 0.0:
		return 0.0

	var elapsed = max(Time.get_unix_time_from_system() - combat_transition.started_at_unix, 0.0)
	combat_transition.started_at_unix = 0.0
	return elapsed


enum Items {
	BLUEBERRY_SEED, WHEAT_SEED, MELON_SEED, CORN_SEED, HOT_PEPPER_SEED, RADISH_SEED, RED_CABBAGE_SEED, TOMATO_SEED,
	CARROT_SEED, CAULIFLOWER_SEED, POTATO_SEED, PARSNIP_SEED, GARLIC_SEED, GREEN_BEANS_SEED, STRAWBERRY_SEED, COFFEE_BEAN_SEED,
	PUMPKIN_SEED, BROCCOLI_SEED, ARTICHOKE_SEED, EGGPLANT_SEED, BOK_CHOY_SEED, GRAPE_SEED,
	BLUEBERRY, WHEAT, MELON, CORN, HOT_PEPPER, RADISH, RED_CABBAGE, TOMATO,
	CARROT, CAULIFLOWER, POTATO, PARSNIP, GARLIC, GREEN_BEANS, STRAWBERRY, COFFEE_BEAN,
	PUMPKIN, BROCCOLI, ARTICHOKE, EGGPLANT, BOK_CHOY, GRAPE,
	WOOD, APPLE, STONE , WATER,
	ROASTED_CORN, TOMATO_SOUP, HERBAL_HASH,
	GARLIC_MASHED_POTATOES, GLAZED_CARROTS, ROASTED_ROOT_MEDLEY,
	CAULIFLOWER_STEAK, GREEN_BEAN_SAUTE, STRAWBERRY_ENERGY_BOWL,
	MORNING_COFFEE, PARSNIP_SOUP
}

const HARVEST_DROPS = {
	Items.BLUEBERRY_SEED: Items.BLUEBERRY,
	Items.WHEAT_SEED: Items.WHEAT,
	Items.MELON_SEED: Items.MELON,
	Items.CORN_SEED: Items.CORN,
	Items.HOT_PEPPER_SEED: Items.HOT_PEPPER,
	Items.RADISH_SEED: Items.RADISH,
	Items.RED_CABBAGE_SEED: Items.RED_CABBAGE,
	Items.TOMATO_SEED: Items.TOMATO,
	Items.CARROT_SEED: Items.CARROT,
	Items.CAULIFLOWER_SEED: Items.CAULIFLOWER,
	Items.POTATO_SEED: Items.POTATO,
	Items.PARSNIP_SEED: Items.PARSNIP,
	Items.GARLIC_SEED: Items.GARLIC,
	Items.GREEN_BEANS_SEED: Items.GREEN_BEANS,
	Items.STRAWBERRY_SEED: Items.STRAWBERRY,
	Items.COFFEE_BEAN_SEED: Items.COFFEE_BEAN,
	Items.PUMPKIN_SEED: Items.PUMPKIN,
	Items.BROCCOLI_SEED: Items.BROCCOLI,
	Items.ARTICHOKE_SEED: Items.ARTICHOKE,
	Items.EGGPLANT_SEED: Items.EGGPLANT,
	Items.BOK_CHOY_SEED: Items.BOK_CHOY,
	Items.GRAPE_SEED: Items.GRAPE
}

const SPRING := &"spring"
const SUMMER := &"summer"
const FALL := &"fall"
const WINTER := &"winter"

# Seed metadata used by farm planting and seed menu UI.
# "seasons" controls when a seed can be planted.
# "allow_off_season" allows special rare seeds to bypass season lock.
const SEED_PLANTING_RULES := {
	Items.BLUEBERRY_SEED: {"seasons": [SUMMER], "allow_off_season": false},
	Items.WHEAT_SEED: {"seasons": [SUMMER], "allow_off_season": false},
	Items.MELON_SEED: {"seasons": [SUMMER], "allow_off_season": false},
	Items.CORN_SEED: {"seasons": [SUMMER], "allow_off_season": false},
	Items.HOT_PEPPER_SEED: {"seasons": [SUMMER], "allow_off_season": false},
	Items.RADISH_SEED: {"seasons": [SUMMER], "allow_off_season": false},
	Items.RED_CABBAGE_SEED: {"seasons": [SUMMER], "allow_off_season": false},
	Items.TOMATO_SEED: {"seasons": [SUMMER], "allow_off_season": false},
	Items.CARROT_SEED: {"seasons": [SPRING], "allow_off_season": false},
	Items.CAULIFLOWER_SEED: {"seasons": [SPRING], "allow_off_season": false},
	Items.POTATO_SEED: {"seasons": [SPRING], "allow_off_season": false},
	Items.PARSNIP_SEED: {"seasons": [SPRING], "allow_off_season": false},
	Items.GARLIC_SEED: {"seasons": [SPRING], "allow_off_season": false},
	Items.GREEN_BEANS_SEED: {"seasons": [SPRING], "allow_off_season": false},
	Items.STRAWBERRY_SEED: {"seasons": [SPRING], "allow_off_season": false},
	Items.COFFEE_BEAN_SEED: {"seasons": [SPRING], "allow_off_season": false},
	Items.PUMPKIN_SEED: {"seasons": [FALL], "allow_off_season": false},
	Items.BROCCOLI_SEED: {"seasons": [FALL], "allow_off_season": false},
	Items.ARTICHOKE_SEED: {"seasons": [FALL], "allow_off_season": false},
	Items.EGGPLANT_SEED: {"seasons": [FALL], "allow_off_season": false},
	Items.BOK_CHOY_SEED: {"seasons": [FALL], "allow_off_season": false},
	Items.GRAPE_SEED: {"seasons": [FALL], "allow_off_season": false}
}

func get_seed_seasons(seed_type: Items) -> Array:
	if not SEED_PLANTING_RULES.has(seed_type):
		return []

	return Array(SEED_PLANTING_RULES[seed_type].get("seasons", []))

func seed_allows_off_season_planting(seed_type: Items) -> bool:
	if not SEED_PLANTING_RULES.has(seed_type):
		return false

	return bool(SEED_PLANTING_RULES[seed_type].get("allow_off_season", false))

func is_seed_in_season(seed_type: Items, season: StringName) -> bool:
	if seed_allows_off_season_planting(seed_type):
		return true

	var allowed_seasons := get_seed_seasons(seed_type)
	return season in allowed_seasons

# 3. TOOLS (Kept separate for state machine logic)
enum Tools { HOE, WATER, AXE, PLANT }

# 4. INVENTORY
# Keys are Items enum, Values are quantity
var inventory = {
	Items.BLUEBERRY_SEED: 0,
	Items.WHEAT_SEED: 0,
	Items.MELON_SEED: 0,
	Items.CORN_SEED: 0,
	Items.HOT_PEPPER_SEED: 0,
	Items.RADISH_SEED: 0,
	Items.RED_CABBAGE_SEED: 0,
	Items.TOMATO_SEED: 0,
	Items.CARROT_SEED: 0,
	Items.CAULIFLOWER_SEED: 0,
	Items.POTATO_SEED: 0,
	Items.PARSNIP_SEED: 0,
	Items.GARLIC_SEED: 0,
	Items.GREEN_BEANS_SEED: 0,
	Items.STRAWBERRY_SEED: 0,
	Items.COFFEE_BEAN_SEED: 0,
	Items.PUMPKIN_SEED: 0,
	Items.BROCCOLI_SEED: 0,
	Items.ARTICHOKE_SEED: 0,
	Items.EGGPLANT_SEED: 0,
	Items.BOK_CHOY_SEED: 0,
	Items.GRAPE_SEED: 0,
	Items.WOOD: 0,
	Items.APPLE: 0,
	Items.STONE: 0,
	Items.BLUEBERRY: 0,
	Items.WHEAT: 0,
	Items.MELON: 0,
	Items.CORN: 0,
	Items.HOT_PEPPER: 0,
	Items.RADISH: 0,
	Items.RED_CABBAGE: 0,
	Items.TOMATO: 0,
	Items.CARROT: 0,
	Items.CAULIFLOWER: 0,
	Items.POTATO: 0,
	Items.PARSNIP: 0,
	Items.GARLIC: 0,
	Items.GREEN_BEANS: 0,
	Items.STRAWBERRY: 0,
	Items.COFFEE_BEAN: 0,
	Items.PUMPKIN: 0,
	Items.BROCCOLI: 0,
	Items.ARTICHOKE: 0,
	Items.EGGPLANT: 0,
	Items.BOK_CHOY: 0,
	Items.GRAPE: 0,
	Items.WATER: 0,
	Items.ROASTED_CORN: 0,
	Items.TOMATO_SOUP: 0,
	Items.HERBAL_HASH: 0,
	Items.GARLIC_MASHED_POTATOES: 0,
	Items.GLAZED_CARROTS: 0,
	Items.ROASTED_ROOT_MEDLEY: 0,
	Items.CAULIFLOWER_STEAK: 0,
	Items.GREEN_BEAN_SAUTE: 0,
	Items.STRAWBERRY_ENERGY_BOWL: 0,
	Items.MORNING_COFFEE: 0,
	Items.PARSNIP_SOUP: 0,
}

# Early-game meal tuning notes:
# - Keep each meal on a 4-point total budget to preserve meaningful choice.
# - Early movement is capped at +1 MOV max; any extra power should flow into SPD/DEX/VIT instead.
const EARLY_FOOD_TOTAL_POWER_POINTS := 4
const EARLY_FOOD_MOVEMENT_CAP := 1

var recipes = {
	Items.ROASTED_CORN: {
		"display_name": "Roasted Corn",
		"buff_preview": "+3 VIT, +1 STR",
		"role_tag": "Frontliner",
		"ingredients": {Items.CORN: 1, Items.WOOD: 1}
	},
	Items.TOMATO_SOUP: {
		"display_name": "Tomato Soup",
		"buff_preview": "+1 DEX, +2 INT, +1 SPD",
		"role_tag": "Purifier",
		"ingredients": {Items.TOMATO: 2, Items.WATER: 1}
	},
	Items.HERBAL_HASH: {
		"display_name": "Herbal Hash",
		"buff_preview": "+1 VIT, +1 DEX, +1 SPD, +1 STR",
		"role_tag": "Generalist",
		"ingredients": {Items.POTATO: 1, Items.GARLIC: 1, Items.WOOD: 1}
	},
	Items.GARLIC_MASHED_POTATOES: {
		"display_name": "Garlic Mashed Potatoes",
		"buff_preview": "+2 STR, +2 DEF",
		"role_tag": "Frontliner",
		"strategy_note": "The Brawler meal for Savannah.",
		"ingredients": {Items.POTATO: 1, Items.GARLIC: 1}
	},
	Items.GLAZED_CARROTS: {
		"display_name": "Glazed Carrots",
		"buff_preview": "+3 DEX, +1 SPD",
		"role_tag": "Archer",
		"strategy_note": "Maximizes Silas's crit chance and accuracy.",
		"ingredients": {Items.CARROT: 1, Items.PARSNIP: 1}
	},
	Items.ROASTED_ROOT_MEDLEY: {
		"display_name": "Roasted Root Medley",
		"buff_preview": "+3 VIT, +1 STR",
		"role_tag": "Frontliner",
		"strategy_note": "Still a fantastic health boost before a boss fight, with less health bloat.",
		"ingredients": {Items.POTATO: 1, Items.CARROT: 1, Items.PARSNIP: 1}
	},
	Items.CAULIFLOWER_STEAK: {
		"display_name": "Cauliflower \"Steak\"",
		"buff_preview": "+3 INT, +1 DEF",
		"role_tag": "Purifier",
		"strategy_note": "Boosts Tera's magic/purifying power and keeps her safe.",
		"ingredients": {Items.CAULIFLOWER: 1, Items.GARLIC: 1}
	},
	Items.GREEN_BEAN_SAUTE: {
		"display_name": "Green Bean Sauté",
		"buff_preview": "+2 VIT, +2 SPD",
		"role_tag": "Archer",
		"strategy_note": "Perfect for dodging or repositioning.",
		"ingredients": {Items.GREEN_BEANS: 1, Items.GARLIC: 1}
	},
	Items.STRAWBERRY_ENERGY_BOWL: {
		"display_name": "Strawberry Energy Bowl",
		"buff_preview": "+2 VIT, +1 SPD, +1 MOV",
		"role_tag": "Archer",
		"strategy_note": "A budgeted speed snack with extra initiative and +1 movement.",
		"ingredients": {Items.STRAWBERRY: 1}
	},
	Items.MORNING_COFFEE: {
		"display_name": "Morning Coffee",
		"buff_preview": "+1 MOV, +2 SPD, +1 DEX",
		"role_tag": "Archer",
		"strategy_note": "Caffeine-fueled mobility and initiative with a focus bump.",
		"ingredients": {Items.COFFEE_BEAN: 1}
	},
	Items.PARSNIP_SOUP: {
		"display_name": "Parsnip Soup",
		"buff_preview": "+2 INT, +2 VIT",
		"role_tag": "Generalist",
		"strategy_note": "A balanced meal for hybrid support/tanking.",
		"ingredients": {Items.PARSNIP: 1, Items.POTATO: 1}
	}
}

const DEFAULT_KNOWN_RECIPES := []

var known_recipes: Array[int] = []

func knows_recipe(recipe_item: Items) -> bool:
	return recipe_item in known_recipes

func learn_recipe(recipe_item: Items, emit_update: bool = true) -> bool:
	if not recipes.has(recipe_item):
		var item_name := str(recipe_item)
		var item_keys := Items.keys()
		if recipe_item >= 0 and recipe_item < item_keys.size():
			item_name = item_keys[recipe_item]
		push_warning("[Global] Ignoring learn_recipe for invalid meal item: %s" % item_name)
		return false

	if knows_recipe(recipe_item):
		return false

	known_recipes.append(recipe_item)
	if emit_update:
		recipe_knowledge_updated.emit()
	return true

func reset_known_recipes_to_defaults() -> void:
	var had_known_recipes := not known_recipes.is_empty()
	known_recipes.clear()
	var learned_any := false
	for recipe_item in DEFAULT_KNOWN_RECIPES:
		if learn_recipe(recipe_item, false):
			learned_any = true

	if had_known_recipes or learned_any:
		recipe_knowledge_updated.emit()

func get_progression_save_data() -> Dictionary:
	return {
		"inventory": inventory.duplicate(true),
		"tutorial_step": tutorial_step,
		"current_day": current_day,
		"resolved_encounters": resolved_encounters.duplicate(true),
		"player_level": get_player_level(),
		"player_class_name": get_player_class_name(),
		"known_recipes": known_recipes.duplicate(),
		"loop_hub_mode_active": loop_hub_mode_active,
		"loop_gold": loop_gold,
		"loop_bloom_points": loop_bloom_points,
		"loop_battle_index": loop_battle_index,
		"loop_unlocked_plots": loop_unlocked_plots.duplicate(true),
		"loop_built_structures": loop_built_structures.duplicate(true),
		"loop_equipped_perk_item": loop_equipped_perk_item
	}

func apply_progression_save_data(save_data: Dictionary) -> void:
	if save_data.has("inventory") and save_data.inventory is Dictionary:
		inventory = save_data.inventory.duplicate(true)

	tutorial_step = int(save_data.get("tutorial_step", tutorial_step))
	current_day = int(save_data.get("current_day", current_day))
	resolved_encounters = Array(save_data.get("resolved_encounters", resolved_encounters)).duplicate(true)
	set_player_level(int(save_data.get("player_level", get_player_level())))
	set_player_class_name(String(save_data.get("player_class_name", get_player_class_name())))
	_migrate_known_recipes_from_save(save_data)
	loop_hub_mode_active = bool(save_data.get("loop_hub_mode_active", loop_hub_mode_active))
	loop_gold = int(save_data.get("loop_gold", loop_gold))
	loop_bloom_points = int(save_data.get("loop_bloom_points", loop_bloom_points))
	loop_battle_index = maxi(int(save_data.get("loop_battle_index", loop_battle_index)), 1)
	var saved_loop_plots = save_data.get("loop_unlocked_plots", loop_unlocked_plots)
	if saved_loop_plots is Dictionary:
		loop_unlocked_plots = saved_loop_plots.duplicate(true)
	var saved_loop_structures = save_data.get("loop_built_structures", loop_built_structures)
	if saved_loop_structures is Dictionary:
		loop_built_structures = saved_loop_structures.duplicate(true)
	loop_equipped_perk_item = int(save_data.get("loop_equipped_perk_item", loop_equipped_perk_item))
	inventory_updated.emit()
	update_tutorial_ui()
	loop_state_changed.emit()

func _migrate_known_recipes_from_save(save_data: Dictionary) -> void:
	if not save_data.has("known_recipes"):
		reset_known_recipes_to_defaults()
		return

	known_recipes.clear()
	var learned_any := false
	for raw_recipe in Array(save_data.get("known_recipes", [])):
		var recipe_item := int(raw_recipe)
		if recipes.has(recipe_item):
			if learn_recipe(recipe_item, false):
				learned_any = true

	if learned_any:
		recipe_knowledge_updated.emit()

	if known_recipes.is_empty():
		reset_known_recipes_to_defaults()

var unlocked_tools: Array[Tools] = []

# 5. HELPER FUNCTIONS
func add_item(item_type: Items, amount: int = 1):
	if item_type in inventory:
		inventory[item_type] += amount
	else:
		inventory[item_type] = amount
		
	# Emit the signal so the UI knows to refresh!
	inventory_updated.emit()

func reset_demo_state() -> void:
	for item_type in inventory.keys():
		inventory[item_type] = 0

	unlocked_tools.clear()
	resolved_encounters.clear()
	pending_combat_scene_path = ""
	pending_day_transition = false
	combat_transition.started_at_unix = 0.0
	saved_farm_scene = null
	returning_from_combat = false
	loop_hub_mode_active = false
	loop_gold = 0
	loop_bloom_points = 0
	loop_battle_index = 1
	loop_unlocked_plots.clear()
	loop_built_structures.clear()
	loop_equipped_perk_item = -1
	pending_intro_forest_visit = false
	pending_intro_forest_return = false
	intro_forest_day_time_left = 0.0
	pending_materials_forest_visit = false
	pending_materials_forest_return = false
	demo_cabin_built = false
	demo_merchant_intro_seen = false
	current_day = 1
	intro_sequence_complete = false
	tutorial_enabled = false
	tutorial_step = 0
	last_battle_result = {
		"victory": false,
		"enemies_defeated": 0,
		"returned_at_unix": 0
	}
	reset_known_recipes_to_defaults()
	active_food_buff.item = null
	active_food_buff.stats = _build_stat_template()
	temporary_stat_modifiers.food = _build_stat_template()
	temporary_stat_modifiers.equipment = _build_stat_template()
	set_player_unbuffed_hp(int(get_player_permanent_totals().get("MAX_HP", 20)))
	inventory_updated.emit()
	recipe_knowledge_updated.emit()
	stats_updated.emit()
	tutorial_updated.emit("")
	loop_state_changed.emit()

func begin_loop_hub_run() -> void:
	reset_demo_state()
	if DemoDirector and DemoDirector.has_method("begin_loop_tutorial_run"):
		DemoDirector.begin_loop_tutorial_run()
	loop_hub_mode_active = true
	loop_gold = 0
	loop_bloom_points = 0
	loop_battle_index = 1
	loop_unlocked_plots[String(LOOP_PLOT_STARTING_FARM)] = true
	inventory[Items.WOOD] = 0
	inventory[Items.STONE] = 0
	inventory[Items.CARROT_SEED] = 4
	inventory[Items.PARSNIP_SEED] = 4
	inventory[Items.POTATO_SEED] = 4
	inventory[Items.GARLIC_SEED] = 4
	unlocked_tools = [Tools.AXE]
	learn_recipe(Items.GARLIC_MASHED_POTATOES, false)
	learn_recipe(Items.GLAZED_CARROTS, false)
	learn_recipe(Items.ROASTED_ROOT_MEDLEY, false)
	if ProgressionService and ProgressionService.has_method("reset_demo_roster"):
		ProgressionService.reset_demo_roster()
	inventory_updated.emit()
	recipe_knowledge_updated.emit()
	stats_updated.emit()
	loop_state_changed.emit()

func has_loop_plot(plot_id: StringName) -> bool:
	return bool(loop_unlocked_plots.get(String(plot_id), false))

func unlock_loop_plot(plot_id: StringName) -> void:
	loop_unlocked_plots[String(plot_id)] = true
	loop_state_changed.emit()

func is_loop_structure_built(structure_id: StringName) -> bool:
	return bool(loop_built_structures.get(String(structure_id), false))

func build_loop_structure(structure_id: StringName) -> void:
	loop_built_structures[String(structure_id)] = true
	loop_state_changed.emit()

func add_loop_gold(amount: int) -> void:
	if amount == 0:
		return
	loop_gold = maxi(loop_gold + amount, 0)
	loop_state_changed.emit()

func add_loop_bloom_points(amount: int) -> void:
	if amount == 0:
		return
	loop_bloom_points = maxi(loop_bloom_points + amount, 0)
	loop_state_changed.emit()

func spend_loop_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if loop_gold < amount:
		return false
	loop_gold -= amount
	loop_state_changed.emit()
	return true

func spend_loop_bloom_points(amount: int) -> bool:
	if amount <= 0:
		return true
	if loop_bloom_points < amount:
		return false
	loop_bloom_points -= amount
	loop_state_changed.emit()
	return true

func set_loop_equipped_perk(recipe_item: Items) -> void:
	loop_equipped_perk_item = int(recipe_item)
	loop_state_changed.emit()

func clear_loop_equipped_perk() -> void:
	if loop_equipped_perk_item == -1:
		return
	loop_equipped_perk_item = -1
	loop_state_changed.emit()

func has_loop_equipped_perk() -> bool:
	return loop_equipped_perk_item >= 0

func get_loop_equipped_perk_item() -> int:
	return loop_equipped_perk_item

func get_loop_equipped_perk_label() -> String:
	if not has_loop_equipped_perk():
		return "None"
	var recipe_data: Dictionary = recipes.get(loop_equipped_perk_item, {})
	var item_keys := Items.keys()
	var fallback_name := "Unknown"
	if loop_equipped_perk_item >= 0 and loop_equipped_perk_item < item_keys.size():
		fallback_name = String(item_keys[loop_equipped_perk_item])
	return String(recipe_data.get("display_name", fallback_name))

func consume_loop_equipped_perk_stats() -> Dictionary:
	if not has_loop_equipped_perk():
		return {}
	var perk_item := loop_equipped_perk_item
	clear_loop_equipped_perk()
	return food_stats.get(perk_item, {}).duplicate(true)

func remove_item(item_type: Items, amount: int = 1) -> bool:
	if inventory.get(item_type, 0) >= amount:
		inventory[item_type] -= amount
		inventory_updated.emit()
		return true
	return false

func get_seed_count(seed_type: Items) -> int:
	return inventory.get(seed_type, 0)

# ==========================================
# Phase 1: RPG STATS & COMBAT DATA
# ==========================================

const PLAYER_STAT_KEYS := ["MAX_HP", "HP", "VIT", "STR", "DEF", "DEX", "INT", "SPD", "MOV", "ATK_RNG"]
const TEMP_MODIFIER_KEYS := ["VIT", "STR", "DEF", "DEX", "INT", "SPD", "MOV", "ATK_RNG"]


func _build_stat_template(default_value: int = 0, include_hp: bool = false) -> Dictionary:
	var template: Dictionary = {}
	for stat_name in TEMP_MODIFIER_KEYS:
		template[stat_name] = default_value

	template["MAX_HP"] = default_value
	if include_hp:
		template["HP"] = default_value

	return template

# 1. Base Stats
var player_stats = {
	"MAX_HP": 20,  # Max Health
	"HP": 20,      # Current Health (This lets her stay injured after battle!)
	"VIT": 10,     # Determines Max HP growth on level up
	"STR": 5,      # Physical Damage
	"DEF": 2,      # NEW: Physical Damage Reduction
	"DEX": 5,      # Accuracy / Crit Chance
	"INT": 5,      # Magic Damage / Healing Power
	"SPD": 5,      # Turn Order / Evasion
	"MOV": 4,      # Grid Movement tiles per turn
	"ATK_RNG": 1   # How many tiles away she can attack (1 for melee)
}

const PLAYER_GROWTH_RATES := {
	"MAX_HP": 80,
	"VIT": 55,
	"STR": 45,
	"DEF": 25,
	"DEX": 45,
	"INT": 30,
	"SPD": 40,
	"MOV": 10,
	"ATK_RNG": 0
}

# 1A. Permanent stats are split into immutable base values and level-derived gains.
# `current_hp` is unbuffed HP so temporary buffs can come and go safely.
var player_permanent_stats = {
	"base": {
		"MAX_HP": 20,
		"VIT": 10,
		"STR": 5,
		"DEF": 2,
		"DEX": 5,
		"INT": 5,
		"SPD": 5,
		"MOV": 4,
		"ATK_RNG": 1
	},
	"level_derived": _build_stat_template(),
	"current_hp": 20
}


# 1B. Temporary modifiers are separated by source and combined only when needed.
var temporary_stat_modifiers = {
	"food": _build_stat_template(),
	"equipment": _build_stat_template()
}

# 2. Equipment Slots
# This tracks what the player is currently wearing. (null means empty)
var equipment = {
	"Weapon": null,
	"Armor": null,
	"Accessory": null
}

# 3. The Active Food Buff
# This tracks what meal the player ate today and what temporary stats it is giving them.
var active_food_buff = {
	"item": null, # e.g., Items.ROASTED_CORN
	"stats": temporary_stat_modifiers.food
}

# 4. The Food Database
# This tells the game exactly what stats to apply when a specific meal is eaten!
var food_stats = {
	# Frontliner path: durable, no movement dependency.
	Items.ROASTED_CORN: {"VIT": 3, "STR": 1, "DEF": 0, "DEX": 0, "INT": 0, "SPD": 0, "MOV": 0},
	# Purifier path: casting tempo and reliability, still no movement dependency.
	Items.TOMATO_SOUP:  {"VIT": 0, "STR": 0, "DEF": 0, "DEX": 1, "INT": 2, "SPD": 1, "MOV": 0},
	# Generalist fallback: broadly useful when role-specific ingredients are unavailable.
	Items.HERBAL_HASH:  {"VIT": 1, "STR": 1, "DEF": 0, "DEX": 1, "INT": 0, "SPD": 1, "MOV": 0},
	Items.GARLIC_MASHED_POTATOES: {"VIT": 0, "STR": 2, "DEF": 2, "DEX": 0, "INT": 0, "SPD": 0, "MOV": 0},
	Items.GLAZED_CARROTS: {"VIT": 0, "STR": 0, "DEF": 0, "DEX": 3, "INT": 0, "SPD": 1, "MOV": 0},
	Items.ROASTED_ROOT_MEDLEY: {"VIT": 3, "STR": 1, "DEF": 0, "DEX": 0, "INT": 0, "SPD": 0, "MOV": 0},
	Items.CAULIFLOWER_STEAK: {"VIT": 0, "STR": 0, "DEF": 1, "DEX": 0, "INT": 3, "SPD": 0, "MOV": 0},
	Items.GREEN_BEAN_SAUTE: {"VIT": 2, "STR": 0, "DEF": 0, "DEX": 0, "INT": 0, "SPD": 2, "MOV": 0},
	Items.STRAWBERRY_ENERGY_BOWL: {"VIT": 2, "STR": 0, "DEF": 0, "DEX": 0, "INT": 0, "SPD": 1, "MOV": 1},
	Items.MORNING_COFFEE: {"VIT": 0, "STR": 0, "DEF": 0, "DEX": 1, "INT": 0, "SPD": 2, "MOV": 1},
	Items.PARSNIP_SOUP: {"VIT": 2, "STR": 0, "DEF": 0, "DEX": 0, "INT": 2, "SPD": 0, "MOV": 0}
	# Add future meals here (respect early MOV cap and total power budget).
}

# ==========================================
# Phase 2: VILLAGER MORALE DATA
# ==========================================

# This will track the overall health of the town
var town_morale: int = 100 # Percentage 0-100
var villagers_fed_yesterday: bool = true


func ensure_player_stat_formats() -> void:
	var has_new_permanent_format := player_permanent_stats is Dictionary and player_permanent_stats.has("base")

	if not has_new_permanent_format:
		_upgrade_legacy_player_stats(player_stats)
		return

	if not _legacy_snapshot_matches_permanent(player_stats):
		_upgrade_legacy_player_stats(player_stats)
		return

	player_permanent_stats.base = _normalize_permanent_bucket(player_permanent_stats.get("base", {}), player_stats)
	player_permanent_stats.level_derived = _normalize_permanent_bucket(player_permanent_stats.get("level_derived", {}), _build_stat_template())
	player_permanent_stats.current_hp = int(player_permanent_stats.get("current_hp", player_stats.get("HP", 20)))

	temporary_stat_modifiers.food = _normalize_temporary_bucket(active_food_buff.get("stats", temporary_stat_modifiers.get("food", {})))
	temporary_stat_modifiers.equipment = _normalize_temporary_bucket(temporary_stat_modifiers.get("equipment", {}))
	_refresh_equipment_temporary_modifiers()
	active_food_buff.stats = temporary_stat_modifiers.food

	_sync_legacy_player_stats_snapshot()


func _upgrade_legacy_player_stats(legacy_stats: Dictionary) -> void:
	var normalized_legacy := _normalize_legacy_snapshot(legacy_stats)

	player_permanent_stats = {
		"base": {
			"MAX_HP": normalized_legacy["MAX_HP"],
			"VIT": normalized_legacy["VIT"],
			"STR": normalized_legacy["STR"],
			"DEF": normalized_legacy["DEF"],
			"DEX": normalized_legacy["DEX"],
			"INT": normalized_legacy["INT"],
			"SPD": normalized_legacy["SPD"],
			"MOV": normalized_legacy["MOV"],
			"ATK_RNG": normalized_legacy["ATK_RNG"]
		},
		"level_derived": _build_stat_template(),
		"current_hp": normalized_legacy["HP"]
	}

	temporary_stat_modifiers.food = _normalize_temporary_bucket(active_food_buff.get("stats", {}))
	temporary_stat_modifiers.equipment = _normalize_temporary_bucket({})
	active_food_buff.stats = temporary_stat_modifiers.food

	_sync_legacy_player_stats_snapshot()


func _refresh_equipment_temporary_modifiers() -> void:
	var combined_modifiers := _build_stat_template()
	for slot_name in ["Weapon", "Armor", "Accessory"]:
		var slot_entry = equipment.get(slot_name, null)
		var slot_modifiers := _extract_equipment_stat_modifiers(slot_entry)
		for stat_name in TEMP_MODIFIER_KEYS:
			combined_modifiers[stat_name] = int(combined_modifiers.get(stat_name, 0)) + int(slot_modifiers.get(stat_name, 0))
		combined_modifiers["MAX_HP"] = int(combined_modifiers.get("MAX_HP", 0)) + int(slot_modifiers.get("MAX_HP", 0))

	temporary_stat_modifiers.equipment = _normalize_temporary_bucket(combined_modifiers)


func _extract_equipment_stat_modifiers(slot_entry) -> Dictionary:
	var resolved := _build_stat_template()
	if slot_entry == null:
		return resolved

	var stat_bonuses: Dictionary = {}
	if slot_entry is Resource:
		var resource_bonuses = slot_entry.get("stat_bonuses")
		if resource_bonuses is Dictionary:
			stat_bonuses = resource_bonuses
	elif slot_entry is Dictionary:
		if slot_entry.has("stat_bonuses") and slot_entry["stat_bonuses"] is Dictionary:
			stat_bonuses = slot_entry["stat_bonuses"]
		else:
			stat_bonuses = slot_entry

	var key_map := {
		"strength": "STR",
		"defense": "DEF",
		"magic_defense": "MDEF",
		"dexterity": "DEX",
		"intelligence": "INT",
		"speed": "SPD",
		"move_range": "MOV",
		"attack_range": "ATK_RNG",
		"max_health": "MAX_HP"
	}

	for source_key in key_map.keys():
		var target_key := String(key_map[source_key])
		resolved[target_key] = int(resolved.get(target_key, 0)) + int(stat_bonuses.get(source_key, 0))

	return resolved


func get_player_permanent_totals() -> Dictionary:
	ensure_player_stat_formats()
	return _compute_permanent_totals()


func _compute_permanent_totals() -> Dictionary:
	var totals := _build_stat_template(0, true)
	for stat_name in TEMP_MODIFIER_KEYS:
		totals[stat_name] = int(player_permanent_stats.base.get(stat_name, 0)) + int(player_permanent_stats.level_derived.get(stat_name, 0))

	totals["MAX_HP"] = int(player_permanent_stats.base.get("MAX_HP", 0)) + int(player_permanent_stats.level_derived.get("MAX_HP", 0))
	totals["HP"] = clampi(int(player_permanent_stats.current_hp), 0, totals["MAX_HP"])
	return totals


func get_player_temporary_modifiers() -> Dictionary:
	ensure_player_stat_formats()

	var combined := _build_stat_template()
	for stat_name in TEMP_MODIFIER_KEYS:
		combined[stat_name] = int(temporary_stat_modifiers.food.get(stat_name, 0)) + int(temporary_stat_modifiers.equipment.get(stat_name, 0))

	combined["MAX_HP"] = int(temporary_stat_modifiers.food.get("MAX_HP", 0)) + int(temporary_stat_modifiers.equipment.get("MAX_HP", 0))
	return combined


func get_player_combat_snapshot() -> Dictionary:
	var permanent := get_player_permanent_totals()
	var temporary := get_player_temporary_modifiers()
	var combined := permanent.duplicate(true)

	for stat_name in TEMP_MODIFIER_KEYS:
		combined[stat_name] = int(combined.get(stat_name, 0)) + int(temporary.get(stat_name, 0))

	combined["MAX_HP"] = int(permanent.get("MAX_HP", 0)) + int(temporary.get("MAX_HP", 0)) + (int(temporary.get("VIT", 0)) * 2)
	combined["HP"] = clampi(int(permanent.get("HP", 0)) + int(temporary.get("MAX_HP", 0)) + (int(temporary.get("VIT", 0)) * 2), 0, combined["MAX_HP"])
	return combined


func set_player_unbuffed_hp(new_hp: int) -> void:
	var permanent := get_player_permanent_totals()
	player_permanent_stats.current_hp = clampi(new_hp, 0, int(permanent.get("MAX_HP", 0)))
	_sync_legacy_player_stats_snapshot()


func get_player_level() -> int:
	return maxi(player_level, 1)


func set_player_level(new_level: int) -> void:
	player_level = maxi(new_level, 1)




func get_player_class_name() -> String:
	if player_class_name.strip_edges().is_empty():
		return "Unknown"
	return player_class_name


func set_player_class_name(new_class_name: String) -> void:
	player_class_name = new_class_name.strip_edges()
	if player_class_name.is_empty():
		player_class_name = "Unknown"

func apply_player_auto_levels(level_count: int, growth_rates: Dictionary = PLAYER_GROWTH_RATES) -> Dictionary:
	ensure_player_stat_formats()
	var resolved_levels := maxi(level_count, 0)

	var gained_stats := _build_stat_template()
	for _level in range(resolved_levels):
		for stat_name in growth_rates.keys():
			var normalized_stat := String(stat_name)
			if normalized_stat == "HP":
				normalized_stat = "MAX_HP"

			if not player_permanent_stats.level_derived.has(normalized_stat):
				continue

			if not _roll_growth(int(growth_rates[stat_name])):
				continue

			player_permanent_stats.level_derived[normalized_stat] = int(player_permanent_stats.level_derived.get(normalized_stat, 0)) + 1
			gained_stats[normalized_stat] = int(gained_stats.get(normalized_stat, 0)) + 1

	var permanent := _compute_permanent_totals()
	player_permanent_stats.current_hp = int(permanent.get("MAX_HP", player_permanent_stats.current_hp))
	player_level = maxi(player_level + resolved_levels, 1)
	_sync_legacy_player_stats_snapshot()
	return gained_stats


func _roll_growth(chance_percent: int) -> bool:
	var progression_service := get_node_or_null("/root/ProgressionService")
	if progression_service != null and progression_service.has_method("roll_growth"):
		return bool(progression_service.call("roll_growth", chance_percent))

	var clamped_chance := clampi(chance_percent, 0, 100)
	return randf() < (clamped_chance / 100.0)


func _sync_legacy_player_stats_snapshot() -> void:
	var permanent := _compute_permanent_totals()
	player_stats = permanent




func _legacy_snapshot_matches_permanent(legacy_stats: Dictionary) -> bool:
	if not legacy_stats.has("MAX_HP"):
		return true

	var normalized_legacy := _normalize_legacy_snapshot(legacy_stats)
	var permanent := _compute_permanent_totals()

	for stat_name in PLAYER_STAT_KEYS:
		if int(normalized_legacy.get(stat_name, 0)) != int(permanent.get(stat_name, 0)):
			return false

	return true

func _normalize_legacy_snapshot(legacy_stats: Dictionary) -> Dictionary:
	return {
		"MAX_HP": int(legacy_stats.get("MAX_HP", 20)),
		"HP": int(legacy_stats.get("HP", legacy_stats.get("MAX_HP", 20))),
		"VIT": int(legacy_stats.get("VIT", 10)),
		"STR": int(legacy_stats.get("STR", 5)),
		"DEF": int(legacy_stats.get("DEF", 2)),
		"DEX": int(legacy_stats.get("DEX", 5)),
		"INT": int(legacy_stats.get("INT", 5)),
		"SPD": int(legacy_stats.get("SPD", 5)),
		"MOV": int(legacy_stats.get("MOV", 4)),
		"ATK_RNG": int(legacy_stats.get("ATK_RNG", 1))
	}


func _normalize_permanent_bucket(source: Dictionary, fallback_source: Dictionary = {}) -> Dictionary:
	var normalized := _build_stat_template()
	for stat_name in normalized.keys():
		normalized[stat_name] = int(source.get(stat_name, fallback_source.get(stat_name, normalized[stat_name])))
	return normalized


func _normalize_temporary_bucket(source: Dictionary) -> Dictionary:
	var normalized := _build_stat_template()
	for stat_name in normalized.keys():
		normalized[stat_name] = int(source.get(stat_name, 0))
	return normalized
