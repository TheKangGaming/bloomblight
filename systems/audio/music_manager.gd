extends Node

var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var current_player: AudioStreamPlayer
var current_track: AudioStream

# 1. Add a reference to track the currently running tween
var active_tween: Tween 

func _ready() -> void:
	player_a = AudioStreamPlayer.new()
	player_b = AudioStreamPlayer.new()
	
	player_a.bus = "Music"
	player_b.bus = "Music"
	
	add_child(player_a)
	add_child(player_b)
	
	current_player = player_a

# Added target_volume parameter, defaulting to 0.0 (native volume)
func crossfade_to(stream: AudioStream, fade_duration: float = 3.0, target_volume: float = 0.0) -> void:
	if current_track == stream:
		return 
		
	current_track = stream
	
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	
	var next_player = player_b if current_player == player_a else player_a
	
	next_player.stop()
	next_player.stream = stream
	next_player.volume_db = -80.0 
	next_player.play()
	
	active_tween = create_tween().set_parallel(true)
	
	if current_player.playing:
		active_tween.tween_property(current_player, "volume_db", -80.0, fade_duration)
		
	# Tween to the dynamic target instead of a hardcoded value
	active_tween.tween_property(next_player, "volume_db", target_volume, fade_duration)
	
	active_tween.chain().tween_callback(current_player.stop)
	
	current_player = next_player
	
func fade_to_silence(fade_duration: float = 2.0) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	active_tween = create_tween()
	
	if current_player and current_player.playing:
		active_tween.tween_property(current_player, "volume_db", -80.0, fade_duration)
		active_tween.tween_callback(current_player.stop)
		
	current_track = null	
