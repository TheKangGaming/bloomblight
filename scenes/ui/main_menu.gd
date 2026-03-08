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
@onready var lbl_hp: RichTextLabel = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblHP
@onready var lbl_dmg: RichTextLabel = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblDMG
@onready var lbl_def: RichTextLabel = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblDEF
@onready var lbl_class: Label = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblClass
@onready var lbl_level: Label = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/StatsColumn/LblLevel

# Column 3: Equipment + Meal
@onready var slot_weapon: TextureRect = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/EquipMealColumn/EquipmentSection/EquipmentSlots/SlotWeapon
@onready var slot_armor: TextureRect = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/EquipMealColumn/EquipmentSection/EquipmentSlots/SlotArmor
@onready var slot_accessory: TextureRect = $CenterContainer/TabContainer/Status/MarginContainer/HBoxContainer/EquipMealColumn/EquipmentSection/EquipmentSlots/SlotAccessory
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
	var player_unit := _find_player_unit()
	var class_data := _resolve_player_class_data(player_unit)
	var weapon := _resolve_player_weapon(player_unit)
	var uses_magic_damage := _class_uses_magic_damage(class_data)

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

	var max_hp_value := int(permanent_stats.get("MAX_HP", permanent_stats.get("HP", 0))) + int(temporary_modifiers.get("MAX_HP", 0)) + (int(temporary_modifiers.get("VIT", 0)) * 2)
	lbl_hp.bbcode_text = "HP: %d/%d" % [int(permanent_stats.get("HP", 0)), max_hp_value]
	lbl_def.bbcode_text = format_stat.call("DEF", int(permanent_stats.get("DEF", 0)), int(temporary_modifiers.get("DEF", 0)))
	lbl_dmg.bbcode_text = _build_attack_preview_text(player_unit, permanent_stats, temporary_modifiers, weapon, uses_magic_damage)

	lbl_level.text = "Level: %d" % Global.get_player_level()
	lbl_class.text = "Class: %s" % _resolve_player_class_name()
	_update_equipment_visuals(player_unit, weapon)
	
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

func _find_player_unit() -> Unit:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return null

	for node in scene_root.find_children("*", "Unit", true, false):
		var unit := node as Unit
		if unit != null and unit.is_player:
			return unit

	return null


func _build_attack_preview_text(player_unit: Unit, permanent_stats: Dictionary, temporary_modifiers: Dictionary, weapon: WeaponData, uses_magic_damage: bool) -> String:
	var attack_stat_name := "INT" if uses_magic_damage else "STR"
	var attack_stat_total := int(permanent_stats.get(attack_stat_name, 0)) + int(temporary_modifiers.get(attack_stat_name, 0))

	if player_unit != null:
		attack_stat_total = player_unit.int_stat if uses_magic_damage else player_unit.strength

	var weapon_bonus_key := "intelligence" if uses_magic_damage else "strength"
	var weapon_bonus := 0
	var weapon_might := 2
	if weapon != null:
		weapon_might = int(weapon.might)
		weapon_bonus = int(weapon.stat_bonuses.get(weapon_bonus_key, 0))

	var attack_total := maxi(0, attack_stat_total + weapon_bonus + weapon_might)
	var stat_component_label := "%s %d" % [attack_stat_name, attack_stat_total]
	if weapon_bonus != 0:
		stat_component_label += " (%+d)" % weapon_bonus

	return "ATK: %d\n[color=gray]%s + MT %d[/color]" % [attack_total, stat_component_label, weapon_might]


func _resolve_player_weapon(player_unit: Unit) -> WeaponData:
	if player_unit != null and player_unit.character_data != null and player_unit.character_data.equipped_weapon != null:
		return player_unit.character_data.equipped_weapon

	var global_weapon = Global.equipment.get("Weapon", null)
	if global_weapon is WeaponData:
		return global_weapon

	return _resolve_player_weapon_from_combat_template()


