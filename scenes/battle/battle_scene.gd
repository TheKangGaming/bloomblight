extends CanvasLayer

@onready var left_spawn: Marker2D = $LeftSpawn
@onready var right_spawn: Marker2D = $RightSpawn

var _defender_can_counter: bool = false
var _defender_survived: bool = true
var _attacker_hit: bool = true
var _defender_hit: bool = true
var _attacker_survived: bool = true
var _attacker_crit: bool = false
var _defender_crit: bool = false
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
	_defender_can_counter = payload.defender_can_counter
	_attacker_survived = payload.attacker_survived
	_defender_survived = payload.defender_survived
	_attacker_hit = payload.attacker_hit
	_defender_hit = payload.defender_hit
	_attacker_crit = payload.attacker_crit
	_defender_crit = payload.defender_crit
	
	
	# Save the distance so we know if a counterattack is possible!
	_combat_distance = payload.distance
	
	# Clear the payload from the Autoload
	CombatManager.clear_payload()
	
	# FIX: Only run the sequence if spawning succeeds
	if _spawn_actors():
		_execute_battle_sequence()

func _spawn_actors() -> bool:
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
		
	if active_attacker == null or active_defender == null:
		push_error("BattleScene Error: Failed to spawn actors. Aborting sequence.")
		_return_to_map()
		return false # Tell _ready() to abort!
		
	return true # Tell _ready() it's safe to proceed!

func _execute_battle_sequence() -> void:
	await get_tree().create_timer(0.5).timeout

	# --- PHASE 1: ATTACKER STRIKES ---
	active_attacker.play_attack()
	await get_tree().create_timer(0.4).timeout

	if not _attacker_hit:
		active_defender.play_evade()
	elif not _defender_survived:
		active_defender.play_death()
	else:
		active_defender.play_hit()

	await get_tree().create_timer(0.8).timeout

	# --- PHASE 2: DEFENDER COUNTERS ---
	if _defender_can_counter:
		active_defender.play_attack()
		await get_tree().create_timer(0.4).timeout

		if not _defender_hit:
			active_attacker.play_evade()
		elif not _attacker_survived:
			active_attacker.play_death()
		else:
			active_attacker.play_hit()

		await get_tree().create_timer(0.8).timeout

	# --- PHASE 3: RETURN ---
	await get_tree().create_timer(0.4).timeout
	_return_to_map()
	
func _return_to_map() -> void:
	# Tell the transition manager to fade out, delete this node, and unpause the map
	if TransitionManager and TransitionManager.has_method("close_overlay"):
		TransitionManager.close_overlay(self, 0.5)
	else:
		queue_free()
		get_tree().paused = false
