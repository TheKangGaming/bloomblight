extends Node2D

@onready var left_spawn: Marker2D = $LeftSpawn
@onready var right_spawn: Marker2D = $RightSpawn


var _combat_distance: int = 1
var _attacker_data: CharacterData
var _defender_data: CharacterData
var _attacker_stats: UnitStats
var _defender_stats: UnitStats

var active_attacker: BattleActor
var active_defender: BattleActor

func _ready() -> void:
	var payload := CombatManager.get_payload()
	
		
	if payload == null:
		push_error("BattleScene Error: Booted up without a CombatPayload!")
		return
		
	# Extract the data
	_attacker_data = payload.attacker_data
	_defender_data = payload.defender_data
	_attacker_stats = payload.attacker_stats
	_defender_stats = payload.defender_stats
	
	# Save the distance so we know if a counterattack is possible!
	_combat_distance = payload.distance
	
	# Clear the payload from the Autoload
	CombatManager.clear_payload()
	
	# Spawn them in
	_spawn_actors()
	_execute_battle_sequence()

func _spawn_actors() -> void:
	# 1. Spawn Attacker (Left Side, Facing Right)
	if _attacker_data and _attacker_data.battle_actor_scene:
		active_attacker = _attacker_data.battle_actor_scene.instantiate() as BattleActor
		left_spawn.add_child(active_attacker)
		# Ensure their position is snapped exactly to the marker
		active_attacker.position = Vector2.ZERO 
		active_attacker.setup_from_combat_snapshot(_attacker_data, _attacker_stats, true)
	else:
		push_error("BattleScene: Attacker missing battle_actor_scene in CharacterData!")

	# 2. Spawn Defender (Right Side, Facing Left)
	if _defender_data and _defender_data.battle_actor_scene:
		active_defender = _defender_data.battle_actor_scene.instantiate() as BattleActor
		right_spawn.add_child(active_defender)
		active_defender.position = Vector2.ZERO
		active_defender.setup_from_combat_snapshot(_defender_data, _defender_stats, false)
	else:
		push_error("BattleScene: Defender missing battle_actor_scene in CharacterData!")

func _execute_battle_sequence() -> void:
	# 1. Dramatic pause as the camera loads in
	await get_tree().create_timer(0.5).timeout
	
	# --- PHASE 1: THE INITIATOR STRIKES ---
	if active_attacker:
		active_attacker.play_attack()
		
	# Wait for the sword/spell to visually connect
	await get_tree().create_timer(0.4).timeout
	
	if active_defender:
		active_defender.play_hit()
		
	# Let the dust settle and give the defender a moment to recover
	await get_tree().create_timer(0.8).timeout
	
	# --- PHASE 2: THE COUNTERATTACK ---
	# If they are fighting in adjacent grid cells (Melee), the defender swings back.
	# (In the future, you will wrap this in an 'if defender.current_hp > 0' check!)
	if _combat_distance == 1 and active_defender:
		active_defender.play_attack()
		
		# Wait for the counterattack to connect
		await get_tree().create_timer(0.4).timeout
		
		if active_attacker:
			active_attacker.play_hit()
			
		# Let the attacker recover from the hit
		await get_tree().create_timer(0.8).timeout
	
	# --- PHASE 3: THE RETURN ---
	# A final brief pause before the screen fades out
	await get_tree().create_timer(0.4).timeout
	_return_to_map()
	
func _return_to_map() -> void:
	# NOTE: Ensure this path perfectly matches your tactical map's file path!
	var map_path := "res://scenes/level/CombatMap_1.tscn"
	var map_scene := load(map_path) as PackedScene
	
	if map_scene == null:
		push_error("BattleScene: Could not load the return map!")
		return
		
	if TransitionManager and TransitionManager.has_method("change_scene"):
		TransitionManager.change_scene(map_scene)
	else:
		# Failsafe if TransitionManager isn't hooked up for the return trip
		get_tree().change_scene_to_packed(map_scene)	
