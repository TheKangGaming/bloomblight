extends Control
# scenes/ui/day_time_hud.gd

@onready var day_label: Label = $VBoxContainer/DayLabel
@onready var time_label: Label = $VBoxContainer/TimeLabel

# We will grab this automatically when the scene loads!
var day_timer: Timer

func _ready() -> void:
	# Try to find the DayTimer in the farm scene
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_node("DayTimer"):
		day_timer = main_scene.get_node("DayTimer")

func _process(_delta: float) -> void:
	# 1. Always keep the Day accurate
	day_label.text = "Day " + str(Global.current_day)
	
	# 2. Update the clock if the timer is ticking
	if day_timer and not day_timer.is_stopped():
		_update_clock()
	elif Global.pending_day_transition:
		time_label.text = "Midnight"

func _update_clock() -> void:
	# Assuming a work day starts at 6:00 AM and ends at 12:00 AM (18 hours)
	var max_time = day_timer.wait_time
	var time_left = day_timer.time_left
	
	# Calculate how far into the day we are (0.0 to 1.0)
	var progress = 1.0 - (time_left / max_time)
	
	# 18 hours * 60 minutes = 1080 total minutes in a day
	var total_minutes = 18 * 60 
	var passed_minutes = int(total_minutes * progress)
	
	# Calculate standard Hours and Minutes
	var hours = 6 + (passed_minutes / 60)
	var minutes = passed_minutes % 60
	
	# Format it to AM/PM beautifully
	var am_pm = "AM"
	if hours >= 12:
		am_pm = "PM"
		
	var display_hour = hours
	if display_hour > 12:
		display_hour -= 12
	if display_hour == 0:
		display_hour = 12
		
	# Force minutes to have a leading zero (e.g., "05" instead of "5")
	var min_str = str(minutes)
	if minutes < 10:
		min_str = "0" + min_str
		
	time_label.text = str(display_hour) + ":" + min_str + " " + am_pm
