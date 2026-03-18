extends Node

var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var current_player: AudioStreamPlayer
var current_track: AudioStream

func _ready() -> void:
	# Create two audio players so we can crossfade them
	player_a = AudioStreamPlayer.new()
	player_b = AudioStreamPlayer.new()
	
	# Assign them to the "Music" audio bus (in case you add volume sliders later)
	player_a.bus = "Music"
	player_b.bus = "Music"
	
	add_child(player_a)
	add_child(player_b)
	
	current_player = player_a

# Call this function from anywhere in your game to change the music!
func crossfade_to(stream: AudioStream, fade_duration: float = 3.0) -> void:
	# Don't do anything if the track is already playing
	if current_track == stream:
		return 
		
	current_track = stream
	
	# Determine which player is currently idle
	var next_player = player_b if current_player == player_a else player_a
	
	# Prep the new track
	next_player.stream = stream
	next_player.volume_db = -80.0 # Start completely silent
	next_player.play()
	
	# Animate the volume changes simultaneously
	var tween = create_tween().set_parallel(true)
	
	if current_player.playing:
		tween.tween_property(current_player, "volume_db", -80.0, fade_duration)
		
	# Fade in the new track (0.0 is default volume, lower it if the tracks are too loud)
	tween.tween_property(next_player, "volume_db", -15, fade_duration)
	
	# Stop the old player once the fade finishes
	tween.chain().tween_callback(current_player.stop)
	
	# Swap our pointers
	current_player = next_player
