extends TileMapLayer
class_name Map

func _ready() -> void:
	pass

func get_movement_costs() -> Dictionary:
	var costs = {}
	var used_cells = get_used_cells()
	
	for cell in used_cells:
		costs[cell] = 1
		
	return costs
