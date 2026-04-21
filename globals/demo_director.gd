extends Node

signal stage_changed(stage: int)
signal input_mode_changed(mode: int)
signal story_harvest_ready
signal meal_eaten(item_type: int)
signal tutorial_card_requested(config: Dictionary)

enum InputMode {
	KEYBOARD_MOUSE,
	CONTROLLER
}

enum ControllerFamily {
	GENERIC,
	PLAYSTATION
}

enum DemoStage {
	NONE,
	OPENER,
	INTRO,
	HARVEST_CROPS,
	LIGHT_CAMPFIRE,
	COOK_MEAL,
	EAT_MEAL,
	MEAL_REVIEW,
	WARNING_BEAT,
	BATTLE_INTRO,
	BATTLE_TUTORIAL,
	BLOOM_TUTORIAL,
	GATHER_MATERIALS,
	RETURN_TO_FARM,
	CABIN_COMPLETE,
	DEMO_COMPLETE
}

const TITLE_SCENE_PATH := "res://scenes/ui/title_screen.tscn"
const STORY_CARD_SCENE := preload("res://scenes/ui/demo_story_card.tscn")
const TUTORIAL_CARD_SCENE := preload("res://scenes/ui/demo_story_card.tscn")

var demo_active := true
var current_stage: DemoStage = DemoStage.NONE
var current_input_mode: InputMode = InputMode.KEYBOARD_MOUSE
var pending_day_two_battle_intro := false
var _active_controller_device := -1
var _controller_family: ControllerFamily = ControllerFamily.GENERIC

var _manual_prompt_id := ""
var _manual_prompt_replacements: Dictionary = {}
var _story_harvests := {}
var _seen_tutorial_cards: Dictionary = {}

const TUTORIAL_CARD_ORDER := [
	"loop_planting",
	"loop_battle",
	"loop_first_night",
	"loop_bloom_points",
	"loop_forest_join",
	"loop_forest_wood",
	"loop_sleep",
	"loop_cooking",
	"farm_controls",
	"farm_farming",
	"meal_buff",
	"battle_savannah",
	"battle_silas",
	"battle_tera_bloom",
	"battle_harvest",
]

func is_demo_active() -> bool:
	return demo_active

func begin_new_demo() -> void:
	demo_active = true
	current_input_mode = InputMode.KEYBOARD_MOUSE
	pending_day_two_battle_intro = false
	_active_controller_device = -1
	_controller_family = ControllerFamily.GENERIC
	_manual_prompt_id = ""
	_manual_prompt_replacements.clear()
	_story_harvests.clear()
	_seen_tutorial_cards.clear()
	Global.reset_demo_state()
	if ProgressionService != null and ProgressionService.has_method("reset_demo_roster"):
		ProgressionService.reset_demo_roster()
	set_stage(DemoStage.OPENER)
	clear_prompt()

func begin_loop_tutorial_run() -> void:
	demo_active = false
	pending_day_two_battle_intro = false
	_manual_prompt_id = ""
	_manual_prompt_replacements.clear()
	_story_harvests.clear()
	for card_id_variant in _seen_tutorial_cards.keys():
		var card_id := String(card_id_variant)
		if card_id.begins_with("loop_") or card_id.begins_with("battle_"):
			_seen_tutorial_cards.erase(card_id_variant)

func _input(event: InputEvent) -> void:
	if event == null:
		return

	if event is InputEventJoypadButton:
		_handle_controller_activity(event.device)
		return

	if event is InputEventJoypadMotion:
		var joy_event := event as InputEventJoypadMotion
		if absf(joy_event.axis_value) >= 0.35:
			_handle_controller_activity(joy_event.device)
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

func _handle_controller_activity(device: int) -> void:
	var family_changed := _update_controller_family(device)
	if current_input_mode != InputMode.CONTROLLER:
		_set_input_mode(InputMode.CONTROLLER)
	elif family_changed:
		input_mode_changed.emit(current_input_mode)
		refresh_current_prompt()

