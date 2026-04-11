extends Control

const SETTINGS_MODAL_SCENE := preload("res://scenes/ui/settings_modal.tscn")
const TITLE_SCENE_PATH := "res://scenes/ui/title_screen.tscn"
const START_BUTTON_INDEX := 6

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var save_button: Button = $CenterContainer/VBoxContainer/SaveButton
@onready var load_button: Button = $CenterContainer/VBoxContainer/LoadButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var exit_to_title_button: Button = $CenterContainer/VBoxContainer/ExitToTitleButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

var _management_menu: Control = null
var _settings_overlay: Control = null

func _ui_sound_manager() -> Node:
	return get_node_or_null("/root/UISoundManager")

func setup(management_menu: Control) -> void:
	_management_menu = management_menu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_wire_button(resume_button)
	_wire_button(save_button)
	_wire_button(load_button)
	_wire_button(settings_button)
	_wire_button(exit_to_title_button)
	_wire_button(quit_button)

	resume_button.pressed.connect(_close_menu)
	save_button.pressed.connect(_save_run)
	load_button.pressed.connect(_load_run)
	settings_button.pressed.connect(_open_settings)
	exit_to_title_button.pressed.connect(_exit_to_title)
	quit_button.pressed.connect(_quit_game)
	_wire_focus_graph()

func _shortcut_input(event: InputEvent) -> void:
	if _handle_toggle_input(event):
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _handle_toggle_input(event):
		get_viewport().set_input_as_handled()
		return

	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel")):
		if _request_settings_close():
			get_viewport().set_input_as_handled()
			return
		_close_menu()
		get_viewport().set_input_as_handled()

func _handle_toggle_input(event: InputEvent) -> bool:
	if _management_menu != null and _management_menu.visible:
		return false

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if visible:
			if _request_settings_close():
				return true
			_close_menu()
		else:
			_open_menu()
		return true

	if event is InputEventJoypadButton and event.pressed and event.button_index == START_BUTTON_INDEX:
		if visible:
			if _request_settings_close():
				return true
			_close_menu()
		else:
			_open_menu()
		return true

	return false

func _open_menu() -> void:
	_refresh_save_load_buttons()
	visible = true
	get_tree().paused = true
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_inventory_toggle()
		ui_sounds.suppress_browse_once()
	call_deferred("_focus_default_button")

func _close_menu() -> void:
	if _settings_overlay != null:
		if _request_settings_close():
			return
	visible = false
	get_tree().paused = false

func _focus_default_button() -> void:
	if is_instance_valid(resume_button):
		resume_button.grab_focus()

func _open_settings() -> void:
	if is_instance_valid(_settings_overlay):
		return
	_settings_overlay = null
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	var modal := SETTINGS_MODAL_SCENE.instantiate()
	_settings_overlay = modal
	add_child(modal)
	if modal.has_signal("modal_closed"):
		modal.modal_closed.connect(_on_settings_closed)

func _on_settings_closed() -> void:
	_settings_overlay = null
	call_deferred("_focus_default_button")

func _request_settings_close() -> bool:
	if _settings_overlay == null or not is_instance_valid(_settings_overlay):
		_settings_overlay = null
		return false
	if _settings_overlay.has_method("request_close"):
		_settings_overlay.call("request_close")
		return true
	return false

func _exit_to_title() -> void:
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	get_tree().paused = false
	TransitionManager.change_scene_path(TITLE_SCENE_PATH)

func _refresh_save_load_buttons() -> void:
	var current_scene := get_tree().current_scene
	var can_manage_run := current_scene != null and Global != null and Global.loop_hub_mode_active and current_scene.has_method("get_loop_run_save_state")
	save_button.disabled = not can_manage_run
	load_button.disabled = SaveManager == null or not SaveManager.has_method("has_save") or not SaveManager.has_save()
	_wire_focus_graph()

func _save_run() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null or not current_scene.has_method("get_loop_run_save_state"):
		return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	if SaveManager != null and SaveManager.has_method("save_current_run"):
		SaveManager.save_current_run(current_scene.get_loop_run_save_state())
	_refresh_save_load_buttons()

func _load_run() -> void:
	if SaveManager == null or not SaveManager.has_method("load_current_run") or not SaveManager.load_current_run():
		return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	get_tree().paused = false
	TransitionManager.change_scene_path("res://scenes/level/game.tscn")

func _quit_game() -> void:
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	get_tree().paused = false
	get_tree().quit()

func _wire_button(button: Button) -> void:
	if button == null:
		return
	button.focus_entered.connect(_on_button_highlighted.bind(button))
	button.mouse_entered.connect(_on_button_highlighted.bind(button))

func _wire_focus_graph() -> void:
	var buttons: Array[Button] = [resume_button, save_button, load_button, settings_button, exit_to_title_button, quit_button]
	for index in range(buttons.size()):
		var button := buttons[index]
		if button == null:
			continue
		var previous := buttons[index - 1] if index > 0 else null
		var following := buttons[index + 1] if index + 1 < buttons.size() else null
		button.focus_neighbor_top = button.get_path_to(previous) if previous != null else NodePath()
		button.focus_neighbor_bottom = button.get_path_to(following) if following != null else NodePath()

func _on_button_highlighted(button: Button) -> void:
	if button == null or button.disabled:
		return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_browse_general(button)
