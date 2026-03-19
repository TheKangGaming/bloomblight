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

func _spawn_actors() -> void:
	# We will write the instantiation logic here next!
	pass
