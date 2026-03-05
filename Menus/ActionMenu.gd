extends CanvasLayer

@onready var cursor: Cursor = get_parent()._cursor
@onready var _attack_button: Button = $VBoxContainer/AttackButton
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_reset_menu_focus()
	
	##disable the cursor
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
	# 1. Tell GameBoard to enter targeting mode!
	get_parent().enter_attack_targeting()
	
	# 2. Bring the cursor visually back to the front
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.show()
	
	# 3. Delete the menu
	queue_free()
	
func _on_items_pressed() -> void:
	pass # Replace with function body.


func _on_trade_button_pressed() -> void:
	pass # Replace with function body.


func _on_wait_button_pressed() -> void:
	# 1. Tell the GameBoard to run its built-in wait logic!
	# This will grey out the unit, clear the active unit, AND set cursor.is_active = true
	get_parent().finish_unit_turn()
	
	# 2. Re-enable the cursor visually
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.show()
	
	# 3. Delete the menu
	queue_free()


func _on_cancel_button_pressed() -> void:
	# 1. Tell the GameBoard to teleport the unit back and unfreeze the cursor
	get_parent()._reset_unit()
	
	# 2. Re-enable the cursor visually
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.show()
	
	# 3. Delete the menu
	queue_free()
