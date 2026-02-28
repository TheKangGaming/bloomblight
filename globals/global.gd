extends Node

signal inventory_updated
@warning_ignore('unused_signal')
signal stats_updated

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

# 1. Base Stats
var player_stats = {
	"MAX_HP": 20,  # Max Health
	"HP": 20,      # Current Health (This lets her stay injured after battle!)
	"VIT": 10,     # Health / Physical Defense
	"STR": 5,      # Physical Damage
	"DEX": 5,      # Accuracy / Crit Chance
	"INT": 5,      # Magic Damage / Healing Power
	"SPD": 5,      # Turn Order / Evasion
	"MOV": 4,      # Grid Movement tiles per turn
	"ATK_RNG": 1   # How many tiles away she can attack (1 for melee)
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
	"stats": {    # The bonus stats granted by the meal
		"VIT": 0,
		"STR": 0,
		"DEX": 0,
		"INT": 0,
		"SPD": 0,
		"MOV": 0
	}
}

# 4. The Food Database
# This tells the game exactly what stats to apply when a specific meal is eaten!
var food_stats = {
	Items.ROASTED_CORN: {"VIT": 2, "STR": 2, "DEX": 0, "INT": 0, "SPD": 0, "MOV": 0},
	Items.TOMATO_SOUP:  {"VIT": 0, "STR": 0, "DEX": 1, "INT": 2, "SPD": 1, "MOV": 0}
	# Add future meals here (e.g., a late-game meal might give +1 MOV!)
}

# ==========================================
# Phase 2: VILLAGER MORALE DATA
# ==========================================

# This will track the overall health of the town
var town_morale: int = 100 # Percentage 0-100
var villagers_fed_yesterday: bool = true
