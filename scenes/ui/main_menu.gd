extends Control

@onready var inventory_grid = $CenterContainer/TabContainer/Inventory/Margin/Grid
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
		# DEBUG: Force the container to "wake up"
		var tabs = $CenterContainer/TabContainer
		tabs.current_tab = 0
		tabs.visible = true
		
		# DEBUG: Print status to console
		print("Menu Open. TabContainer Size: ", tabs.size)
		print("TabContainer Visible: ", tabs.visible)
		print("Inventory Grid Path Valid: ", inventory_grid != null)
		update_inventory()

func update_inventory():

	if not inventory_grid:
		printerr("CRITICAL ERROR: Inventory Grid node not found! Check your node path.")
		return
	# Clear existing slots
	for child in inventory_grid.get_children():
		child.queue_free()
	print("Updating Inventory... Total Items: ", Global.inventory.size()) # DEBUG PRINT
	# Loop through global inventory
	for item_enum in Global.inventory:
		var count = Global.inventory[item_enum]
		if count > 0:
			var item_name = Global.Items.keys()[item_enum]
			print("Adding slot for: ", item_name) # DEBUG PRINT
			
			var slot = SLOT_SCENE.instantiate()
			inventory_grid.add_child(slot)
			slot.setup(item_name, count)
