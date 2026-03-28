extends Control

const DAY_START_HOUR := 6
const DAY_LENGTH_MINUTES := 18 * 60
const TIME_TICK_MINUTES := 30

@onready var day_label: Label = $VBoxContainer/DayLabel
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var time_icon: AnimatedSprite2D = $TimeIcon

@export var day_music: AudioStream
@export var night_music: AudioStream
@export var day_ambience: AudioStream
@export var night_ambience: AudioStream

var _active_music_phase: String = ""
var _active_ambience_phase: String = ""
var day_timer: Timer
var _last_rendered_day := -1
var _last_rendered_time := ""
var _last_animation := ""
var _day_ambience_player: AudioStreamPlayer = null
var _night_ambience_player: AudioStreamPlayer = null

const DAY_AMBIENCE_VOLUME_DB := -22.0
const NIGHT_AMBIENCE_VOLUME_DB := -20.0

func _ready() -> void:
	_resolve_day_timer()
	_ensure_ambience_players()
	_update_view(true)
	_update_day_display(Global.current_day)
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
	if Global.pending_day_transition:
		_set_time_label("Midnight", force)
		_set_icon_animation("night", force)
		
		if _active_music_phase != "silence":
			_active_music_phase = "silence"
			MusicManager.fade_to_silence(0.45)

		if _active_ambience_phase != "silence":
			_active_ambience_phase = "silence"
			_fade_ambience_to_silence(0.45)
			
		return

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
		var tween = create_tween()
		tween.tween_property(time_icon, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func(): time_icon.play(next_animation))
		tween.tween_property(time_icon, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

func _check_music_transition(clock_hour_24: int) -> void:
	var target_phase: String = "day" if (clock_hour_24 >= 6 and clock_hour_24 < 18) else "night"

	if target_phase == _active_music_phase:
		return

	_active_music_phase = target_phase

	if target_phase == "day" and day_music:
		MusicManager.crossfade_to(day_music, 0.35)
	elif target_phase == "night" and night_music:
		MusicManager.crossfade_to(night_music, 0.35)

	_check_ambience_transition(target_phase)

func _ensure_ambience_players() -> void:
	if _day_ambience_player == null:
		_day_ambience_player = AudioStreamPlayer.new()
		_day_ambience_player.name = "DayAmbiencePlayer"
		_day_ambience_player.bus = "Ambience"
		add_child(_day_ambience_player)

	if _night_ambience_player == null:
		_night_ambience_player = AudioStreamPlayer.new()
		_night_ambience_player.name = "NightAmbiencePlayer"
		_night_ambience_player.bus = "Ambience"
		add_child(_night_ambience_player)

	_assign_ambience_streams()

func _assign_ambience_streams() -> void:
	if _day_ambience_player and day_ambience:
		_day_ambience_player.stream = _prepare_looping_stream(day_ambience)
	if _night_ambience_player and night_ambience:
		_night_ambience_player.stream = _prepare_looping_stream(night_ambience)

func _prepare_looping_stream(stream: AudioStream) -> AudioStream:
	if stream == null:
		return null

	var duplicated := stream.duplicate(true)
	if duplicated is AudioStreamWAV:
		(duplicated as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	return duplicated

func _check_ambience_transition(target_phase: String) -> void:
	if target_phase == _active_ambience_phase:
		return

	_active_ambience_phase = target_phase
	if target_phase == "day":
		_crossfade_ambience(_day_ambience_player, DAY_AMBIENCE_VOLUME_DB, _night_ambience_player, 0.5)
	elif target_phase == "night":
		_crossfade_ambience(_night_ambience_player, NIGHT_AMBIENCE_VOLUME_DB, _day_ambience_player, 0.5)

func _crossfade_ambience(fade_in_player: AudioStreamPlayer, target_volume: float, fade_out_player: AudioStreamPlayer, duration: float) -> void:
	if fade_in_player != null and fade_in_player.stream != null:
		if not fade_in_player.playing:
			fade_in_player.volume_db = -40.0
			fade_in_player.play()

		var fade_in_tween := create_tween()
		fade_in_tween.tween_property(fade_in_player, "volume_db", target_volume, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if fade_out_player != null and fade_out_player.playing:
		var fade_out_tween := create_tween()
		fade_out_tween.tween_property(fade_out_player, "volume_db", -40.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fade_out_tween.tween_callback(fade_out_player.stop)

func _fade_ambience_to_silence(duration: float) -> void:
	for player in [_day_ambience_player, _night_ambience_player]:
		if player == null or not player.playing:
			continue

		var tween := create_tween()
		tween.tween_property(player, "volume_db", -40.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(player.stop)


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
	_check_music_transition(clock_hour_24)
