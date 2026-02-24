extends Control

@onready var inventory_grid = $CenterContainer/TabContainer/Inventory/Margin/Grid
@onready var tabs = $CenterContainer/TabContainer
@onready var lbl_vit = $CenterContainer/TabContainer/Status/HBoxContainer/StatsSide/LblVIT
@onready var lbl_str = $CenterContainer/TabContainer/Status/HBoxContainer/StatsSide/LblSTR
@onready var lbl_dex = $CenterContainer/TabContainer/Status/HBoxContainer/StatsSide/LblDEX
@onready var lbl_int = $CenterContainer/TabContainer/Status/HBoxContainer/StatsSide/LblINT
@onready var lbl_spd = $CenterContainer/TabContainer/Status/HBoxContainer/StatsSide/LblSPD
@onready var lbl_mov = $CenterContainer/TabContainer/Status/HBoxContainer/StatsSide/LblMOV
@onready var lbl_food = $CenterContainer/TabContainer/Status/HBoxContainer/StatsSide/HBoxContainer/LblFoodBuff

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
		update_status_page()

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
			
func update_status_page():
	var stats = Global.player_stats
	var buff = Global.active_food_buff.stats
	
	# A quick helper function (lambda) inside to format the text!
	# It will output something like "STR: 5" or "STR: 5 (+2)" if you have a buff.
	var format_stat = func(stat_name, base_val, buff_val):
		if buff_val > 0:
			return stat_name + ": " + str(base_val) + " [color=green](+" + str(buff_val) + ")[/color]"
		return stat_name + ": " + str(base_val)
		
	# Update all the labels
	# Note: If you want to use the [color] tags above, make sure your labels in the UI 
	# are RichTextLabels! If they are normal Labels, just remove the color tags from the string.
	lbl_vit.text = format_stat.call("VIT", stats["VIT"], buff["VIT"])
	lbl_str.text = format_stat.call("STR", stats["STR"], buff["STR"])
	lbl_dex.text = format_stat.call("DEX", stats["DEX"], buff["DEX"])
	lbl_int.text = format_stat.call("INT", stats["INT"], buff["INT"])
	lbl_spd.text = format_stat.call("SPD", stats["SPD"], buff["SPD"])
	lbl_mov.text = format_stat.call("MOV", stats["MOV"], buff["MOV"])
	
	# Update Meal Text
	if Global.active_food_buff.item != null:
		lbl_food.text = "Ate a hearty meal!"
	else:
		lbl_food.text = "No meal eaten today."
		
