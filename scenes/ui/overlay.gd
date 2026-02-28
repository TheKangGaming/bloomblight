extends Control

@onready var tool_label = $ToolBar/ToolPanel/ToolMargin/ToolRow/Label
@onready var tool_icon = $ToolBar/ToolPanel/ToolMargin/ToolRow/ToolDisplay/Sprite2D

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
