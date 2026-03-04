extends Control

@onready var tool_label = $ToolBar/Label
@onready var tool_icon = $ToolBar/ToolDisplay/Sprite2D

# Add this variable at the top of your script
var quest_label: Label

func _ready() -> void:
	# ... keep your existing ready code here ...
	
	# 1. Build the Quest UI
	_setup_quest_ui()
	
	# 2. Connect to the Global tutorial system
	Global.tutorial_updated.connect(_on_tutorial_updated)
	
	# 3. Fire the very first quest!
	Global.update_tutorial_ui()

## Builds a golden text box in the top-left corner
func _setup_quest_ui() -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	quest_label = Label.new()
	quest_label.add_theme_font_size_override("font_size", 24)
	quest_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2)) # A nice golden yellow
	quest_label.add_theme_color_override("font_outline_color", Color.BLACK)
	quest_label.add_theme_constant_override("outline_size", 6)
	quest_label.text = ""
	
	margin.add_child(quest_label)
	add_child(margin)

## Updates the text and animates it
func _on_tutorial_updated(text: String) -> void:
	if text == "":
		# If the text is empty, the tutorial is over. Fade it out!
		var tween = create_tween()
		tween.tween_property(quest_label, "modulate:a", 0.0, 1.0)
	else:
		# Update text and fade it in
		quest_label.text = text
		quest_label.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(quest_label, "modulate:a", 1.0, 0.5)

func _process(_delta):
	if Global.unlocked_tools.is_empty():
		$ToolBar.visible = false
	else:
		$ToolBar.visible = true
	var player = get_tree().get_first_node_in_group("Player")
	
	if player and not Global.unlocked_tools.is_empty():
		# Update Text
		var tool_name = "None"
		var tool_frame = 0
		
		match player.current_tool:
			player.Tools.HOE: 
				tool_name = "Hoe"
				tool_frame = 0 # 1st image in tools.png
			player.Tools.AXE: 
				tool_name = "Axe"
				tool_frame = 1 # 2nd image
			player.Tools.WATER: 
				tool_name = "Watering Can"
				tool_frame = 2 # 3rd image
		
		if tool_label:
			tool_label.text = tool_name
			
		if tool_icon:
			tool_icon.frame = tool_frame
