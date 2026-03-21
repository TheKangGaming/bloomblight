class_name BattleActor extends Node2D

signal strike_impact
signal animation_finished_playing

var _character_data: CharacterData
var _runtime_stats: UnitStats
var _is_attacker: bool

# We look for a dedicated child node to handle the actual visuals
@onready var _visual_driver: Node2D = get_node_or_null("VisualDriver")

func setup_from_combat_snapshot(data: CharacterData, stats: UnitStats, is_attacker: bool) -> void:
	_character_data = data
	_runtime_stats = stats
	_is_attacker = is_attacker
	
	# Attacker faces right, Defender faces left
	var facing := Vector2.RIGHT if is_attacker else Vector2.LEFT
	
	if _visual_driver:
		if _visual_driver.has_method("apply_combat_snapshot"):
			_visual_driver.apply_combat_snapshot(data, stats)
			
		if _visual_driver.has_method("set_facing"):
			_visual_driver.set_facing(facing)
			
	play_idle()

# --- The Public Battle API ---

func play_idle() -> void:
	if _visual_driver and _visual_driver.has_method("play_idle"):
		_visual_driver.play_idle()

func play_attack() -> void:
	if _visual_driver and _visual_driver.has_method("play_attack"):
		_visual_driver.play_attack()

func play_hit() -> void:
	if _visual_driver and _visual_driver.has_method("play_hit"):
		_visual_driver.play_hit()

func play_death() -> void:
	if _visual_driver and _visual_driver.has_method("play_death"):
		_visual_driver.play_death()
		
func play_evade() -> void:
	if _visual_driver and _visual_driver.has_method("play_evade"):
		_visual_driver.play_evade()
