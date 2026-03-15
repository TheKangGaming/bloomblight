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
var _focus_tooltip: PanelContainer
const FOCUS_TINT := Color(1.0, 0.95, 0.72, 1.0)
const DEFAULT_TINT := Color(1, 1, 1, 1)
const FOCUS_BORDER_COLOR := Color(1.0, 0.88, 0.3, 1.0)
const DEFAULT_BORDER_COLOR := Color(0.23, 0.23, 0.23, 0.95)
const FOCUS_BG_COLOR := Color(0.24, 0.22, 0.13, 0.95)
const DEFAULT_BG_COLOR := Color(0.12, 0.12, 0.12, 0.86)

func _ready():
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(_on_focus_entered)
	mouse_exited.connect(_on_focus_exited)
	_apply_focus_visual(false)

	# Define where everything lives. 
	# Format: ItemEnum : [TextureResource, Vector2i(Column, Row)]
	
	# -- SEEDS (On Farm Sheet) --
	item_map[Global.Items.BLUEBERRY_SEED] = [SHEET_FARM, Vector2i(3, 17)]
	item_map[Global.Items.WHEAT_SEED] = [SHEET_FARM, Vector2i(4, 17)]
	item_map[Global.Items.MELON_SEED] = [SHEET_FARM, Vector2i(5, 17)]
	item_map[Global.Items.CORN_SEED] = [SHEET_FARM, Vector2i(6, 17)]
	item_map[Global.Items.HOT_PEPPER_SEED] = [SHEET_FARM, Vector2i(7, 17)]
	item_map[Global.Items.RADISH_SEED] = [SHEET_FARM, Vector2i(8, 17)]
	item_map[Global.Items.RED_CABBAGE_SEED] = [SHEET_FARM, Vector2i(9, 17)]
	item_map[Global.Items.TOMATO_SEED] = [SHEET_FARM, Vector2i(10, 17)]
	item_map[Global.Items.CARROT_SEED] = [SHEET_FARM, Vector2i(13, 17)]
	item_map[Global.Items.CAULIFLOWER_SEED] = [SHEET_FARM, Vector2i(14, 17)]
	item_map[Global.Items.POTATO_SEED] = [SHEET_FARM, Vector2i(15, 17)]
	item_map[Global.Items.PARSNIP_SEED] = [SHEET_FARM, Vector2i(16, 17)]
	item_map[Global.Items.GARLIC_SEED] = [SHEET_FARM, Vector2i(17, 17)]
	item_map[Global.Items.GREEN_BEANS_SEED] = [SHEET_FARM, Vector2i(18, 17)]
	item_map[Global.Items.STRAWBERRY_SEED] = [SHEET_FARM, Vector2i(19, 17)]
	item_map[Global.Items.COFFEE_BEAN_SEED] = [SHEET_FARM, Vector2i(20, 17)]
	item_map[Global.Items.PUMPKIN_SEED] = [SHEET_FARM, Vector2i(24, 17)]
	item_map[Global.Items.BROCCOLI_SEED] = [SHEET_FARM, Vector2i(25, 17)]
	item_map[Global.Items.ARTICHOKE_SEED] = [SHEET_FARM, Vector2i(26, 17)]
	item_map[Global.Items.EGGPLANT_SEED] = [SHEET_FARM, Vector2i(27, 17)]
	item_map[Global.Items.BOK_CHOY_SEED] = [SHEET_FARM, Vector2i(28, 17)]
	item_map[Global.Items.GRAPE_SEED] = [SHEET_FARM, Vector2i(29, 17)]
	
	# -- CROPS (On Farm Sheet) --
	item_map[Global.Items.BLUEBERRY] = [SHEET_FARM, Vector2i(10, 8)]
	item_map[Global.Items.WHEAT] = [SHEET_FARM, Vector2i(10, 9)]
	item_map[Global.Items.MELON] = [SHEET_FARM, Vector2i(10, 10)]
	item_map[Global.Items.CORN] = [SHEET_FARM, Vector2i(10, 11)]
	item_map[Global.Items.HOT_PEPPER] = [SHEET_FARM, Vector2i(10, 12)]
	item_map[Global.Items.RADISH] = [SHEET_FARM, Vector2i(10, 13)]
	item_map[Global.Items.RED_CABBAGE] = [SHEET_FARM, Vector2i(10, 14)]
	item_map[Global.Items.TOMATO] = [SHEET_FARM, Vector2i(10, 15)]
	item_map[Global.Items.CARROT] = [SHEET_FARM, Vector2i(20, 8)]
	item_map[Global.Items.CAULIFLOWER] = [SHEET_FARM, Vector2i(20, 9)]
	item_map[Global.Items.POTATO] = [SHEET_FARM, Vector2i(20, 10)]
	item_map[Global.Items.PARSNIP] = [SHEET_FARM, Vector2i(20, 11)]
	item_map[Global.Items.GARLIC] = [SHEET_FARM, Vector2i(20, 12)]
	item_map[Global.Items.GREEN_BEANS] = [SHEET_FARM, Vector2i(20, 13)]
	item_map[Global.Items.STRAWBERRY] = [SHEET_FARM, Vector2i(20, 14)]
	item_map[Global.Items.COFFEE_BEAN] = [SHEET_FARM, Vector2i(20, 15)]
	item_map[Global.Items.PUMPKIN] = [SHEET_FARM, Vector2i(30, 8)]
	item_map[Global.Items.BROCCOLI] = [SHEET_FARM, Vector2i(31, 9)]
	item_map[Global.Items.ARTICHOKE] = [SHEET_FARM, Vector2i(32, 10)]
	item_map[Global.Items.EGGPLANT] = [SHEET_FARM, Vector2i(33, 11)]
	item_map[Global.Items.BOK_CHOY] = [SHEET_FARM, Vector2i(34, 12)]
	item_map[Global.Items.GRAPE] = [SHEET_FARM, Vector2i(35, 13)]
	
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
	if has_focus():
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
	_apply_focus_visual(true)
	_show_focus_tooltip()

