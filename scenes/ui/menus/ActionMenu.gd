extends CanvasLayer

@onready var cursor: Cursor = get_parent()._cursor
@onready var _attack_button: Button = $VBoxContainer/AttackButton
@onready var _ability_button: Button = $VBoxContainer/AbilityButton
@onready var _items_button: Button = $VBoxContainer/ItemsButton
@onready var _trade_button: Button = $VBoxContainer/TradeButton
@onready var _wait_button: Button = $VBoxContainer/WaitButton
@onready var _cancel_button: Button = $VBoxContainer/CancelButton

func _ui_sound_manager() -> Node:
	return get_node_or_null("/root/UISoundManager")

func _ready() -> void:
	$VBoxContainer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	$VBoxContainer.move_child(_wait_button, $VBoxContainer.get_child_count() - 1)
	_wire_browse_sound(_attack_button)
	_wire_browse_sound(_ability_button)
	_wire_browse_sound(_items_button)
	_wire_browse_sound(_trade_button)
	_wire_browse_sound(_wait_button)
	_wire_browse_sound(_cancel_button)
	var unit = get_parent()._active_unit
	var board = get_parent()

	_attack_button.disabled = unit == null or not board._unit_has_available_main_action(unit)
	var items_available: bool = unit != null and bool(board._unit_has_usable_battle_items(unit))
	var item_action_used: bool = unit != null and unit.main_action_used
	var item_target_full_hp: bool = unit != null and unit.health >= unit.max_health
	_items_button.disabled = unit == null or item_action_used or not items_available or item_target_full_hp
	if unit == null:
		_items_button.text = "Items"
	elif item_action_used:
		_items_button.text = "Items (Used)"
	elif not items_available:
		_items_button.text = "Items (No Tonics)"
	elif item_target_full_hp:
		_items_button.text = "Items (Full HP)"
	else:
		_items_button.text = "Items"
	
	if unit.character_data and not unit.character_data.abilities.is_empty():
		var ability = unit.character_data.abilities[0]
		_ability_button.show()
		var bonus_action_ability: bool = board._ability_uses_bonus_action(ability)
		var ability_available: bool = board._unit_has_available_bonus_action(unit) if bonus_action_ability else board._unit_has_available_main_action(unit)
		
		if ability.type == AbilityData.AbilityType.BUFF and unit.has_combat_effect(&"hunt"):
			_ability_button.text = "%s (Active %d)" % [ability.ability_name, maxi(unit.get_combat_effect_turns(&"hunt"), 1)]
			_ability_button.disabled = true
		elif unit.is_ability_ready(ability):
			_ability_button.text = ability.ability_name
			_ability_button.disabled = not ability_available

			if ability.type == AbilityData.AbilityType.HARVEST and unit.health >= unit.max_health:
				_ability_button.text = ability.ability_name + " (Full HP)"
				_ability_button.disabled = true
			elif ability.type == AbilityData.AbilityType.HARVEST and not board._has_adjacent_battle_plant(unit):
				_ability_button.text = ability.ability_name + " (No Flower)"
				_ability_button.disabled = true
			elif bonus_action_ability and unit.bonus_action_used:
				_ability_button.text = ability.ability_name + " (Used)"
				_ability_button.disabled = true
			elif not bonus_action_ability and unit.main_action_used:
				_ability_button.text = ability.ability_name + " (Used)"
				_ability_button.disabled = true
			
			if not _ability_button.pressed.is_connected(_on_ability_button_pressed):
				_ability_button.pressed.connect(_on_ability_button_pressed.bind(ability))
		else:
			var remaining = unit.ability_cooldowns[ability]
			_ability_button.text = ability.ability_name + " (" + str(remaining) + ")"
			_ability_button.disabled = true
	else:
		_ability_button.hide()

	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.suppress_browse_once()
	_reset_menu_focus()
	
	cursor.hide()
	cursor.process_mode = Node.PROCESS_MODE_DISABLED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		_on_cancel_button_pressed()
		get_viewport().set_input_as_handled()

func _reset_menu_focus() -> void:
	if is_instance_valid(_attack_button) and not _attack_button.disabled:
		_attack_button.grab_focus()
	elif is_instance_valid(_ability_button) and _ability_button.visible and not _ability_button.disabled:
		_ability_button.grab_focus()
	elif is_instance_valid(_items_button) and _items_button.visible and not _items_button.disabled:
		_items_button.grab_focus()
	elif is_instance_valid(_wait_button):
		_wait_button.grab_focus()
	elif is_instance_valid(_cancel_button):
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

func _on_visibility_changed() -> void:
	if visible:
		call_deferred("_reset_menu_focus")

func _on_attack_button_pressed() -> void:
	get_parent().enter_attack_targeting()
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.show()
	queue_free()

func _on_ability_button_pressed(ability: AbilityData) -> void:
	get_parent().enter_ability_targeting(ability)
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.show()
	queue_free()
	
func _on_items_pressed() -> void:
	get_parent().open_battle_item_menu()


func _on_trade_button_pressed() -> void:
	pass


func _on_wait_button_pressed() -> void:
	get_parent().finish_unit_turn()
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.show()
	queue_free()


func _on_cancel_button_pressed() -> void:
	get_parent().cancel_action_menu()
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.show()
	queue_free()
