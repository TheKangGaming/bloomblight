class_name BattleActor extends Node2D

@warning_ignore("unused_signal")
signal strike_impact
@warning_ignore("unused_signal")
signal animation_finished_playing

const DEATH_SINK_DISTANCE := 40.0
const DEATH_SINK_DURATION := 0.4
const ACTION_TIMEOUT_SECONDS := 1.5

var _character_data: CharacterData
var _runtime_stats: UnitStats
var _is_attacker: bool
var _waiting_for_action_finish := false

# We look for a dedicated child node to handle the actual visuals
@onready var _visual_driver: Node2D = get_node_or_null("VisualDriver")
@onready var _effect_anchor: Marker2D = get_node_or_null("EffectAnchor")
@onready var _damage_anchor: Marker2D = get_node_or_null("DamageAnchor")

func setup_from_combat_snapshot(data: CharacterData, stats: UnitStats, is_attacker: bool, weapon: WeaponData = null) -> void:
	_character_data = data
	_runtime_stats = stats
	_is_attacker = is_attacker
	
	# Attacker faces right, Defender faces left
	var facing := Vector2.RIGHT if is_attacker else Vector2.LEFT
	
	if _visual_driver:
		if _visual_driver.has_method("apply_combat_snapshot"):
			_visual_driver.apply_combat_snapshot(data, stats, weapon)
			
		if _visual_driver.has_method("set_facing"):
			_visual_driver.set_facing(facing)
			
	play_idle()

# --- The Public Battle API ---

func play_idle() -> void:
	if _visual_driver and _visual_driver.has_method("play_idle"):
		_visual_driver.play_idle()

func play_attack() -> void:
	if _visual_driver and _visual_driver.has_method("play_attack"):
		_waiting_for_action_finish = true
		_visual_driver.play_attack()
		
func play_run() -> void:
	if _visual_driver and _visual_driver.has_method("play_run"):
		_visual_driver.play_run()
		
func play_jump() -> void:
	if _visual_driver and _visual_driver.has_method("play_jump"):
		_visual_driver.play_jump()

func play_hit() -> void:
	if _visual_driver and _visual_driver.has_method("play_hit"):
		_waiting_for_action_finish = true
		_visual_driver.play_hit()

func play_death() -> void:
	if _visual_driver and _visual_driver.has_method("play_death"):
		_waiting_for_action_finish = true
		_visual_driver.play_death()
		
func play_evade() -> void:
	if _visual_driver and _visual_driver.has_method("play_evade"):
		_waiting_for_action_finish = true
		_visual_driver.play_evade()

func play_mood_shocked() -> void:
	if _visual_driver and _visual_driver.has_method("play_mood_shocked"):
		_waiting_for_action_finish = false
		_visual_driver.play_mood_shocked()

func play_mood_impatient() -> void:
	if _visual_driver and _visual_driver.has_method("play_mood_impatient"):
		_waiting_for_action_finish = false
		_visual_driver.play_mood_impatient()

func play_bow_aim() -> void:
	if _visual_driver and _visual_driver.has_method("play_bow_aim"):
		_waiting_for_action_finish = false
		_visual_driver.play_bow_aim()
		
func set_facing(direction: Vector2) -> void:
	if _visual_driver and _visual_driver.has_method("set_facing"):
		_visual_driver.set_facing(direction)

func get_damage_anchor_position() -> Vector2:
	if _visual_driver and _visual_driver.has_method("get_damage_anchor_position"):
		return _visual_driver.get_damage_anchor_position()
	if _damage_anchor:
		return _damage_anchor.global_position
	return global_position + Vector2(0.0, -40.0)

func get_effect_anchor_position() -> Vector2:
	if _visual_driver and _visual_driver.has_method("get_effect_anchor_position"):
		return _visual_driver.get_effect_anchor_position()
	if _effect_anchor:
		return _effect_anchor.global_position
	return global_position

func finish_tracked_action() -> void:
	_waiting_for_action_finish = false
	animation_finished_playing.emit()

func wait_for_tracked_action() -> void:
	if not _waiting_for_action_finish:
		return

	var tree := get_tree()
	if tree == null:
		_waiting_for_action_finish = false
		return

	var timeout_timer := tree.create_timer(ACTION_TIMEOUT_SECONDS)
	while _waiting_for_action_finish and timeout_timer.time_left > 0.0:
		await tree.process_frame

	if _waiting_for_action_finish:
		finish_tracked_action()
