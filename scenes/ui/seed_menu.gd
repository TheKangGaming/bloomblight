extends Control

var seed_button_scene = preload("res://scenes/ui/seed_button.tscn")

signal seed_chosen(seed_type)
signal menu_cancelled

func _ready() -> void:
	$PanelContainer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.09, 0.1, 0.92)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.88, 0.82, 0.56, 0.95)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	$PanelContainer.add_theme_stylebox_override("panel", panel_style)
	hide()

func has_available_seeds() -> bool:
	for item_type in Global.inventory:
		if item_type in Global.HARVEST_DROPS and int(Global.inventory[item_type]) > 0:
			return true
	return false
	
func open(player_pos: Vector2):
	for child in $PanelContainer/Grid.get_children():
		$PanelContainer/Grid.remove_child(child)
		child.queue_free()

	var current_season := CalendarService.get_current_season()
		
	var has_seeds = false
	for item_type in Global.inventory:
		if item_type in Global.HARVEST_DROPS:
			
			var amount = Global.inventory[item_type]
			if amount > 0:
				has_seeds = true
				var btn = seed_button_scene.instantiate()
				$PanelContainer/Grid.add_child(btn)

				var in_season := Global.is_seed_in_season(item_type, current_season)
				var growth_label := Global.get_seed_growth_label(item_type)
				var tooltip := "In season (%s)\nGrowth: %s" % [String(current_season).capitalize(), growth_label]
				if not in_season:
					var allowed_seasons: Array = Global.get_seed_seasons(item_type)
					var season_names: PackedStringArray = []
					for season_name in allowed_seasons:
						season_names.append(String(season_name).capitalize())
					tooltip = "Out of season. Plantable in: %s\nGrowth: %s" % [", ".join(season_names), growth_label]

				btn.setup(item_type, amount, in_season, tooltip)
				btn.seed_selected.connect(_on_seed_selected)

	if has_seeds:
		# Let the container finish sizing itself before we place it over the player.
		show()
		await get_tree().process_frame
		
		$PanelContainer.global_position = player_pos
		$PanelContainer.global_position.x -= $PanelContainer.size.x / 2
		$PanelContainer.global_position.y -= $PanelContainer.size.y + 20
		_clamp_panel_to_viewport()
		
		$PanelContainer.pivot_offset = $PanelContainer.size / 2
		$PanelContainer.scale = Vector2.ZERO
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property($PanelContainer, "scale", Vector2.ONE * 1.05, 0.2)
		tween.tween_property($PanelContainer, "scale", Vector2.ONE, 0.12)
		
		var focused_button := false
		for child in $PanelContainer/Grid.get_children():
			if child is Button and not child.disabled:
				child.grab_focus()
				focused_button = true
				break
		if not focused_button and $PanelContainer/Grid.get_child_count() > 0:
			$PanelContainer/Grid.get_child(0).grab_focus()
		
	else:
		menu_cancelled.emit()
		hide()

func _input(event):
	if visible:
		if event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
			
			hide()
			menu_cancelled.emit()
			get_viewport().set_input_as_handled()		

func _on_seed_selected(seed_type):
	seed_chosen.emit(seed_type)
	hide()

func _clamp_panel_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	var panel_size: Vector2 = $PanelContainer.size
	var clamped_position: Vector2 = $PanelContainer.global_position
	clamped_position.x = clampf(clamped_position.x, 8.0, maxf(8.0, viewport_size.x - panel_size.x - 8.0))
	clamped_position.y = clampf(clamped_position.y, 8.0, maxf(8.0, viewport_size.y - panel_size.y - 8.0))
	$PanelContainer.global_position = clamped_position.round()
