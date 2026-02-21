extends StaticBody2D

@onready var animation_player = $AnimationPlayer

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
	animation_player.play("open")
	give_loot()

func give_loot():
	print("Chest opened! Loot distributed.")
	# Here is where you will interface with your inventory!
	# Example: Global.add_item("hoe")
	# Example: Global.add_item("seeds", 5)

func _on_interact_area_body_entered(body):
	# Check if the thing that entered the area is the player
	if body.name == "Player":
		player_in_range = true

func _on_interact_area_body_exited(body):
	if body.name == "Player":
		player_in_range = false
