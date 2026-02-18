extends Control

@onready var inventory_grid = $Background/TabContainer/Inventory/Margin/Grid
const SLOT_SCENE = preload("res://scenes/ui/inventory_slot.tscn") 

func _ready() -> void:
	visible = false
	# We process input even when paused so we can close the menu
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	Global.inventory_updated.connect(update_inventory)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"): # Default TAB key in Godot
		toggle_menu()

func toggle_menu():
	visible = not visible
	get_tree().paused = visible # Pause the game world
	
	if visible:
		update_inventory()

func update_inventory():
	# Clear existing slots
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Loop through global inventory
	for item_enum in Global.inventory:
		var count = Global.inventory[item_enum]
		if count > 0:
			var slot = SLOT_SCENE.instantiate()
			inventory_grid.add_child(slot)
			# We will assume your slot has a setup function
			# Pass the Item Name and Count
			var item_name = Global.Items.keys()[item_enum]
			slot.setup(item_name, count)
