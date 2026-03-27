extends Node2D

# Point this to wherever your MSCA AnimationTree controller is in the child scene
@onready var msca_player = $Player # Adjust this path to point to your MSCA visual rig!
@onready var parent_actor = get_parent()
@onready var sprite_layers: Node = $Player/SpriteLayers
@onready var anim_player: AnimationPlayer = $Player/SpriteLayers/AnimationPlayer
@onready var anim_tree: AnimationTree = $Player/SpriteLayers/AnimationTree
@onready var body_sprite: Sprite2D = get_node_or_null("Player/SpriteLayers/01body")
@onready var one_h_weapon: CanvasItem = $Player/SpriteLayers/farmer_1h_weapon
@onready var bow_weapon: CanvasItem = $Player/SpriteLayers/farmer_bow

const BOW_IMPACT_FALLBACK_DELAY := 0.16
const MAGIC_IMPACT_FALLBACK_DELAY := 0.18
const MELEE_IMPACT_FALLBACK_DELAY := 0.12

var _character_data: CharacterData
var _weapon_snapshot: WeaponData
var _facing := Vector2.RIGHT
var _pending_finish_state := ""
var _is_dying: bool = false
var _attack_serial: int = 0
var _impact_emitted_serial: int = -1

func _ready() -> void:
	if sprite_layers and sprite_layers.has_signal("animation_state_started"):
		sprite_layers.connect("animation_state_started", Callable(self, "_on_animation_state_started"))
	if sprite_layers and sprite_layers.has_signal("animation_state_finished"):
		sprite_layers.connect("animation_state_finished", Callable(self, "_on_animation_state_finished"))

func _on_animation_state_started(state_name: String, _wait_time: float = 0.0) -> void:
	if _pending_finish_state.is_empty():
		return

	# BowShot and other short battle reactions can occasionally flow back into
	# idle without the exact finish callback we are waiting on. If the rig has
	# clearly transitioned home, unblock the battle loop instead of hanging.
	if state_name != _pending_finish_state and _is_idle_state(state_name) and not _is_dying:
		_complete_pending_action()

func _on_animation_state_finished(state_name: String, _wait_time: float = 0.0) -> void:
	if state_name != _pending_finish_state:
		return

	_complete_pending_action()

func emit_impact() -> void:
	if _impact_emitted_serial == _attack_serial:
		return
	_impact_emitted_serial = _attack_serial
	if is_instance_valid(parent_actor) and parent_actor.has_signal("strike_impact"):
		parent_actor.strike_impact.emit()

func apply_combat_snapshot(_data: CharacterData, _stats: UnitStats, weapon: WeaponData = null) -> void:
	_character_data = _data
	_weapon_snapshot = weapon
	_is_dying = false
	modulate = Color.WHITE
	# Future: Swap weapon sprites, color palettes, or armor layers here based on the data!

func set_facing(dir: Vector2) -> void:
	_facing = dir
	scale.x = 1.0
	
	if msca_player != null:
		# 1. Force the MSCA internal variable to update
		if "facing_direction" in msca_player:
			msca_player.facing_direction = dir
			
		# 2. Immediately force the AnimationTree to adopt the new facing direction
		if msca_player.has_method("travel_to_anim"):
			msca_player.travel_to_anim("Idle", dir)
			
		# 3. (Optional) Keep the Sprite flip_h fallback just in case your rig 
		# relies on it instead of true directional animations
		var sprite = msca_player.get_node_or_null("SpriteLayers/01body") 
		if sprite and "flip_h" in sprite:
			sprite.flip_h = (dir == Vector2.LEFT)

	_apply_weapon_visibility("neutral")

func play_idle() -> void:
	_set_anim_tree_active(true)
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = ""
		_apply_weapon_visibility("neutral")
		msca_player.travel_to_anim("Idle", _facing)

func play_run() -> void:
	_set_anim_tree_active(true)
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = ""
		_apply_weapon_visibility("neutral")
		# Note: Check your MSCA AnimationTree! It might be named "Walk" or "Run" 
		# depending on which specific MSCA base pack you are using.
		msca_player.travel_to_anim("Run", _facing)
		
func play_jump() -> void:
	_set_anim_tree_active(true)
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = ""
		_apply_weapon_visibility("neutral")
		# Double check this exact string in your AnimationTree!
		msca_player.travel_to_anim("Jump", _facing)

func play_attack() -> void:
	if not msca_player or not msca_player.has_method("travel_to_anim"):
		return

	_set_anim_tree_active(true)
	_attack_serial += 1
	_impact_emitted_serial = -1
	_pending_finish_state = _get_attack_animation_name()
	_apply_weapon_visibility(_get_weapon_visibility_mode())
	msca_player.travel_to_anim(_pending_finish_state, _facing)
	_schedule_attack_impact_fallback(_attack_serial, _pending_finish_state, _get_attack_impact_fallback_delay())

func _get_attack_animation_name() -> String:
	var weapon_type := ""
	if _weapon_snapshot:
		weapon_type = _weapon_snapshot.weapon_type
	elif _character_data and _character_data.equipped_weapon:
		weapon_type = _character_data.equipped_weapon.weapon_type

	match weapon_type:
		"Bow":
			return "BowShot"
		"Tome", "Staff":
			return "CastSpell1"
		_:
			return "StrikeForehandOneHandWeapon"

