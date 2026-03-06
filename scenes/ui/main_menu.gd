extends Control

@onready var inventory_grid: GridContainer = $CenterContainer/TabContainer/Inventory/Margin/Grid
@onready var tabs: TabContainer = $CenterContainer/TabContainer


# Column 2: Stats
@onready var lbl_vit: RichTextLabel = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblVIT
@onready var lbl_str: RichTextLabel = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblSTR
@onready var lbl_dex: RichTextLabel = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblDEX
@onready var lbl_int: RichTextLabel = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblINT
@onready var lbl_spd: RichTextLabel = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblSPD
@onready var lbl_mov: RichTextLabel = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblMOV
@onready var lbl_class: Label = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblClass
@onready var lbl_level: Label = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblLevel

# Column 3: Meal
@onready var lbl_food = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/EquipMealColumn/MealSection/MealBox/LblFoodBuff

# Preload the slot scene
const SLOT_SCENE = preload("res://scenes/ui/inventory_slot.tscn")
const TAB_PREV_ACTIONS: Array[StringName] = [&"tool_backward", &"ui_page_up"]
const TAB_NEXT_ACTIONS: Array[StringName] = [&"tool_forward", &"ui_page_down"]
const NAV_LEFT_ACTIONS: Array[StringName] = [&"left", &"ui_left"]
const NAV_RIGHT_ACTIONS: Array[StringName] = [&"right", &"ui_right"]
const NAV_UP_ACTIONS: Array[StringName] = [&"up", &"ui_up"]
const NAV_DOWN_ACTIONS: Array[StringName] = [&"down", &"ui_down"]
const NAV_REPEAT_INITIAL_DELAY_MS := 220
const NAV_REPEAT_INTERVAL_MS := 140

var _last_nav_action: StringName = StringName()
var _last_nav_time_ms: int = -100000

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	Global.inventory_updated.connect(update_inventory)
	Global.stats_updated.connect(update_status_page)

func _shortcut_input(event: InputEvent) -> void:
	if _handle_menu_toggle_input(event):
		return

