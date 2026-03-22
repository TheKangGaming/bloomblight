extends Node2D

# Point this to wherever your MSCA AnimationTree controller is in the child scene
@onready var msca_player = $Player # Adjust this path to point to your MSCA visual rig!
@onready var parent_actor = get_parent()
@onready var sprite_layers: Node = $Player/SpriteLayers
@onready var body_sprite: Sprite2D = get_node_or_null("Player/SpriteLayers/01body")
@onready var one_h_weapon: CanvasItem = $Player/SpriteLayers/farmer_1h_weapon
@onready var bow_weapon: CanvasItem = $Player/SpriteLayers/farmer_bow

var _character_data: CharacterData
var _weapon_snapshot: WeaponData
var _facing := Vector2.RIGHT
var _pending_finish_state := ""
var _is_dying: bool = false

func _ready() -> void:
	if sprite_layers and sprite_layers.has_signal("animation_state_finished"):
		sprite_layers.connect("animation_state_finished", Callable(self, "_on_animation_state_finished"))

func _on_animation_state_finished(state_name: String, _wait_time: float = 0.0) -> void:
	if state_name != _pending_finish_state:
		return

	_pending_finish_state = ""
	_apply_weapon_visibility("neutral")

	# --- THE INTERCEPTOR ---
	if _is_dying:
		_begin_death_sink()
	else:
		if is_instance_valid(parent_actor) and parent_actor.has_method("finish_tracked_action"):
			parent_actor.finish_tracked_action()

func emit_impact() -> void:
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
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = ""
		_apply_weapon_visibility("neutral")
		msca_player.travel_to_anim("Idle", _facing)

func play_run() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = ""
		_apply_weapon_visibility("neutral")
		# Note: Check your MSCA AnimationTree! It might be named "Walk" or "Run" 
		# depending on which specific MSCA base pack you are using.
		msca_player.travel_to_anim("Run", _facing)
		
func play_jump() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = ""
		_apply_weapon_visibility("neutral")
		# Double check this exact string in your AnimationTree!
		msca_player.travel_to_anim("Jump", _facing)

func play_attack() -> void:
	if not msca_player or not msca_player.has_method("travel_to_anim"):
		return

	_pending_finish_state = _get_attack_animation_name()
	_apply_weapon_visibility(_get_weapon_visibility_mode())
	msca_player.travel_to_anim(_pending_finish_state, _facing)

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

func play_hit() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = "Hurt"
		_apply_weapon_visibility("neutral")
		msca_player.travel_to_anim("Hurt", _facing)

func play_death() -> void:
	_is_dying = true
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = "DeathBounce"
		_apply_weapon_visibility("neutral")
		scale.x = -1.0 if _facing == Vector2.LEFT else 1.0
		msca_player.travel_to_anim("DeathBounce", Vector2.DOWN)
		
func play_evade() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		_pending_finish_state = "Evade"
		_apply_weapon_visibility("neutral")
		msca_player.travel_to_anim("Evade", _facing)

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
