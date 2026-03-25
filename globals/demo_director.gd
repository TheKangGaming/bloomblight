extends Node

signal stage_changed(stage: int)
signal input_mode_changed(mode: int)
signal story_harvest_ready
signal meal_eaten(item_type: int)

enum InputMode {
	KEYBOARD_MOUSE,
	CONTROLLER
}

enum DemoStage {
	NONE,
	OPENER,
	INTRO,
	HARVEST_CROPS,
	LIGHT_CAMPFIRE,
	COOK_MEAL,
	EAT_MEAL,
	WARNING_BEAT,
	BATTLE_INTRO,
	BATTLE_TUTORIAL,
	BLOOM_TUTORIAL,
	DEMO_COMPLETE
}

const TITLE_SCENE := preload("res://scenes/ui/title_screen.tscn")
const STORY_CARD_SCENE := preload("res://scenes/ui/demo_story_card.tscn")

var demo_active := true
var current_stage: DemoStage = DemoStage.NONE
var current_input_mode: InputMode = InputMode.KEYBOARD_MOUSE
var pending_day_two_battle_intro := false

var _manual_prompt_id := ""
var _manual_prompt_replacements: Dictionary = {}
var _story_harvests := {}

func is_demo_active() -> bool:
	return demo_active

func begin_new_demo() -> void:
	demo_active = true
	current_input_mode = InputMode.KEYBOARD_MOUSE
	pending_day_two_battle_intro = false
	_manual_prompt_id = ""
	_manual_prompt_replacements.clear()
	_story_harvests.clear()
	Global.reset_demo_state()
	set_stage(DemoStage.OPENER)
	clear_prompt()

func _input(event: InputEvent) -> void:
	if event == null:
		return

	if event is InputEventJoypadButton:
		_set_input_mode(InputMode.CONTROLLER)
		return

	if event is InputEventJoypadMotion:
		var joy_event := event as InputEventJoypadMotion
		if absf(joy_event.axis_value) >= 0.35:
			_set_input_mode(InputMode.CONTROLLER)
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.echo:
			_set_input_mode(InputMode.KEYBOARD_MOUSE)
		return

	if event is InputEventMouseButton or event is InputEventMouseMotion:
		_set_input_mode(InputMode.KEYBOARD_MOUSE)

func _set_input_mode(mode: InputMode) -> void:
	if current_input_mode == mode:
		return

	current_input_mode = mode
	input_mode_changed.emit(mode)
	refresh_current_prompt()

func set_stage(stage: DemoStage) -> void:
	current_stage = stage
	stage_changed.emit(stage)

	match stage:
		DemoStage.HARVEST_CROPS, DemoStage.LIGHT_CAMPFIRE, DemoStage.COOK_MEAL, DemoStage.EAT_MEAL:
			_manual_prompt_id = ""
			_manual_prompt_replacements.clear()
			refresh_current_prompt()
		DemoStage.WARNING_BEAT, DemoStage.BATTLE_INTRO, DemoStage.DEMO_COMPLETE:
			clear_prompt()

func advance_stage() -> void:
	set_stage(mini(int(current_stage) + 1, int(DemoStage.DEMO_COMPLETE)))

func clear_prompt() -> void:
	_manual_prompt_id = ""
	_manual_prompt_replacements.clear()
	Global.show_tutorial_text("")

func show_context_prompt(prompt_id: String, replacements: Dictionary = {}) -> void:
	_manual_prompt_id = prompt_id
	_manual_prompt_replacements = replacements.duplicate(true)
	Global.show_tutorial_text(_resolve_prompt(prompt_id, replacements))

func refresh_current_prompt() -> void:
	if not demo_active:
		return

	if not _manual_prompt_id.is_empty():
		Global.show_tutorial_text(_resolve_prompt(_manual_prompt_id, _manual_prompt_replacements))
		return

	var text := _get_stage_prompt_text(current_stage)
	Global.show_tutorial_text(text)

func notify_intro_complete() -> void:
	set_stage(DemoStage.HARVEST_CROPS)

func notify_story_crop_harvested(item_type: int) -> void:
	if current_stage != DemoStage.HARVEST_CROPS:
		return

	if item_type not in [Global.Items.CARROT, Global.Items.PARSNIP]:
		return

	_story_harvests[item_type] = true
	if _story_harvests.has(Global.Items.CARROT) and _story_harvests.has(Global.Items.PARSNIP):
		clear_prompt()
		story_harvest_ready.emit()

func notify_recipe_learned(recipe_item: int) -> void:
	if recipe_item != Global.Items.GLAZED_CARROTS:
		return
	set_stage(DemoStage.LIGHT_CAMPFIRE)

