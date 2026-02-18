extends Control

var seed_button_scene = preload("res://scenes/ui/seed_button.tscn")

signal seed_chosen(seed_type)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide() # Start hidden
	
func open():
	show()
	
	# clear old buttons
	for child in $PanelContainer/Grid.get_children():
		child.queue_free()
		
	var has_seeds = false
	
	for seed_type in Global.inventory:
		var amount = Global.inventory[seed_type]
		
		if amount > 0:
			has_seeds = true
			var btn = seed_button_scene.instantiate()
			$PanelContainer/Grid.add_child(btn)
			
			btn.seed_selected.connect(_on_seed_selected)

	if has_seeds:
		$PanelContainer/Grid.get_child(0).grab_focus()
	else:
		print('no seeds to plant!')
		hide()
		
func _on_seed_selected(seed_type):
	seed_chosen.emit(seed_type)
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
