extends CanvasLayer

signal overlay_closed
@onready var fade_rect: ColorRect = $FadeRect
@onready var flash_rect: ColorRect = $FlashRect
var _is_transitioning: bool = false
var _pending_scene_path: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reset_transition_visuals()

func _reset_transition_visuals() -> void:
	fade_rect.modulate.a = 0.0
	flash_rect.modulate.a = 0.0

func change_scene(scene: PackedScene, fade_duration: float = 0.25) -> void:
	if _is_transitioning or scene == null:
		return
	change_scene_path(scene.resource_path, fade_duration)

func change_scene_path(scene_path: String, fade_duration: float = 0.25) -> void:
	if _is_transitioning or scene_path.strip_edges().is_empty():
		return

	_is_transitioning = true
	_pending_scene_path = scene_path.strip_edges()
	
	# 1. Fade to black
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	
	# 2. Swap the scene invisibly while the screen is black, then fade back in
	tween.tween_callback(_change_scene_after_fade.bind(fade_duration))

func change_scene_path_bloom(scene_path: String, flash_duration: float = 0.1, fade_duration: float = 0.16) -> void:
	if _is_transitioning or scene_path.strip_edges().is_empty():
		return

	_is_transitioning = true
	_pending_scene_path = scene_path.strip_edges()
	_reset_transition_visuals()
	flash_rect.color = Color(0.86, 1.0, 0.78, 1.0)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(flash_rect, "modulate:a", 0.96, flash_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(fade_rect, "modulate:a", 0.1, flash_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_change_scene_after_bloom.bind(fade_duration))

func open_overlay(scene: PackedScene, fade_duration: float = 0.5) -> void:
	if _is_transitioning or scene == null:
		return
		
	_is_transitioning = true

	var overlay = scene.instantiate()
	get_tree().current_scene.add_child(overlay)
	get_tree().paused = true

	_reset_transition_visuals()
	flash_rect.color = Color(1.0, 0.96, 0.86, 1.0)

	var tween := create_tween()
	tween.tween_property(flash_rect, "modulate:a", 0.9, minf(fade_duration * 0.08, 0.04))
	tween.parallel().tween_property(fade_rect, "modulate:a", 0.12, minf(fade_duration * 0.12, 0.06))
	tween.tween_property(flash_rect, "modulate:a", 0.0, minf(fade_duration * 0.28, 0.14))
	tween.parallel().tween_property(fade_rect, "modulate:a", 0.0, minf(fade_duration * 0.36, 0.18))
	tween.tween_callback(func():
		_is_transitioning = false
	)

func close_overlay(overlay_node: Node, fade_duration: float = 0.5) -> void:
	if _is_transitioning or overlay_node == null:
		return
		
	_is_transitioning = true

	if overlay_node.has_method("begin_overlay_exit"):
		overlay_node.begin_overlay_exit()

	_reset_transition_visuals()
	flash_rect.color = Color(1.0, 0.92, 0.78, 1.0)

	var tween := create_tween()
	tween.tween_interval(minf(fade_duration * 0.12, 0.06))
	tween.tween_property(flash_rect, "modulate:a", 0.72, minf(fade_duration * 0.08, 0.04))
	tween.parallel().tween_property(fade_rect, "modulate:a", 0.1, minf(fade_duration * 0.12, 0.06))
	tween.tween_property(flash_rect, "modulate:a", 0.0, minf(fade_duration * 0.24, 0.12))
	tween.parallel().tween_property(fade_rect, "modulate:a", 0.0, minf(fade_duration * 0.28, 0.14))
	tween.tween_callback(func():
		overlay_node.queue_free()
		get_tree().paused = false
		_is_transitioning = false
		overlay_closed.emit()
	)

func _finish_scene_transition() -> void:
	_is_transitioning = false

func _change_scene_after_fade(fade_duration: float) -> void:
	var next_scene_path := _pending_scene_path
	_pending_scene_path = ""
	if next_scene_path.is_empty():
		_is_transitioning = false
		_reset_transition_visuals()
		return

	get_tree().change_scene_to_file(next_scene_path)

	var in_tween = create_tween()
	in_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	in_tween.tween_callback(_finish_scene_transition)

func _change_scene_after_bloom(fade_duration: float) -> void:
	var next_scene_path := _pending_scene_path
	_pending_scene_path = ""
	if next_scene_path.is_empty():
		_is_transitioning = false
		_reset_transition_visuals()
		return

	get_tree().change_scene_to_file(next_scene_path)

	var in_tween := create_tween().set_parallel(true)
	in_tween.tween_property(flash_rect, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	in_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	in_tween.chain().tween_callback(_finish_scene_transition)
