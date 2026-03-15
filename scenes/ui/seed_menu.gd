extends Control

var seed_button_scene = preload("res://scenes/ui/seed_button.tscn")

signal seed_chosen(seed_type)
signal menu_cancelled

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide() # Start hidden
	
func open(player_pos: Vector2):
	# 1. Clear old buttons first
	for child in $PanelContainer/Grid.get_children():
		$PanelContainer/Grid.remove_child(child)
		child.queue_free()
		
	
	var has_seeds = false
	for item_type in Global.inventory:
		# FIX: Only create buttons if the item is actually a seed!
		# We check if the item is in our SEED_COORDS dictionary (from seed_button)
		# Or you can manually check:
		if item_type in Global.HARVEST_DROPS:
			
			var amount = Global.inventory[item_type]
			if amount > 0:
				has_seeds = true
				var btn = seed_button_scene.instantiate()
				$PanelContainer/Grid.add_child(btn)
				btn.setup(item_type, amount)
				btn.seed_selected.connect(_on_seed_selected)

	if has_seeds:
		show() # Make it visible so Godot can calculate the layout size
		
		# Wait 1 frame for the Container to resize itself
		await get_tree().process_frame
		
		# Calculate the Center Position
		# Start at the player's position
		$PanelContainer.global_position = player_pos
		
		# Shift Left by half the width (to center horizontally)
		$PanelContainer.global_position.x -= $PanelContainer.size.x / 2
		
		# Shift Up by the full height + padding (to sit above the head)
		$PanelContainer.global_position.y -= $PanelContainer.size.y + 20
		
		$PanelContainer.pivot_offset = $PanelContainer.size / 2
		$PanelContainer.scale = Vector2.ZERO
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) # Make it bounce!
		tween.tween_property($PanelContainer, "scale", Vector2.ONE, 0.3)
		
		# Focus the first button
		$PanelContainer/Grid.get_child(0).grab_focus()
		
	else:
		print('no seeds to plant!')
		hide()

func _input(event):
	# Only listen for inputs if the menu is actually open!
	if visible:
		# "cancel" maps to Escape/B for consistent menu backing out
		# We also added a check for Right-Click just in case!
		if event.is_action_pressed("cancel") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
			
			hide() # Close the menu visually
			menu_cancelled.emit() # Tell the game it was cancelled
			
			# This stops the 'Escape' or 'Right Click' from triggering other things
			get_viewport().set_input_as_handled()		

func _on_seed_selected(seed_type):
	seed_chosen.emit(seed_type)
	hide()