func set_stage(stage: DemoStage) -> void:
	current_stage = stage
	stage_changed.emit(stage)

	match stage:
		DemoStage.INTRO, DemoStage.HARVEST_CROPS, DemoStage.LIGHT_CAMPFIRE, DemoStage.COOK_MEAL, DemoStage.EAT_MEAL, DemoStage.MEAL_REVIEW, DemoStage.BATTLE_TUTORIAL, DemoStage.BLOOM_TUTORIAL, DemoStage.GATHER_MATERIALS, DemoStage.RETURN_TO_FARM, DemoStage.CABIN_COMPLETE:
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

func show_tutorial_card(card_id: String, parent: Node = null, replay_only: bool = false) -> void:
	if card_id.is_empty():
		return

	if not replay_only and has_seen_tutorial(card_id):
		return

	var config := get_tutorial_card_config(card_id)
	if config.is_empty():
		return

	mark_tutorial_seen(card_id)
	config["card_type"] = "tutorial"
	config["allow_skip"] = false
	config["confirm_hint"] = "continue"
	config["skip_hint"] = "dismiss"
	tutorial_card_requested.emit(config.duplicate(true))

	var host: Node = _resolve_tutorial_host(parent)
	if host == null or not is_instance_valid(host):
		return

	var tree := get_tree()
	var was_paused := tree.paused if tree != null else false
	if tree != null:
		tree.paused = true

	var card = TUTORIAL_CARD_SCENE.instantiate()
	host.add_child(card)
	await card.configure(config)
	await card.confirmed

	if tree != null:
		tree.paused = was_paused

func has_seen_tutorial(card_id: String) -> bool:
	return bool(_seen_tutorial_cards.get(card_id, false))

func mark_tutorial_seen(card_id: String) -> void:
	if card_id.is_empty():
		return
	_seen_tutorial_cards[card_id] = true

func get_seen_tutorial_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for card_id in TUTORIAL_CARD_ORDER:
		if not has_seen_tutorial(card_id):
			continue
		var config := get_tutorial_card_config(card_id)
		if config.is_empty():
			continue
		cards.append({
			"id": card_id,
			"title": String(config.get("title", card_id)),
			"body": String(config.get("body", "")),
		})
	return cards

func get_seen_tutorial_ids() -> Array[String]:
	var ids: Array[String] = []
	for card_id_variant in _seen_tutorial_cards.keys():
		if bool(_seen_tutorial_cards.get(card_id_variant, false)):
			ids.append(String(card_id_variant))
	ids.sort()
	return ids

func apply_seen_tutorial_ids(card_ids: Array) -> void:
	_seen_tutorial_cards.clear()
	for raw_card_id in card_ids:
		var card_id := String(raw_card_id)
		if card_id.is_empty():
			continue
		_seen_tutorial_cards[card_id] = true

