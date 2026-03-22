extends TextureRect

const ItemTooltipPanel = preload("res://scenes/ui/item_tooltip.gd")

@export var tooltip_min_width := 320.0
@export var tooltip_font_size := 18

func _make_custom_tooltip(for_text: String) -> Object:
	if for_text.strip_edges().is_empty():
		return null

	return ItemTooltipPanel.new().setup(for_text, tooltip_min_width, tooltip_font_size)
