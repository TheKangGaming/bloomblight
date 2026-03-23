extends Node2D

@export var actor_scene: PackedScene
@export var actor_scale := Vector2(1.5, 1.5)
@export var visual_offset := Vector2(0, 0)

var _actor_instance: Node2D = null

func _ready() -> void:
	_rebuild_actor()

func face_down() -> void:
	_set_facing(Vector2.DOWN)

func face_up() -> void:
	_set_facing(Vector2.UP)

func face_side(face_right: bool) -> void:
	_set_facing(Vector2.RIGHT if face_right else Vector2.LEFT)

func play_idle() -> void:
	if _actor_instance and _actor_instance.has_method("play_idle"):
		_actor_instance.play_idle()

func play_walk() -> void:
	if _actor_instance and _actor_instance.has_method("play_run"):
		_actor_instance.play_run()

func set_actor_scene(scene: PackedScene) -> void:
	actor_scene = scene
	_rebuild_actor()

func _set_facing(direction: Vector2) -> void:
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