func get_tutorial_card_config(card_id: String) -> Dictionary:
	var template := ""
	var title := ""
	match card_id:
		"loop_planting":
			title = "Tutorial: Planting"
			template = "Stand on plowed soil and press {plant} to plant a seed.\n\nPlant before battle. Crops grow while you fight, then come back ready to harvest."
		"loop_battle":
			title = "Tutorial: Next Step"
			template = "Once you've planted, head to the bridge and press {confirm} to start a battle.\n\nWinning battles earns Bloom Points and Gold."
		"loop_first_night":
			title = "Tutorial: Night"
			template = "Battles advance time. Night is your reward phase.\n\nHarvest, cook, trade, and sleep when you're ready for the next day."
		"loop_bloom_points":
			title = "Tutorial: Bloom Points"
			template = "Bloom Points let Tera use Bloom to purify dead plots and expand the settlement.\n\nOpen the forest first so you can chop wood, repair the cabin, and keep the loop moving."
		"loop_forest_join":
			title = "Tutorial: Silas Joins"
			template = "Silas joins the party after you open the forest.\n\nHe stays with the settlement and fights beside you from now on."
		"loop_forest_wood":
			title = "Tutorial: Forest Wood"
			template = "Now that the forest is open, use your Axe on the trees to chop Wood.\n\nWood repairs the cabin first. Once you can sleep, the farm can roll into a new day."
		"loop_sleep":
			title = "Tutorial: Cabin Sleep"
			template = "The cabin is repaired.\n\nAt Night, use the bed to sleep and begin the next day. Battles only open again after you rest."
		"loop_cooking":
			title = "Tutorial: Cooking"
			template = "Harvested crops can be cooked at the campfire.\n\n{loop_perk_rule}"
		"farm_controls":
			title = "Tutorial: Movement"
			template = "Move with {move}. Hold {run} to run, and press {confirm} near objects to interact."
		"farm_farming":
			title = "Tutorial: Farming"
			template = "Cycle tools with {tool_cycle}. Use the Hoe or Watering Can with {action}.\n\nTo plant, face a tilled soil tile and press {plant} to open the seed menu, then choose a seed."
		"meal_buff":
			title = "Tutorial: Meal Buffs"
			template = "{loop_perk_rule}\n\nPress {inventory} to open the menu, review the prepared perk in Party, then close the menu when you're ready to continue."
		"battle_savannah":
			title = "Tutorial: Savannah"
			template = "Savannah is your front line. Use {battle_cursor} to select her, then {battle_confirm} to move or attack.\n\nKeep her between the enemy and the rest of the party, and Harvest adjacent Healflowers when she needs HP back."
		"battle_silas":
			title = "Tutorial: Silas"
			template = "Silas attacks from range and wants a clear lane to fire.\n\nHunt is a bonus action that gives him +15 Hit and +20 Crit for this turn and the next one. Use it before key shots, keep him behind Savannah, and pick off enemies from safety."
		"battle_tera_bloom":
			title = "Tutorial: Tera"
			template = "Tera is fragile, but Bloom can shape the fight.\n\nUse Bloom to grow Healflowers near the front line so Savannah can Harvest them when the pressure starts."
		"battle_harvest":
			title = "Tutorial: Harvest"
			template = "Move Savannah next to a Healflower and choose Harvest to restore HP."
		_:
			return {}

	return {
		"id": card_id,
		"title": title,
		"card_layout": "battle" if card_id in ["battle_savannah", "battle_silas", "battle_tera_bloom", "battle_harvest"] else ("compact" if card_id == "loop_cooking" else "full"),
		"body": _format_template(template, {
			"confirm": get_confirm_label(),
			"move": get_move_label(),
			"run": get_action_label("run"),
			"action": get_action_label("action"),
			"plant": get_action_label("plant"),
			"tool_cycle": get_tool_cycle_label(),
			"inventory": get_action_label("menu_toggle"),
			"loop_perk_rule": Global.LOOP_PERK_RULE_TEXT if Global != null else "Meals grant a perk that lasts until your next battle.",
			"battle_confirm": get_battle_confirm_label(),
			"battle_cursor": get_battle_cursor_label(),
		}),
	}

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

	set_stage(DemoStage.MEAL_REVIEW)
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
		return get_action_label("interact")
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
		return _get_left_stick_label()

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

func get_battle_confirm_label() -> String:
	if current_input_mode == InputMode.CONTROLLER:
		return "press %s" % get_confirm_label()
	return "left click"

func get_battle_cursor_label() -> String:
	if current_input_mode == InputMode.CONTROLLER:
		return "the %s or D-Pad" % _get_left_stick_label()
	return "the mouse"

func show_demo_complete_card(parent: Node) -> void:
	if parent == null or not is_instance_valid(parent):
		return

	set_stage(DemoStage.DEMO_COMPLETE)

	var card = STORY_CARD_SCENE.instantiate()
	parent.add_child(card)
	card.configure({
		"title": "Demo Complete",
		"body": "The cabin stands, the road is stirring again, and word of the farm is beginning to spread.\n\nLife can still take root here. This is only the beginning.",
		"confirm_hint": "return to title",
		"allow_skip": false
	})
	card.confirmed.connect(_return_to_title_from_demo_complete)

func _return_to_title_from_demo_complete() -> void:
	if TransitionManager:
		TransitionManager.change_scene_path(TITLE_SCENE_PATH, 1.0)

