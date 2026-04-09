extends Control

signal confirmed
signal skipped

const CARD_INTRO_FADE := 0.18
const CARD_OUTRO_FADE := 0.16
const CARD_POP_DURATION := 0.16
const CARD_EXIT_SLIDE := 26.0
const TUTORIAL_CARD_WIDTH := 820.0
const COMPACT_TUTORIAL_CARD_WIDTH := 700.0
const BATTLE_TUTORIAL_CARD_WIDTH := 560.0
const TUTORIAL_TITLE_SIZE := 40
const TUTORIAL_BODY_SIZE := 24
const TUTORIAL_CONFIRM_SIZE := 20
const TUTORIAL_SKIP_SIZE := 18
const COMPACT_TUTORIAL_TITLE_SIZE := 34
const COMPACT_TUTORIAL_BODY_SIZE := 20
const COMPACT_TUTORIAL_CONFIRM_SIZE := 18
const COMPACT_TUTORIAL_SKIP_SIZE := 16
const BATTLE_TUTORIAL_TITLE_SIZE := 30
const BATTLE_TUTORIAL_BODY_SIZE := 18
const BATTLE_TUTORIAL_CONFIRM_SIZE := 15
const BATTLE_TUTORIAL_SKIP_SIZE := 14

@onready var background: TextureRect = $Background
@onready var fallback_background: ColorRect = $FallbackBackground
@onready var panel: PanelContainer = $Content/Panel
@onready var content_root: Control = $Content
@onready var title_label: Label = $Content/Panel/Margin/VBox/Title
@onready var body_label: Label = $Content/Panel/Margin/VBox/Body
@onready var confirm_label: Label = $Content/Panel/Margin/VBox/Confirm
@onready var skip_label: Label = $Content/Panel/Margin/VBox/Skip

var _allow_skip := true
var _confirm_hint := "continue"
var _skip_hint := "skip"
var _fade_tween: Tween
var _is_dismissing := false
var _card_type := "story"
var _card_layout := "full"

func _ui_sound_manager() -> Node:
	return get_node_or_null("/root/UISoundManager")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate.a = 0.0
	panel.scale = Vector2(0.94, 0.94)
	content_root.position = Vector2(0, 18)
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
	_card_type = String(config.get("card_type", "story"))
	_card_layout = String(config.get("card_layout", "full")).to_lower()

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
	_apply_panel_style()
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

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		if not _allow_skip:
			get_viewport().set_input_as_handled()
			return
		_dismiss(false)
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if _is_dismissing:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_dismiss(true)
			accept_event()

func _on_input_mode_changed(_mode: int) -> void:
	_refresh_prompts()

func _refresh_prompts() -> void:
	var continue_label := DemoDirector.get_confirm_label() if DemoDirector else "E"
	if continue_label == "Left Click":
		confirm_label.text = "Click to %s." % _confirm_hint
	else:
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
	panel.pivot_offset = panel.size * 0.5
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_popup()
	_kill_fade_tween()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(self, "modulate:a", 1.0, CARD_INTRO_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(panel, "scale", Vector2.ONE, CARD_POP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(content_root, "position", Vector2.ZERO, CARD_POP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _dismiss(was_confirmed: bool) -> void:
	if _is_dismissing:
		return

	_is_dismissing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.pivot_offset = panel.size * 0.5
	_kill_fade_tween()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(self, "modulate:a", 0.0, CARD_OUTRO_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_fade_tween.tween_property(panel, "scale", Vector2(0.97, 0.97), CARD_OUTRO_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_fade_tween.tween_property(content_root, "position", Vector2(0, -CARD_EXIT_SLIDE), CARD_OUTRO_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
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
	var panel_margin := get_node_or_null("Content/Panel/Margin") as MarginContainer
	if _card_type == "tutorial":
		var compact := _card_layout == "compact"
		var battle := _card_layout == "battle"
		var tutorial_width := BATTLE_TUTORIAL_CARD_WIDTH if battle else (COMPACT_TUTORIAL_CARD_WIDTH if compact else TUTORIAL_CARD_WIDTH)
		var margin_left := 14 if battle else (22 if compact else 28)
		var margin_top := 14 if battle else (20 if compact else 24)
		var margin_right := 14 if battle else (22 if compact else 28)
		var margin_bottom := 12 if battle else (16 if compact else 20)
		var title_size := BATTLE_TUTORIAL_TITLE_SIZE if battle else (COMPACT_TUTORIAL_TITLE_SIZE if compact else TUTORIAL_TITLE_SIZE)
		var body_size := BATTLE_TUTORIAL_BODY_SIZE if battle else (COMPACT_TUTORIAL_BODY_SIZE if compact else TUTORIAL_BODY_SIZE)
		var confirm_size := BATTLE_TUTORIAL_CONFIRM_SIZE if battle else (COMPACT_TUTORIAL_CONFIRM_SIZE if compact else TUTORIAL_CONFIRM_SIZE)
		var skip_size := BATTLE_TUTORIAL_SKIP_SIZE if battle else (COMPACT_TUTORIAL_SKIP_SIZE if compact else TUTORIAL_SKIP_SIZE)
		style.bg_color = Color(0.05, 0.07, 0.11, 0.93)
		style.border_color = Color(0.64, 0.83, 1.0, 0.98)
		panel.custom_minimum_size = Vector2(tutorial_width, 0)
		if panel_margin != null:
			panel_margin.add_theme_constant_override("margin_left", margin_left)
			panel_margin.add_theme_constant_override("margin_top", margin_top)
			panel_margin.add_theme_constant_override("margin_right", margin_right)
			panel_margin.add_theme_constant_override("margin_bottom", margin_bottom)
		title_label.add_theme_font_size_override("font_size", title_size)
		body_label.add_theme_font_size_override("font_size", body_size)
		confirm_label.add_theme_font_size_override("font_size", confirm_size)
		skip_label.add_theme_font_size_override("font_size", skip_size)
	else:
		style.bg_color = Color(0.08, 0.07, 0.05, 0.9)
		style.border_color = Color(0.9, 0.77, 0.46, 0.96)
		panel.custom_minimum_size = Vector2(980, 0)
		if panel_margin != null:
			panel_margin.add_theme_constant_override("margin_left", 42)
			panel_margin.add_theme_constant_override("margin_top", 34)
			panel_margin.add_theme_constant_override("margin_right", 42)
			panel_margin.add_theme_constant_override("margin_bottom", 28)
		title_label.add_theme_font_size_override("font_size", 54)
		body_label.add_theme_font_size_override("font_size", 30)
		confirm_label.add_theme_font_size_override("font_size", 26)
		skip_label.add_theme_font_size_override("font_size", 22)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	panel.add_theme_stylebox_override("panel", style)

	if _card_type == "tutorial":
		title_label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0))
		body_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
		confirm_label.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))
		skip_label.add_theme_color_override("font_color", Color(0.84, 0.89, 0.96))
	else:
		title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
		body_label.add_theme_color_override("font_color", Color(0.94, 0.93, 0.88))
		confirm_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.46))
		skip_label.add_theme_color_override("font_color", Color(0.86, 0.86, 0.86))

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
