extends Control

@onready var warning_text: Label = $CenterContainer/WarningText
@onready var defend_button: Button = $CenterContainer/DefendButton

func _ready() -> void:
	# 1. Start completely invisible
	modulate.a = 0.0
	defend_button.disabled = true # Prevent clicking before the fade finishes
	
	# 2. Grab the specific threat data from the Calendar
	var day = Global.current_day
	var encounter = CalendarService.get_encounter_for_day(day)
	
	# Fallback just in case, though the Interceptor shouldn't allow this!
	var threat_name = encounter.get("display_name", "Unknown Threat") 
	
	# 3. Format the ominous message
	warning_text.text = "DAY " + str(day) + "\n\nTHE " + threat_name.to_upper() + " HAS FOUND YOU."
	
	# 4. Fade the screen in slowly for dramatic effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): defend_button.disabled = false) # Unlock the button
	
	# Connect the button
	defend_button.pressed.connect(_on_defend_button_pressed)

func _on_defend_button_pressed() -> void:
	# Lock the button so they can't double-click it
	defend_button.disabled = true 
	
	# 1. Create a smooth fade out for the text and button
	var tween = create_tween()
	# Fades the CenterContainer to 0% opacity over 1.5 seconds
	tween.tween_property($CenterContainer, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	
	# 2. Tell the tween to load the map ONLY after the screen is completely black
	tween.tween_callback(_load_combat_scene)

func _load_combat_scene() -> void:
	if Global.pending_combat_scene_path != "":
		get_tree().change_scene_to_file(Global.pending_combat_scene_path)
	else:
		print("ERROR: No combat map was saved to Global!")