func _get_stage_prompt_text(stage: DemoStage) -> String:
	match stage:
		DemoStage.INTRO:
			return "Objective: Find Tera."
		DemoStage.HARVEST_CROPS:
			return "Objective: Harvest the carrot and parsnip."
		DemoStage.LIGHT_CAMPFIRE:
			return "Objective: Light the campfire with %s." % get_confirm_label()
		DemoStage.COOK_MEAL:
			return "Objective: Cook Glazed Carrots at the campfire."
		DemoStage.EAT_MEAL:
			return "Objective: Eat the Glazed Carrots from the menu. Press %s to open it." % get_action_label("menu_toggle")
		DemoStage.MEAL_REVIEW:
			return "Objective: Review your prepared perk in Party. Press %s to open the menu." % get_action_label("menu_toggle")
		DemoStage.BATTLE_TUTORIAL, DemoStage.BLOOM_TUTORIAL:
			return "Objective: Drive off the bandits."
		DemoStage.GATHER_MATERIALS:
			return "Objective: Gather %d Wood and %d Stone in the forest." % [Global.DEMO_CABIN_WOOD_REQUIRED, Global.DEMO_CABIN_STONE_REQUIRED]
		DemoStage.RETURN_TO_FARM:
			return "Objective: Return to the farm with the materials."
		DemoStage.CABIN_COMPLETE:
			return "Objective: Try the cabin door, then press %s to settle in for the night." % get_action_label("time_skip")
		_:
			return ""

func _resolve_prompt(prompt_id: String, replacements: Dictionary = {}) -> String:
	var template := ""
	match prompt_id:
		"battle_defeat_enemies":
			template = "Objective: Drive off the bandits."
		"farm_find_tera":
			template = "Objective: Find Tera."
		"farm_open_chest":
			template = "Objective: Open the old chest by the ruined field."
		"farm_search_forest":
			template = "Objective: Search the forest for seeds. Head through the trees and look deeper inside."
		"farm_gather_materials":
			template = "Objective: Gather %d Wood and %d Stone in the forest." % [Global.DEMO_CABIN_WOOD_REQUIRED, Global.DEMO_CABIN_STONE_REQUIRED]
		"farm_return_with_materials":
			template = "Objective: Return to the farm with the gathered materials."
		"farm_sleep_in_cabin":
			template = "Objective: Try the cabin door, then press {time_skip} to settle in for the night."
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
	merged["time_skip"] = get_action_label("time_skip")
	return _format_template(template, merged)

func _format_template(template: String, replacements: Dictionary) -> String:
	var resolved := template
	for key in replacements.keys():
		resolved = resolved.replace("{" + String(key) + "}", String(replacements[key]))
	return resolved

func _resolve_tutorial_host(parent: Node) -> Node:
	if parent != null and is_instance_valid(parent):
		if parent is CanvasLayer or parent is Control:
			return parent

		var direct_host := parent.get_node_or_null("DemoOverlayLayer")
		if direct_host is CanvasLayer or direct_host is Control:
			return direct_host

		direct_host = parent.get_node_or_null("CanvasLayer")
		if direct_host is CanvasLayer or direct_host is Control:
			return direct_host

		var parent_node := parent.get_parent()
		if parent_node != null and is_instance_valid(parent_node):
			if parent_node is CanvasLayer or parent_node is Control:
				return parent_node
			direct_host = parent_node.get_node_or_null("DemoOverlayLayer")
			if direct_host is CanvasLayer or direct_host is Control:
				return direct_host
			direct_host = parent_node.get_node_or_null("CanvasLayer")
			if direct_host is CanvasLayer or direct_host is Control:
				return direct_host

	var current_scene := get_tree().current_scene
	if current_scene != null and is_instance_valid(current_scene):
		if current_scene is CanvasLayer or current_scene is Control:
			return current_scene

		var scene_host := current_scene.get_node_or_null("DemoOverlayLayer")
		if scene_host is CanvasLayer or scene_host is Control:
			return scene_host
		scene_host = current_scene.get_node_or_null("CanvasLayer")
		if scene_host is CanvasLayer or scene_host is Control:
			return scene_host

	return current_scene

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
		return _get_controller_axis_label(motion_event.axis)

	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		return _get_controller_button_label(button_event.button_index)

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
			return "Mouse Wheel Up"
		&"tool_backward":
			return "Mouse Wheel Down"
		&"confirm", &"interact":
			return "E"
		_:
			return String(action_name).capitalize()

