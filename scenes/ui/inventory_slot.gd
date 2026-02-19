extends PanelContainer

@onready var icon = $Icon

# 1. THE SPRITE SHEET
const ATLAS_TEXTURE = preload("res://graphics/plants/Atlas-Props4-crops update.png")
const TILE_SIZE = 32

# 2. MASTER COORDINATE LIST (Column X, Row Y)
# Use the "Frame Coords" from the Inspector to fill these in.
const ITEM_COORDS = {
	# --- SEEDS (From previous steps) ---
	Global.Items.CORN_SEED: Vector2i(6, 17),
	Global.Items.TOMATO_SEED: Vector2i(8, 17),
	Global.Items.PUMPKIN_SEED: Vector2i(24, 17),
	
	# --- CROPS (The harvested food) ---
	# Usually located 4 or 5 frames to the right of the seed
	Global.Items.CORN: Vector2i(10, 11),     # Check this on your sheet!
	Global.Items.TOMATO: Vector2i(10, 15),  # Check this!
	Global.Items.PUMPKIN: Vector2i(30, 8), # Check this!
	
	# --- RESOURCES ---
	# Find where the Log and Apple are on the sheet and update these!
	Global.Items.WOOD: Vector2i(0, 0),      # <--- UPDATE THIS
	Global.Items.APPLE: Vector2i(0, 0),     # <--- UPDATE THIS
	Global.Items.STONE: Vector2i(0, 0)      # <--- UPDATE THIS
}

func setup(item_enum: Global.Items, quantity: int):
	# A. SETUP TOOLTIP
	var item_name = Global.Items.keys()[item_enum].replace("_", " ").capitalize()
	tooltip_text = "%s\nQuantity: %d" % [item_name, quantity]
	
	# B. SETUP ICON USING ATLAS
	if item_enum in ITEM_COORDS:
		var atlas = AtlasTexture.new()
		atlas.atlas = ATLAS_TEXTURE
		
		# Get the grid position
		var grid_pos = ITEM_COORDS[item_enum]
		
		# Create the clipping region
		atlas.region = Rect2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
		
		icon.texture = atlas
	else:
		# Fallback if we forgot to add coordinates
		icon.texture = null
		printerr("Missing Atlas Coords for: ", item_name)
