extends Control

@onready var day_label: Label = $VBoxContainer/DayLabel
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var time_icon: AnimatedSprite2D = $TimeIcon # <--- NEW REFERENCE

var day_timer: Timer

func _ready() -> void:
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_node("DayTimer"):
		day_timer = main_scene.get_node("DayTimer")

func _process(_delta: float) -> void:
	day_label.text = "Day " + str(Global.current_day)
	
	if day_timer and not day_timer.is_stopped():
		_update_clock()
	elif Global.pending_day_transition:
		time_label.text = "Midnight"
		# Force the night animation while sleeping
		if time_icon.animation != "night":
			time_icon.play("night")

func _update_clock() -> void:
	var max_time = day_timer.wait_time
	var time_left = day_timer.time_left
	var progress = 1.0 - (time_left / max_time)
	
	var total_minutes = 18 * 60 
	var passed_minutes = int(total_minutes * progress)
	
	var hours = 6 + (passed_minutes / 60)
	var minutes = passed_minutes % 60
	
	var am_pm = "AM"
	if hours >= 12:
		am_pm = "PM"
		
	var display_hour = hours
	if display_hour > 12:
		display_hour -= 12
	if display_hour == 0:
		display_hour = 12
		
	var min_str = str(minutes)
	if minutes < 10:
		min_str = "0" + min_str
		
	time_label.text = str(display_hour) + ":" + min_str + " " + am_pm
	
	# --- NEW ANIMATION LOGIC ---
	var current_anim = "day"
	
	if hours >= 6 and hours < 9:
		current_anim = "dawn"   # 6:00 AM to 8:59 AM
	elif hours >= 9 and hours < 13:
		current_anim = "day"    # 9:00 AM to 12:59 PM
	elif hours >= 13 and hours < 18:
		current_anim = "noon"   # 1:00 PM to 5:59 PM
	else:
		current_anim = "night"  # 6:00 PM onwards

	# Only call play() if the animation actually needs to change, 
	# otherwise it will restart the animation every single frame!
	if time_icon.animation != current_anim:
		time_icon.play(current_anim)
