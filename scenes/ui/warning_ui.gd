extends Control

@onready var warning_text: Label = $CenterContainer/WarningText
@onready var defend_button: Button = $CenterContainer/DefendButton
@onready var center_container: VBoxContainer = $CenterContainer

var _transitioning := false

func _ready() -> void:
	modulate.a = 0.0
	center_container.modulate.a = 1.0
	center_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	warning_text.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	defend_button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	defend_button.disabled = true

	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color(0.5, 0.08, 0.08, 0.92)
	button_style.border_color = Color(1.0, 0.82, 0.6, 1.0)
	button_style.border_width_left = 3
	button_style.border_width_top = 3
	button_style.border_width_right = 3
	button_style.border_width_bottom = 3
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_right = 10
	button_style.corner_radius_bottom_left = 10
	defend_button.add_theme_stylebox_override("normal", button_style)
	defend_button.add_theme_stylebox_override("hover", button_style.duplicate())
	defend_button.add_theme_stylebox_override("focus", button_style.duplicate())

	var day = Global.current_day
	var encounter = CalendarService.get_encounter_for_day(day)
	var threat_name = String(encounter.get("display_name", "Unknown Threat"))
	warning_text.text = "DAY " + str(day) + "\n\nTHE " + threat_name.to_upper() + " HAS FOUND YOU."
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): defend_button.disabled = false)

	defend_button.pressed.connect(_on_defend_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or defend_button.disabled:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_on_defend_button_pressed()
		get_viewport().set_input_as_handled()


func _on_defend_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true

	defend_button.disabled = true

	var tween = create_tween()
	tween.tween_property(center_container, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_load_combat_scene)


func _load_combat_scene() -> void:
	if Global.pending_combat_scene_path.is_empty():
		push_error("No combat map was saved to Global.pending_combat_scene_path.")
		_transitioning = false
		defend_button.disabled = false
		return

	if not ResourceLoader.exists(Global.pending_combat_scene_path):
		push_error("Combat map path is invalid: %s" % Global.pending_combat_scene_path)
		_transitioning = false
		defend_button.disabled = false
		return

	var combat_scene_path := Global.pending_combat_scene_path
	Global.pending_combat_scene_path = ""

	var scene_tree := get_tree()
	if scene_tree == null:
		_transitioning = false
		defend_button.disabled = false
		return

	var transition_layer := CanvasLayer.new()
	transition_layer.layer = 100
	transition_layer.name = "CombatSceneTransitionLayer"
	scene_tree.root.add_child(transition_layer)

	var fade_rect := ColorRect.new()
	fade_rect.name = "CombatSceneTransition"
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_rect.color = Color(0, 0, 0, 1)
	transition_layer.add_child(fade_rect)

	var combat_scene = load(combat_scene_path).instantiate()
	var combat_music: AudioStreamPlayer = combat_scene.get_node_or_null("AudioStreamPlayer")
	if is_instance_valid(combat_music):
		combat_music.autoplay = false
		combat_music.stop()

	var previous_scene := scene_tree.current_scene
	if Global.tutorial_step == 13:
		Global.advance_tutorial()
	Global.begin_combat_transition()

	scene_tree.root.add_child(combat_scene)
	scene_tree.current_scene = combat_scene
	scene_tree.root.remove_child(previous_scene)

	await scene_tree.process_frame

	if is_instance_valid(combat_music):
		combat_music.stop()

	var savannah: Node = combat_scene.get_node_or_null("GameBoard/Savannah")
	var cursor: Node = combat_scene.get_node_or_null("GameBoard/Cursor")
	if savannah != null and cursor != null and "cell" in savannah and "cell" in cursor:
		cursor.cell = savannah.cell.round()
		if "is_active" in cursor:
			cursor.is_active = true

	var reveal := scene_tree.create_tween()
	reveal.set_ease(Tween.EASE_IN_OUT)
	reveal.set_trans(Tween.TRANS_SINE)
	reveal.tween_interval(0.12)
	reveal.tween_property(fade_rect, "color:a", 0.0, 0.9)
	await reveal.finished

	if is_instance_valid(previous_scene):
		previous_scene.queue_free()
	if is_instance_valid(transition_layer):
		transition_layer.queue_free()
