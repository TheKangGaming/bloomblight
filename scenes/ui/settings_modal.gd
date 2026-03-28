extends Control

signal modal_closed

const SETTINGS_PANEL_SCENE := preload("res://scenes/ui/settings_panel.tscn")

@onready var backdrop: ColorRect = $Backdrop
@onready var center_container: CenterContainer = $CenterContainer

var _panel: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _panel == null:
		_panel = SETTINGS_PANEL_SCENE.instantiate()
		if _panel.has_method("configure"):
			_panel.configure({"embedded": false})
		if _panel.has_signal("close_requested"):
			_panel.close_requested.connect(_on_close_requested)
		center_container.add_child(_panel)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		_on_close_requested()
		get_viewport().set_input_as_handled()

func _on_close_requested() -> void:
	if SettingsManager and SettingsManager.has_pending_display_preview():
		SettingsManager.revert_display_preview()
	modal_closed.emit()
	queue_free()
