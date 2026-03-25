extends Node2D

@export var actor_scene: PackedScene
@export var actor_scale := Vector2(1.5, 1.5)
@export var visual_offset := Vector2(0, 0)

var _actor_instance: Node2D = null
var _emote_tween: Tween = null
var _emote_base_position := Vector2.ZERO
var _emote_active := false

func _ready() -> void:
	_rebuild_actor()

func face_down() -> void:
	_set_facing(Vector2.DOWN)

func face_up() -> void:
	_set_facing(Vector2.UP)

func face_side(face_right: bool) -> void:
	_set_facing(Vector2.RIGHT if face_right else Vector2.LEFT)

func play_idle() -> void:
	_stop_emote()
	if _actor_instance and _actor_instance.has_method("play_idle"):
		_actor_instance.play_idle()

func play_walk() -> void:
	_stop_emote()
	if _actor_instance and _actor_instance.has_method("play_run"):
		_actor_instance.play_run()

func play_attack() -> void:
	_stop_emote()
	if _actor_instance and _actor_instance.has_method("play_attack"):
		_actor_instance.play_attack()

func play_hit() -> void:
	_stop_emote()
	if _actor_instance and _actor_instance.has_method("play_hit"):
		_actor_instance.play_hit()

func play_evade() -> void:
	_stop_emote()
	if _actor_instance and _actor_instance.has_method("play_evade"):
		_actor_instance.play_evade()

func play_shocked() -> void:
	_stop_emote()
	if _actor_instance and _actor_instance.has_method("play_mood_shocked"):
		_actor_instance.play_mood_shocked()
		return
	if _actor_instance and _actor_instance.has_method("play_hit"):
		_actor_instance.play_hit()
	_play_emote_shake(Vector2(4.0, 2.0), 0.28, 3)

func play_impatient() -> void:
	_stop_emote()
	if _actor_instance and _actor_instance.has_method("play_mood_impatient"):
		_actor_instance.play_mood_impatient()
		return
	if _actor_instance and _actor_instance.has_method("play_idle"):
		_actor_instance.play_idle()
	_play_emote_shake(Vector2(2.0, 1.0), 0.42, 4)

func play_bow_aim() -> void:
	_stop_emote()
	if _actor_instance and _actor_instance.has_method("play_bow_aim"):
		_actor_instance.play_bow_aim()
		return
	play_attack()

func set_actor_scene(scene: PackedScene) -> void:
	actor_scene = scene
	_rebuild_actor()

func _set_facing(direction: Vector2) -> void:
	_stop_emote()
	if _actor_instance and _actor_instance.has_method("set_facing"):
		_actor_instance.set_facing(direction)
	play_idle()

func _rebuild_actor() -> void:
	if not is_inside_tree():
		return

	if _actor_instance and is_instance_valid(_actor_instance):
		_actor_instance.queue_free()
		_actor_instance = null

	if actor_scene == null:
		return

	_actor_instance = actor_scene.instantiate() as Node2D
	if _actor_instance == null:
		return

	add_child(_actor_instance)
	_actor_instance.position = visual_offset
	_actor_instance.scale = actor_scale
	play_idle()

func _play_emote_shake(amplitude: Vector2, duration: float, shakes: int) -> void:
	_stop_emote()
	if shakes <= 0 or duration <= 0.0:
		return

	_emote_base_position = position
	_emote_active = true
	_emote_tween = create_tween()
	_emote_tween.set_trans(Tween.TRANS_SINE)
	_emote_tween.set_ease(Tween.EASE_IN_OUT)

	var step_duration := duration / float(shakes * 2)
	for i in range(shakes):
		var direction := 1.0 if i % 2 == 0 else -1.0
		_emote_tween.tween_property(self, "position", _emote_base_position + Vector2(amplitude.x * direction, -amplitude.y), step_duration)
		_emote_tween.tween_property(self, "position", _emote_base_position, step_duration)

func _stop_emote() -> void:
	if _emote_tween:
		_emote_tween.kill()
		_emote_tween = null
	_emote_active = false