func _input(event: InputEvent) -> void:
	if _handle_menu_toggle_input(event):
		return
	if not visible:
		return

	if _is_action_pressed(event, TAB_PREV_ACTIONS):
		_switch_tab(-1)
		get_viewport().set_input_as_handled()
	elif _is_action_pressed(event, TAB_NEXT_ACTIONS):
		_switch_tab(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_activate_focused_control()
	elif _can_trigger_navigation(event, NAV_LEFT_ACTIONS, &"left"):
		_move_focus(Vector2.LEFT)
		get_viewport().set_input_as_handled()
	elif _can_trigger_navigation(event, NAV_RIGHT_ACTIONS, &"right"):
		_move_focus(Vector2.RIGHT)
		get_viewport().set_input_as_handled()
	elif _can_trigger_navigation(event, NAV_UP_ACTIONS, &"up"):
		_move_focus(Vector2.UP)
		get_viewport().set_input_as_handled()
	elif _can_trigger_navigation(event, NAV_DOWN_ACTIONS, &"down"):
		_move_focus(Vector2.DOWN)
		get_viewport().set_input_as_handled()

func _handle_menu_toggle_input(event: InputEvent) -> bool:
	if event.is_action_pressed("menu_toggle"):
		toggle_menu()
		get_viewport().set_input_as_handled()
		return true

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		toggle_menu()
		get_viewport().set_input_as_handled()
		return true

	if visible and event.is_action_pressed("ui_cancel"):
		toggle_menu()
		get_viewport().set_input_as_handled()
		return true

	return false

func toggle_menu():
	visible = not visible
	get_tree().paused = visible
	update_status_page()
	
	if visible:
		# Default to Inventory tab (Index 1) for now
		if tabs:
			tabs.current_tab = 1
		update_inventory()
		_focus_first_interactable_deferred()


func _activate_focused_control() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner() as Control
	if focus_owner == null or not _is_in_current_tab(focus_owner):
		_focus_first_interactable_deferred()
		return

	if focus_owner is BaseButton:
		(focus_owner as BaseButton).pressed.emit()
		get_viewport().set_input_as_handled()
		return

	if focus_owner.has_method("_try_interact"):
		focus_owner.call("_try_interact")
		get_viewport().set_input_as_handled()

func _is_action_pressed(event: InputEvent, actions: Array[StringName]) -> bool:
	for action in actions:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			return true
	return false

func _can_trigger_navigation(event: InputEvent, actions: Array[StringName], nav_key: StringName) -> bool:
	if not _is_action_pressed(event, actions):
		return false

	for action in actions:
		if InputMap.has_action(action) and Input.is_action_just_pressed(action):
			_last_nav_action = nav_key
			_last_nav_time_ms = Time.get_ticks_msec()
			return true

	if event is InputEventJoypadMotion:
		var now := Time.get_ticks_msec()
		var required_delay := NAV_REPEAT_INTERVAL_MS if _last_nav_action == nav_key else NAV_REPEAT_INITIAL_DELAY_MS
		if now - _last_nav_time_ms >= required_delay:
			_last_nav_action = nav_key
			_last_nav_time_ms = now
			return true

	return false

func _switch_tab(delta: int) -> void:
	if tabs == null:
		return

	var count: int = tabs.get_tab_count()
	if count <= 0:
		return

	tabs.current_tab = wrapi(tabs.current_tab + delta, 0, count)
	_focus_first_interactable_deferred()

func _focus_first_interactable() -> void:
	for candidate in _get_tab_focusable_controls():
		if candidate.get_focus_mode_with_override() == Control.FOCUS_ALL:
			candidate.grab_focus()
			return

func _focus_first_interactable_deferred() -> void:
	call_deferred("_focus_first_interactable")

func _move_focus(direction: Vector2) -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner() as Control
	if focus_owner == null or not visible or not _is_in_current_tab(focus_owner):
		_focus_first_interactable()
		return

	var controls := _get_tab_focusable_controls()
	if controls.is_empty():
		return

	if _move_grid_focus_if_possible(focus_owner, controls, direction):
		return

	var current_center := _control_center(focus_owner)
	var best: Control = null
	var best_score := INF

	for candidate in controls:
		if candidate == focus_owner:
			continue
		var offset := _control_center(candidate) - current_center
		if offset == Vector2.ZERO:
			continue
		if direction.dot(offset.normalized()) <= 0.25:
			continue

		var score := offset.length_squared()
		if score < best_score:
			best_score = score
			best = candidate

	if best:
		best.grab_focus()
		return

	_move_focus_linear(focus_owner, controls, direction)


func _move_grid_focus_if_possible(focus_owner: Control, controls: Array[Control], direction: Vector2) -> bool:
	if tabs == null or tabs.current_tab != 1 or inventory_grid == null:
		return false

	var current_index := controls.find(focus_owner)
	if current_index == -1:
		return false

	var columns: int = maxi(inventory_grid.columns, 1)
	var target_index := current_index

	if direction == Vector2.LEFT:
		target_index = max(current_index - 1, 0)
	elif direction == Vector2.RIGHT:
		target_index = min(current_index + 1, controls.size() - 1)
	elif direction == Vector2.UP:
		target_index = max(current_index - columns, 0)
	elif direction == Vector2.DOWN:
		target_index = min(current_index + columns, controls.size() - 1)

	if target_index == current_index:
		return false

	controls[target_index].grab_focus()
	return true

func _move_focus_linear(focus_owner: Control, controls: Array[Control], direction: Vector2) -> void:
	var current_index := controls.find(focus_owner)
	if current_index == -1:
		_focus_first_interactable()
		return

	var step := 0
	if direction == Vector2.LEFT or direction == Vector2.UP:
		step = -1
	elif direction == Vector2.RIGHT or direction == Vector2.DOWN:
		step = 1

	if step == 0:
		return

	var target_index := wrapi(current_index + step, 0, controls.size())
	controls[target_index].grab_focus()

func _get_tab_focusable_controls() -> Array[Control]:
	var result: Array[Control] = []
	if tabs == null:
		return result

	var tab_content: Control = tabs.get_current_tab_control()
	if tab_content == null:
		return result

	_collect_focusable_controls(tab_content, result)
	return result

func _collect_focusable_controls(node: Node, result: Array[Control]) -> void:
	if node is Control:
		var control := node as Control
		if control.visible and control.get_focus_mode_with_override() == Control.FOCUS_ALL:
			result.append(control)

	for child in node.get_children():
		_collect_focusable_controls(child, result)

func _is_in_current_tab(control: Control) -> bool:
	if tabs == null:
		return false

	var tab_content: Control = tabs.get_current_tab_control()
	if tab_content == null:
		return false

	return tab_content == control or tab_content.is_ancestor_of(control)

func _control_center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()
		

func update_inventory():
	if not inventory_grid: return

	# 1. Clear existing slots
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# 2. Add slots for current inventory
	for item_enum in Global.inventory:
		var count = Global.inventory[item_enum]
		if count > 0:
			var slot = SLOT_SCENE.instantiate()
			inventory_grid.add_child(slot)
			
			# UPDATE: Pass the ENUM, not the Name string
			slot.setup(item_enum, count)

	if visible and tabs and tabs.current_tab == 1:
		_focus_first_interactable_deferred()
			
func update_status_page():
	Global.ensure_player_stat_formats()
	var permanent_stats: Dictionary = Global.get_player_permanent_totals()
	var temporary_modifiers: Dictionary = Global.get_player_temporary_modifiers()

	var format_stat = func(stat_name: String, base_val: int, buff_val: int) -> String:
			
		if buff_val > 0:
			return "%s: %d [color=green](+%d)[/color]" % [stat_name, base_val, buff_val]
		elif buff_val < 0:
			return "%s: %d [color=red](%d)[/color]" % [stat_name, base_val, buff_val]
		else:
			return "%s: %d" % [stat_name, base_val]

	# Show permanent value plus temporary modifier, mirroring combat calculations.
	lbl_vit.bbcode_text = format_stat.call("VIT", int(permanent_stats.get("VIT", 0)), int(temporary_modifiers.get("VIT", 0)))
	lbl_str.bbcode_text = format_stat.call("STR", int(permanent_stats.get("STR", 0)), int(temporary_modifiers.get("STR", 0)))
	lbl_dex.bbcode_text = format_stat.call("DEX", int(permanent_stats.get("DEX", 0)), int(temporary_modifiers.get("DEX", 0)))
	lbl_int.bbcode_text = format_stat.call("INT", int(permanent_stats.get("INT", 0)), int(temporary_modifiers.get("INT", 0)))
	lbl_spd.bbcode_text = format_stat.call("SPD", int(permanent_stats.get("SPD", 0)), int(temporary_modifiers.get("SPD", 0)))
	lbl_mov.bbcode_text = format_stat.call("MOV", int(permanent_stats.get("MOV", 0)), int(temporary_modifiers.get("MOV", 0)))
	lbl_level.text = "Level: %d" % Global.get_player_level()
	lbl_class.text = "Class: %s" % _resolve_player_class_name()
	
	# Update Meal Text
	if Global.active_food_buff.item != null:
		lbl_food.text = "Ate a hearty meal!"
	else:
		lbl_food.text = "No meal."


func _resolve_player_class_name() -> String:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		if Global.has_method("get_player_class_name"):
			return String(Global.get_player_class_name())
		return "Unknown"

	for node in scene_root.find_children("*", "Unit", true, false):
		var unit := node as Unit
		if unit == null or not unit.is_player:
			continue

		if unit.character_data != null and unit.character_data.class_data != null:
			var unit_class_name := String(unit.character_data.class_data.metadata_name).strip_edges()
			if not unit_class_name.is_empty():
				Global.set_player_class_name(unit_class_name)
				return unit_class_name

	if Global.has_method("get_player_class_name"):
		return String(Global.get_player_class_name())

	return "Unknown"
