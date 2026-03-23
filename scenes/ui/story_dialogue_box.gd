extends Control

signal dialogue_finished

@onready var speaker_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel
@onready var body_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/BodyLabel
@onready var prompt_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/PromptLabel

var _lines: Array[Dictionary] = []
var _line_index := -1

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func play(lines: Array[Dictionary]) -> void:
	_lines = lines.duplicate(true)
	_line_index = -1
	visible = true
	_advance()

func hide_box() -> void:
	visible = false
	_lines.clear()
	_line_index = -1

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if not _is_advance_press(event):
		return

	get_viewport().set_input_as_handled()
	_advance()

func _is_advance_press(event: InputEvent) -> bool:
	if not (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		return false

	if event is InputEventKey and event.echo:
		return false

	return true

func _advance() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		hide_box()
		dialogue_finished.emit()
		return

	var line: Dictionary = _lines[_line_index]
	speaker_label.text = String(line.get("speaker", ""))
	body_label.text = String(line.get("text", ""))
	prompt_label.text = "Press E to continue"
