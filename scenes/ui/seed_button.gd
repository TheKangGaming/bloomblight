extends Button

signal seed_selected(seed_type)

var my_seed_type: Global.Items

const HFRAMES = 34
const VFRAMES = 18

# Map Seeds to their starting coordinates (Same as plant.gd)
const SEED_COORDS = {
	Global.Items.BLUEBERRY_SEED: Vector2i(3, 17),
	Global.Items.WHEAT_SEED: Vector2i(4, 17),
	Global.Items.MELON_SEED: Vector2i(5, 17),
	Global.Items.CORN_SEED: Vector2i(6, 17),
	Global.Items.HOT_PEPPER_SEED: Vector2i(7, 17),
	Global.Items.RADISH_SEED: Vector2i(8, 17),
	Global.Items.RED_CABBAGE_SEED: Vector2i(9, 17),
	Global.Items.TOMATO_SEED: Vector2i(10, 17),
	Global.Items.CARROT_SEED: Vector2i(13, 17),
	Global.Items.CAULIFLOWER_SEED: Vector2i(14, 17),
	Global.Items.POTATO_SEED: Vector2i(15, 17),
	Global.Items.PARSNIP_SEED: Vector2i(16, 17),
	Global.Items.GARLIC_SEED: Vector2i(17, 17),
	Global.Items.GREEN_BEANS_SEED: Vector2i(18, 17),
	Global.Items.STRAWBERRY_SEED: Vector2i(19, 17),
	Global.Items.COFFEE_BEAN_SEED: Vector2i(20, 17),
	Global.Items.PUMPKIN_SEED: Vector2i(24, 17),
	Global.Items.BROCCOLI_SEED: Vector2i(25, 17),
	Global.Items.ARTICHOKE_SEED: Vector2i(26, 17),
	Global.Items.EGGPLANT_SEED: Vector2i(27, 17),
	Global.Items.BOK_CHOY_SEED: Vector2i(28, 17),
	Global.Items.GRAPE_SEED: Vector2i(29, 17)
}

func setup(seed_type: Global.Items, amount: int, can_plant_now: bool = true, status_tooltip: String = ""):
	my_seed_type = seed_type
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Sprite2D/Label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	# Update the label text
	$Sprite2D/Label.text = str(amount)
	
	# Setup Texture
	$Sprite2D.texture = preload("res://graphics/plants/Atlas-Props4-crops update.png")
	$Sprite2D.hframes = HFRAMES
	$Sprite2D.vframes = VFRAMES
	
	# Set Icon
	if seed_type in SEED_COORDS:
		$Sprite2D.frame_coords = SEED_COORDS[seed_type]
	else:
		$Sprite2D.frame_coords = Vector2i(0, 0)

	disabled = not can_plant_now
	modulate = Color(1, 1, 1, 1) if can_plant_now else Color(1, 1, 1, 0.45)
	tooltip_text = status_tooltip
	
func _pressed():
	seed_selected.emit(my_seed_type)
