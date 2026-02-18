extends Button

signal seed_selected(seed_type)

var my_seed_type: Global.Seeds

func setup(seed_type: Global.Seeds, amount: int):
	my_seed_type = seed_type
	
	$Sprite2D/Label.text = str(amount)
	
	$Sprite2D.frame = int(seed_type)
	
func _pressed():
	seed_selected.emit(my_seed_type)
