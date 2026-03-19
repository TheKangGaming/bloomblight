extends Node2D

@onready var left_spawn: Marker2D = $LeftSpawn
@onready var right_spawn: Marker2D = $RightSpawn

var _attacker_data: CharacterData
var _defender_data: CharacterData
var _attacker_stats: UnitStats
var _defender_stats: UnitStats

var active_attacker: BattleActor
var active_defender: BattleActor

func _ready() -> void:
	var payload := CombatManager.get_payload()
	
	# --- DEBUG INJECTION ---
	# If we hit F6 to run this scene by itself, build a fake payload for testing!
	if payload == null and OS.is_debug_build():
		push_warning("BattleScene: No payload found. Injecting DEBUG Savannah Mirror Match!")
		payload = CombatPayload.new()
		# Make sure this path points exactly to your saved .tres file!
		var debug_savannah = load("res://Units/Data/Savannah/savannah_data.tres") as CharacterData
		payload.attacker_data = debug_savannah
		payload.defender_data = debug_savannah # Savannah fights her own clone for now!
		payload.attacker_stats = UnitStats.new()
		payload.defender_stats = UnitStats.new()
	# -----------------------
		
	if payload == null:
		push_error("BattleScene Error: Booted up without a CombatPayload!")
		return
		
	# Extract the data
	_attacker_data = payload.attacker_data
	_defender_data = payload.defender_data
	_attacker_stats = payload.attacker_stats
	_defender_stats = payload.defender_stats
	
	# Clear the payload from the Autoload
	CombatManager.clear_payload()
	
	# Spawn them in
	_spawn_actors()

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
