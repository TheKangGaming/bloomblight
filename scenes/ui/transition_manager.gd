extends CanvasLayer

signal overlay_closed
@onready var fade_rect: ColorRect = $FadeRect
@onready var flash_rect: ColorRect = $FlashRect
@onready var prototype_footer_label: Label = $PrototypeFooter/FooterLabel

const PROTOTYPE_DISCLAIMER_TEXT := "Prototype build using placeholder assets."
const CONTROLLER_CURSOR_THRESHOLD := 0.55

var _is_transitioning: bool = false
var _pending_scene_path: String = ""
var _pending_scene_packed: PackedScene = null
var _scene_handoff_active: bool = false
var _scene_handoff_dim_alpha: float = 0.0
var _scene_handoff_tween: Tween = null
var _last_input_mode: StringName = &"mouse"

func _log_run_start(message: String) -> void:
	if OS.is_debug_build():
		print("[RunStart][Transition] %d %s" % [Time.get_ticks_msec(), message])

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reset_transition_visuals()
	if prototype_footer_label != null:
		prototype_footer_label.text = PROTOTYPE_DISCLAIMER_TEXT
		prototype_footer_label.add_theme_font_size_override("font_size", 15)
		prototype_footer_label.modulate = Color(0.96, 0.95, 0.9, 0.62)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if mouse_motion.relative.length_squared() > 0.0:
			_set_input_mode(&"mouse")
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.pressed:
			_set_input_mode(&"mouse")
		return

	if event is InputEventJoypadMotion:
		var joy_motion := event as InputEventJoypadMotion
		if absf(joy_motion.axis_value) >= CONTROLLER_CURSOR_THRESHOLD:
			_set_input_mode(&"controller")
		return

	if event is InputEventJoypadButton:
		var joy_button := event as InputEventJoypadButton
		if joy_button.pressed:
			_set_input_mode(&"controller")
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_last_input_mode = &"keyboard"

func _set_input_mode(mode: StringName) -> void:
	if _last_input_mode == mode:
		return
	_last_input_mode = mode
	match mode:
		&"mouse":
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		&"controller":
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _reset_transition_visuals() -> void:
	fade_rect.modulate.a = 0.0
	flash_rect.modulate.a = 0.0

func _clear_scene_handoff_state() -> void:
	_scene_handoff_active = false
	_scene_handoff_dim_alpha = 0.0
	if _scene_handoff_tween != null:
		if _scene_handoff_tween.is_running():
			_scene_handoff_tween.kill()
	_scene_handoff_tween = null

func has_active_scene_handoff() -> bool:
	return _scene_handoff_active

func finish_scene_handoff(reveal_duration: float = 0.32, target_alpha: float = 0.0) -> Tween:
	if not _scene_handoff_active:
		var noop_tween := create_tween()
		noop_tween.tween_interval(0.0)
		return noop_tween

	if _scene_handoff_tween != null:
		_scene_handoff_tween.kill()

	_scene_handoff_tween = create_tween().set_parallel(true)
	_scene_handoff_tween.tween_property(fade_rect, "modulate:a", clampf(target_alpha, 0.0, 1.0), reveal_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if flash_rect.modulate.a > 0.0:
		_scene_handoff_tween.tween_property(flash_rect, "modulate:a", 0.0, minf(reveal_duration * 0.6, 0.18)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_scene_handoff_tween.chain().tween_callback(func():
		_clear_scene_handoff_state()
	)
	return _scene_handoff_tween

func change_scene(scene: PackedScene, fade_duration: float = 0.25) -> void:
	if _is_transitioning or scene == null:
		return
	change_scene_path(scene.resource_path, fade_duration)

func change_scene_path(scene_path: String, fade_duration: float = 0.25) -> void:
	if _is_transitioning or scene_path.strip_edges().is_empty():
		return

	_clear_scene_handoff_state()
	_is_transitioning = true
	_pending_scene_path = scene_path.strip_edges()
	_pending_scene_packed = null
	
	# 1. Fade to black
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	
	# 2. Swap the scene invisibly while the screen is black, then fade back in
	tween.tween_callback(_change_scene_after_fade.bind(fade_duration))

func change_scene_path_bloom(scene_path: String, flash_duration: float = 0.1, fade_duration: float = 0.16, handoff_dim_alpha: float = 0.0) -> void:
	if _is_transitioning or scene_path.strip_edges().is_empty():
		return

	_clear_scene_handoff_state()
	_is_transitioning = true
	_pending_scene_path = scene_path.strip_edges()
	_pending_scene_packed = null
	_scene_handoff_active = handoff_dim_alpha > 0.0
	_scene_handoff_dim_alpha = clampf(handoff_dim_alpha, 0.0, 1.0)
	_begin_bloom_transition(flash_duration, fade_duration)

func change_scene_packed_bloom(scene: PackedScene, flash_duration: float = 0.1, fade_duration: float = 0.16, handoff_dim_alpha: float = 0.0) -> void:
	if _is_transitioning or scene == null:
		return

	_clear_scene_handoff_state()
	_is_transitioning = true
	_pending_scene_path = ""
	_pending_scene_packed = scene
	_scene_handoff_active = handoff_dim_alpha > 0.0
	_scene_handoff_dim_alpha = clampf(handoff_dim_alpha, 0.0, 1.0)
	_begin_bloom_transition(flash_duration, fade_duration)

func _begin_bloom_transition(flash_duration: float, fade_duration: float) -> void:
	_reset_transition_visuals()
	flash_rect.color = Color(0.86, 1.0, 0.78, 1.0)
	_log_run_start("Bloom transition begin")
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
	_pending_scene_packed = null
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
	var next_scene_packed := _pending_scene_packed
	_pending_scene_path = ""
	_pending_scene_packed = null
	if next_scene_path.is_empty() and next_scene_packed == null:
		_is_transitioning = false
		_clear_scene_handoff_state()
		_reset_transition_visuals()
		return

	_log_run_start("Scene swap")
	if next_scene_packed != null:
		get_tree().change_scene_to_packed(next_scene_packed)
	else:
		get_tree().change_scene_to_file(next_scene_path)

	var in_tween := create_tween().set_parallel(true)
	in_tween.tween_property(flash_rect, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	in_tween.tween_property(fade_rect, "modulate:a", _scene_handoff_dim_alpha, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	in_tween.chain().tween_callback(_finish_scene_transition)
