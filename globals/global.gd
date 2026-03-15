extends Node

func _ready() -> void:
	ensure_player_stat_formats()
	_sync_player_progression_from_combat_scene_template()


func _sync_player_progression_from_combat_scene_template() -> void:
	var combat_template := load("res://scenes/level/CombatMap_1.tscn") as PackedScene
	if combat_template == null:
		return

	var combat_root := combat_template.instantiate()
	if combat_root == null:
		return

	var savannah := combat_root.get_node_or_null("GameBoard/Savannah")
	if savannah == null:
		combat_root.queue_free()
		return

	var template_level := int(savannah.get("level"))
	if template_level > get_player_level():
		apply_player_auto_levels(template_level - get_player_level())

	var character_data = savannah.get("character_data")
	if character_data != null:
		var class_data = character_data.get("class_data")
		if class_data != null:
			var template_class_name := String(class_data.get("metadata_name"))
			if not template_class_name.strip_edges().is_empty():
				set_player_class_name(template_class_name)

	combat_root.queue_free()


signal inventory_updated
@warning_ignore('unused_signal')
signal stats_updated
var saved_farm_scene: Node = null

var returning_from_combat: bool = false
var player_level: int = 1
var player_class_name: String = "Deserter"
var last_battle_result := {
	"victory": false,
	"enemies_defeated": 0,
	"returned_at_unix": 0
}

# --- TIME & CALENDAR STATE ---
var current_day: int = 1
var pending_day_transition: bool = false

# Tracks which encounters have been beaten (for save/load later)
var resolved_encounters: Array = [] 

# Used to temporarily hold the specific map we need to load
var pending_combat_scene_path: String = ""
# -----------------------------

# --- TUTORIAL SYSTEM ---
signal tutorial_updated(text: String)
var tutorial_step: int = 0
const MAX_TUTORIAL_STEP := 15

## Progresses to the next quest and tells the UI to update
func advance_tutorial() -> void:
	tutorial_step = min(tutorial_step + 1, MAX_TUTORIAL_STEP)
	update_tutorial_ui()

## Broadcasts the current quest text to the screen
func update_tutorial_ui() -> void:
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
		13: tutorial_updated.emit("Quest: Press C to enter your first Battle!")
		14: tutorial_updated.emit("Quest: Defeat the enemy and return to the farm!")
		15: tutorial_updated.emit("") # An empty string will hide the UI!
		_:
			tutorial_updated.emit("") # An empty string will hide the UI!

var combat_transition := {
	"started_at_unix": 0.0
}

var has_seen_combat_intro: bool = false

func begin_combat_transition() -> void:
	combat_transition.started_at_unix = Time.get_unix_time_from_system()

func consume_combat_elapsed_seconds() -> float:
	if combat_transition.started_at_unix <= 0.0:
		return 0.0

	var elapsed = max(Time.get_unix_time_from_system() - combat_transition.started_at_unix, 0.0)
	combat_transition.started_at_unix = 0.0
	return elapsed


# 1. THE MASTER ITEM LIST
# We distinguish between the SEED (what you plant) and the CROP (what you eat/sell)
enum Items {
	# Seeds
	BLUEBERRY_SEED, WHEAT_SEED, MELON_SEED, CORN_SEED, HOT_PEPPER_SEED, RADISH_SEED, RED_CABBAGE_SEED, TOMATO_SEED,
	CARROT_SEED, CAULIFLOWER_SEED, POTATO_SEED, PARSNIP_SEED, GARLIC_SEED, GREEN_BEANS_SEED, STRAWBERRY_SEED, COFFEE_BEAN_SEED,
	PUMPKIN_SEED, BROCCOLI_SEED, ARTICHOKE_SEED, EGGPLANT_SEED, BOK_CHOY_SEED, GRAPE_SEED,
	# Crops
	BLUEBERRY, WHEAT, MELON, CORN, HOT_PEPPER, RADISH, RED_CABBAGE, TOMATO,
	CARROT, CAULIFLOWER, POTATO, PARSNIP, GARLIC, GREEN_BEANS, STRAWBERRY, COFFEE_BEAN,
	PUMPKIN, BROCCOLI, ARTICHOKE, EGGPLANT, BOK_CHOY, GRAPE,
	# Resources
	WOOD, APPLE, STONE , WATER,
	
	# Food
	
	ROASTED_CORN, TOMATO_SOUP
}

# 2. HARVEST MAPPING
# This tells the game: "If I harvest a CORN_SEED plant, give me a CORN item."
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
}

var recipes = {
	Items.ROASTED_CORN: {
		"display_name": "Roasted Corn",
		"buff_preview": "+2 VIT, +2 STR",
		"role_tag": "Frontliner",
		"ingredients": {Items.CORN: 1, Items.WOOD: 1}
	},
	Items.TOMATO_SOUP: {
		"display_name": "Tomato Soup",
		"buff_preview": "+1 DEX, +2 INT, +1 SPD",
		"role_tag": "Purifier",
		"ingredients": {Items.TOMATO: 2, Items.WATER: 1}
	}
}

var unlocked_tools: Array[Tools] = []

# 5. HELPER FUNCTIONS
func add_item(item_type: Items, amount: int = 1):
	if item_type in inventory:
		inventory[item_type] += amount
	else:
		inventory[item_type] = amount
		
	# Emit the signal so the UI knows to refresh!
	inventory_updated.emit()
	print("Added ", amount, " of ", Items.keys()[item_type], ". Total: ", inventory[item_type])

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
	Items.ROASTED_CORN: {"VIT": 2, "STR": 2, "DEF": 0, "DEX": 0, "INT": 0, "SPD": 0, "MOV": 0},
	Items.TOMATO_SOUP:  {"VIT": 0, "STR": 0, "DEF": 0, "DEX": 1, "INT": 2, "SPD": 1, "MOV": 0}
	# Add future meals here (e.g., a late-game meal might give +1 MOV!)
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
