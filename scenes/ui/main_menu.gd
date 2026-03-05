extends Control

@onready var inventory_grid: GridContainer = $CenterContainer/TabContainer/Inventory/Margin/Grid
@onready var tabs: TabContainer = $CenterContainer/TabContainer


# Column 2: Stats
@onready var lbl_vit = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblVIT
@onready var lbl_str = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblSTR
@onready var lbl_dex = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblDEX
@onready var lbl_int = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblINT
@onready var lbl_spd = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblSPD
@onready var lbl_mov = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblMOV

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

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	Global.inventory_updated.connect(update_inventory)
	Global.stats_updated.connect(update_status_page)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_toggle"): # Tab / Controller Menu Toggle
		toggle_menu()
	elif visible and event.is_action_pressed("ui_cancel"): # Escape / Controller B
		toggle_menu()
	elif visible:
		if _is_action_pressed(event, TAB_PREV_ACTIONS):
			_switch_tab(-1)
			get_viewport().set_input_as_handled()
		elif _is_action_pressed(event, TAB_NEXT_ACTIONS):
			_switch_tab(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			_activate_focused_control()
		elif _is_action_pressed(event, NAV_LEFT_ACTIONS):
			_move_focus(Vector2.LEFT)
		elif _is_action_pressed(event, NAV_RIGHT_ACTIONS):
			_move_focus(Vector2.RIGHT)
		elif _is_action_pressed(event, NAV_UP_ACTIONS):
			_move_focus(Vector2.UP)
		elif _is_action_pressed(event, NAV_DOWN_ACTIONS):
			_move_focus(Vector2.DOWN)

func toggle_menu():
	visible = not visible
	get_tree().paused = visible
	update_status_page()
	
	if visible:
		# Default to Inventory tab (Index 1) for now
		if tabs:
			tabs.current_tab = 1
		update_inventory()
		_focus_first_interactable()


func _activate_focused_control() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner() as Control
	if focus_owner == null or not _is_in_current_tab(focus_owner):
		_focus_first_interactable()
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

func _switch_tab(delta: int) -> void:
	if tabs == null:
		return

	var count: int = tabs.get_tab_count()
	if count <= 0:
		return

	tabs.current_tab = wrapi(tabs.current_tab + delta, 0, count)
	_focus_first_interactable()

func _focus_first_interactable() -> void:
	for candidate in _get_tab_focusable_controls():
		candidate.grab_focus()
		return

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
		if control.visible and control.focus_mode != Control.FOCUS_NONE:
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
		_focus_first_interactable()
			
func update_status_page():
	var format_stat = func(stat_name: String, base_val: int) -> String:
		var buff_val = 0
		if Global.active_food_buff.item != null:
			# .get() safely looks for the stat, returning 0 if the key is missing
			buff_val = Global.active_food_buff.stats.get(stat_name, 0)
			
		if buff_val > 0:
			return "%s: %d [color=green](+%d)[/color]" % [stat_name, base_val, buff_val]
		elif buff_val < 0:
			return "%s: %d [color=red](%d)[/color]" % [stat_name, base_val, buff_val]
		else:
			return "%s: %d" % [stat_name, base_val]

	# --- THE FIX: We now only pass the TWO required arguments ---
	lbl_vit.text = format_stat.call("VIT", Global.player_stats["VIT"])
	lbl_str.text = format_stat.call("STR", Global.player_stats["STR"])
	lbl_dex.text = format_stat.call("DEX", Global.player_stats["DEX"])
	lbl_int.text = format_stat.call("INT", Global.player_stats["INT"])
	lbl_spd.text = format_stat.call("SPD", Global.player_stats["SPD"])
	lbl_mov.text = format_stat.call("MOV", Global.player_stats["MOV"])
	
	# Update Meal Text
	if Global.active_food_buff.item != null:
		lbl_food.text = "Ate a hearty meal!"
	else:
		lbl_food.text = "No meal."
