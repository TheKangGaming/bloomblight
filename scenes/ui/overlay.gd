extends Control

@onready var tool_label = $ToolBar/Label
@onready var tool_icon = $ToolBar/ToolDisplay/Sprite2D

func _process(_delta):
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		# Update Text
		var tool_name = "None"
		var tool_frame = 0
		
		match player.current_tool:
			player.Tools.HOE: 
				tool_name = "Hoe"
				tool_frame = 0 # 1st image in tools.png
			player.Tools.WATER: 
				tool_name = "Watering Can"
				tool_frame = 2 # 2nd image
			player.Tools.AXE: 
				tool_name = "Axe"
				tool_frame = 1 # 3rd image
			player.Tools.PLANT: 
				tool_name = "Seeds"
				tool_frame = 3 # 4th image (if it exists)
		
		if tool_label:
			tool_label.text = tool_name
			
		if tool_icon:
			tool_icon.frame = tool_frame
