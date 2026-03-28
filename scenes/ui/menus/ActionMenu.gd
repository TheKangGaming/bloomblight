extends CanvasLayer

@onready var cursor: Cursor = get_parent()._cursor
@onready var _attack_button: Button = $VBoxContainer/AttackButton
@onready var _ability_button: Button = $VBoxContainer/AbilityButton
@onready var _wait_button: Button = $VBoxContainer/WaitButton
@onready var _cancel_button: Button = $VBoxContainer/CancelButton

func _ready() -> void:
	$VBoxContainer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	$VBoxContainer.move_child(_wait_button, $VBoxContainer.get_child_count() - 1)
	var unit = get_parent()._active_unit
	var board = get_parent()

	_attack_button.disabled = unit == null or not board._unit_has_available_main_action(unit)
	
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
	elif is_instance_valid(_wait_button):
		_wait_button.grab_focus()
	elif is_instance_valid(_cancel_button):
		_cancel_button.grab_focus()

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
	pass


func _on_trade_button_pressed() -> void:
	pass


func _on_wait_button_pressed() -> void:
	get_parent().finish_unit_turn()
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.show()
	queue_free()


func _on_cancel_button_pressed() -> void:
	get_parent()._reset_unit()
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.show()
	queue_free()