func notify_campfire_lit() -> void:
	if current_stage == DemoStage.LIGHT_CAMPFIRE:
		set_stage(DemoStage.COOK_MEAL)

func notify_meal_cooked(recipe_item: int) -> void:
	if recipe_item != Global.Items.GLAZED_CARROTS:
		return

	if current_stage in [DemoStage.LIGHT_CAMPFIRE, DemoStage.COOK_MEAL]:
		set_stage(DemoStage.EAT_MEAL)

func notify_food_eaten(item_type: int) -> void:
	if item_type != Global.Items.GLAZED_CARROTS:
		return

	if current_stage != DemoStage.EAT_MEAL:
		return

	set_stage(DemoStage.WARNING_BEAT)
	meal_eaten.emit(item_type)

func prepare_day_two_battle_intro() -> void:
	pending_day_two_battle_intro = true

func consume_pending_day_two_battle_intro() -> bool:
	var pending := pending_day_two_battle_intro
	pending_day_two_battle_intro = false
	return pending

func get_continue_prompt_text() -> String:
	return "Press %s to continue" % get_confirm_label()

func get_skip_prompt_text() -> String:
	return "Press %s to skip" % get_action_label("cancel")

func get_confirm_label() -> String:
	if current_input_mode == InputMode.CONTROLLER:
		return "Confirm"
	return get_action_label("interact")

func get_action_label(action_name: StringName) -> String:
	if current_input_mode == InputMode.CONTROLLER:
		var controller_event := _find_input_event(action_name, true)
		if controller_event != null:
			return _format_input_event(controller_event)
		return _controller_fallback_label(action_name)

	var kb_event := _find_input_event(action_name, false)
	if kb_event != null:
		return _format_input_event(kb_event)
	return _keyboard_fallback_label(action_name)

func get_move_label() -> String:
	if current_input_mode == InputMode.CONTROLLER:
		return "Left Stick"

	var labels := []
	for action_name in [&"up", &"left", &"down", &"right"]:
		var label := get_action_label(action_name)
		if not label.is_empty() and label not in labels:
			labels.append(label)
	return ", ".join(labels)

func get_tool_cycle_label() -> String:
	var forward_label := get_action_label("tool_forward")
	var backward_label := get_action_label("tool_backward")
	if forward_label.is_empty():
		return backward_label
	if backward_label.is_empty():
		return forward_label
	if forward_label == backward_label:
		return forward_label
	return "%s / %s" % [forward_label, backward_label]

func show_demo_complete_card(parent: Node) -> void:
	if parent == null or not is_instance_valid(parent):
		return

	set_stage(DemoStage.DEMO_COMPLETE)

	var card = STORY_CARD_SCENE.instantiate()
	parent.add_child(card)
	card.configure({
		"title": "Demo Complete",
		"body": "The scouting party is gone, but the blight is still closing in.\n\nLife can still take root here. This is only the beginning.",
		"confirm_hint": "return to title",
		"allow_skip": false
	})
	card.confirmed.connect(func() -> void:
		if TransitionManager:
			TransitionManager.change_scene(TITLE_SCENE, 1.0)
	)

func _get_stage_prompt_text(stage: DemoStage) -> String:
	match stage:
		DemoStage.HARVEST_CROPS:
			return "Objective: Harvest the carrot and parsnip."
		DemoStage.LIGHT_CAMPFIRE:
			return "Objective: Walk to the campfire and press %s to light it." % get_confirm_label()
		DemoStage.COOK_MEAL:
			return "Objective: Cook Glazed Carrots at the campfire."
		DemoStage.EAT_MEAL:
			return "Objective: Open inventory (%s) and eat the Glazed Carrots." % get_action_label("menu_toggle")
		_:
			return ""

