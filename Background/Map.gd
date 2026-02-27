extends TileMapLayer
class_name Map

func _ready() -> void:
	# We no longer need to look for the tutorial's custom tileset script
	pass

func get_movement_costs() -> Dictionary:
	var costs = {}
	
	# Get every single cell you painted on this layer
	var used_cells = get_used_cells()
	
	for cell in used_cells:
		# For right now, let's default all painted grass/dirt to a cost of 1
		costs[cell] = 1
		
		# NOTE: Later, we can easily check your Epic_Tileset here to see 
		# if a tile is a solid wall, and set its cost to 99 so Savannah can't pass!
		
	return costs
