extends Control

@onready var player = get_tree().get_first_node_in_group("Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1. Update the labels immediately when the game starts
	update_ui()
	
	# 2. Listen for future updates
	# We connect the Global signal to our update_ui function
	Global.inventory_updated.connect(update_ui)
	
	if player:
		player.tool_changed.connect(_on_tool_changed)
		
		
		_on_tool_changed(player.current_tool)
		
	
func update_ui():
	# 3. Set the text
	# We access the dictionary directly
	$MarginContainer/VBoxContainer/CornLabel.text = "Corn: " + str(Global.inventory[Global.Seeds.CORN])
	$MarginContainer/VBoxContainer/TomatoLabel.text = "Tomato: " + str(Global.inventory[Global.Seeds.TOMATO])
	$MarginContainer/VBoxContainer/PumpkinLabel.text = "Pumpkin: " + str(Global.inventory[Global.Seeds.PUMPKIN])
	
func _on_tool_changed(tool_enum: int):
	$ToolBar/ToolDisplay/Sprite2D.frame = tool_enum
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
