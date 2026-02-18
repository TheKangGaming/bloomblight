extends Control

var seed_button_scene = preload("res://scenes/ui/seed_button.tscn")

signal seed_chosen(seed_type)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide() # Start hidden
	
func open(player_pos: Vector2):
	# 1. Clear old buttons first
	for child in $PanelContainer/Grid.get_children():
		$PanelContainer/Grid.remove_child(child)
		child.queue_free()
		
	var has_seeds = false
	
	# 2. Add new buttons
	for seed_type in Global.inventory:
		var amount = Global.inventory[seed_type]
		
		if amount > 0:
			has_seeds = true
			var btn = seed_button_scene.instantiate()
			$PanelContainer/Grid.add_child(btn)
			btn.setup(seed_type, amount)
			btn.seed_selected.connect(_on_seed_selected)

	if has_seeds:
		show() # Make it visible so Godot can calculate the layout size
		
		# 3. Wait 1 frame for the Container to resize itself
		await get_tree().process_frame
		
		# 4. Calculate the Center Position
		# Start at the player's position
		$PanelContainer.global_position = player_pos
		
		# Shift Left by half the width (to center horizontally)
		$PanelContainer.global_position.x -= $PanelContainer.size.x / 2
		
		# Shift Up by the full height + padding (to sit above the head)
		$PanelContainer.global_position.y -= $PanelContainer.size.y + 20
		
		$PanelContainer.pivot_offset = $PanelContainer.size / 2
		$PanelContainer.scale = Vector2.ZERO
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) # Make it bouncy!
		tween.tween_property($PanelContainer, "scale", Vector2.ONE, 0.3)
		
		# 5. Focus the first button
		$PanelContainer/Grid.get_child(0).grab_focus()
		
	else:
		print('no seeds to plant!')
		hide()
		
func _on_seed_selected(seed_type):
	seed_chosen.emit(seed_type)
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
