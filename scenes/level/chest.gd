extends StaticBody2D

@onready var animation_player = $AnimationPlayer
@onready var loot_popup = $LootPopup

var is_open := false
var player_in_range := false

func _ready():
	# Connect the Area2D signals
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)


func _unhandled_input(event):
	
	if event.is_action_just_pressed("interact") and player_in_range and not is_open:
		open_chest()
		if Global.tutorial_step == 2:
			Global.advance_tutorial()

func open_chest():
	is_open = true
	animation_player.play('open')
	give_loot()
	$InteractArea/CollisionShape2D.set_deferred("disabled", true)

func give_loot():
	print("Chest opened! Loot distributed.")
	
	# Safely add to the inventory using Global enums
	Global.inventory[Global.Items.CORN_SEED] += 5
	Global.inventory[Global.Items.TOMATO_SEED] += 5
	Global.inventory[Global.Items.PUMPKIN_SEED] += 5
	
	# Give the tools by adding them to the unlocked array
	if not Global.unlocked_tools.has(Global.Tools.HOE):
		Global.unlocked_tools.append(Global.Tools.HOE)
		Global.unlocked_tools.append(Global.Tools.WATER)
		Global.unlocked_tools.append(Global.Tools.AXE)
	
	Global.inventory_updated.emit()
	
	loot_popup.visible = true
	
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
