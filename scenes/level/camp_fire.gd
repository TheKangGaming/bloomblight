extends StaticBody2D

const AUTO_OPEN_DELAY_SECONDS := 0.7
const AUTO_OPEN_INPUT_BUFFER_SECONDS := 0.9

var player_in_range := false
var is_lit := false
var _player_body: CharacterBody2D = null
var _cooking_menu = null
var _interaction_block_until_msec := 0
var _feedback_layer: CanvasLayer = null
var _feedback_popup: PanelContainer = null
var _feedback_label: Label = null
var _feedback_tween: Tween = null

@onready var fire_sprite = $Fire
@onready var smoke_sprite = $Smoke
@onready var anim_player = $AnimationPlayer

func get_cooking_menu():
	if is_instance_valid(_cooking_menu):
		return _cooking_menu

	_cooking_menu = get_tree().get_first_node_in_group("CookingMenu")
	return _cooking_menu

func _ready():
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)
	_ensure_feedback_ui()
	var cooking_menu = get_cooking_menu()
	if cooking_menu:
		if not cooking_menu.menu_opened.is_connected(_on_cooking_menu_opened):
			cooking_menu.menu_opened.connect(_on_cooking_menu_opened)
		if not cooking_menu.menu_closed.is_connected(_on_cooking_menu_closed):
			cooking_menu.menu_closed.connect(_on_cooking_menu_closed)

	# Turn fire off at the start of the game
	toggle_fire(false)

func _exit_tree() -> void:
	if _feedback_layer != null and is_instance_valid(_feedback_layer):
		_feedback_layer.queue_free()

func _unhandled_input(event) -> void:
	if not player_in_range:
		return
	if _player_body != null and is_instance_valid(_player_body) and not _player_body.can_move:
		return
	if Time.get_ticks_msec() < _interaction_block_until_msec:
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
			show_feedback("Campfire lit")
			block_interaction_for(AUTO_OPEN_INPUT_BUFFER_SECONDS)
			_set_player_movement_locked(true)
			await get_tree().create_timer(AUTO_OPEN_DELAY_SECONDS, true).timeout
			if cooking_menu and player_in_range and is_lit and not cooking_menu.visible:
				_open_cooking_menu(cooking_menu)
			else:
				_set_player_movement_locked(false)
			return

		if cooking_menu and not cooking_menu.visible:
			if should_advance_tutorial:
				Global.advance_tutorial()
			_open_cooking_menu(cooking_menu)
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

func _open_cooking_menu(cooking_menu) -> void:
	if cooking_menu == null or not player_in_range or not is_lit or cooking_menu.visible:
		return

	cooking_menu.open_menu()
	show_feedback("Cooking menu opened")

func _set_player_movement_locked(locked: bool) -> void:
	if _player_body == null or not is_instance_valid(_player_body):
		return

	_player_body.can_move = not locked
	if locked:
		_player_body.direction = Vector2.ZERO

func block_interaction_for(seconds: float) -> void:
	_interaction_block_until_msec = Time.get_ticks_msec() + int(maxf(seconds, 0.0) * 1000.0)

func show_feedback(message: String) -> void:
	_ensure_feedback_ui()
	if _feedback_popup == null or _feedback_label == null:
		return

	_feedback_label.text = message
	_feedback_popup.visible = true
	_feedback_popup.modulate.a = 0.0
	if _feedback_tween != null and is_instance_valid(_feedback_tween):
		_feedback_tween.kill()
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_feedback_popup, "modulate:a", 1.0, 0.12)
	_feedback_tween.tween_interval(0.95)
	_feedback_tween.tween_property(_feedback_popup, "modulate:a", 0.0, 0.18)
	_feedback_tween.tween_callback(_hide_feedback_popup)

func _ensure_feedback_ui() -> void:
	if _feedback_layer != null and is_instance_valid(_feedback_layer):
		return

	_feedback_layer = CanvasLayer.new()
	_feedback_layer.name = "CampfireFeedbackLayer"
	_feedback_layer.layer = 25
	var root := get_tree().root if get_tree() != null else null
	if root != null:
		root.add_child(_feedback_layer)
	else:
		add_child(_feedback_layer)

	var popup := PanelContainer.new()
	popup.name = "FeedbackPopup"
	popup.visible = false
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.anchor_left = 0.5
	popup.anchor_right = 0.5
	popup.anchor_top = 0.0
	popup.anchor_bottom = 0.0
	popup.offset_left = -170.0
	popup.offset_top = 76.0
	popup.offset_right = 170.0
	popup.offset_bottom = 128.0

	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	popup.add_child(label)
	_feedback_layer.add_child(popup)
	WorldPopupStyle.apply(popup, label, 18)
	_feedback_popup = popup
	_feedback_label = label

func _hide_feedback_popup() -> void:
	if _feedback_popup != null and is_instance_valid(_feedback_popup):
		_feedback_popup.visible = false
