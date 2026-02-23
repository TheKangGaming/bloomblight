extends StaticBody2D

var player_in_range := false
var is_lit := false

@onready var fire_sprite = $Fire
@onready var smoke_sprite = $Smoke
@onready var anim_player = $AnimationPlayer

func _ready():
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)
	
	# Turn fire off at the start of the game
	toggle_fire(false)

func _unhandled_input(event):
	if event.is_action_pressed('interact') and player_in_range:
		# Toggle the fire state
		if not is_lit:
			toggle_fire(true)
			print("Campfire lit! Ready to cook.")
		else:
			toggle_fire(false)
			print("Campfire extinguished.")

func toggle_fire(on: bool):
	is_lit = on
	if is_lit:
		fire_sprite.visible = true
		smoke_sprite.visible = true
		# IMPORTANT: Change "burn" to whatever you named your animation!
		anim_player.play("fire_on") 
	else:
		fire_sprite.visible = false
		smoke_sprite.visible = false
		anim_player.stop()

func _on_interact_area_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_interact_area_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		# Optional: Auto-extinguish if the player walks away
		if is_lit:
			toggle_fire(false)
