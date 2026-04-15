extends CanvasLayer

@onready var cursor: Cursor = get_parent()._cursor
@onready var _title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var _items_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ItemsList
@onready var _cancel_button: Button = $Panel/MarginContainer/VBoxContainer/CancelButton

func _ui_sound_manager() -> Node:
	return get_node_or_null("/root/UISoundManager")

func _ready() -> void:
	$Panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.1, 0.94)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.78, 0.72, 0.54, 0.95)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.corner_radius_bottom_left = 10
	$Panel.add_theme_stylebox_override("panel", panel_style)
	_wire_browse_sound(_cancel_button)
	refresh_for_current_unit()
	cursor.hide()
	cursor.process_mode = Node.PROCESS_MODE_DISABLED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		_on_cancel_button_pressed()
		get_viewport().set_input_as_handled()

func refresh_for_current_unit() -> void:
	for child in _items_list.get_children():
		_items_list.remove_child(child)
		child.queue_free()

	var board = get_parent()
	var unit = board._active_unit
	_title_label.text = "Items"
	if unit != null:
		_title_label.text = "%s's Items" % unit.name

	var tonics: Array[int] = board.get_active_unit_available_tonics()
	if tonics.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No tonics in inventory."
		_items_list.add_child(empty_label)
	else:
		for item_variant in tonics:
			var item_type := int(item_variant)
			var count := int(Global.inventory.get(item_type, 0))
			var heal_amount := Global.get_tonic_heal_amount(item_type)
			var button := Button.new()
			button.custom_minimum_size = Vector2(0, 52)
			button.text = "%s x%d  (Heal %d)" % [Global.get_item_display_name(item_type), count, heal_amount]
			button.pressed.connect(_on_item_pressed.bind(item_type))
			_wire_browse_sound(button)
			_items_list.add_child(button)

	call_deferred("_focus_first_button")

func _focus_first_button() -> void:
	for child in _items_list.get_children():
		var button := child as Button
		if button != null and not button.disabled:
			button.grab_focus()
			return
	_cancel_button.grab_focus()

func _wire_browse_sound(button: Button) -> void:
	if button == null:
		return
	button.focus_entered.connect(_on_menu_button_highlighted.bind(button))
	button.mouse_entered.connect(_on_menu_button_highlighted.bind(button))

func _on_menu_button_highlighted(button: Button) -> void:
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_browse_battle(button)

func _on_item_pressed(item_type: int) -> void:
	var board = get_parent()
	var success: bool = bool(board.try_use_battle_item_on_active_unit(item_type))
	if success:
		cursor.process_mode = Node.PROCESS_MODE_INHERIT
		cursor.show()
		queue_free()
		return
	refresh_for_current_unit()

func _on_cancel_button_pressed() -> void:
	get_parent().cancel_battle_item_menu()
