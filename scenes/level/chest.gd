extends StaticBody2D

@onready var animation_player = $AnimationPlayer
@onready var loot_popup = $LootPopup

var is_open := false
var player_in_range := false

func _ready():
	# Connect the Area2D signals in code (or do it via the Node dock on the right)
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)

# _unhandled_input is great for interactions. It only fires if the UI hasn't consumed the click/button.
func _unhandled_input(event):
	# Using your existing 'action' key, or you can map a specific 'interact' key in Project Settings
	if event.is_action_pressed("interact") and player_in_range and not is_open:
		open_chest()

func open_chest():
	is_open = true
	animation_player.play('open')
	give_loot()

func give_loot():
	print("Chest opened! Loot distributed.")
	
	# Safely add to the inventory using your Global enums
	Global.inventory[Global.Items.CORN_SEED] += 5
	Global.inventory[Global.Items.TOMATO_SEED] += 5
	Global.inventory[Global.Items.PUMPKIN_SEED] += 5
	
	# Give the tools by adding them to the unlocked array
	if not Global.unlocked_tools.has(Global.Tools.HOE):
		Global.unlocked_tools.append(Global.Tools.HOE)
		Global.unlocked_tools.append(Global.Tools.WATER)
		Global.unlocked_tools.append(Global.Tools.AXE)
	
	
	# Emit the signal you already have set up to tell your UI to refresh!
	Global.inventory_updated.emit()
	
	loot_popup.visible = true
	
	var tween = get_tree().create_tween()
	
	# Tween 1: Move the label's Y position up by 30 pixels over 1.2 seconds
	# Using TRANS_OUT makes it decelerate smoothly as it rises
	tween.tween_property(loot_popup, "position:y", loot_popup.position.y - 30, 2).set_trans(Tween.TRANS_SPRING)
	
	# Tween 2: Run in parallel (at the same time) to fade the alpha to 0.0
	tween.parallel().tween_property(loot_popup, "modulate:a", 0.0, 2)

func _on_interact_area_body_entered(body):
	print("Something touched the chest: ", body.name)
	# Check if the thing that entered the area is the player
	if body.name == "Player":
		player_in_range = true
		print("Player is successfully in range!")

func _on_interact_area_body_exited(body):
	if body.name == "Player":
		player_in_range = false
