extends Control

@onready var inventory_grid = $CenterContainer/TabContainer/Inventory/Margin/Grid
@onready var tabs = $CenterContainer/TabContainer

# Preload the slot scene
const SLOT_SCENE = preload("res://scenes/ui/inventory_slot.tscn")

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	Global.inventory_updated.connect(update_inventory)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"): # Tab Key
		toggle_menu()

func toggle_menu():
	visible = not visible
	get_tree().paused = visible
	
	if visible:
		# Default to Inventory tab (Index 1) for now
		if tabs:
			tabs.current_tab = 1
		update_inventory()

func update_inventory():
	if not inventory_grid: return

	# 1. Clear existing slots
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# 2. Add slots for current inventory
	for item_enum in Global.inventory:
		var count = Global.inventory[item_enum]
		if count > 0:
			var slot = SLOT_SCENE.instantiate()
			inventory_grid.add_child(slot)
			
			# UPDATE: Pass the ENUM, not the Name string
			slot.setup(item_enum, count)
