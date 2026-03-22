extends Control

const DAY_START_HOUR := 6
const DAY_LENGTH_MINUTES := 18 * 60
const TIME_TICK_MINUTES := 30

@onready var day_label: Label = $VBoxContainer/DayLabel
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var time_icon: AnimatedSprite2D = $TimeIcon

# Drag your audio files from the FileSystem into these variables!
@export var day_music: AudioStream
@export var night_music: AudioStream

# Tracks the current audio phase so we don't spam the MusicManager
var _active_music_phase: String = ""
var day_timer: Timer
var _last_rendered_day := -1
var _last_rendered_time := ""
var _last_animation := ""

func _ready() -> void:
	_resolve_day_timer()
	_update_view(true)
	
	# 2. Set the text immediately on boot
	_update_day_display(Global.current_day)
	
	# 3. Connect to the global signal so we never have to poll it in _process
	Global.day_changed.connect(_update_day_display)
	
func _update_day_display(new_day: int) -> void:
	if day_label:
		day_label.text = "Day " + str(new_day)
func _process(_delta: float) -> void:
	if not is_instance_valid(day_timer):
		_resolve_day_timer()

	_update_view()

func _resolve_day_timer() -> void:
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_node("DayTimer"):
		day_timer = main_scene.get_node("DayTimer") as Timer

func _update_view(force := false) -> void:
	# 1. The Ultimate Override: Is the day ending?
	if Global.pending_day_transition:
		_set_time_label("Midnight", force)
		_set_icon_animation("night", force)
		
		# Lock in the silence phase immediately
		if _active_music_phase != "silence":
			_active_music_phase = "silence"
			MusicManager.fade_to_silence(0.45)
			
		return # Halt all further UI updates for this frame

	# 2. Normal Gameplay: Is the timer running?
	if not day_timer.is_stopped():
		_update_clock(force)

func _set_day_label(force := false) -> void:
	if not force and _last_rendered_day == Global.current_day:
		return

	_last_rendered_day = Global.current_day
	day_label.text = "Day " + str(Global.current_day)

func _set_time_label(next_time: String, force := false) -> void:
	if not force and _last_rendered_time == next_time:
		return

	_last_rendered_time = next_time
	time_label.text = next_time

func _set_icon_animation(next_animation: String, force := false) -> void:
	if not force and _last_animation == next_animation:
		return

	_last_animation = next_animation
	
	if time_icon.animation != next_animation:
		# --- ELEGANT FADE TRANSITION ---
		var tween = create_tween()
		# 1. Fade the current icon to 0% opacity over 0.5 seconds
		tween.tween_property(time_icon, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		# 2. Swap the animation while it's invisible
		tween.tween_callback(func(): time_icon.play(next_animation))
		# 3. Fade the new icon back to 100% opacity over 0.5 seconds
		tween.tween_property(time_icon, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

func _check_music_transition(clock_hour_24: int) -> void:
	# Determine what the music phase *should* be right now
	var target_phase: String = "day" if (clock_hour_24 >= 6 and clock_hour_24 < 18) else "night"

	# If we are already in this phase, bail out immediately. Zero Autoload traffic.
	if target_phase == _active_music_phase:
		return

	# Otherwise, the phase just changed! Update the cache and trigger the crossfade.
	_active_music_phase = target_phase

	if target_phase == "day" and day_music:
		MusicManager.crossfade_to(day_music, 0.35)
	elif target_phase == "night" and night_music:
		MusicManager.crossfade_to(night_music, 0.35)


func _update_clock(force := false) -> void:
	var max_time = day_timer.wait_time
	if max_time <= 0.0:
		_set_time_label("6:00 AM", force)
		_set_icon_animation("dawn", force)
		return

	var time_left = day_timer.time_left
	var progress = clampf(1.0 - (time_left / max_time), 0.0, 1.0)
	
	var passed_minutes = int(DAY_LENGTH_MINUTES * progress)
	var displayed_minutes = passed_minutes - (passed_minutes % TIME_TICK_MINUTES)

	var hours = DAY_START_HOUR + int(displayed_minutes / 60.0)
	
	# Normalize to a strict 0-23 format
	var clock_hour_24 = hours % 24 
	var minutes = displayed_minutes % 60
	
	var am_pm = "AM"
	if clock_hour_24 >= 12:
		am_pm = "PM"
		
	var display_hour = clock_hour_24
	if display_hour > 12:
		display_hour -= 12
	if display_hour == 0: 
		display_hour = 12
		
	var min_str = str(minutes)
	if minutes < 10:
		min_str = "0" + min_str
		
	_set_time_label(str(display_hour) + ":" + min_str + " " + am_pm, force)

	var current_anim = "day"
	
	if clock_hour_24 >= 6 and clock_hour_24 < 9:
		current_anim = "dawn"
	elif clock_hour_24 >= 9 and clock_hour_24 < 13:
		current_anim = "day"
	elif clock_hour_24 >= 13 and clock_hour_24 < 18:
		current_anim = "noon"
	else:
		current_anim = "night"

	_set_icon_animation(current_anim, force)
	
	# Safely trigger music checks based purely on the clock math
	_check_music_transition(clock_hour_24)
