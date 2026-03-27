extends CanvasLayer

@onready var cursor: Cursor = get_parent()._cursor
@onready var _attack_button: Button = $VBoxContainer/AttackButton
@onready var _ability_button: Button = $VBoxContainer/AbilityButton

func _ready() -> void:
	$VBoxContainer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var unit = get_parent()._active_unit
	
	if unit.character_data and not unit.character_data.abilities.is_empty():
		var ability = unit.character_data.abilities[0]
		_ability_button.show()
		
		if unit.is_ability_ready(ability):
			_ability_button.text = ability.ability_name
			_ability_button.disabled = false

			if ability.type == AbilityData.AbilityType.HARVEST and unit.health >= unit.max_health:
				_ability_button.text = ability.ability_name + " (Full HP)"
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
	if is_instance_valid(_attack_button):
		_attack_button.grab_focus()

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
