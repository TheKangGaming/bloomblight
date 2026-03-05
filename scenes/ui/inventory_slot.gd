extends PanelContainer

@onready var icon = $Icon

# We need a variable to remember what item this slot is holding!
var stored_item_enum: Global.Items

# --- TEXTURE SOURCES ---
# 1. The Farm Sheet (Seeds & Crops)
const SHEET_FARM = preload("res://graphics/plants/Atlas-Props4-crops update.png")

# 2. The Loot Sheet (Wood, etc)
const SHEET_LOOT = preload("res://graphics/loot/loot-drops.png") 
# 3. Props
const SHEET_FURNITURE = preload("res://graphics/tilesets/furniture_and_props.png")

# 4. Single Images
const IMG_APPLE = preload("res://graphics/plants/apple.png")

# --- COORDINATES (X, Y) on the Sheets ---
# This dictionary maps the Item Enum -> The specific sheet and coordinates
var item_map: Dictionary = {}
var _focus_tooltip: PopupPanel
const FOCUS_TINT := Color(1.0, 0.95, 0.72, 1.0)
const DEFAULT_TINT := Color(1, 1, 1, 1)

func _ready():
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(_on_focus_entered)
	mouse_exited.connect(_on_focus_exited)

	# Define where everything lives. 
	# Format: ItemEnum : [TextureResource, Vector2i(Column, Row)]
	
	# -- SEEDS (On Farm Sheet) --
	item_map[Global.Items.CORN_SEED] = [SHEET_FARM, Vector2i(6, 17)]
	item_map[Global.Items.TOMATO_SEED] = [SHEET_FARM, Vector2i(8, 17)]
	item_map[Global.Items.PUMPKIN_SEED] = [SHEET_FARM, Vector2i(24, 17)]
	
	# -- CROPS (On Farm Sheet) --
	item_map[Global.Items.CORN] = [SHEET_FARM, Vector2i(10, 11)]
	item_map[Global.Items.TOMATO] = [SHEET_FARM, Vector2i(10, 15)]
	item_map[Global.Items.PUMPKIN] = [SHEET_FARM, Vector2i(30, 8)]
	
	# -- LOOT (On Loot Sheet) --
	item_map[Global.Items.WOOD] = [SHEET_LOOT, Vector2i(5, 4)]
	item_map[Global.Items.STONE] = [SHEET_LOOT, Vector2i(5, 2)] 
	
	# Props
	
	item_map[Global.Items.ROASTED_CORN] = [SHEET_FURNITURE, Vector2i(23,4)]
	item_map[Global.Items.TOMATO_SOUP] = [SHEET_FURNITURE, Vector2i(21,4)]
	


func setup(item_enum: Global.Items, quantity: int):
	
	stored_item_enum = item_enum
	# 1. Tooltip Logic
	var item_name = Global.Items.keys()[item_enum].replace("_", " ").capitalize()
	tooltip_text = "%s\nQuantity: %d" % [item_name, quantity]
	if has_focus() and is_instance_valid(_focus_tooltip):
		_show_focus_tooltip()
	
	# 2. Icon Logic
	if item_enum == Global.Items.APPLE:
		# Apple is a special case: Single PNG
		icon.texture = IMG_APPLE
		
	elif item_enum in item_map:
		# It's on a sprite sheet (Farm, Loot, or Stone)
		var data = item_map[item_enum]
		var texture_source = data[0]
		var coords = data[1]
		
		var atlas = AtlasTexture.new()
		atlas.atlas = texture_source
		
		atlas.region = Rect2(coords.x * 32, coords.y * 32, 32, 32)
		
		icon.texture = atlas
	else:
		icon.texture = null
		printerr("No icon definition found for: ", item_name)
		

func _exit_tree() -> void:
	_hide_focus_tooltip(true)

func _on_focus_entered() -> void:
	self_modulate = FOCUS_TINT
	_show_focus_tooltip()

func _on_focus_exited() -> void:
	self_modulate = DEFAULT_TINT
	_hide_focus_tooltip()

func _show_focus_tooltip() -> void:
	if tooltip_text.is_empty():
		return

	var popup := _get_or_create_focus_tooltip()
	var text_label: Label = popup.get_node("Margin/Text") as Label
	text_label.text = tooltip_text
	popup.reset_size()

	var slot_rect: Rect2 = get_global_rect()
	var popup_size: Vector2 = popup.size
	var viewport_size: Vector2 = get_viewport_rect().size

	var target_position := slot_rect.position + Vector2(slot_rect.size.x + 8.0, 0.0)
	if target_position.x + popup_size.x > viewport_size.x:
		target_position.x = slot_rect.position.x - popup_size.x - 8.0
	if target_position.y + popup_size.y > viewport_size.y:
		target_position.y = max(8.0, viewport_size.y - popup_size.y - 8.0)
	target_position.y = max(8.0, target_position.y)

	popup.position = target_position.round()
	popup.popup()

func _hide_focus_tooltip(force_free: bool = false) -> void:
	if not is_instance_valid(_focus_tooltip):
		return

	_focus_tooltip.hide()
	if force_free:
		_focus_tooltip.queue_free()
		_focus_tooltip = null

func _get_or_create_focus_tooltip() -> PopupPanel:
	if is_instance_valid(_focus_tooltip):
		return _focus_tooltip

	var popup := PopupPanel.new()
	popup.name = "FocusTooltip"
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.visible = false

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)

	var text_label := Label.new()
	text_label.name = "Text"
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(text_label)
	popup.add_child(margin)

	get_tree().root.add_child(popup)
	_focus_tooltip = popup
	return _focus_tooltip

func _gui_input(event: InputEvent) -> void:
	# Detect a Left Mouse Button click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_interact()

	if event.is_action_pressed("ui_accept"):
		_try_interact()

func _try_interact() -> void:
	# Check if we selected a food item AND we actually have some in our inventory.
	if stored_item_enum in Global.food_stats and Global.inventory[stored_item_enum] > 0:
		eat_food()

func eat_food():
	# 1. Consume the item first (This already triggers the inventory_updated signal!)
	if not Global.remove_item(stored_item_enum, 1):
		return

	if Global.tutorial_step == 12:
		Global.advance_tutorial()

	Global.active_food_buff.item = stored_item_enum
	Global.active_food_buff.stats = Global.food_stats[stored_item_enum].duplicate()
	
	# 2. Apply the buff! We use .duplicate() so we don't accidentally alter the master food_stats list
	Global.stats_updated.emit()
	
	print("Ate a delicious ", Global.Items.keys()[stored_item_enum], "!")
