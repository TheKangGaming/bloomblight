extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var parent_actor = get_parent()

func apply_combat_snapshot(data: CharacterData, stats: UnitStats) -> void:
	pass # In the future, you can swap monster textures or colors here!

func _ready() -> void:
	if anim_player:
		anim_player.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(anim_name: String) -> void:
	if parent_actor and parent_actor.has_user_signal("animation_finished_playing"):
		parent_actor.animation_finished_playing.emit()

func emit_impact() -> void:
	if parent_actor and parent_actor.has_user_signal("strike_impact"):
		parent_actor.strike_impact.emit()

func set_facing(dir: Vector2) -> void:
	if sprite:
		# Assuming your monster sprites are drawn facing LEFT by default:
		sprite.flip_h = (dir == Vector2.RIGHT) 

func play_idle() -> void:
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func play_attack() -> void:
	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")

func play_hit() -> void:
	if anim_player and anim_player.has_animation("hit"):
		anim_player.play("hit")

func play_death() -> void:
	if anim_player and anim_player.has_animation("death"):
		anim_player.play("death")
		
func play_evade() -> void:
	if anim_player and anim_player.has_animation("evade"):
		anim_player.play("evade")
	else:
		play_idle()
