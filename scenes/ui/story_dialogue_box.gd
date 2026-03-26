extends Control

signal dialogue_finished

@onready var speaker_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel
@onready var body_label: RichTextLabel = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/BodyLabel
@onready var prompt_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/PromptLabel

var _lines: Array[Dictionary] = []
var _line_index := -1
var _is_revealing := false
var _reveal_generation := 0
var _current_body_text := ""

const REVEAL_CHAR_DURATION := 0.018
const REVEAL_ALPHA_STEPS := 2
const REVEAL_STEP_DURATION := REVEAL_CHAR_DURATION / float(REVEAL_ALPHA_STEPS)

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_text_legibility()
	body_label.bbcode_enabled = true
	body_label.fit_content = false
	body_label.scroll_active = false
	if DemoDirector and not DemoDirector.input_mode_changed.is_connected(_on_input_mode_changed):
		DemoDirector.input_mode_changed.connect(_on_input_mode_changed)
	_update_prompt_text()

func play(lines: Array[Dictionary]) -> void:
	_lines = lines.duplicate(true)
	_line_index = -1
	_is_revealing = false
	_reveal_generation += 1
	visible = true
	_advance()

func hide_box() -> void:
	visible = false
	_lines.clear()
	_line_index = -1
	_is_revealing = false
	_reveal_generation += 1
	_current_body_text = ""
	if body_label:
		body_label.clear()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if not _is_advance_press(event):
		return

	get_viewport().set_input_as_handled()
	_advance()

func _is_advance_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed

	if not (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		return false

	if event is InputEventKey and event.echo:
		return false

	return true

func _advance() -> void:
	if _is_revealing:
		_finish_current_reveal()
		return

	_line_index += 1
	if _line_index >= _lines.size():
		hide_box()
		dialogue_finished.emit()
		return

	var line: Dictionary = _lines[_line_index]
	speaker_label.text = String(line.get("speaker", ""))
	_start_body_reveal(String(line.get("text", "")))
	_update_prompt_text()

func _exit_tree() -> void:
	if DemoDirector and DemoDirector.input_mode_changed.is_connected(_on_input_mode_changed):
		DemoDirector.input_mode_changed.disconnect(_on_input_mode_changed)

func _on_input_mode_changed(_mode: int) -> void:
	_update_prompt_text()

func _update_prompt_text() -> void:
	if DemoDirector:
		prompt_label.text = DemoDirector.get_continue_prompt_text()
	else:
		prompt_label.text = "Press E to continue"

func _start_body_reveal(text: String) -> void:
	_is_revealing = true
	_current_body_text = text
	var reveal_generation := _reveal_generation + 1
	_reveal_generation = reveal_generation
	body_label.clear()
	call_deferred("_reveal_body_text", text, reveal_generation)

func _finish_current_reveal() -> void:
	_is_revealing = false
	_reveal_generation += 1
	body_label.clear()
	body_label.append_text(_escape_bbcode(_current_body_text))

func _reveal_body_text(text: String, reveal_generation: int) -> void:
	await get_tree().process_frame
	if reveal_generation != _reveal_generation:
		return

	if text.is_empty():
		body_label.clear()
		_is_revealing = false
		return

	for char_index in range(text.length()):
		for alpha_step in range(REVEAL_ALPHA_STEPS):
			if reveal_generation != _reveal_generation:
				return

			var alpha := float(alpha_step + 1) / float(REVEAL_ALPHA_STEPS)
			body_label.clear()
			body_label.append_text(_build_reveal_markup(text, char_index, alpha))
			await get_tree().create_timer(REVEAL_STEP_DURATION).timeout

	if reveal_generation != _reveal_generation:
		return

	body_label.clear()
	body_label.append_text(_escape_bbcode(text))
	_is_revealing = false

func _build_reveal_markup(text: String, reveal_index: int, alpha: float) -> String:
	var prefix := _escape_bbcode(text.substr(0, reveal_index))
	if reveal_index >= text.length():
		return prefix

	var current_char := _escape_bbcode(text.substr(reveal_index, 1))
	var alpha_code := Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)).to_html(true)
	return "%s[color=%s]%s[/color]" % [prefix, alpha_code, current_char]

func _escape_bbcode(text: String) -> String:
	return text.replace("\\", "\\\\").replace("[", "\\[").replace("]", "\\]")

func _apply_text_legibility() -> void:
	speaker_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	body_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	prompt_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	speaker_label.add_theme_color_override("font_outline_color", Color.BLACK)
	speaker_label.add_theme_constant_override("outline_size", 2)
	body_label.add_theme_color_override("default_color", Color(0.95, 0.94, 0.89, 1.0))
	body_label.add_theme_color_override("font_outline_color", Color.BLACK)
	body_label.add_theme_constant_override("outline_size", 2)
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 1)
