extends Control

# UPDATED PATH: CenterContainer is now a direct child of MainMenu (Sibling of Background)
@onready var inventory_grid = $CenterContainer/TabContainer/Inventory/Margin/Grid
@onready var tabs = $CenterContainer/TabContainer

const SLOT_SCENE = preload("res://scenes/ui/inventory_slot.tscn")

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	Global.inventory_updated.connect(update_inventory)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"): # TAB
		toggle_menu()

func toggle_menu():
	visible = not visible
	get_tree().paused = visible
	
	if visible:
		# Force the "Inventory" tab (Index 1) to be active so you can see the items
		if tabs:
			tabs.current_tab = 1 
		
		update_inventory()

func update_inventory():
	# Defensive check
	if not inventory_grid:
		printerr("Error: Inventory Grid not found. Check node structure.")
		return

	for child in inventory_grid.get_children():
		child.queue_free()
	
	for item_enum in Global.inventory:
		var count = Global.inventory[item_enum]
		if count > 0:
			var slot = SLOT_SCENE.instantiate()
			inventory_grid.add_child(slot)
			var item_name = Global.Items.keys()[item_enum]
			slot.setup(item_name, count)