func _resolve_player_weapon_from_combat_template() -> WeaponData:
	var combat_template := load("res://scenes/level/CombatMap_1.tscn") as PackedScene
	if combat_template == null:
		return null

	var combat_root := combat_template.instantiate()
	if combat_root == null:
		return null

	var savannah := combat_root.get_node_or_null("GameBoard/Savannah")
	if savannah == null:
		combat_root.queue_free()
		return null

	var character_data: CharacterData = savannah.get("character_data") as CharacterData
	if character_data != null and character_data.equipped_weapon != null:
		var template_weapon := character_data.equipped_weapon
		combat_root.queue_free()
		return template_weapon

	combat_root.queue_free()
	return null




func _resolve_player_armor_from_combat_template() -> ArmorData:
	var combat_template := load("res://scenes/level/CombatMap_1.tscn") as PackedScene
	if combat_template == null:
		return null

	var combat_root := combat_template.instantiate()
	if combat_root == null:
		return null

	var savannah := combat_root.get_node_or_null("GameBoard/Savannah")
	if savannah == null:
		combat_root.queue_free()
		return null

	var character_data: CharacterData = savannah.get("character_data") as CharacterData
	if character_data != null and character_data.equipped_armor != null:
		var template_armor := character_data.equipped_armor
		combat_root.queue_free()
		return template_armor

	combat_root.queue_free()
	return null


func _resolve_player_accessory_from_combat_template() -> AccessoryData:
	var combat_template := load("res://scenes/level/CombatMap_1.tscn") as PackedScene
	if combat_template == null:
		return null

	var combat_root := combat_template.instantiate()
	if combat_root == null:
		return null

	var savannah := combat_root.get_node_or_null("GameBoard/Savannah")
	if savannah == null:
		combat_root.queue_free()
		return null

	var character_data: CharacterData = savannah.get("character_data") as CharacterData
	if character_data != null and character_data.equipped_accessory != null:
		var template_accessory := character_data.equipped_accessory
		combat_root.queue_free()
		return template_accessory

	combat_root.queue_free()
	return null

func _resolve_player_class_data(player_unit: Unit) -> ClassData:
	if player_unit != null and player_unit.character_data != null and player_unit.character_data.class_data != null:
		return player_unit.character_data.class_data

	var combat_template := load("res://scenes/level/CombatMap_1.tscn") as PackedScene
	if combat_template == null:
		return null

	var combat_root := combat_template.instantiate()
	if combat_root == null:
		return null

	var savannah := combat_root.get_node_or_null("GameBoard/Savannah")
	if savannah == null:
		combat_root.queue_free()
		return null

	var character_data: CharacterData = savannah.get("character_data") as CharacterData
	if character_data != null and character_data.class_data != null:
		var template_class_data := character_data.class_data
		combat_root.queue_free()
		return template_class_data

	combat_root.queue_free()
	return null


func _class_uses_magic_damage(class_data: ClassData) -> bool:
	if class_data == null:
		return false

	var damage_stat := String(class_data.primary_damage_stat).to_lower()
	if damage_stat == "intelligence" or damage_stat == "int":
		return true
	if damage_stat == "strength" or damage_stat == "str":
		return false

	return String(class_data.role).to_lower().contains("mage")


func _resolve_equipment_icon(slot_name: String, player_unit: Unit) -> Texture2D:
	var equipped_entry = Global.equipment.get(slot_name, null)
	if player_unit != null and player_unit.character_data != null:
		if slot_name == "Weapon" and player_unit.character_data.equipped_weapon != null:
			equipped_entry = player_unit.character_data.equipped_weapon
		elif slot_name == "Armor" and player_unit.character_data.equipped_armor != null:
			equipped_entry = player_unit.character_data.equipped_armor
		elif slot_name == "Accessory" and player_unit.character_data.equipped_accessory != null:
			equipped_entry = player_unit.character_data.equipped_accessory

	if equipped_entry is WeaponData:
		return equipped_entry.icon

	if equipped_entry is Resource and equipped_entry.get("icon") != null:
		return equipped_entry.get("icon")

	if equipped_entry is Dictionary and equipped_entry.has("icon"):
		var icon_entry = equipped_entry["icon"]
		if icon_entry is Texture2D:
			return icon_entry
		if icon_entry is String and not String(icon_entry).is_empty():
			return load(String(icon_entry))

	return null



