extends Node

var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var current_player: AudioStreamPlayer
var current_track: AudioStream

# 1. Add a reference to track the currently running tween
var active_tween: Tween 

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
		
	# Set parallel to true so both players fade at the exact same time
	active_tween = create_tween().set_parallel(true)
	
	# Catch and fade ANY player that is currently making noise
	if player_a.playing:
		active_tween.tween_property(player_a, "volume_db", -80.0, fade_duration)
	if player_b.playing:
		active_tween.tween_property(player_b, "volume_db", -80.0, fade_duration)
		
	# Wait for the fade to finish, then explicitly shut both down
	active_tween.chain().tween_callback(player_a.stop)
	active_tween.parallel().tween_callback(player_b.stop)
		
	current_track = null	
