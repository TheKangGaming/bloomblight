extends PanelContainer

@onready var icon = $Icon

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
var item_map = {}

func _ready():
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
	# 1. Tooltip Logic
	var item_name = Global.Items.keys()[item_enum].replace("_", " ").capitalize()
	tooltip_text = "%s\nQuantity: %d" % [item_name, quantity]
	
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
