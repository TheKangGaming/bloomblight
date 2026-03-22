extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var parent_actor = get_parent()

func apply_combat_snapshot(_data: CharacterData, _stats: UnitStats) -> void:
	pass # In the future, you can swap monster textures or colors here!

func _ready() -> void:
	if anim_player:
		anim_player.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(_anim_name: String) -> void:
	if is_instance_valid(parent_actor) and parent_actor.has_method("finish_tracked_action"):
		parent_actor.finish_tracked_action()

func emit_impact() -> void:
	if is_instance_valid(parent_actor) and parent_actor.has_signal("strike_impact"):
		parent_actor.strike_impact.emit()

func set_facing(direction: Vector2) -> void:
	# A simple sprite flip based on the X direction!
	if direction == Vector2.LEFT:
		scale.x = -1 # Flip horizontally
	elif direction == Vector2.RIGHT:
		scale.x = 1  # Standard facing

func play_idle() -> void:
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")
	else:
		# Ultimate Failsafe: Just freeze the sprite on whatever frame it's on!
		if anim_player:
			anim_player.stop()
			
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
		
func play_run() -> void:
	if anim_player and anim_player.has_animation("run_start") and anim_player.has_animation("run"):
		anim_player.play("run_start")
		anim_player.queue("run")
	elif anim_player and anim_player.has_animation("run"):
		anim_player.play("run")
	elif anim_player and anim_player.has_animation("walk"):
		anim_player.play("walk")
		
func play_jump() -> void:
	if anim_player and anim_player.has_animation("jump"):
		anim_player.play("jump")
	else:
		play_idle() # Failsafe: Just slide backwards in an idle pose!

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
	if is_instance_valid(parent_actor) and parent_actor.has_method("finish_tracked_action"):
		parent_actor.finish_tracked_action()

func _fake_reaction_animation(_kind: String) -> void:
	# Reactions should not emit an attack impact.
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(parent_actor) and parent_actor.has_method("finish_tracked_action"):
		parent_actor.finish_tracked_action()

func get_effect_anchor_position() -> Vector2:
	if sprite:
		return sprite.global_position + Vector2(0.0, -30.0)
	return global_position + Vector2(0.0, -30.0)

func get_damage_anchor_position() -> Vector2:
	if sprite:
		return sprite.global_position + Vector2(0.0, -40.0)
	return global_position + Vector2(0.0, -40.0)
