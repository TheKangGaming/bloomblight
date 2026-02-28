extends Node2D

# We only need to bridge the middle-of-the-swing strikes here. 
# The end-of-the-swing unlock is handled by the signal we just connected in _ready!

func axe_use() -> void:
	if get_parent().has_method("axe_use"):
		get_parent().axe_use()
