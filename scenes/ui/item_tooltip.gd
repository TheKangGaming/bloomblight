class_name ItemTooltip
extends PanelContainer

const TOOLTIP_MARGIN_X := 12.0
const TOOLTIP_MARGIN_Y := 8.0

var _text_label: Label

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_content()

func setup(text: String, min_width: float = 320.0, font_size: int = 18) -> ItemTooltip:
	_build_content()
	custom_minimum_size = Vector2(min_width, 0.0)
	_text_label.add_theme_font_size_override("font_size", font_size)
	var label_width := maxf(min_width - (TOOLTIP_MARGIN_X * 2.0), 0.0)
	_text_label.custom_minimum_size = Vector2(label_width, 0.0)
	_text_label.size = Vector2(label_width, 0.0)
	_text_label.text = text
	_text_label.reset_size()
	update_minimum_size()
	var label_size := _text_label.get_combined_minimum_size()
	size = Vector2(
		maxf(min_width, label_size.x + (TOOLTIP_MARGIN_X * 2.0)),
		label_size.y + (TOOLTIP_MARGIN_Y * 2.0)
	)
	custom_minimum_size = size
	return self

func _build_content() -> void:
	if _text_label != null:
		return

	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.08, 0.1, 0.12, 0.98)
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_bottom = 2
	tooltip_style.border_color = Color(0.95, 0.83, 0.45, 0.98)
	tooltip_style.corner_radius_top_left = 8
	tooltip_style.corner_radius_top_right = 8
	tooltip_style.corner_radius_bottom_right = 8
	tooltip_style.corner_radius_bottom_left = 8
	add_theme_stylebox_override("panel", tooltip_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(TOOLTIP_MARGIN_X))
	margin.add_theme_constant_override("margin_right", int(TOOLTIP_MARGIN_X))
	margin.add_theme_constant_override("margin_top", int(TOOLTIP_MARGIN_Y))
	margin.add_theme_constant_override("margin_bottom", int(TOOLTIP_MARGIN_Y))
	add_child(margin)

	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_text_label)
