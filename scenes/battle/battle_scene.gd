extends Node2D

var _attacker_data: CharacterData
var _defender_data: CharacterData
var _attacker_stats: UnitStats
var _defender_stats: UnitStats

# Optional: Add Marker2D nodes in your scene to define exactly where they spawn!
# @onready var left_spawn: Marker2D = $LeftSpawn
# @onready var right_spawn: Marker2D = $RightSpawn

func _ready() -> void:
	# 1. Grab the secure briefcase from the Autoload
	var payload := CombatManager.get_payload()
	
	if payload == null:
		push_error("BattleScene Error: Booted up without a CombatPayload!")
		return
		
	# 2. Extract the data locally
	_attacker_data = payload.attacker_data
	_defender_data = payload.defender_data
	_attacker_stats = payload.attacker_stats
	_defender_stats = payload.defender_stats
	
	# 3. DESTROY the payload in the Autoload so it never leaks into the next battle
	CombatManager.clear_payload()
	
	# 4. Boot up the visuals
	_spawn_actors()

@onready var left_spawn: Marker2D = $LeftSpawn   # Create these in your scene!
@onready var right_spawn: Marker2D = $RightSpawn # Create these in your scene!

var active_attacker: BattleActor
var active_defender: BattleActor

func _spawn_actors() -> void:
	# 1. Instantiate the attacker
	if _attacker_data.battle_actor_scene:
		active_attacker = _attacker_data.battle_actor_scene.instantiate() as BattleActor
		left_spawn.add_child(active_attacker)
		active_attacker.setup_from_combat_snapshot(_attacker_data, _attacker_stats, true)
	
	# 2. Instantiate the defender
	if _defender_data.battle_actor_scene:
		active_defender = _defender_data.battle_actor_scene.instantiate() as BattleActor
		right_spawn.add_child(active_defender)
		active_defender.setup_from_combat_snapshot(_defender_data, _defender_stats, false)