func _resolve_prompt(prompt_id: String, replacements: Dictionary = {}) -> String:
	var template := ""
	match prompt_id:
		"battle_select_savannah":
			template = "Tutorial: Select Savannah with %s." % get_action_label("confirm")
		"battle_move_savannah":
			template = "Tutorial: Move the cursor with %s, then press %s on a blue tile." % [get_move_label(), get_action_label("confirm")]
		"battle_choose_attack":
			template = "Tutorial: Choose Attack to strike the scouting party, or Wait to end Savannah's turn."
		"battle_choose_bloom":
			template = "Tutorial: Select Tera, choose Bloom, then press %s to awaken the roots around her." % get_action_label("confirm")
		"battle_harvest_healflower":
			template = "Tutorial: Move Savannah onto a Healflower, choose Harvest, then press %s to recover HP." % get_action_label("confirm")
		"battle_defeat_enemies":
			template = "Objective: Defeat the scouting party."
		"farm_controls_intro":
			template = "Tutorial: Move with {move}. Hold {run} to run, and press {confirm} near objects to interact.\nObjective: Find Tera."
		"farm_find_tera":
			template = "Objective: Find Tera."
		"farm_open_chest":
			template = "Objective: Open the old chest by the ruined field."
		"farm_search_forest":
			template = "Objective: Search the forest edge for seeds."
		"farm_farming_controls":
			template = "Tutorial: Cycle tools with {tool_cycle}. Use the Hoe or Watering Can with {action}, and plant seeds with {plant}.\nObjective: Plant the carrot and parsnip seeds, then water them."
		"farm_plant_and_water":
			template = "Objective: Plant the carrot and parsnip seeds, then water them."
		"farm_water_both":
			template = "Objective: Water both planted seeds."
		_:
			template = ""

	var merged := replacements.duplicate(true)
	merged["confirm"] = get_confirm_label()
	merged["move"] = get_move_label()
	merged["run"] = get_action_label("run")
	merged["action"] = get_action_label("action")
	merged["plant"] = get_action_label("plant")
	merged["tool_cycle"] = get_tool_cycle_label()
	merged["inventory"] = get_action_label("menu_toggle")
	merged["cancel"] = get_action_label("cancel")
	return _format_template(template, merged)

func _format_template(template: String, replacements: Dictionary) -> String:
	var resolved := template
	for key in replacements.keys():
		resolved = resolved.replace("{" + String(key) + "}", String(replacements[key]))
	return resolved

func _find_input_event(action_name: StringName, wants_controller: bool) -> InputEvent:
	if not InputMap.has_action(action_name):
		return null

	for event in InputMap.action_get_events(action_name):
		if _is_matching_input_event(event, wants_controller):
			return event
	return null

func _is_matching_input_event(event: InputEvent, wants_controller: bool) -> bool:
	if wants_controller:
		return event is InputEventJoypadButton or event is InputEventJoypadMotion

	return event is InputEventKey or event is InputEventMouseButton

func _format_input_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.physical_keycode != 0:
			return OS.get_keycode_string(key_event.physical_keycode)
		if key_event.keycode != 0:
			return OS.get_keycode_string(key_event.keycode)
		return "Key"

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT:
				return "Left Click"
			MOUSE_BUTTON_RIGHT:
				return "Right Click"
			MOUSE_BUTTON_WHEEL_UP:
				return "Mouse Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "Mouse Wheel Down"
			_:
				return "Mouse %d" % mouse_event.button_index

	if event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		match motion_event.axis:
			JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
				return "Left Stick"
			JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
				return "Right Stick"
			JOY_AXIS_TRIGGER_LEFT:
				return "L2"
			JOY_AXIS_TRIGGER_RIGHT:
				return "R2"
			_:
				return "Stick"

	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		match button_event.button_index:
			JOY_BUTTON_A:
				return "Confirm"
			JOY_BUTTON_B:
				return "Cancel"
			JOY_BUTTON_X:
				return "X"
			JOY_BUTTON_Y:
				return "Y"
			JOY_BUTTON_LEFT_SHOULDER:
				return "L1"
			JOY_BUTTON_RIGHT_SHOULDER:
				return "R1"
			JOY_BUTTON_DPAD_UP:
				return "D-Pad Up"
			JOY_BUTTON_DPAD_DOWN:
				return "D-Pad Down"
			JOY_BUTTON_DPAD_LEFT:
				return "D-Pad Left"
			JOY_BUTTON_DPAD_RIGHT:
				return "D-Pad Right"
			JOY_BUTTON_BACK:
				return "Back"
			JOY_BUTTON_START:
				return "Start"
			_:
				return "Pad %d" % button_event.button_index

	return "Input"

func _keyboard_fallback_label(action_name: StringName) -> String:
	match action_name:
		&"menu_toggle":
			return "Tab"
		&"cancel":
			return "Esc"
		&"action":
			return "Space"
		&"tool_forward":
			return "1"
		&"tool_backward":
			return "Mouse Wheel Down"
		&"confirm", &"interact":
			return "E"
		_:
			return String(action_name).capitalize()

func _controller_fallback_label(action_name: StringName) -> String:
	match action_name:
		&"confirm", &"interact", &"ui_accept":
			return "Confirm"
		&"cancel", &"ui_cancel":
			return "Cancel"
		&"menu_toggle":
			return "L1"
		&"run":
			return "L2"
		&"action":
			return "R2"
		&"plant":
			return "Confirm"
		&"tool_forward":
			return "R1"
		&"tool_backward":
			return "L1"
		&"time_skip":
			return "X"
		_:
			return String(action_name).capitalize()