func _controller_fallback_label(action_name: StringName) -> String:
	match action_name:
		&"confirm", &"interact", &"ui_accept":
			return _get_controller_button_label(JOY_BUTTON_A)
		&"cancel", &"ui_cancel":
			return _get_controller_button_label(JOY_BUTTON_B)
		&"menu_toggle":
			return _get_controller_button_label(JOY_BUTTON_BACK)
		&"run":
			return _get_controller_axis_label(JOY_AXIS_TRIGGER_LEFT)
		&"action":
			return _get_controller_axis_label(JOY_AXIS_TRIGGER_RIGHT)
		&"plant":
			return _get_controller_button_label(JOY_BUTTON_A)
		&"tool_forward":
			return _get_controller_button_label(JOY_BUTTON_RIGHT_SHOULDER)
		&"tool_backward":
			return _get_controller_button_label(JOY_BUTTON_LEFT_SHOULDER)
		&"time_skip":
			return _get_controller_button_label(JOY_BUTTON_X)
		_:
			return String(action_name).capitalize()

func _update_controller_family(device: int) -> bool:
	var resolved_device := _resolve_controller_device(device)
	var next_family := _detect_controller_family(resolved_device)
	var did_change := resolved_device != _active_controller_device or next_family != _controller_family
	_active_controller_device = resolved_device
	_controller_family = next_family
	return did_change

func _resolve_controller_device(device: int) -> int:
	if device >= 0:
		return device

	var connected := Input.get_connected_joypads()
	if not connected.is_empty():
		return int(connected[0])
	return -1

func _detect_controller_family(device: int) -> ControllerFamily:
	if device < 0:
		return ControllerFamily.GENERIC

	var joy_name := Input.get_joy_name(device).to_lower()
	if joy_name.contains("playstation") or joy_name.contains("dualsense") or joy_name.contains("dualshock") or joy_name.contains("ps5") or joy_name.contains("ps4") or joy_name.contains("wireless controller") or joy_name.contains("sony"):
		return ControllerFamily.PLAYSTATION
	return ControllerFamily.GENERIC

func _get_left_stick_label() -> String:
	return "Left Stick"

func _get_right_stick_label() -> String:
	return "Right Stick"

func _get_controller_axis_label(axis: int) -> String:
	match axis:
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
			return _get_left_stick_label()
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
			return _get_right_stick_label()
		JOY_AXIS_TRIGGER_LEFT:
			return "L2"
		JOY_AXIS_TRIGGER_RIGHT:
			return "R2"
		_:
			return "Stick"

func _get_controller_button_label(button_index: int) -> String:
	if _controller_family == ControllerFamily.PLAYSTATION:
		match button_index:
			JOY_BUTTON_A:
				return "Cross"
			JOY_BUTTON_B:
				return "Circle"
			JOY_BUTTON_X:
				return "Square"
			JOY_BUTTON_Y:
				return "Triangle"
			JOY_BUTTON_LEFT_SHOULDER:
				return "L1"
			JOY_BUTTON_RIGHT_SHOULDER:
				return "R1"
			JOY_BUTTON_BACK:
				return "Create"
			JOY_BUTTON_START:
				return "Options"
			_:
				return _get_generic_controller_button_label(button_index)

	return _get_generic_controller_button_label(button_index)

func _get_generic_controller_button_label(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A:
			return "A"
		JOY_BUTTON_B:
			return "B"
		JOY_BUTTON_X:
			return "X"
		JOY_BUTTON_Y:
			return "Y"
		JOY_BUTTON_LEFT_SHOULDER:
			return "LB"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB"
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
			return "Pad %d" % button_index
