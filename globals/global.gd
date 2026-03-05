extends Node

func _ready() -> void:
	ensure_player_stat_formats()


signal inventory_updated
@warning_ignore('unused_signal')
signal stats_updated
var saved_farm_scene: Node = null

var returning_from_combat: bool = false
var player_level: int = 1
var last_battle_result := {
	"victory": false,
	"enemies_defeated": 0,
	"returned_at_unix": 0
}

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
	CORN_SEED, TOMATO_SEED, PUMPKIN_SEED,
	# Crops
	CORN, TOMATO, PUMPKIN,
	# Resources
	WOOD, APPLE, STONE , WATER,
	
	# Food
	
	ROASTED_CORN, TOMATO_SOUP
}

# 2. HARVEST MAPPING
# This tells the game: "If I harvest a CORN_SEED plant, give me a CORN item."
const HARVEST_DROPS = {
	Items.CORN_SEED: Items.CORN,
	Items.TOMATO_SEED: Items.TOMATO,
	Items.PUMPKIN_SEED: Items.PUMPKIN
}

# 3. TOOLS (Kept separate for state machine logic)
enum Tools { HOE, WATER, AXE, PLANT }

# 4. INVENTORY
# Keys are Items enum, Values are quantity
var inventory = {
	Items.CORN_SEED: 0,
	Items.TOMATO_SEED: 0,
	Items.PUMPKIN_SEED: 0,
	Items.WOOD: 0,
	Items.APPLE: 0,
	Items.STONE: 0,
	Items.TOMATO: 0,
	Items.WATER: 0,
	Items.ROASTED_CORN: 0,
	Items.TOMATO_SOUP: 0,
	Items.CORN: 0
}

var recipes = {
	Items.ROASTED_CORN: {Items.CORN: 1, Items.WOOD: 1},
	Items.TOMATO_SOUP: {Items.TOMATO: 2, Items.WATER: 1}
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
