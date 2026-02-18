extends Node

signal inventory_updated

# 1. THE MASTER ITEM LIST
# We distinguish between the SEED (what you plant) and the CROP (what you eat/sell)
enum Items {
	# Seeds
	CORN_SEED, TOMATO_SEED, PUMPKIN_SEED,
	# Crops
	CORN, TOMATO, PUMPKIN,
	# Resources
	WOOD, APPLE, STONE
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
	Items.CORN_SEED: 5,
	Items.TOMATO_SEED: 5,
	Items.PUMPKIN_SEED: 5,
	Items.WOOD: 0,
	Items.APPLE: 0
}

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
