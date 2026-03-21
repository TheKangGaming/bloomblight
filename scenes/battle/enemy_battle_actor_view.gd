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
	if is_instance_valid(parent_actor) and parent_actor.has_signal("animation_finished_playing"):
		parent_actor.animation_finished_playing.emit()

func emit_impact() -> void:
	if is_instance_valid(parent_actor) and parent_actor.has_signal("strike_impact"):
		parent_actor.strike_impact.emit()

func set_facing(dir: Vector2) -> void:
	if sprite:
		# Assuming your monster sprites are drawn facing LEFT by default:
		sprite.flip_h = (dir == Vector2.RIGHT) 

func play_attack() -> void:
	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")
	else:
		_fake_attack_animation()

func play_hit() -> void:
	if anim_player and anim_player.has_animation("hit"):
		anim_player.play("hit")
	else:
		_fake_reaction_animation("hit")

func play_death() -> void:
	if anim_player and anim_player.has_animation("death"):
		anim_player.play("death")
	else:
		_fake_reaction_animation("death")

func play_evade() -> void:
	if anim_player and anim_player.has_animation("evade"):
		anim_player.play("evade")
	else:
		_fake_reaction_animation("evade")

func _fake_attack_animation() -> void:
	# Attack fallback still needs both impact and finish.
	await get_tree().create_timer(0.3).timeout
	emit_impact()
	
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(parent_actor) and parent_actor.has_signal("animation_finished_playing"):
		parent_actor.animation_finished_playing.emit()

func _fake_reaction_animation(kind: String) -> void:
	# Reactions should not emit an attack impact.
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(parent_actor) and parent_actor.has_signal("animation_finished_playing"):
		parent_actor.animation_finished_playing.emit()