func _get_attack_impact_fallback_delay() -> float:
	var weapon_type := ""
	if _weapon_snapshot:
		weapon_type = _weapon_snapshot.weapon_type
	elif _character_data and _character_data.equipped_weapon:
		weapon_type = _character_data.equipped_weapon.weapon_type

	match weapon_type:
		"Bow":
			return BOW_IMPACT_FALLBACK_DELAY
		"Tome", "Staff":
			return MAGIC_IMPACT_FALLBACK_DELAY
		_:
			return MELEE_IMPACT_FALLBACK_DELAY

func _schedule_attack_impact_fallback(serial: int, expected_state: String, delay: float) -> void:
	if delay <= 0.0:
		return
	_schedule_attack_impact_fallback_async(serial, expected_state, delay)

func _schedule_attack_impact_fallback_async(serial: int, expected_state: String, delay: float) -> void:
	await get_tree().create_timer(delay, true).timeout
	if serial != _attack_serial:
		return
	if _impact_emitted_serial == serial:
		return
	if _pending_finish_state != expected_state:
		return
	emit_impact()

func play_hit() -> void:
	_set_anim_tree_active(true)
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = "Hurt"
		_apply_weapon_visibility("neutral")
		msca_player.travel_to_anim("Hurt", _facing)

func play_death() -> void:
	_is_dying = true
	_set_anim_tree_active(true)
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = "DeathBounce"
		_apply_weapon_visibility("neutral")
		scale.x = -1.0 if _facing == Vector2.LEFT else 1.0
		msca_player.travel_to_anim("DeathBounce", Vector2.DOWN)
		
func play_evade() -> void:
	_set_anim_tree_active(true)
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = "Evade"
		_apply_weapon_visibility("neutral")
		msca_player.travel_to_anim("Evade", _facing)

func play_mood_shocked() -> void:
	_play_story_animation("MoodShocked", "neutral")

func play_mood_impatient() -> void:
	_play_story_animation("MoodImpatient", "neutral")

func play_bow_aim() -> void:
	_play_story_animation("BowShot", "bow", 0.18)

func _get_weapon_visibility_mode() -> String:
	var weapon_type := ""
	if _weapon_snapshot:
		weapon_type = _weapon_snapshot.weapon_type
	elif _character_data and _character_data.equipped_weapon:
		weapon_type = _character_data.equipped_weapon.weapon_type

	match weapon_type:
		"Bow":
			return "bow"
		"Tome", "Staff":
			return "neutral"
		_:
			return "one_h"

func _apply_weapon_visibility(mode: String) -> void:
	if one_h_weapon:
		one_h_weapon.visible = (mode == "one_h")
	if bow_weapon:
		bow_weapon.visible = (mode == "bow")

func _play_story_animation(base_name: String, weapon_mode: String, pause_at: float = -1.0) -> void:
	if anim_player == null:
		return

	_pending_finish_state = ""
	_set_anim_tree_active(false)
	_apply_weapon_visibility(weapon_mode)
	var animation_name := _resolve_directional_animation_name(base_name)
	if not anim_player.has_animation(animation_name):
		_set_anim_tree_active(true)
		return

	anim_player.play(animation_name)
	if pause_at >= 0.0:
		anim_player.seek(pause_at, true)
		anim_player.pause()

func _resolve_directional_animation_name(base_name: String) -> String:
	if _facing == Vector2.LEFT:
		return base_name + "Left"
	if _facing == Vector2.RIGHT:
		return base_name + "Right"
	if _facing == Vector2.UP:
		return base_name + "Up"
	return base_name + "Down"

func _set_anim_tree_active(is_active: bool) -> void:
	if anim_tree:
		anim_tree.active = is_active

func get_effect_anchor_position() -> Vector2:
	if bow_weapon and bow_weapon.visible:
		var bow_x := 12.0 if _facing == Vector2.RIGHT else -12.0
		return bow_weapon.global_position + Vector2(bow_x, -20.0)
	if body_sprite:
		return body_sprite.global_position + Vector2(0.0, -34.0)
	return global_position + Vector2(0.0, -34.0)

func get_damage_anchor_position() -> Vector2:
	if body_sprite:
		return body_sprite.global_position + Vector2(0.0, -42.0)
	return global_position + Vector2(0.0, -42.0)
	
func _begin_death_sink() -> void:
	var sink_tween = create_tween().set_parallel(true)
	
	# NEW: 'EASE_IN' makes the movement start slow and accelerate, simulating gravity!
	sink_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	sink_tween.tween_property(self, "position:y", position.y + BattleActor.DEATH_SINK_DISTANCE, BattleActor.DEATH_SINK_DURATION)
	sink_tween.tween_property(self, "modulate:a", 0.0, BattleActor.DEATH_SINK_DURATION)
	
	await sink_tween.finished
	
	if is_instance_valid(parent_actor) and parent_actor.has_method("finish_tracked_action"):
		parent_actor.finish_tracked_action()

func _complete_pending_action() -> void:
	_pending_finish_state = ""
	_apply_weapon_visibility("neutral")

	if _is_dying:
		_begin_death_sink()
		return

	if is_instance_valid(parent_actor) and parent_actor.has_method("finish_tracked_action"):
		parent_actor.finish_tracked_action()

func _is_idle_state(state_name: String) -> bool:
	return state_name == "Idle" or state_name == "Idle2"
