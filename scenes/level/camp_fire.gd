extends StaticBody2D

var player_in_range := false
var is_lit := false
var _player_body: CharacterBody2D = null
var _cooking_menu = null

@onready var fire_sprite = $Fire
@onready var smoke_sprite = $Smoke
@onready var anim_player = $AnimationPlayer
@onready var feedback_popup: PanelContainer = $FeedbackPopup
@onready var feedback_label: Label = $FeedbackPopup/Label
@onready var feedback_timer = $FeedbackTimer

func get_cooking_menu():
	if is_instance_valid(_cooking_menu):
		return _cooking_menu

	_cooking_menu = get_tree().get_first_node_in_group("CookingMenu")
	return _cooking_menu

func _ready():
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)
	feedback_timer.timeout.connect(_on_feedback_timer_timeout)
	WorldPopupStyle.apply(feedback_popup, feedback_label, 18)
	var cooking_menu = get_cooking_menu()
	if cooking_menu:
		if not cooking_menu.menu_opened.is_connected(_on_cooking_menu_opened):
			cooking_menu.menu_opened.connect(_on_cooking_menu_opened)
		if not cooking_menu.menu_closed.is_connected(_on_cooking_menu_closed):
			cooking_menu.menu_closed.connect(_on_cooking_menu_closed)

	# Turn fire off at the start of the game
	toggle_fire(false)

func _unhandled_input(event):
	if not player_in_range:
		return

	var cooking_menu = get_cooking_menu()
	var is_confirm: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	var is_cancel: bool = event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel")
	var should_advance_tutorial := Global.tutorial_step == 10

	if is_confirm:
		if not is_lit:
			toggle_fire(true)
			if DemoDirector:
				DemoDirector.notify_campfire_lit()
			if should_advance_tutorial:
				Global.advance_tutorial()
			if cooking_menu:
				cooking_menu.open_menu()
				show_feedback("Campfire lit. Cooking menu opened")
			else:
				show_feedback("Campfire is lit")
			return

		if cooking_menu and not cooking_menu.visible:
			if should_advance_tutorial:
				Global.advance_tutorial()
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
		_player_body = body as CharacterBody2D

func _on_interact_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		var cooking_menu = get_cooking_menu()
		if cooking_menu and cooking_menu.visible:
			cooking_menu.close_menu()
		_set_player_movement_locked(false)
		_player_body = null

func _on_cooking_menu_opened() -> void:
	_set_player_movement_locked(true)

func _on_cooking_menu_closed() -> void:
	_set_player_movement_locked(false)

func _set_player_movement_locked(locked: bool) -> void:
	if _player_body == null or not is_instance_valid(_player_body):
		return

	_player_body.can_move = not locked
	if locked:
		_player_body.direction = Vector2.ZERO

func show_feedback(message: String):
	feedback_label.text = message
	feedback_popup.visible = true
	feedback_popup.modulate.a = 1.0
	feedback_timer.start()

func _on_feedback_timer_timeout():
	feedback_popup.visible = false
