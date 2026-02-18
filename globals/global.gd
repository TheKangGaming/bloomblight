extends Node

signal inventory_updated

enum Seeds {CORN, TOMATO, PUMPKIN}

# 1. The Inventory Dictionary
# Keys will be the Seeds enum, Values will be the quantity (int)
var inventory = {
	Seeds.CORN: 5,
	Seeds.TOMATO: 5,
	Seeds.PUMPKIN: 5
}
# 2. A function to add items
func add_item(type: Seeds, amount: int = 1):
	if type in inventory:
		inventory[type] += amount
		# print so we know it's working
		print("Added " + str(amount) + " " + str(Seeds.keys()[type]) + ". Total: " + str(inventory[type]))
	else:
		# Safety check in case we add a new seed type later and forget to add it to the dictionary
		inventory[type] = amount
		
	inventory_updated.emit()
