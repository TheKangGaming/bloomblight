class_name BattleActor extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var effect_anchor: Marker2D = $EffectAnchor
@onready var damage_anchor: Marker2D = $DamageAnchor

# The isolated snapshots we received from the bridge
var _character_data: CharacterData
var _runtime_stats: UnitStats

## Called by the BattleScene right after instantiating this node
func setup_from_combat_snapshot(data: CharacterData, stats: UnitStats, is_attacker: bool) -> void:
	_character_data = data
	_runtime_stats = stats
	
	# 1. Visual Setup: Facing Direction
	# In Fire Emblem style, the attacker is usually on the left (facing right)
	# and the defender is on the right (facing left).
	if is_attacker:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
		
	# 2. Kick off the default state
	play_idle()

## Animation Triggers
func play_idle() -> void:
	if anim_player.has_animation("idle"):
		anim_player.play("idle")

func play_attack() -> void:
	if anim_player.has_animation("attack"):
		anim_player.play("attack")

func play_hit() -> void:
	if anim_player.has_animation("hit"):
		anim_player.play("hit")
