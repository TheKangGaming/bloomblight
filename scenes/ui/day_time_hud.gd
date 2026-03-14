extends Control

const DAY_START_HOUR := 6
const DAY_LENGTH_MINUTES := 18 * 60
const TIME_TICK_MINUTES := 30

@onready var day_label: Label = $VBoxContainer/DayLabel
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var time_icon: AnimatedSprite2D = $TimeIcon

var day_timer: Timer
var _last_rendered_day := -1
var _last_rendered_time := ""
var _last_animation := ""

func _ready() -> void:
	_resolve_day_timer()
	_update_view(true)

func _process(_delta: float) -> void:
	if not is_instance_valid(day_timer):
		_resolve_day_timer()

	_update_view()

func _resolve_day_timer() -> void:
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_node("DayTimer"):
		day_timer = main_scene.get_node("DayTimer") as Timer

func _update_view(force := false) -> void:
	_set_day_label(force)

	if day_timer and not day_timer.is_stopped():
		_update_clock(force)
	elif Global.pending_day_transition:
		_set_time_label("Midnight", force)
		_set_icon_animation("night", force)
	else:
		_set_time_label("6:00 AM", force)
		_set_icon_animation("dawn", force)

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
		time_icon.play(next_animation)

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

	var hours = DAY_START_HOUR + (displayed_minutes / 60)
	var minutes = displayed_minutes % 60
	
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
		
	_set_time_label(str(display_hour) + ":" + min_str + " " + am_pm, force)

	var current_anim = "day"
	
	if hours >= 6 and hours < 9:
		current_anim = "dawn"
	elif hours >= 9 and hours < 13:
		current_anim = "day"
	elif hours >= 13 and hours < 18:
		current_anim = "noon"
	else:
		current_anim = "night"

	_set_icon_animation(current_anim, force)
