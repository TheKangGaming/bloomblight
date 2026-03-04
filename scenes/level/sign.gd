extends StaticBody2D

@export_multiline var sign_text: String = "Default sign text."

@onready var label = $Label
var player_in_range := false

func _ready():
	
	label.text = sign_text
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)

func _unhandled_input(event):
	# Using your action key to read the sign
	if event.is_action_pressed("interact") and player_in_range:
		# This toggles the label: If it's visible, it hides it. If hidden, it shows it.
		label.visible = !label.visible
		
		if Global.tutorial_step == 1:
			Global.advance_tutorial()

func _on_interact_area_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true

func _on_interact_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		# Auto-hide the text if the player walks away while reading
		label.visible = false