func _build_weapon_tooltip_text(weapon: WeaponData) -> String:
	if weapon == null:
		return "Weapon"

	var lines: PackedStringArray = ["Weapon: %s" % String(weapon.weapon_name)]
	lines.append("MT %d | HIT %d | RNG %d" % [int(weapon.might), int(weapon.hit_rate), int(weapon.attack_range)])

	var bonus_labels := {
		"strength": "STR",
		"intelligence": "INT",
		"dexterity": "DEX",
		"speed": "SPD",
		"defense": "DEF",
		"magic_defense": "MDEF"
	}

	var bonus_parts: PackedStringArray = []
	for bonus_key in ["strength", "intelligence", "dexterity", "speed", "defense", "magic_defense"]:
		var bonus_value := int(weapon.stat_bonuses.get(bonus_key, 0))
		if bonus_value != 0:
			bonus_parts.append("%s %+d" % [String(bonus_labels.get(bonus_key, bonus_key.to_upper())), bonus_value])

	if not bonus_parts.is_empty():
		lines.append("Bonuses: " + ", ".join(bonus_parts))

	if not String(weapon.description).strip_edges().is_empty():
		lines.append(String(weapon.description))

	return "\n".join(lines)


func _build_generic_equipment_tooltip(item: Resource, fallback_label: String) -> String:
	if item == null:
		return fallback_label

	var stat_bonuses = item.get("stat_bonuses")
	var bonus_labels := {
		"strength": "STR",
		"intelligence": "INT",
		"dexterity": "DEX",
		"speed": "SPD",
		"defense": "DEF",
		"magic_defense": "MDEF"
	}

	var title := fallback_label
	if item is ArmorData:
		title = "Armor: %s" % String((item as ArmorData).armor_name)
	elif item is AccessoryData:
		title = "Accessory: %s" % String((item as AccessoryData).accessory_name)

	var lines: PackedStringArray = [title]
	if stat_bonuses is Dictionary:
		var bonus_parts: PackedStringArray = []
		for bonus_key in ["strength", "intelligence", "dexterity", "speed", "defense", "magic_defense"]:
			var bonus_value := int((stat_bonuses as Dictionary).get(bonus_key, 0))
			if bonus_value != 0:
				bonus_parts.append("%s %+d" % [String(bonus_labels.get(bonus_key, bonus_key.to_upper())), bonus_value])

		if not bonus_parts.is_empty():
			lines.append("Bonuses: " + ", ".join(bonus_parts))

	var description := String(item.get("description")).strip_edges()
	if not description.is_empty():
		lines.append(description)

	return "\n".join(lines)

func _update_equipment_visuals(player_unit: Unit, resolved_weapon: WeaponData = null) -> void:
	var weapon_icon := _resolve_equipment_icon("Weapon", player_unit)
	if weapon_icon == null and resolved_weapon != null:
		weapon_icon = resolved_weapon.icon
	var armor_icon := _resolve_equipment_icon("Armor", player_unit)
	var accessory_icon := _resolve_equipment_icon("Accessory", player_unit)

	var equipped_armor: Resource = Global.equipment.get("Armor", null)
	var equipped_accessory: Resource = Global.equipment.get("Accessory", null)
	if player_unit != null and player_unit.character_data != null:
		if player_unit.character_data.equipped_armor != null:
			equipped_armor = player_unit.character_data.equipped_armor
		if player_unit.character_data.equipped_accessory != null:
			equipped_accessory = player_unit.character_data.equipped_accessory
	else:
		if equipped_armor == null:
			equipped_armor = _resolve_player_armor_from_combat_template()
		if equipped_accessory == null:
			equipped_accessory = _resolve_player_accessory_from_combat_template()

	slot_weapon.texture = weapon_icon
	slot_armor.texture = armor_icon
	slot_accessory.texture = accessory_icon

	slot_weapon.tooltip_text = _build_weapon_tooltip_text(resolved_weapon)
	slot_armor.tooltip_text = _build_generic_equipment_tooltip(equipped_armor, "Armor")
	slot_accessory.tooltip_text = _build_generic_equipment_tooltip(equipped_accessory, "Accessory")
