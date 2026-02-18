extends Control

@onready var tool_label = $ToolBar # Or whatever your node is named

func _process(_delta):
	# Update the Tool Display
	var current_tool_name = "None"
	
	# We need to find the player to know what tool they are holding
	# This assumes the player is in the "Player" group
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		# Assuming your player script has an enum or string for current_tool
		# You might need to adjust this depending on how you store 'current_tool' in player.gd
		# If current_tool is an Enum (0, 1, 2), we map it to string:
		match player.current_tool:
			player.Tools.HOE: current_tool_name = "Hoe"
			player.Tools.WATER: current_tool_name = "Watering Can"
			player.Tools.AXE: current_tool_name = "Axe"
			player.Tools.PLANT: current_tool_name = "Planting"
			
	if tool_label:
		tool_label.text = "Tool: " + current_tool_name
