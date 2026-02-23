extends StaticBody2D

var player_in_range := false
var is_lit := false

@onready var anim_player = $AnimationPlayer

func _ready():
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)
	
	# Turn fire off at the start of the game
	toggle_fire(false)

func _unhandled_input(event):
	if event.is_action_pressed("action") and player_in_range:
		# If the fire is off, turn it on (and eventually open the UI)
		if not is_lit:
			toggle_fire(true)
			print("Campfire lit! Opening cooking menu...")
		# If it's already on, turn it off (and close the UI)
		else:
			toggle_fire(false)
			print("Campfire extinguished.")

func toggle_fire(on: bool):
	is_lit = on
	if is_lit:
		pass
		# Turn your animations ON here!
		fire.visible = true
		# fire_anim.play("burn")
	else:
		pass
		# Turn your animations OFF here!
		# fire_anim.visible = false
		# fire_anim.stop()

func _on_interact_area_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_interact_area_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		# Auto-extinguish if the player walks away while cooking!
		if is_lit:
			toggle_fire(false)
