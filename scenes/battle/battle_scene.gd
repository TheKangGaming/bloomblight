extends CanvasLayer

# --- NODE REFERENCES ---
@onready var battle_world: Node2D = $BattleWorld

# --- STAGING ANCHORS ---
@onready var center_anchor: Marker2D = $BattleWorld/CenterAnchor
@onready var attacker_start: Marker2D = $BattleWorld/AttackerStart
@onready var defender_start: Marker2D = $BattleWorld/DefenderStart
@onready var attacker_melee: Marker2D = $BattleWorld/AttackerMelee
@onready var defender_melee: Marker2D = $BattleWorld/DefenderMelee

# --- COMBAT DATA ---
var _combat_distance: int = 1
var _attacker_data: CharacterData
var _defender_data: CharacterData
var _attacker_stats: UnitStats
var _defender_stats: UnitStats

var _combat_strikes: Array[CombatStrike] = []
var active_attacker: BattleActor
var active_defender: BattleActor

func _ready() -> void:
	var payload := CombatManager.get_payload()
		
	if payload == null:
		push_error("BattleScene Error: Booted up without a CombatPayload!")
		_return_to_map() # <--- SAFETY NET ADDED HERE
		return
		
	# Extract the data
	_attacker_data = payload.attacker_data
	_defender_data = payload.defender_data
	_attacker_stats = payload.attacker_stats
	_defender_stats = payload.defender_stats
	_combat_strikes = payload.strikes
	
	# Save the distance so we know if a counterattack is possible!
	_combat_distance = payload.distance
	
	# Clear the payload from the Autoload
	CombatManager.clear_payload()
	
	# FIX: Only run the sequence if spawning succeeds
	if _spawn_actors():
		_setup_staging()
		_execute_battle_sequence()
		
# --- THE STAGING DIRECTOR ---
func _setup_staging() -> void:
	# 1. Move the entire BattleWorld to the exact center of your monitor
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	battle_world.global_position = screen_center
	
	# 2. "Zoom" in by scaling the world! (Adjust these numbers for perfect framing)
	battle_world.scale = Vector2(2.5, 2.5) 
	
	# 3. Snap actors to their designated starting corners inside the world
	active_attacker.position = attacker_start.position
	active_defender.position = defender_start.position
	
	# 4. Ensure they are facing each other
	if active_attacker.has_method("set_facing"):
		active_attacker.set_facing("right")
	if active_defender.has_method("set_facing"):
		active_defender.set_facing("left")

func _spawn_actors() -> bool:
	# 1. Spawn Attacker (Left Side, Facing Right)
	if _attacker_data and _attacker_data.battle_actor_scene:
		active_attacker = _attacker_data.battle_actor_scene.instantiate() as BattleActor
		battle_world.add_child(active_attacker)
		# Ensure their position is snapped exactly to the marker
		active_attacker.position = Vector2.ZERO 
		active_attacker.setup_from_combat_snapshot(_attacker_data, _attacker_stats, true)
	else:
		push_error("BattleScene: Attacker missing battle_actor_scene in CharacterData!")

	# 2. Spawn Defender (Right Side, Facing Left)
	if _defender_data and _defender_data.battle_actor_scene:
		active_defender = _defender_data.battle_actor_scene.instantiate() as BattleActor
		battle_world.add_child(active_defender)
		active_defender.position = Vector2.ZERO
		active_defender.setup_from_combat_snapshot(_defender_data, _defender_stats, false)
	else:
		push_error("BattleScene: Defender missing battle_actor_scene in CharacterData!")
		
	if active_attacker == null or active_defender == null:
		push_error("BattleScene Error: Failed to spawn actors. Aborting sequence.")
		_return_to_map()
		return false # Tell _ready() to abort!
		
	return true # Tell _ready() it's safe to proceed!

func _execute_battle_sequence() -> void:
	# A dramatic pause as the arena fades in
	await get_tree().create_timer(0.5).timeout
	
	# THE MOVIE PLAYER: Iterate through the pre-calculated script!
	for i in _combat_strikes.size():
		var strike := _combat_strikes[i]
		
		# 1. Figure out who is swinging and who is getting hit
		var striker: BattleActor = active_attacker if strike.is_attacker_striking else active_defender
		var target: BattleActor = active_defender if strike.is_attacker_striking else active_attacker
		
		# 2. Initiate the attack animation
		striker.play_attack()
		
		# 3. Wait for the EXACT frame the weapon connects
		await striker.strike_impact
		
		# 4. The Reaction
		if strike.is_hit:
			# TODO: Spawn a floating damage number UI here! (strike.damage_dealt)
			if strike.target_survived:
				target.play_hit()
			else:
				target.play_death()
		else:
			# TODO: Spawn a "Miss!" UI here!
			if target.has_method("play_evade"):
				target.play_evade()
			else:
				target.play_hit() # Fallback if you don't have a dodge animation yet
				
		# 5. Wait for the attacker to finish their follow-through
		await striker.animation_finished_playing
		
		# A tiny buffer between strikes so they don't blend together
		await get_tree().create_timer(0.2).timeout

	# The script is over! Let the dust settle, then close the overlay.
	await get_tree().create_timer(0.6).timeout
	_return_to_map()
	
func _return_to_map() -> void:
	# Tell the transition manager to fade out, delete this node, and unpause the map
	if TransitionManager and TransitionManager.has_method("close_overlay"):
		TransitionManager.close_overlay(self, 0.5)
	else:
		queue_free()
		get_tree().paused = false