func _on_focus_exited() -> void:
	_apply_focus_visual(false)
	_hide_focus_tooltip()

func _apply_focus_visual(is_focused: bool) -> void:
	self_modulate = FOCUS_TINT if is_focused else DEFAULT_TINT

	var style := StyleBoxFlat.new()
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	style.bg_color = FOCUS_BG_COLOR if is_focused else DEFAULT_BG_COLOR
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = FOCUS_BORDER_COLOR if is_focused else DEFAULT_BORDER_COLOR

	add_theme_stylebox_override("panel", style)

func _show_focus_tooltip() -> void:
	if tooltip_text.is_empty():
		return

	var tooltip: PanelContainer = _get_or_create_focus_tooltip()
	var text_label: Label = tooltip.get_node("Margin/Text") as Label
	text_label.text = tooltip_text

	var slot_rect: Rect2 = get_global_rect()
	var tooltip_size: Vector2 = text_label.get_combined_minimum_size() + Vector2(16.0, 12.0)
	var viewport_size: Vector2 = get_viewport_rect().size

	var target_position: Vector2 = slot_rect.position + Vector2(slot_rect.size.x + 8.0, 0.0)
	if target_position.x + tooltip_size.x > viewport_size.x:
		target_position.x = slot_rect.position.x - tooltip_size.x - 8.0
	if target_position.y + tooltip_size.y > viewport_size.y:
		target_position.y = max(8.0, viewport_size.y - tooltip_size.y - 8.0)
	target_position.y = max(8.0, target_position.y)

	tooltip.custom_minimum_size = tooltip_size
	tooltip.position = target_position.round()
	tooltip.visible = true

func _hide_focus_tooltip(force_free: bool = false) -> void:
	if not is_instance_valid(_focus_tooltip):
		return

	_focus_tooltip.hide()
	if force_free:
		_focus_tooltip.queue_free()
		_focus_tooltip = null

func _get_or_create_focus_tooltip() -> PanelContainer:
	if is_instance_valid(_focus_tooltip):
		return _focus_tooltip

	var tooltip: PanelContainer = PanelContainer.new()
	tooltip.name = "FocusTooltip"
	tooltip.visible = false
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.z_index = 100

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)

	var text_label: Label = Label.new()
	text_label.name = "Text"
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(text_label)
	tooltip.add_child(margin)

	get_tree().root.add_child(tooltip)
	_focus_tooltip = tooltip
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
