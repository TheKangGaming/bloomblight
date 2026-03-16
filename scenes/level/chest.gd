extends StaticBody2D

@onready var animation_player = $AnimationPlayer
@onready var loot_popup = $LootPopup

@export var recipe_to_teach: Global.Items = Global.Items.WOOD

var is_open := false
var player_in_range := false

func _ready():
	# Connect the Area2D signals
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)


func _is_interact_press(event: InputEvent) -> bool:
	if not event.is_action_pressed("interact"):
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
	animation_player.play('open')
	give_loot()
	$InteractArea/CollisionShape2D.set_deferred("disabled", true)

func give_loot():
	print("Chest opened! Loot distributed.")

	var gave_recipe := false
	if Global.recipes.has(recipe_to_teach):
		gave_recipe = Global.learn_recipe(recipe_to_teach)
		if gave_recipe:
			print("You found a recipe scroll!")

	if not gave_recipe:
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
