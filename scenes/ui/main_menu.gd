extends Control

@onready var inventory_grid = $CenterContainer/TabContainer/Inventory/Margin/Grid
@onready var tabs = $CenterContainer/TabContainer


# Column 2: Stats
@onready var lbl_vit = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblVIT
@onready var lbl_str = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblSTR
@onready var lbl_dex = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblDEX
@onready var lbl_int = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblINT
@onready var lbl_spd = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblSPD
@onready var lbl_mov = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblMOV

# Column 3: Meal
@onready var lbl_food = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/EquipMealColumn/MealSection/MealBox/LblFoodBuff

# Preload the slot scene
const SLOT_SCENE = preload("res://scenes/ui/inventory_slot.tscn")

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	Global.inventory_updated.connect(update_inventory)
	Global.stats_updated.connect(update_status_page)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_toggle"): # Tab / Controller Menu Toggle
		toggle_menu()
	elif visible and event.is_action_pressed("ui_cancel"): # Escape / Controller B
		toggle_menu()

func toggle_menu():
	visible = not visible
	get_tree().paused = visible
	update_status_page()
	
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
			
func update_status_page():
	var format_stat = func(stat_name: String, base_val: int) -> String:
		var buff_val = 0
		if Global.active_food_buff.item != null:
			# .get() safely looks for the stat, returning 0 if the key is missing
			buff_val = Global.active_food_buff.stats.get(stat_name, 0)
			
		if buff_val > 0:
			return "%s: %d [color=green](+%d)[/color]" % [stat_name, base_val, buff_val]
		elif buff_val < 0:
			return "%s: %d [color=red](%d)[/color]" % [stat_name, base_val, buff_val]
		else:
			return "%s: %d" % [stat_name, base_val]

	# --- THE FIX: We now only pass the TWO required arguments ---
	lbl_vit.text = format_stat.call("VIT", Global.player_stats["VIT"])
	lbl_str.text = format_stat.call("STR", Global.player_stats["STR"])
	lbl_dex.text = format_stat.call("DEX", Global.player_stats["DEX"])
	lbl_int.text = format_stat.call("INT", Global.player_stats["INT"])
	lbl_spd.text = format_stat.call("SPD", Global.player_stats["SPD"])
	lbl_mov.text = format_stat.call("MOV", Global.player_stats["MOV"])
	
	# Update Meal Text
	if Global.active_food_buff.item != null:
		lbl_food.text = "Ate a hearty meal!"
	else:
		lbl_food.text = "No meal."
