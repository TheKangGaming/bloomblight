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

func crossfade_to(stream: AudioStream, fade_duration: float = 3.0) -> void:
	if current_track == stream:
		return 
		
	current_track = stream
	
	# 2. If a crossfade is already happening, execute it immediately
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	
	var next_player = player_b if current_player == player_a else player_a
	
	# 3. Force stop the next player just in case it was left playing by a killed tween
	next_player.stop()
	
	next_player.stream = stream
	next_player.volume_db = -80.0 
	next_player.play()
	
	# 4. Assign the new tween to our tracker variable
	active_tween = create_tween().set_parallel(true)
	
	if current_player.playing:
		active_tween.tween_property(current_player, "volume_db", -80.0, fade_duration)
		
	active_tween.tween_property(next_player, "volume_db", 0.0, fade_duration)
	
	active_tween.chain().tween_callback(current_player.stop)
	
	current_player = next_player
