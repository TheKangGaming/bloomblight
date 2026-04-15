extends Control

const QUEST_FONT = preload("res://assets/fonts/Cinzel_Spaced.tres")

@onready var tool_label = $ToolBar/Label
@onready var tool_icon = $ToolBar/ToolDisplay/Sprite2D

var quest_label: Label
var quest_ui_root: Control
var quest_tween: Tween
var notice_label: Label
var notice_ui_root: Control
var notice_tween: Tween
var targeting_hint_label: Label
var targeting_hint_root: Control
var player_ref: Node = null
var last_tool: int = -1
var toolbar_visible_state := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_quest_ui()
	_setup_notice_ui()
	_setup_targeting_hint_ui()
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
	$ToolBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tool_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tool_label.add_theme_font_override("font", QUEST_FONT)
	tool_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	tool_label.add_theme_color_override("font_outline_color", Color.BLACK)
	tool_label.add_theme_constant_override("outline_size", 2)

func _on_player_tool_changed(tool: Global.Tools) -> void:
	_update_tool_display(tool)

## Builds a golden text box near the top of the screen without covering battle forecasts
func _setup_quest_ui() -> void:
	var margin = MarginContainer.new()
	margin.name = "QuestUI"
	margin.anchor_left = 0.0
	margin.anchor_right = 0.0
	margin.anchor_top = 0.0
	margin.anchor_bottom = 0.0
	margin.position = Vector2(20, 20)
	margin.custom_minimum_size = Vector2(440, 0)

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
	quest_label.add_theme_font_size_override("font_size", 26)
	quest_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	quest_label.add_theme_color_override("font_outline_color", Color.BLACK)
	quest_label.add_theme_constant_override("outline_size", 3)
	quest_label.text = ""

	content.add_child(quest_label)
	panel.add_child(content)
	margin.add_child(panel)
	add_child(margin)
	quest_ui_root = margin
	quest_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_ui_root.modulate.a = 0.0
	quest_ui_root.visible = false

func _setup_notice_ui() -> void:
	var margin = MarginContainer.new()
	margin.name = "NoticeUI"
	margin.anchor_left = 0.0
	margin.anchor_right = 0.0
	margin.anchor_top = 0.0
	margin.anchor_bottom = 0.0
	margin.position = Vector2(20, 96)
	margin.custom_minimum_size = Vector2(440, 0)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.09, 0.12, 0.94)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.72, 0.8, 0.94, 0.95)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", panel_style)

	var content = MarginContainer.new()
	content.add_theme_constant_override("margin_top", 7)
	content.add_theme_constant_override("margin_bottom", 7)
	content.add_theme_constant_override("margin_left", 12)
	content.add_theme_constant_override("margin_right", 12)

	notice_label = Label.new()
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	notice_label.add_theme_font_override("font", QUEST_FONT)
	notice_label.add_theme_font_size_override("font_size", 22)
	notice_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	notice_label.add_theme_color_override("font_outline_color", Color.BLACK)
	notice_label.add_theme_constant_override("outline_size", 2)
	notice_label.text = ""

	content.add_child(notice_label)
	panel.add_child(content)
	margin.add_child(panel)
	add_child(margin)
	notice_ui_root = margin
	notice_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_ui_root.modulate.a = 0.0
	notice_ui_root.visible = false

func _setup_targeting_hint_ui() -> void:
	var margin = MarginContainer.new()
	margin.name = "TargetingHintUI"
	margin.anchor_left = 0.5
	margin.anchor_right = 0.5
	margin.anchor_top = 1.0
	margin.anchor_bottom = 1.0
	margin.position = Vector2(-170, -74)
	margin.custom_minimum_size = Vector2(340, 0)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.06, 0.88)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.84, 0.84, 0.86, 0.9)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", panel_style)

	var content = MarginContainer.new()
	content.add_theme_constant_override("margin_top", 6)
	content.add_theme_constant_override("margin_bottom", 6)
	content.add_theme_constant_override("margin_left", 12)
	content.add_theme_constant_override("margin_right", 12)

	targeting_hint_label = Label.new()
	targeting_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	targeting_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	targeting_hint_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	targeting_hint_label.add_theme_font_override("font", QUEST_FONT)
	targeting_hint_label.add_theme_font_size_override("font_size", 20)
	targeting_hint_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
	targeting_hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	targeting_hint_label.add_theme_constant_override("outline_size", 2)
	targeting_hint_label.text = ""

	content.add_child(targeting_hint_label)
	panel.add_child(content)
	margin.add_child(panel)
	add_child(margin)
	targeting_hint_root = margin
	targeting_hint_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	targeting_hint_root.visible = false
	targeting_hint_root.modulate.a = 0.0

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

func show_notice(text: String, duration := 1.4) -> void:
	if notice_ui_root == null or notice_label == null:
		return

	if notice_tween:
		notice_tween.kill()

	notice_label.text = text
	notice_ui_root.visible = true
	notice_ui_root.modulate.a = 0.0

	notice_tween = create_tween()
	notice_tween.tween_property(notice_ui_root, "modulate:a", 1.0, 0.18)
	notice_tween.tween_interval(maxf(duration, 0.2))
	notice_tween.tween_property(notice_ui_root, "modulate:a", 0.0, 0.22)
	notice_tween.tween_callback(Callable(self, "_hide_notice_ui"))

func _hide_notice_ui() -> void:
	if notice_ui_root:
		notice_ui_root.visible = false

func show_targeting_hint(text: String = "Confirm target / Cancel back") -> void:
	if targeting_hint_root == null or targeting_hint_label == null:
		return

	targeting_hint_label.text = text
	targeting_hint_root.visible = true
	targeting_hint_root.modulate.a = 1.0

func hide_targeting_hint() -> void:
	if targeting_hint_root:
		targeting_hint_root.visible = false
		targeting_hint_root.modulate.a = 0.0

func _process(_delta):
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("Player")
		_try_bind_to_player_signal()

	var has_valid_player := player_ref != null and is_instance_valid(player_ref)
	var should_show_toolbar = not Global.unlocked_tools.is_empty() and has_valid_player
	if toolbar_visible_state != should_show_toolbar:
		toolbar_visible_state = should_show_toolbar
		$ToolBar.visible = should_show_toolbar

	if not should_show_toolbar:
		return

	if has_valid_player:
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
