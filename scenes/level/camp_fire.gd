extends StaticBody2D

var player_in_range := false
var is_lit := false

@onready var fire_sprite = $Fire
@onready var smoke_sprite = $Smoke
@onready var anim_player = $AnimationPlayer
@onready var feedback_label = $FeedbackLabel
@onready var feedback_timer = $FeedbackTimer

func get_cooking_menu():
	return get_tree().get_first_node_in_group("CookingMenu")

func _ready():
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)
	feedback_timer.timeout.connect(_on_feedback_timer_timeout)

	# Turn fire off at the start of the game
	toggle_fire(false)

func _unhandled_input(event):
	if not player_in_range:
		return

	var cooking_menu = get_cooking_menu()
	var is_confirm := event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	var is_cancel := event.is_action_pressed("ui_cancel")

	if is_confirm:
		if not is_lit:
			toggle_fire(true)
			if Global.tutorial_step == 10:
				Global.advance_tutorial()
			if cooking_menu:
				cooking_menu.open_menu()
				show_feedback("Campfire lit. Cooking menu opened")
			else:
				show_feedback("Campfire is lit")
			return

		if cooking_menu and not cooking_menu.visible:
			cooking_menu.open_menu()
			show_feedback("Cooking menu opened")
		return

	if is_cancel and is_lit:
		if cooking_menu and cooking_menu.visible:
			cooking_menu.close_menu()
			show_feedback("Cooking menu closed")
		else:
			toggle_fire(false)
			show_feedback("Campfire extinguished")

func toggle_fire(on: bool):
	is_lit = on
	if is_lit:
		fire_sprite.visible = true
		smoke_sprite.visible = true
		anim_player.play("fire_on")
	else:
		fire_sprite.visible = false
		smoke_sprite.visible = false
		anim_player.stop()

func _on_interact_area_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true

func _on_interact_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		var cooking_menu = get_cooking_menu()
		if cooking_menu and cooking_menu.visible:
			cooking_menu.close_menu()

func show_feedback(message: String):
	feedback_label.text = message
	feedback_label.visible = true
	feedback_timer.start()

func _on_feedback_timer_timeout():
	feedback_label.visible = false
