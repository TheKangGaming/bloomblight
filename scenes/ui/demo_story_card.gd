extends Control

signal confirmed
signal skipped

@onready var background: TextureRect = $Background
@onready var fallback_background: ColorRect = $FallbackBackground
@onready var panel: PanelContainer = $Content/Panel
@onready var title_label: Label = $Content/Panel/Margin/VBox/Title
@onready var body_label: Label = $Content/Panel/Margin/VBox/Body
@onready var confirm_label: Label = $Content/Panel/Margin/VBox/Confirm
@onready var skip_label: Label = $Content/Panel/Margin/VBox/Skip

var _allow_skip := true
var _confirm_hint := "continue"
var _skip_hint := "skip"
var _fade_tween: Tween
var _is_dismissing := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate.a = 0.0
	_apply_text_legibility()
	_apply_panel_style()

	if DemoDirector and not DemoDirector.input_mode_changed.is_connected(_on_input_mode_changed):
		DemoDirector.input_mode_changed.connect(_on_input_mode_changed)

	_play_ken_burns()
	_refresh_prompts()
	call_deferred("_play_intro_fade")

func configure(config: Dictionary) -> void:
	if not is_node_ready():
		await ready

	title_label.text = String(config.get("title", ""))
	body_label.text = String(config.get("body", ""))
	_confirm_hint = String(config.get("confirm_hint", "continue"))
	_skip_hint = String(config.get("skip_hint", "skip"))
	_allow_skip = bool(config.get("allow_skip", true))

	var background_texture: Texture2D = config.get("background", null)
	if background_texture != null:
		background.texture = background_texture
		background.visible = true
		fallback_background.visible = false
	else:
		background.texture = null
		background.visible = false
		fallback_background.visible = true

	skip_label.visible = _allow_skip
	_refresh_prompts()

func _exit_tree() -> void:
	if DemoDirector and DemoDirector.input_mode_changed.is_connected(_on_input_mode_changed):
		DemoDirector.input_mode_changed.disconnect(_on_input_mode_changed)
	if _fade_tween:
		_fade_tween.kill()

func _unhandled_input(event: InputEvent) -> void:
	if _is_dismissing:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_dismiss(true)
		get_viewport().set_input_as_handled()
		return

	if _allow_skip and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel")):
		_dismiss(false)
		get_viewport().set_input_as_handled()

func _on_input_mode_changed(_mode: int) -> void:
	_refresh_prompts()

func _refresh_prompts() -> void:
	var continue_label := DemoDirector.get_confirm_label() if DemoDirector else "E"
	confirm_label.text = "Press %s to %s." % [continue_label, _confirm_hint]
	if _allow_skip:
		var skip_input := DemoDirector.get_action_label("cancel") if DemoDirector else "Esc"
		skip_label.text = "Press %s to %s." % [skip_input, _skip_hint]

func _play_ken_burns() -> void:
	if background == null:
		return

	background.scale = Vector2.ONE
	background.position = Vector2.ZERO

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(background, "scale", Vector2(1.08, 1.08), 12.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(background, "position", Vector2(-48.0, -24.0), 12.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background, "scale", Vector2(1.02, 1.02), 12.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(background, "position", Vector2(24.0, 12.0), 12.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_intro_fade() -> void:
	if _is_dismissing:
		return
	_kill_fade_tween()
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(self, "modulate:a", 1.0, 0.8)

func _dismiss(was_confirmed: bool) -> void:
	if _is_dismissing:
		return

	_is_dismissing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_fade_tween()
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.75)
	await _fade_tween.finished

	if was_confirmed:
		confirmed.emit()
	else:
		skipped.emit()

	queue_free()

func _kill_fade_tween() -> void:
	if _fade_tween:
		_fade_tween.kill()
		_fade_tween = null

func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.05, 0.9)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.9, 0.77, 0.46, 0.96)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	panel.add_theme_stylebox_override("panel", style)

func _apply_text_legibility() -> void:
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	title_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	body_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	confirm_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	skip_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 4)
	body_label.add_theme_color_override("font_outline_color", Color.BLACK)
	body_label.add_theme_constant_override("outline_size", 3)
	confirm_label.add_theme_color_override("font_outline_color", Color.BLACK)
	confirm_label.add_theme_constant_override("outline_size", 2)
	skip_label.add_theme_color_override("font_outline_color", Color.BLACK)
	skip_label.add_theme_constant_override("outline_size", 2)
