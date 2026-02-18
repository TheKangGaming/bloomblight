extends Button

signal seed_selected(seed_type)

var my_seed_type: Global.Seeds

const HFRAMES = 34
const VFRAMES = 18

# Map Seeds to their starting coordinates (Same as plant.gd)
const SEED_COORDS = {
	Global.Seeds.CORN: Vector2i(6, 17),
	Global.Seeds.TOMATO: Vector2i(8, 17),
	Global.Seeds.PUMPKIN: Vector2i(24, 17)
}

func setup(seed_type: Global.Seeds, amount: int):
	my_seed_type = seed_type
	# Setup Texture
	$Sprite2D.texture = preload("res://graphics/plants/Atlas-Props4-crops update.png")
	$Sprite2D.hframes = HFRAMES
	$Sprite2D.vframes = VFRAMES
	
	# Set Icon
	if seed_type in SEED_COORDS:
		$Sprite2D.frame_coords = SEED_COORDS[seed_type]
	else:
		$Sprite2D.frame_coords = Vector2i(0, 0)
	
func _pressed():
	seed_selected.emit(my_seed_type)
