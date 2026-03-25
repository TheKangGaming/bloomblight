extends Control

const QUEST_FONT = preload("res://assets/fonts/Cinzel_Spaced.tres")

@onready var tool_label = $ToolBar/Label
@onready var tool_icon = $ToolBar/ToolDisplay/Sprite2D

var quest_label: Label
var quest_ui_root: Control
var quest_tween: Tween
var player_ref: Node = null
var last_tool: int = -1
var toolbar_visible_state := true

func _ready() -> void:
	_setup_quest_ui()
	_setup_toolbar_ui()
	if not Global.tutorial_updated.is_connected(_on_tutorial_updated):
		Global.tutorial_updated.connect(_on_tutorial_updated)
	player_ref = get_tree().get_first_node_in_group("Player")
	_try_bind_to_player_signal()
	Global.update_tutorial_ui()

func _try_bind_to_player_signal() -> void:
	if not player_ref or not player_ref.has_signal("tool_changed"):
		return
	if not player_ref.is_connected("tool_changed", Callable(self, "_on_player_tool_changed")):
		player_ref.connect("tool_changed", Callable(self, "_on_player_tool_changed"))

func _setup_toolbar_ui() -> void:
	tool_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tool_label.add_theme_font_override("font", QUEST_FONT)
	tool_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	tool_label.add_theme_color_override("font_outline_color", Color.BLACK)
	tool_label.add_theme_constant_override("outline_size", 2)

func _on_player_tool_changed(tool: Global.Tools) -> void:
	_update_tool_display(tool)

## Builds a golden text box in the top-left corner
func _setup_quest_ui() -> void:
	var margin = MarginContainer.new()
	margin.name = "QuestUI"
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.07, 0.03, 0.92)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.82, 0.7, 0.28, 0.95)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", panel_style)

	var content = MarginContainer.new()
	content.add_theme_constant_override("margin_top", 8)
	content.add_theme_constant_override("margin_bottom", 8)
	content.add_theme_constant_override("margin_left", 12)
	content.add_theme_constant_override("margin_right", 12)

	quest_label = Label.new()
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	quest_label.add_theme_font_override("font", QUEST_FONT)
	quest_label.add_theme_font_size_override("font_size", 24)
	quest_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	quest_label.add_theme_color_override("font_outline_color", Color.BLACK)
	quest_label.add_theme_constant_override("outline_size", 3)
	quest_label.text = ""

	content.add_child(quest_label)
	panel.add_child(content)
	margin.add_child(panel)
	add_child(margin)
	quest_ui_root = margin
	quest_ui_root.modulate.a = 0.0
	quest_ui_root.visible = false

## Updates the text and animates it
func _on_tutorial_updated(text: String) -> void:
	if quest_tween:
		quest_tween.kill()

	if text == "":
		if quest_label:
			quest_label.text = ""
		if quest_ui_root == null or not quest_ui_root.visible:
			if quest_ui_root:
				quest_ui_root.visible = false
				quest_ui_root.modulate.a = 0.0
			return

		quest_tween = create_tween()
		quest_tween.tween_property(quest_ui_root, "modulate:a", 0.0, 0.25)
		quest_tween.tween_callback(Callable(self, "_hide_quest_ui"))
		return

	quest_tween = create_tween()
	quest_label.text = text
	if quest_ui_root:
		quest_ui_root.visible = true
		quest_ui_root.modulate.a = 0.0
	quest_tween.tween_property(quest_ui_root, "modulate:a", 1.0, 0.2)

func _hide_quest_ui() -> void:
	if quest_ui_root:
		quest_ui_root.visible = false

func _process(_delta):
	var should_show_toolbar = not Global.unlocked_tools.is_empty() and player_ref != null and is_instance_valid(player_ref)
	if toolbar_visible_state != should_show_toolbar:
		toolbar_visible_state = should_show_toolbar
		$ToolBar.visible = should_show_toolbar

	if not should_show_toolbar:
		return

	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("Player")
		_try_bind_to_player_signal()
	if player_ref:
		_update_tool_display(player_ref.current_tool)

func _update_tool_display(tool: Global.Tools) -> void:
	if tool == last_tool:
		return
	last_tool = tool

	var tool_name = "None"
	var tool_frame = 0

	match tool:
		Global.Tools.HOE:
			tool_name = "Hoe"
			tool_frame = 0
		Global.Tools.AXE:
			tool_name = "Axe"
			tool_frame = 1
		Global.Tools.WATER:
			tool_name = "Watering Can"
			tool_frame = 2

	if tool_label:
		tool_label.text = tool_name
	if tool_icon:
		tool_icon.frame = tool_frame
