## Draws a selected unit's walkable tiles.
class_name UnitOverlay
extends TileMapLayer


## Fills the tilemap with the cells, giving a visual representation of the cells a unit can walk.
func draw_walkable_cells(cells: Array) -> void:
	
	for cell in cells:
		set_cell(cell, 0, Vector2i(0,0))
		
func draw_attackable_cells(cells: Array) -> void:
	for cell in cells:
		# Source ID 0, Atlas Coords (1, 0) = Grab the Right side of the image (Red)
		set_cell(cell, 0, Vector2i(1, 0))
