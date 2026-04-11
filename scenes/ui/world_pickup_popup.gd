class_name WorldPickupPopup
extends Control

const SHEET_FARM := preload("res://graphics/plants/Atlas-Props4-crops update.png")
const SHEET_LOOT := preload("res://graphics/loot/loot-drops.png")
const IMG_APPLE := preload("res://graphics/plants/apple.png")

const ICON_SIZE := Vector2(32.0, 32.0)
const FLOAT_DISTANCE := 56.0
const POPUP_LIFETIME := 0.58

const ITEM_ICON_MAP := {
	Global.Items.BLUEBERRY: [SHEET_FARM, Vector2i(10, 8)],
	Global.Items.WHEAT: [SHEET_FARM, Vector2i(10, 9)],
	Global.Items.MELON: [SHEET_FARM, Vector2i(10, 10)],
	Global.Items.CORN: [SHEET_FARM, Vector2i(10, 11)],
	Global.Items.HOT_PEPPER: [SHEET_FARM, Vector2i(10, 12)],
	Global.Items.RADISH: [SHEET_FARM, Vector2i(10, 13)],
	Global.Items.RED_CABBAGE: [SHEET_FARM, Vector2i(10, 14)],
	Global.Items.TOMATO: [SHEET_FARM, Vector2i(10, 15)],
	Global.Items.CARROT: [SHEET_FARM, Vector2i(20, 8)],
	Global.Items.CAULIFLOWER: [SHEET_FARM, Vector2i(20, 9)],
	Global.Items.POTATO: [SHEET_FARM, Vector2i(20, 10)],
	Global.Items.PARSNIP: [SHEET_FARM, Vector2i(20, 11)],
	Global.Items.GARLIC: [SHEET_FARM, Vector2i(20, 12)],
	Global.Items.GREEN_BEANS: [SHEET_FARM, Vector2i(20, 13)],
	Global.Items.STRAWBERRY: [SHEET_FARM, Vector2i(20, 14)],
	Global.Items.COFFEE_BEAN: [SHEET_FARM, Vector2i(20, 15)],
	Global.Items.PUMPKIN: [SHEET_FARM, Vector2i(30, 8)],
	Global.Items.BROCCOLI: [SHEET_FARM, Vector2i(30, 9)],
	Global.Items.ARTICHOKE: [SHEET_FARM, Vector2i(30, 10)],
	Global.Items.EGGPLANT: [SHEET_FARM, Vector2i(30, 11)],
	Global.Items.BOK_CHOY: [SHEET_FARM, Vector2i(30, 12)],
	Global.Items.GRAPE: [SHEET_FARM, Vector2i(30, 13)],
	Global.Items.WOOD: [SHEET_LOOT, Vector2i(5, 4)],
	Global.Items.STONE: [SHEET_LOOT, Vector2i(5, 2)],
}

var _panel: PanelContainer = null
var _icon: TextureRect = null
var _label: Label = null

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

func setup(item_type: int, amount: int = 1) -> WorldPickupPopup:
	_build()
	_configure_icon(item_type)
	_label.text = "+%d %s" % [maxi(amount, 1), _format_item_name(item_type)]
	_label.reset_size()
	_panel.reset_size()
	custom_minimum_size = _panel.get_combined_minimum_size()
	size = custom_minimum_size
	return self

func play_at(screen_anchor: Vector2) -> void:
	if _panel == null:
		return
	var popup_size := _panel.get_combined_minimum_size()
	custom_minimum_size = popup_size
	size = popup_size
	position = (screen_anchor - Vector2(popup_size.x * 0.5, 76.0)).round()
	scale = Vector2(0.82, 0.82)
	modulate = Color(1, 1, 1, 0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 1.04, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", position + Vector2(0, -FLOAT_DISTANCE), POPUP_LIFETIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var fade_tween := create_tween()
	fade_tween.tween_interval(0.3)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_tween.finished.connect(queue_free)

func _build() -> void:
	if _panel != null:
		return

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.92, 0.84, 0.48, 0.94)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	_panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = ICON_SIZE
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 19)
	_label.modulate = Color(0.98, 0.96, 0.9, 1.0)
	row.add_child(_label)

func _configure_icon(item_type: int) -> void:
	if _icon == null:
		return

	if item_type == Global.Items.APPLE:
		_icon.texture = IMG_APPLE
		return

	if not ITEM_ICON_MAP.has(item_type):
		_icon.texture = null
		return

	var icon_data: Array = ITEM_ICON_MAP[item_type]
	var atlas := AtlasTexture.new()
	atlas.atlas = icon_data[0]
	var coords: Vector2i = icon_data[1]
	atlas.region = Rect2(coords.x * 32, coords.y * 32, 32, 32)
	_icon.texture = atlas

func _format_item_name(item_type: int) -> String:
	var item_keys := Global.Items.keys()
	if item_type < 0 or item_type >= item_keys.size():
		return "Item"
	var parts := String(item_keys[item_type]).to_lower().split("_")
	var capitalized: PackedStringArray = []
	for part in parts:
		if part.is_empty():
			continue
		capitalized.append(part.capitalize())
	return " ".join(capitalized)
