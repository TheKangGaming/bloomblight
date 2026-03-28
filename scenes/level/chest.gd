extends StaticBody2D

signal opened

@export var grant_tools := true
@export var carrot_seed_reward := 5
@export var parsnip_seed_reward := 5
@export var grant_glazed_carrots_recipe := true
@export var reward_popup_text := "+ Seeds & Tools!"

@onready var animation_player = $AnimationPlayer
@onready var loot_popup: PanelContainer = $LootPopup
@onready var loot_popup_label: Label = $LootPopup/Label
@onready var open_sfx: AudioStreamPlayer2D = $OpenSfx
var _loot_popup_start_position := Vector2.ZERO

var is_open := false
var player_in_range := false

func _ready():
	WorldPopupStyle.apply(loot_popup, loot_popup_label, 18)
	_loot_popup_start_position = loot_popup.position
	loot_popup_label.text = reward_popup_text
	# Connect the Area2D signals
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)


func _is_interact_press(event: InputEvent) -> bool:
	if not (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		return false
	if event is InputEventKey and event.echo:
		return false
	return true

func _unhandled_input(event):
	if _is_interact_press(event) and player_in_range and not is_open:
		open_chest()
		if Global.tutorial_step == 2:
			Global.advance_tutorial()

func open_chest():
	is_open = true
	if open_sfx != null:
		open_sfx.play()
	animation_player.play('open')
	give_loot()
	$InteractArea/CollisionShape2D.set_deferred("disabled", true)
	opened.emit()

func give_loot():
	print("Chest opened! Loot distributed.")

	if carrot_seed_reward > 0:
		Global.inventory[Global.Items.CARROT_SEED] += carrot_seed_reward
	if parsnip_seed_reward > 0:
		Global.inventory[Global.Items.PARSNIP_SEED] += parsnip_seed_reward

	if grant_tools and not Global.unlocked_tools.has(Global.Tools.HOE):
		Global.unlocked_tools.append(Global.Tools.HOE)
		Global.unlocked_tools.append(Global.Tools.WATER)
		Global.unlocked_tools.append(Global.Tools.AXE)

	if grant_glazed_carrots_recipe and Global.learn_recipe(Global.Items.GLAZED_CARROTS):
		print("You found the Glazed Carrots recipe!")

	Global.inventory_updated.emit()

	loot_popup_label.text = reward_popup_text
	loot_popup.visible = true
	loot_popup.position = _loot_popup_start_position
	loot_popup.modulate.a = 1.0
	
	var tween = get_tree().create_tween()
	
	# Tween 1: Move the label's Y position up by 30 pixels over 2 seconds
	tween.tween_property(loot_popup, "position:y", loot_popup.position.y - 30, 2).set_trans(Tween.TRANS_SPRING)
	
	# Tween 2: Run in parallel (at the same time) to fade the alpha to 0.0
	tween.parallel().tween_property(loot_popup, "modulate:a", 0.0, 2)

func _on_interact_area_body_entered(body):
	# Check if the thing that entered the area is the player
	if body.is_in_group("Player"):
		player_in_range = true

func _on_interact_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
