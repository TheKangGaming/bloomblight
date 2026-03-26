extends CanvasLayer

@onready var cursor: Cursor = get_parent()._cursor
@onready var _units_button: Button = $VBoxContainer/UnitsButton
@onready var _tutorials_button: Button = $VBoxContainer/TutorialsButton

var _units_snapshot: Array = []
var _units_overlay: CanvasLayer = null
var _tutorials_overlay: CanvasLayer = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_reset_menu_focus()
	
	##disable the cursor
	cursor.hide()
	cursor.process_mode = Node.PROCESS_MODE_DISABLED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		if _units_overlay != null:
			_close_units_overlay()
		elif _tutorials_overlay != null:
			_close_tutorials_overlay()
		else:
			_on_close_button_pressed()
		get_viewport().set_input_as_handled()

func _reset_menu_focus() -> void:
	if is_instance_valid(_units_button):
		_units_button.grab_focus()
	elif is_instance_valid(_tutorials_button):
		_tutorials_button.grab_focus()

func _on_visibility_changed() -> void:
	if visible:
		call_deferred("_reset_menu_focus")


func _set_units(units: Array) -> void:
	_units_snapshot = []
	for unit in units:
		if unit is Unit:
			_units_snapshot.append(unit)


func _on_units_button_pressed() -> void:
	if _units_overlay != null:
		_close_units_overlay()
		return

	_units_overlay = CanvasLayer.new()
	add_child(_units_overlay)

	var panel := PanelContainer.new()
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	panel.custom_minimum_size = Vector2(900, 560)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -450
	panel.offset_top = -280
	panel.offset_right = 450
	panel.offset_bottom = 280
	_units_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(content)

	var title := Label.new()
	title.text = "Units"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	content.add_child(title)

	var list_text := RichTextLabel.new()
	list_text.bbcode_enabled = true
	list_text.fit_content = false
	list_text.scroll_active = true
	list_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_text.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	list_text.add_theme_font_size_override("normal_font_size", 24)
	list_text.bbcode_text = _build_units_summary()
	content.add_child(list_text)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 64)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.pressed.connect(_close_units_overlay)
	content.add_child(close_btn)
	close_btn.grab_focus()


func _close_units_overlay() -> void:
	if _units_overlay != null:
		_units_overlay.queue_free()
		_units_overlay = null
	_reset_menu_focus()

func _on_tutorials_button_pressed() -> void:
	if _tutorials_overlay != null:
		_close_tutorials_overlay()
		return

	_tutorials_overlay = CanvasLayer.new()
	add_child(_tutorials_overlay)

	var panel := PanelContainer.new()
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	panel.custom_minimum_size = Vector2(920, 580)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -460
	panel.offset_top = -290
	panel.offset_right = 460
	panel.offset_bottom = 290
	_tutorials_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Tutorials"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	content.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var seen_cards: Array[Dictionary] = DemoDirector.get_seen_tutorial_cards() if DemoDirector else []
	if seen_cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No tutorials unlocked yet."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 24)
		list.add_child(empty_label)
	else:
		for card in seen_cards:
			var button := Button.new()
			button.text = String(card.get("title", "Tutorial"))
			button.custom_minimum_size = Vector2(0, 58)
			button.add_theme_font_size_override("font_size", 24)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.set_meta("tutorial_card_id", String(card.get("id", "")))
			button.pressed.connect(_on_tutorial_replay_button_pressed.bind(button))
			list.add_child(button)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 64)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.pressed.connect(_close_tutorials_overlay)
	content.add_child(close_btn)
	close_btn.grab_focus()

func _close_tutorials_overlay() -> void:
	if _tutorials_overlay != null:
		_tutorials_overlay.queue_free()
		_tutorials_overlay = null
	_reset_menu_focus()

func _replay_tutorial_card(card_id: String) -> void:
	if card_id.is_empty():
		return

	_close_tutorials_overlay()
	if DemoDirector:
		await DemoDirector.show_tutorial_card(card_id, self, true)
	_reset_menu_focus()

func _on_tutorial_replay_button_pressed(button: Button) -> void:
	if button == null:
		return

	await _replay_tutorial_card(String(button.get_meta("tutorial_card_id", "")))


func _build_units_summary() -> String:
	if _units_snapshot.is_empty():
		return "No units found."

	var lines: Array[String] = []
	for unit in _units_snapshot:
		if not is_instance_valid(unit):
			continue

		var display_name := "Unit"
		var unit_class_name := "Unknown"
		if unit.character_data != null:
			if not String(unit.character_data.display_name).is_empty():
				display_name = String(unit.character_data.display_name)
			if unit.character_data.class_data != null:
				unit_class_name = String(unit.character_data.class_data.metadata_name)

		var team_name := "Enemy" if unit.is_enemy else "Ally"
		lines.append("[b]%s[/b] (%s) - %s Lv.%d\nHP %d/%d  STR %d  DEF %d  SPD %d" % [
			display_name,
			team_name,
			unit_class_name,
			maxi(unit.level, 1),
			unit.health,
			unit.max_health,
			unit.strength,
			unit.defense,
			unit.speed,
		])

	return "\n\n".join(lines)


func _on_options_button_pressed() -> void:
	pass # Replace with function body.


func _on_end_turn_button_pressed() -> void:
	get_parent().end_player_phase()
	_on_close_button_pressed() # Uses your existing cleanup logic!

func _on_close_button_pressed() -> void:
	_close_units_overlay()
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	#cursor.reset_cursor()
	cursor.show()
	queue_free()
