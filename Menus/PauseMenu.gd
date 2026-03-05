extends CanvasLayer

@onready var cursor: Cursor = get_parent()._cursor
@onready var _units_button: Button = $VBoxContainer/UnitsButton
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_reset_menu_focus()
	
	##disable the cursor
	cursor.hide()
	cursor.process_mode = Node.PROCESS_MODE_DISABLED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()

func _reset_menu_focus() -> void:
	if is_instance_valid(_units_button):
		_units_button.grab_focus()

func _on_visibility_changed() -> void:
	if visible:
		call_deferred("_reset_menu_focus")


func _on_units_button_pressed() -> void:
	pass # Replace with function body.


func _on_options_button_pressed() -> void:
	pass # Replace with function body.


func _on_end_turn_button_pressed() -> void:
	get_parent().end_player_phase()
	_on_close_button_pressed() # Uses your existing cleanup logic!

func _on_close_button_pressed() -> void:
	
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	#cursor.reset_cursor()
	cursor.show()
	queue_free()
	
