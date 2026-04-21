extends Control

signal menu_opened
signal menu_closed
signal status_tab_viewed

const SLOT_SCENE := preload("res://scenes/ui/inventory_slot.tscn")
const CONTROLLER_SCROLL_THRESHOLD := 0.35
const CONTROLLER_SCROLL_STEP := 42.0
const CALENDAR_GRID_COLUMNS := 7
const CALENDAR_GRID_DAYS := 28
const LOOP_STAGE_COLUMNS := 5
const LOOP_STAGE_COUNT := 10
const LOOP_STAGE_CHECK_TEXTURE := preload("res://graphics/animations/ui/symbol_success_001_large_green/spritesheet.png")
const LOOP_STAGE_CHECK_FRAME_SIZE := Vector2i(80, 80)
const LOOP_STAGE_CHECK_FRAMES := 60
const LOOP_STAGE_CHECK_HOLD_FRAME := 30

enum MenuSection { PARTY, INVENTORY, CALENDAR }

@onready var section_title: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/SectionTitle
@onready var party_button: Button = $CenterContainer/MenuPanel/MarginContainer/RootRow/NavColumn/NavButtons/PartyButton
@onready var inventory_button: Button = $CenterContainer/MenuPanel/MarginContainer/RootRow/NavColumn/NavButtons/InventoryButton
@onready var calendar_button: Button = $CenterContainer/MenuPanel/MarginContainer/RootRow/NavColumn/NavButtons/CalendarButton

@onready var party_section: Control = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection
@onready var inventory_section: Control = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/InventorySection
@onready var calendar_section: Control = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection

@onready var roster_list: VBoxContainer = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/RosterColumn/RosterScroll/RosterList
@onready var portrait_rect: TextureRect = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/CharacterHeader/HeaderTopRow/PortraitFrame/Portrait
@onready var character_name_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/CharacterHeader/HeaderTopRow/HeaderInfo/CharacterName
@onready var character_role_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/CharacterHeader/HeaderTopRow/HeaderInfo/CharacterRole
@onready var character_level_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/CharacterHeader/HeaderTopRow/HeaderInfo/CharacterLevel
@onready var meal_status_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/CharacterHeader/MealStatus
@onready var status_view: Control = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/PartyDetailStack/StatusView
@onready var equipment_view: ScrollContainer = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/PartyDetailStack/EquipmentView
@onready var weapon_slot_button: Button = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/PartyDetailStack/EquipmentView/EquipmentContent/EquipmentBody/EquipmentSlots/WeaponSlotButton
@onready var armor_slot_button: Button = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/PartyDetailStack/EquipmentView/EquipmentContent/EquipmentBody/EquipmentSlots/ArmorSlotButton
@onready var accessory_slot_button: Button = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/PartyDetailStack/EquipmentView/EquipmentContent/EquipmentBody/EquipmentSlots/AccessorySlotButton
@onready var equipment_slot_heading_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/PartyDetailStack/EquipmentView/EquipmentContent/EquipmentBody/EquipmentPicker/EquipmentSlotHeading
@onready var equipped_now_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/PartyDetailStack/EquipmentView/EquipmentContent/EquipmentBody/EquipmentPicker/EquippedNowLabel
@onready var equipment_choice_list: ItemList = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/PartyDetailStack/EquipmentView/EquipmentContent/EquipmentBody/EquipmentPicker/EquipmentChoiceList
@onready var equipment_detail_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/PartySection/HBoxContainer/DetailColumn/PartyDetailStack/EquipmentView/EquipmentContent/EquipmentBody/EquipmentPicker/EquipmentDetailLabel

@onready var items_view: ScrollContainer = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/InventorySection/VBoxContainer/InventoryDetailStack/ItemsView
@onready var inventory_grid: GridContainer = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/InventorySection/VBoxContainer/InventoryDetailStack/ItemsView/ItemsMargin/Grid

@onready var calendar_kicker_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection/CalendarContent/CalendarPage/CalendarMargin/CalendarLayout/CalendarHeader/CalendarKickerLabel
@onready var calendar_season_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection/CalendarContent/CalendarPage/CalendarMargin/CalendarLayout/CalendarHeader/CalendarSeasonLabel
@onready var calendar_day_summary_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection/CalendarContent/CalendarPage/CalendarMargin/CalendarLayout/CalendarHeader/CalendarDaySummaryLabel
@onready var calendar_grid: GridContainer = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection/CalendarContent/CalendarPage/CalendarMargin/CalendarLayout/CalendarGrid
@onready var calendar_note_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection/CalendarContent/CalendarPage/CalendarMargin/CalendarLayout/CalendarFooter/CalendarNoteLabel
@onready var calendar_flavor_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection/CalendarContent/CalendarPage/CalendarMargin/CalendarLayout/CalendarFooter/CalendarFlavorLabel
@onready var calendar_legend_panel: PanelContainer = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection/CalendarContent/CalendarPage/CalendarMargin/CalendarLayout/CalendarFooter/CalendarLegendPanel
@onready var calendar_past_legend_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection/CalendarContent/CalendarPage/CalendarMargin/CalendarLayout/CalendarFooter/CalendarLegendPanel/CalendarLegendMargin/CalendarLegendRow/PastLegendLabel
@onready var calendar_today_legend_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection/CalendarContent/CalendarPage/CalendarMargin/CalendarLayout/CalendarFooter/CalendarLegendPanel/CalendarLegendMargin/CalendarLegendRow/TodayLegendLabel
@onready var calendar_upcoming_legend_label: Label = $CenterContainer/MenuPanel/MarginContainer/RootRow/ContentColumn/ContentStack/CalendarSection/CalendarContent/CalendarPage/CalendarMargin/CalendarLayout/CalendarFooter/CalendarLegendPanel/CalendarLegendMargin/CalendarLegendRow/UpcomingLegendLabel

var _current_section := MenuSection.PARTY
var _selected_party_index := 0
var _last_opened_section := MenuSection.PARTY
var _status_tab_highlight_enabled := false
var _status_tab_highlight_tween: Tween = null
var _equipment_refresh_in_progress := false
var _active_equipment_slot := "Weapon"
var _party_equipment_picker_open := false
var _equipment_choices_by_slot := {
	"Weapon": [],
	"Armor": [],
	"Accessory": [],
}
var _party_overview_root: ScrollContainer = null
var _party_overview_content: VBoxContainer = null
var _party_stats_grid: GridContainer = null
var _party_abilities_list: VBoxContainer = null
var _party_equipment_buttons: Dictionary = {}
var _roster_button_cache: Array[Button] = []
var _inventory_slot_cache: Array[Control] = []
var _inventory_slot_order: Array[int] = []
var _calendar_day_panels: Array[PanelContainer] = []
var _calendar_day_labels: Array[Label] = []
var _calendar_day_checks: Array[TextureRect] = []
var _last_rendered_loop_stage := -1

func _ui_sound_manager() -> Node:
	return get_node_or_null("/root/UISoundManager")

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	Global.inventory_updated.connect(update_inventory)
	Global.stats_updated.connect(_refresh_all_views)
	if ProgressionService != null:
		if not ProgressionService.party_roster_changed.is_connected(_refresh_all_views):
			ProgressionService.party_roster_changed.connect(_refresh_all_views)
		if not ProgressionService.equipment_catalog_changed.is_connected(_refresh_all_views):
			ProgressionService.equipment_catalog_changed.connect(_refresh_all_views)

	_build_party_overview_ui()
	_configure_demo_menu_layout()
	_wire_navigation_buttons()
	_wire_party_controls()
	_wire_inventory_controls()
	_wire_calendar_controls()
	_build_calendar_grid()
	_update_section_visibility()
	_refresh_all_views()

func _shortcut_input(event: InputEvent) -> void:
	if _handle_menu_toggle_input(event):
		return

func _input(event: InputEvent) -> void:
	if _handle_menu_toggle_input(event):
		return
	if not visible:
		return

	if _handle_controller_scroll(event):
		get_viewport().set_input_as_handled()
		return

	if _is_mouse_wheel_event(event):
		return

	if _handle_manual_menu_accept(event):
		get_viewport().set_input_as_handled()
	elif _handle_manual_menu_navigation(event):
		get_viewport().set_input_as_handled()

func _handle_menu_toggle_input(event: InputEvent) -> bool:
	if _is_system_menu_blocking():
		return false

	if event.is_action_pressed("menu_toggle"):
		toggle_menu()
		get_viewport().set_input_as_handled()
		return true

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		toggle_menu()
		get_viewport().set_input_as_handled()
		return true

	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel")):
		if _try_close_equipment_picker():
			get_viewport().set_input_as_handled()
			return true
		if _try_step_back_within_menu():
			get_viewport().set_input_as_handled()
			return true
		toggle_menu()
		get_viewport().set_input_as_handled()
		return true

	return false

func _handle_manual_menu_accept(event: InputEvent) -> bool:
	if not (event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")):
		return false
	var focus_owner: Control = get_viewport().gui_get_focus_owner() as Control
	if focus_owner == null or not _is_in_active_content(focus_owner):
		return false
	if _is_section_root_focus(focus_owner):
		var focused_section: int = _get_section_from_root_button(focus_owner)
		if focused_section >= 0 and _current_section != focused_section:
			_set_section(focused_section)
			return true
		var inward_target := _get_section_entry_target(focused_section if focused_section >= 0 else _current_section)
		if inward_target != null and inward_target != focus_owner:
			inward_target.grab_focus()
			return true
	if focus_owner == equipment_choice_list:
		_activate_selected_equipment_choice()
		return true
	return false

func _handle_manual_menu_navigation(event: InputEvent) -> bool:
	var focus_owner: Control = get_viewport().gui_get_focus_owner() as Control
	if focus_owner == null or not _is_in_active_content(focus_owner):
		return false
	if focus_owner == party_button and _is_action_pressed(event, [&"right", &"ui_right"]):
		var roster_target := _get_selected_roster_button()
		if roster_target != null:
			roster_target.grab_focus()
			return true
	if focus_owner == inventory_button and (_is_action_pressed(event, [&"down", &"ui_down"]) or _is_action_pressed(event, [&"right", &"ui_right"])):
		var inventory_slot := _get_first_inventory_slot()
		if inventory_slot != null:
			inventory_slot.grab_focus()
			return true
	return false

func _is_mouse_wheel_event(event: InputEvent) -> bool:
	if event is not InputEventMouseButton:
		return false
	var mouse_button := event as InputEventMouseButton
	if not mouse_button.pressed:
		return false
	return mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN

func _handle_controller_scroll(event: InputEvent) -> bool:
	if event is not InputEventJoypadMotion:
		return false
	var joy_motion := event as InputEventJoypadMotion
	if joy_motion.axis != JOY_AXIS_RIGHT_Y:
		return false
	if absf(joy_motion.axis_value) < CONTROLLER_SCROLL_THRESHOLD:
		return false
	var active_scroll := _get_active_scroll_container()
	if active_scroll == null or not active_scroll.visible:
		return false
	active_scroll.scroll_vertical = maxi(0, active_scroll.scroll_vertical + int(round(joy_motion.axis_value * CONTROLLER_SCROLL_STEP)))
	return true

func _get_active_scroll_container() -> ScrollContainer:
	match _current_section:
		MenuSection.PARTY:
			return equipment_view if _party_equipment_picker_open else _party_overview_root
		MenuSection.INVENTORY:
			return items_view
		MenuSection.CALENDAR:
			return null
	return null

func _is_system_menu_blocking() -> bool:
	var system_menu := get_parent().get_node_or_null("OverworldSystemMenu") if get_parent() != null else null
	return system_menu != null and system_menu.visible

func toggle_menu() -> void:
	var opening := not visible
	var ui_sounds := _ui_sound_manager()
	visible = opening
	get_tree().paused = visible
	_refresh_all_views()
	if ui_sounds:
		ui_sounds.play_inventory_toggle()

	if visible:
		open_menu_to_tab(_last_opened_section if _last_opened_section in [MenuSection.PARTY, MenuSection.INVENTORY, MenuSection.CALENDAR] else MenuSection.PARTY)
		menu_opened.emit()
		if ui_sounds:
			ui_sounds.suppress_browse_once()
	else:
		_complete_status_review_if_needed(true)
		_stop_status_highlight()
		menu_closed.emit()

func open_status_tab() -> void:
	var was_visible := visible
	visible = true
	get_tree().paused = true
	_current_section = MenuSection.PARTY
	_last_opened_section = MenuSection.PARTY
	_party_equipment_picker_open = false
	_update_section_visibility()
	_refresh_all_views()
	_complete_status_review_if_needed()
	if not was_visible:
		var ui_sounds := _ui_sound_manager()
		if ui_sounds:
			ui_sounds.play_inventory_toggle()
			ui_sounds.suppress_browse_once()
		menu_opened.emit()
	_focus_section_root_deferred()

func open_menu_to_tab(tab_index: int) -> void:
	var was_visible := visible
	visible = true
	get_tree().paused = true
	_current_section = clampi(tab_index, 0, 2) as MenuSection
	_last_opened_section = _current_section
	if _current_section != MenuSection.PARTY:
		_party_equipment_picker_open = false
	_update_section_visibility()
	_refresh_all_views()
	_complete_status_review_if_needed()
	if not was_visible:
		var ui_sounds := _ui_sound_manager()
		if ui_sounds:
			ui_sounds.play_inventory_toggle()
			ui_sounds.suppress_browse_once()
		menu_opened.emit()
	_focus_section_root_deferred()

func set_status_tab_highlight(enabled: bool) -> void:
	_status_tab_highlight_enabled = enabled
	_refresh_status_highlight()

func update_inventory() -> void:
	if inventory_grid == null:
		return
	if not is_inside_tree():
		return

	var visible_entries: Array[Dictionary] = []
	for raw_item_key in Global.inventory:
		var item_enum := _resolve_inventory_item_enum(raw_item_key)
		if item_enum < 0:
			continue
		var count := int(Global.inventory[raw_item_key])
		if count <= 0:
			continue
		visible_entries.append({
			"item": item_enum,
			"count": count,
		})

	var desired_order: Array[int] = []
	for entry_variant in visible_entries:
		desired_order.append(int((entry_variant as Dictionary).get("item", -1)))

	if desired_order != _inventory_slot_order:
		_clear_container_children(inventory_grid)
		_inventory_slot_cache.clear()
		_inventory_slot_order.clear()
		for entry_variant in visible_entries:
			var entry := entry_variant as Dictionary
			var slot = SLOT_SCENE.instantiate()
			inventory_grid.add_child(slot)
			slot.setup(int(entry.get("item", 0)), int(entry.get("count", 0)))
			_inventory_slot_cache.append(slot)
			_inventory_slot_order.append(int(entry.get("item", -1)))
		return

	for index in range(mini(visible_entries.size(), _inventory_slot_cache.size())):
		var entry := visible_entries[index] as Dictionary
		var slot := _inventory_slot_cache[index]
		if slot != null and is_instance_valid(slot):
			slot.setup(int(entry.get("item", 0)), int(entry.get("count", 0)))

func _resolve_inventory_item_enum(raw_item_key: Variant) -> int:
	if raw_item_key is int:
		return int(raw_item_key)
	var key_name := String(raw_item_key)
	if key_name.is_empty():
		return -1
	var item_keys := Global.Items.keys()
	return item_keys.find(key_name)

func _refresh_all_views() -> void:
	_refresh_roster_buttons()
	_refresh_party_view()
	update_inventory()
	_refresh_calendar_view()
	_refresh_status_highlight()
	_rebuild_focus_graph()

func _wire_navigation_buttons() -> void:
	_wire_browse_sound(party_button, false)
	_wire_browse_sound(inventory_button, false)
	_wire_browse_sound(calendar_button, false)
	party_button.pressed.connect(func() -> void: _set_section(MenuSection.PARTY))
	inventory_button.pressed.connect(func() -> void: _set_section(MenuSection.INVENTORY))
	calendar_button.pressed.connect(func() -> void: _set_section(MenuSection.CALENDAR))

func _wire_party_controls() -> void:
	for slot_name in ["Weapon", "Armor", "Accessory"]:
		var slot_button := _get_equipment_slot_button(slot_name)
		_wire_browse_sound(slot_button, false)
		slot_button.focus_entered.connect(_on_equipment_slot_focus_entered.bind(slot_name))
		slot_button.mouse_entered.connect(_on_equipment_slot_mouse_entered.bind(slot_name))
		slot_button.pressed.connect(_on_equipment_slot_pressed.bind(slot_name))

	_wire_browse_sound(equipment_choice_list, false)
	equipment_choice_list.focus_mode = Control.FOCUS_ALL
	equipment_choice_list.item_selected.connect(_on_equipment_choice_selected)
	equipment_choice_list.item_activated.connect(_on_equipment_choice_activated)

func _wire_inventory_controls() -> void:
	pass

func _wire_calendar_controls() -> void:
	_wire_browse_sound(calendar_legend_panel, false)

func _configure_demo_menu_layout() -> void:
	_refresh_navigation_labels()

func _build_party_overview_ui() -> void:
	if _party_overview_root != null and is_instance_valid(_party_overview_root):
		return

	_party_overview_root = ScrollContainer.new()
	_party_overview_root.follow_focus = true
	_party_overview_root.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_party_overview_root.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_party_overview_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_party_overview_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status_view.add_child(_party_overview_root)

	_party_overview_content = VBoxContainer.new()
	_party_overview_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_party_overview_content.add_theme_constant_override("separation", 14)
	_party_overview_root.add_child(_party_overview_content)

	var stats_panel := _build_overview_section_panel("Battle Read")
	_party_overview_content.add_child(stats_panel)
	var stats_layout := stats_panel.get_node("SectionMargin/SectionLayout") as VBoxContainer
	_party_stats_grid = GridContainer.new()
	_party_stats_grid.columns = 4
	_party_stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_party_stats_grid.add_theme_constant_override("h_separation", 14)
	_party_stats_grid.add_theme_constant_override("v_separation", 8)
	stats_layout.add_child(_party_stats_grid)

	var abilities_panel := _build_overview_section_panel("Abilities")
	_party_overview_content.add_child(abilities_panel)
	var abilities_layout := abilities_panel.get_node("SectionMargin/SectionLayout") as VBoxContainer
	_party_abilities_list = VBoxContainer.new()
	_party_abilities_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_party_abilities_list.add_theme_constant_override("separation", 10)
	abilities_layout.add_child(_party_abilities_list)

	var equipment_panel := _build_overview_section_panel("Equipment")
	_party_overview_content.add_child(equipment_panel)
	var equipment_layout := equipment_panel.get_node("SectionMargin/SectionLayout") as VBoxContainer
	for slot_name in ["Weapon", "Armor", "Accessory"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 74)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_open_party_equipment_picker.bind(slot_name))
		_wire_browse_sound(button, false)
		equipment_layout.add_child(button)
		_party_equipment_buttons[slot_name] = button

func _build_overview_section_panel(title_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.09, 0.06, 0.96)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.46, 0.36, 0.18, 1.0)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.name = "SectionMargin"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "SectionLayout"
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 24)
	layout.add_child(heading)
	return panel

func _set_section(section: int) -> void:
	var next_section := clampi(section, 0, 2) as MenuSection
	if _current_section == next_section:
		return
	_current_section = next_section
	_last_opened_section = _current_section
	if _current_section != MenuSection.PARTY:
		_party_equipment_picker_open = false
	var ui_sounds := _ui_sound_manager()
	if visible and ui_sounds:
		ui_sounds.play_tab_switch()
	_update_section_visibility()
	_refresh_all_views()
	_complete_status_review_if_needed()
	_focus_section_root_deferred()

func _update_section_visibility() -> void:
	party_section.visible = _current_section == MenuSection.PARTY
	inventory_section.visible = _current_section == MenuSection.INVENTORY
	calendar_section.visible = _current_section == MenuSection.CALENDAR

	status_view.visible = _current_section == MenuSection.PARTY and not _party_equipment_picker_open
	equipment_view.visible = _current_section == MenuSection.PARTY and _party_equipment_picker_open

	items_view.visible = _current_section == MenuSection.INVENTORY

	_refresh_navigation_labels()
	_update_button_state(party_button, _current_section == MenuSection.PARTY)
	_update_button_state(inventory_button, _current_section == MenuSection.INVENTORY)
	_update_button_state(calendar_button, _current_section == MenuSection.CALENDAR)

func _refresh_navigation_labels() -> void:
	if inventory_button != null:
		inventory_button.text = "Items"
	if calendar_button != null:
		calendar_button.text = "Stages" if Global != null and Global.loop_hub_mode_active else "Calendar"
	if section_title == null:
		return
	match _current_section:
		MenuSection.PARTY:
			section_title.text = "Party"
		MenuSection.INVENTORY:
			section_title.text = "Items"
		MenuSection.CALENDAR:
			section_title.text = "Stages" if Global != null and Global.loop_hub_mode_active else "Calendar"

func _update_button_state(button: BaseButton, is_active: bool) -> void:
	if button == null:
		return
	button.modulate = Color(1.0, 0.95, 0.76, 1.0) if is_active else Color(1, 1, 1, 1)

func _refresh_roster_buttons() -> void:
	if roster_list == null:
		return

	var roster := _get_party_roster()
	if roster.is_empty():
		_clear_container_children(roster_list)
		_roster_button_cache.clear()
		return

	_selected_party_index = clampi(_selected_party_index, 0, roster.size() - 1)
	var desired_labels: Array[String] = []
	for member in roster:
		desired_labels.append(String(member.display_name))
	var needs_rebuild := desired_labels.size() != _roster_button_cache.size()
	if not needs_rebuild:
		for index in range(desired_labels.size()):
			var cached_button := _roster_button_cache[index]
			if cached_button == null or not is_instance_valid(cached_button) or cached_button.text != desired_labels[index]:
				needs_rebuild = true
				break

	if needs_rebuild:
		_clear_container_children(roster_list)
		_roster_button_cache.clear()
	for index in range(roster.size()):
		var member: CharacterData = roster[index]
		var button: Button = null
		if needs_rebuild:
			button = Button.new()
			button.text = String(member.display_name)
			button.custom_minimum_size = Vector2(0, 54)
			button.add_theme_font_size_override("font_size", 22)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_wire_browse_sound(button, false)
			button.pressed.connect(_on_roster_button_pressed.bind(index))
			roster_list.add_child(button)
			_roster_button_cache.append(button)
		else:
			button = _roster_button_cache[index]
		_update_button_state(button, index == _selected_party_index)

func _on_roster_button_pressed(index: int) -> void:
	_selected_party_index = index
	var ui_sounds := _ui_sound_manager()
	if visible and ui_sounds:
		ui_sounds.play_browse_general(self)
	_refresh_party_view()
	call_deferred("_focus_selected_roster_button")

func _refresh_party_view() -> void:
	var character := _get_selected_party_member()
	if character == null:
		return

	character_name_label.text = String(character.display_name)
	character_role_label.text = _build_character_role_text(character)
	character_level_label.text = "Level %d" % _resolve_character_level(character)
	portrait_rect.texture = _resolve_character_portrait(character)
	meal_status_label.text = _build_meal_status_text(character)
	_refresh_party_overview(character)
	_refresh_equipment_panel(character)

func _refresh_equipment_panel(character: CharacterData) -> void:
	_equipment_refresh_in_progress = true
	for slot_name in ["Weapon", "Armor", "Accessory"]:
		var slot_button := _get_equipment_slot_button(slot_name)
		var overview_button := _party_equipment_buttons.get(slot_name, null) as Button
		var equipped_item := _get_equipped_item_for_slot(character, slot_name)
		_equipment_choices_by_slot[slot_name] = _build_equipment_choices(character, slot_name)
		_refresh_equipment_slot_button(slot_button, slot_name, equipped_item)
		_refresh_equipment_slot_button(overview_button, slot_name, equipped_item)

	_refresh_equipment_picker(character)
	_equipment_refresh_in_progress = false

func _refresh_party_overview(character: CharacterData) -> void:
	if character == null:
		return
	var stats := _build_character_unit_stats(character)
	_rebuild_party_stats_grid(stats, character)
	_rebuild_party_abilities(character)

func _build_equipment_choices(character: CharacterData, slot_name: String) -> Array:
	var choices: Array = [null]
	var owned_equipment: Array = ProgressionService.get_owned_equipment(slot_name) if ProgressionService != null else []
	for item in owned_equipment:
		if slot_name == "Weapon" and character != null and ProgressionService != null and ProgressionService.has_method("can_character_equip_item") and not ProgressionService.can_character_equip_item(character, item):
			continue
		choices.append(item)
	return choices

func _refresh_equipment_slot_button(button: Button, slot_name: String, equipped_item: Resource) -> void:
	if button == null:
		return
	button.icon = _get_equipment_icon(equipped_item)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var equipped_label := _get_equipment_display_name(equipped_item, "") if equipped_item != null else "Empty"
	button.text = "%s\n%s" % [slot_name, equipped_label]
	_update_button_state(button, _active_equipment_slot == slot_name)

func _refresh_equipment_picker(character: CharacterData) -> void:
	if character == null:
		return
	var slot_name := _normalize_equipment_slot_name(_active_equipment_slot)
	var choices: Array = _equipment_choices_by_slot.get(slot_name, [null])
	equipment_slot_heading_label.text = "%s Slot" % slot_name
	equipped_now_label.text = "Currently equipped: %s" % _get_equipment_display_name(_get_equipped_item_for_slot(character, slot_name), "None")

	equipment_choice_list.clear()
	for item in choices:
		var entry_text := "Unequip"
		var entry_icon: Texture2D = null
		if item != null:
			entry_text = "%s%s" % [_get_equipment_display_name(item, slot_name), _build_equipment_owner_suffix(item, slot_name)]
			entry_icon = _get_equipment_icon(item)
		equipment_choice_list.add_item(entry_text, entry_icon, true)

	var selected_index := _resolve_equipment_choice_index(character, slot_name, choices)
	if selected_index >= 0 and selected_index < equipment_choice_list.item_count:
		equipment_choice_list.select(selected_index)
		_update_equipment_detail_from_index(slot_name, selected_index)
	else:
		equipment_detail_label.text = "Select a %s to review its bonuses and who is currently using it." % slot_name.to_lower()

func _resolve_equipment_choice_index(character: CharacterData, slot_name: String, choices: Array) -> int:
	var equipped_item := _get_equipped_item_for_slot(character, slot_name)
	if equipped_item == null:
		return 0
	var found_index := choices.find(equipped_item)
	return found_index if found_index != -1 else 0

func _on_equipment_slot_focus_entered(slot_name: String) -> void:
	_preview_equipment_slot(slot_name)

func _on_equipment_slot_mouse_entered(slot_name: String) -> void:
	_preview_equipment_slot(slot_name)

func _preview_equipment_slot(slot_name: String) -> void:
	var normalized_slot := _normalize_equipment_slot_name(slot_name)
	if normalized_slot.is_empty():
		return
	_active_equipment_slot = normalized_slot
	var character := _get_selected_party_member()
	if character == null:
		return
	for slot_label in ["Weapon", "Armor", "Accessory"]:
		_update_button_state(_get_equipment_slot_button(slot_label), slot_label == _active_equipment_slot)
	_refresh_equipment_picker(character)

func _on_equipment_slot_pressed(slot_name: String) -> void:
	_preview_equipment_slot(slot_name)
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	call_deferred("_focus_equipment_choice_list")

func _open_party_equipment_picker(slot_name: String) -> void:
	var normalized_slot := _normalize_equipment_slot_name(slot_name)
	if normalized_slot.is_empty():
		return
	_active_equipment_slot = normalized_slot
	_party_equipment_picker_open = true
	var ui_sounds := _ui_sound_manager()
	if visible and ui_sounds:
		ui_sounds.play_menu_button()
	_update_section_visibility()
	_refresh_party_view()
	_rebuild_focus_graph()
	call_deferred("_focus_party_equipment_picker")

func _focus_party_equipment_picker() -> void:
	var slot_button := _get_equipment_slot_button(_active_equipment_slot)
	if slot_button != null and slot_button.visible:
		slot_button.grab_focus()

func _close_party_equipment_picker() -> void:
	_party_equipment_picker_open = false
	_update_section_visibility()
	_refresh_party_view()
	_rebuild_focus_graph()

func _focus_equipment_choice_list() -> void:
	if equipment_choice_list == null or equipment_choice_list.item_count <= 0:
		return
	equipment_choice_list.grab_focus()

func _on_equipment_choice_selected(index: int) -> void:
	_update_equipment_detail_from_index(_active_equipment_slot, index)
	if _equipment_refresh_in_progress:
		return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_browse_general(equipment_choice_list)

func _on_equipment_choice_activated(index: int) -> void:
	_apply_equipment_choice(_active_equipment_slot, index)

func _update_equipment_detail_from_index(slot_name: String, index: int) -> void:
	var choices: Array = _equipment_choices_by_slot.get(_normalize_equipment_slot_name(slot_name), [])
	if index < 0 or index >= choices.size():
		return
	var character := _get_selected_party_member()
	var equipped_item := _get_equipped_item_for_slot(character, slot_name) if character != null else null
	var item: Resource = choices[index]
	if item == null:
		equipment_detail_label.text = "Unequip the current %s and leave this slot empty.\n%s" % [
			slot_name.to_lower(),
			_build_equipment_compare_text(null, equipped_item)
		]
		return
	equipment_detail_label.text = _build_equipment_description(item, "No %s equipped." % slot_name.to_lower(), equipped_item)

func _apply_equipment_choice(slot_name: String, index: int) -> void:
	var normalized_slot := _normalize_equipment_slot_name(slot_name)
	var choices: Array = _equipment_choices_by_slot.get(normalized_slot, [])
	var character := _get_selected_party_member()
	if character == null or index < 0 or index >= choices.size():
		return
	var item: Resource = choices[index]
	if ProgressionService != null:
		var equipped := ProgressionService.equip_character_item(character, normalized_slot, item)
		if not equipped and item != null:
			equipment_detail_label.text = "%s cannot equip %s." % [String(character.display_name), _get_equipment_display_name(item, normalized_slot)]
			return
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_menu_button()
	_refresh_all_views()

func _build_calendar_grid() -> void:
	if calendar_grid == null:
		return

	_calendar_day_panels.clear()
	_calendar_day_labels.clear()
	_calendar_day_checks.clear()
	for child in calendar_grid.get_children():
		calendar_grid.remove_child(child)
		child.queue_free()

	var loop_mode := Global != null and Global.loop_hub_mode_active
	var cell_count := LOOP_STAGE_COUNT if loop_mode else CALENDAR_GRID_DAYS
	calendar_grid.columns = LOOP_STAGE_COLUMNS if loop_mode else CALENDAR_GRID_COLUMNS
	for day in range(1, cell_count + 1):
		var day_panel := PanelContainer.new()
		day_panel.custom_minimum_size = Vector2(0, 76)
		day_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		day_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		day_panel.add_child(margin)

		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_child(stack)

		var day_label := Label.new()
		day_label.text = str(day)
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		day_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		day_label.add_theme_font_size_override("font_size", 26)
		stack.add_child(day_label)

		var check_rect := TextureRect.new()
		check_rect.custom_minimum_size = Vector2(28, 28)
		check_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		check_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		check_rect.visible = false
		stack.add_child(check_rect)

		calendar_grid.add_child(day_panel)
		_calendar_day_panels.append(day_panel)
		_calendar_day_labels.append(day_label)
		_calendar_day_checks.append(check_rect)

func _make_calendar_cell_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style

func _apply_calendar_cell_state(day_panel: PanelContainer, day_label: Label, state: String) -> void:
	if day_panel == null or day_label == null:
		return

	var background := Color(0.13, 0.11, 0.08, 0.92)
	var border := Color(0.30, 0.24, 0.14, 1.0)
	var font_color := Color(0.85, 0.80, 0.68, 1.0)
	var font_size := 26

	match state:
		"past":
			background = Color(0.19, 0.15, 0.10, 0.96)
			border = Color(0.46, 0.34, 0.20, 1.0)
			font_color = Color(0.95, 0.88, 0.72, 1.0)
		"current":
			background = Color(0.55, 0.31, 0.12, 0.98)
			border = Color(1.0, 0.83, 0.48, 1.0)
			font_color = Color(1.0, 0.97, 0.88, 1.0)
			font_size = 30

	day_panel.add_theme_stylebox_override("panel", _make_calendar_cell_style(background, border))
	day_label.add_theme_color_override("font_color", font_color)
	day_label.add_theme_font_size_override("font_size", font_size)

func _refresh_calendar_view() -> void:
	if Global != null and Global.loop_hub_mode_active:
		_refresh_loop_stage_tracker()
		return

	var current_day: int = int(Global.current_day)
	if current_day <= 0:
		current_day = 1

	var season_name: String = "Spring"
	var days_per_season: int = CALENDAR_GRID_DAYS
	var season_day: int = ((current_day - 1) % days_per_season) + 1
	var season_start: int = current_day - season_day + 1
	var season_end: int = season_start + days_per_season - 1

	if CalendarService != null:
		season_name = String(CalendarService.get_current_season()).capitalize()
		days_per_season = int(CalendarService.DAYS_PER_SEASON)
		season_day = int(CalendarService.get_day_in_season(current_day))
		season_start = int(CalendarService.get_season_start_day(current_day))
		season_end = int(CalendarService.get_season_end_day(current_day))

	calendar_kicker_label.text = "Season Almanac"
	calendar_season_label.text = season_name
	calendar_day_summary_label.text = "Day %d of %d" % [season_day, days_per_season]
	calendar_past_legend_label.text = "Past days"
	calendar_today_legend_label.text = "Today"
	calendar_upcoming_legend_label.text = "Upcoming"

	var public_entry_count: int = 0
	if CalendarService != null and CalendarService.has_method("get_public_calendar_entries_for_day"):
		for day in range(season_start, season_end + 1):
			public_entry_count += CalendarService.get_public_calendar_entries_for_day(day).size()

	calendar_note_label.text = "No public notices are marked this season." if public_entry_count == 0 else "Known notices are recorded in the almanac."
	calendar_flavor_label.text = "This page covers days %d-%d of the year." % [season_start, season_end]

	for index in range(_calendar_day_panels.size()):
		var displayed_day := index + 1
		var state := "future"
		if displayed_day < season_day:
			state = "past"
		elif displayed_day == season_day:
			state = "current"
		_apply_calendar_cell_state(_calendar_day_panels[index], _calendar_day_labels[index], state)

func _refresh_loop_stage_tracker() -> void:
	if _calendar_day_panels.size() != LOOP_STAGE_COUNT:
		_build_calendar_grid()

	var current_stage := clampi(maxi(Global.loop_battle_index, 1), 1, LOOP_STAGE_COUNT)
	var completed_count := clampi(maxi(Global.loop_battle_index - 1, 0), 0, LOOP_STAGE_COUNT)

	calendar_kicker_label.text = "Forest Stages"
	calendar_season_label.text = ""
	calendar_day_summary_label.text = "Stage %d of %d" % [current_stage, LOOP_STAGE_COUNT]
	calendar_note_label.text = "Clear each stage to earn Bloom Points, Gold, and party levels."
	calendar_flavor_label.text = "Track your progress as the forest route opens up."
	calendar_past_legend_label.text = "Cleared"
	calendar_today_legend_label.text = "Current"
	calendar_upcoming_legend_label.text = "Ahead"

	for index in range(_calendar_day_panels.size()):
		var stage_number := index + 1
		var state := "future"
		if stage_number <= completed_count:
			state = "past"
		elif stage_number == current_stage:
			state = "current"
		_apply_calendar_cell_state(_calendar_day_panels[index], _calendar_day_labels[index], state)

		var check_rect := _calendar_day_checks[index] if index < _calendar_day_checks.size() else null
		if check_rect != null:
			if stage_number <= completed_count:
				check_rect.visible = true
				_set_stage_check_frame(check_rect, LOOP_STAGE_CHECK_HOLD_FRAME)
			else:
				check_rect.visible = false

	if completed_count > 0 and completed_count != _last_rendered_loop_stage:
		var animated_index := clampi(completed_count - 1, 0, _calendar_day_checks.size() - 1)
		if animated_index < _calendar_day_checks.size():
			var animated_check := _calendar_day_checks[animated_index]
			if animated_check != null:
				animated_check.visible = true
				call_deferred("_play_stage_check_animation", animated_check)
	_last_rendered_loop_stage = completed_count

func _set_stage_check_frame(target: TextureRect, frame: int) -> void:
	if target == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = LOOP_STAGE_CHECK_TEXTURE
	atlas.region = Rect2(frame * LOOP_STAGE_CHECK_FRAME_SIZE.x, 0, LOOP_STAGE_CHECK_FRAME_SIZE.x, LOOP_STAGE_CHECK_FRAME_SIZE.y)
	target.texture = atlas

func _play_stage_check_animation(target: TextureRect) -> void:
	if target == null or not is_instance_valid(target):
		return
	for frame in range(LOOP_STAGE_CHECK_FRAMES):
		if target == null or not is_instance_valid(target):
			return
		_set_stage_check_frame(target, frame)
		await get_tree().process_frame
	_set_stage_check_frame(target, LOOP_STAGE_CHECK_HOLD_FRAME)

func _build_attack_label(character: CharacterData, stats: UnitStats) -> String:
	var preview := CombatCalculator.get_attack_preview_data_from_snapshot(stats, character, character.equipped_weapon)
	var attack_total := int(preview.get("attack_total", 0))
	var weapon_might := int(preview.get("weapon_might", 0))
	var attack_stat := int(preview.get("attack_stat", 0))
	var profile: Dictionary = preview.get("profile", {})
	var stat_label := String(profile.get("stat_label", "STR"))
	return "ATK: %d (%s %d + MT %d)" % [attack_total, stat_label, attack_stat, weapon_might]

func _build_character_unit_stats(character: CharacterData) -> UnitStats:
	var stats := UnitStats.new()
	if character == null:
		return stats

	if _is_player_character(character):
		var snapshot := Global.get_player_combat_snapshot() if Global != null else {}
		stats.apply_class_progression(character)
		stats.hp = int(snapshot.get("HP", stats.hp))
		stats.max_hp = int(snapshot.get("MAX_HP", stats.max_hp))
		stats.str = int(snapshot.get("STR", stats.str))
		stats.physical_def = int(snapshot.get("DEF", stats.physical_def))
		stats.magic_def = int(snapshot.get("MDEF", stats.magic_def))
		stats.dex = int(snapshot.get("DEX", stats.dex))
		stats.int_stat = int(snapshot.get("INT", stats.int_stat))
		stats.spd = int(snapshot.get("SPD", stats.spd))
		stats.mov = int(snapshot.get("MOV", stats.mov))
		stats.atk_rng = int(snapshot.get("ATK_RNG", stats.atk_rng))
		stats.clamp_to_caps()
		return stats
	stats.apply_class_progression(character)
	if ProgressionService != null:
		stats.apply_delta(ProgressionService.get_member_runtime_growth_delta(String(character.display_name)))
	stats.apply_delta(_extract_equipment_delta(character.equipped_weapon))
	stats.apply_delta(_extract_equipment_delta(character.equipped_armor))
	stats.apply_delta(_extract_equipment_delta(character.equipped_accessory))
	stats.clamp_to_caps()
	stats.hp = stats.max_hp
	return stats

func _resolve_character_portrait(character: CharacterData) -> Texture2D:
	if character == null:
		return null
	var source_texture := character.portrait
	if character.battle_actor_scene == null:
		return source_texture
	var actor_root := character.battle_actor_scene.instantiate()
	if actor_root == null:
		return source_texture
	var body_sprite := actor_root.get_node_or_null("VisualDriver/Player/SpriteLayers/01body") as Sprite2D
	if body_sprite == null or body_sprite.texture == null:
		actor_root.free()
		return source_texture
	var texture_source := source_texture if source_texture != null else body_sprite.texture
	if body_sprite.hframes <= 1 and body_sprite.vframes <= 1:
		actor_root.free()
		return texture_source
	var source_size := texture_source.get_size()
	var actor_size := body_sprite.texture.get_size()
	if source_size != actor_size:
		actor_root.free()
		return texture_source
	var frame_width := int(actor_size.x / max(1, body_sprite.hframes))
	var frame_height := int(actor_size.y / max(1, body_sprite.vframes))
	if frame_width <= 0 or frame_height <= 0:
		actor_root.free()
		return texture_source
	var atlas := AtlasTexture.new()
	atlas.atlas = texture_source
	atlas.region = Rect2(0, 0, frame_width, frame_height)
	actor_root.free()
	return atlas

func _extract_equipment_delta(item: Resource) -> Dictionary:
	var delta := {}
	if item == null:
		return delta
	var bonuses = item.get("stat_bonuses")
	if bonuses is Dictionary:
		delta = {
			"STR": int((bonuses as Dictionary).get("strength", 0)),
			"DEF": int((bonuses as Dictionary).get("defense", 0)),
			"MDEF": int((bonuses as Dictionary).get("magic_defense", 0)),
			"DEX": int((bonuses as Dictionary).get("dexterity", 0)),
			"INT": int((bonuses as Dictionary).get("intelligence", 0)),
			"SPD": int((bonuses as Dictionary).get("speed", 0)),
			"MOV": int((bonuses as Dictionary).get("move_range", 0)),
			"ATK_RNG": int((bonuses as Dictionary).get("attack_range", 0)),
			"MAX_HP": int((bonuses as Dictionary).get("max_health", 0)),
		}
	return delta

func _build_character_role_text(character: CharacterData) -> String:
	if character == null or character.class_data == null:
		return "Unknown"
	var class_label := String(character.class_data.metadata_name)
	var role_name := String(character.class_data.role).capitalize()
	if role_name.is_empty():
		return class_label
	return "%s | %s" % [class_label, role_name]

func _resolve_character_level(character: CharacterData) -> int:
	if character == null:
		return 1
	if _is_player_character(character):
		return Global.get_player_level() if Global != null else 1
	return ProgressionService.get_member_runtime_level(String(character.display_name)) if ProgressionService != null else 1

func _build_meal_status_text(character: CharacterData) -> String:
	if character == null:
		return "No meal active."
	if Global.loop_hub_mode_active:
		return Global.get_loop_equipped_perk_status_text()
	if not _is_player_character(character):
		return "Meal buffs are currently tracked on Savannah's lead slot."
	if Global.active_food_buff.item == null:
		return "No meal active."
	var meal_item: Global.Items = Global.active_food_buff.item
	var meal_name := String(Global.Items.keys()[meal_item]).replace("_", " ").capitalize()
	var stat_parts: PackedStringArray = []
	for stat_name in ["VIT", "STR", "DEF", "DEX", "INT", "SPD", "MOV"]:
		var stat_value := int(Global.active_food_buff.stats.get(stat_name, 0))
		if stat_value != 0:
			stat_parts.append("+%d %s" % [stat_value, stat_name])
	return "Meal: %s%s" % [meal_name, " (%s)" % ", ".join(stat_parts) if not stat_parts.is_empty() else ""]

func _build_equipment_description(item: Resource, empty_text: String, equipped_item: Resource = null) -> String:
	if item == null:
		return empty_text
	var display_name := _get_equipment_display_name(item, "")
	var description := String(item.get("description")).strip_edges()
	var bonus_parts: PackedStringArray = []
	var bonuses = item.get("stat_bonuses")
	if bonuses is Dictionary:
		var label_map := {
			"strength": "STR",
			"defense": "DEF",
			"magic_defense": "MDEF",
			"dexterity": "DEX",
			"intelligence": "INT",
			"speed": "SPD",
		}
		for key in ["strength", "defense", "magic_defense", "dexterity", "intelligence", "speed"]:
			var value := int((bonuses as Dictionary).get(key, 0))
			if value != 0:
				bonus_parts.append("%s %+d" % [String(label_map[key]), value])
	var compare_text := _build_equipment_compare_text(item, equipped_item)
	return "%s%s%s" % [
		display_name,
		"\n" + ", ".join(bonus_parts) if not bonus_parts.is_empty() else "",
		"\n%s%s" % [
			compare_text,
			"\n" + description if not description.is_empty() else ""
		]
	]

func _build_equipment_compare_text(selected_item: Resource, equipped_item: Resource) -> String:
	if selected_item == null and equipped_item == null:
		return "No stat change from current gear."
	if selected_item == equipped_item:
		return "Currently equipped."

	var selected_delta := _extract_equipment_delta(selected_item)
	var equipped_delta := _extract_equipment_delta(equipped_item)
	var stat_order := ["MAX_HP", "STR", "DEF", "MDEF", "DEX", "INT", "SPD", "MOV", "ATK_RNG"]
	var stat_labels := {
		"MAX_HP": "HP",
		"STR": "STR",
		"DEF": "DEF",
		"MDEF": "MDEF",
		"DEX": "DEX",
		"INT": "INT",
		"SPD": "SPD",
		"MOV": "MOV",
		"ATK_RNG": "RNG",
	}
	var compare_parts: PackedStringArray = []
	for stat_name in stat_order:
		var delta_value := int(selected_delta.get(stat_name, 0)) - int(equipped_delta.get(stat_name, 0))
		if delta_value != 0:
			compare_parts.append("%s %+d" % [String(stat_labels.get(stat_name, stat_name)), delta_value])

	if compare_parts.is_empty():
		return "No stat change from current gear."

	return "Compared to equipped: %s" % ", ".join(compare_parts)

func _build_equipment_owner_suffix(item: Resource, slot_name: String) -> String:
	if item == null or ProgressionService == null:
		return ""
	for member in _get_party_roster():
		match slot_name:
			"Weapon":
				if member.equipped_weapon == item:
					return "  [Equipped by %s]" % String(member.display_name)
			"Armor":
				if member.equipped_armor == item:
					return "  [Equipped by %s]" % String(member.display_name)
			"Accessory":
				if member.equipped_accessory == item:
					return "  [Equipped by %s]" % String(member.display_name)
	return "  [Unequipped]"

func _get_equipment_display_name(item: Resource, fallback_slot: String) -> String:
	if item == null:
		return "None"
	if item is WeaponData:
		return String((item as WeaponData).weapon_name)
	if item is ArmorData:
		return String((item as ArmorData).armor_name)
	if item is AccessoryData:
		return String((item as AccessoryData).accessory_name)
	return fallback_slot if not fallback_slot.is_empty() else String(item.resource_name)

func _get_equipment_icon(item: Resource) -> Texture2D:
	if item == null:
		return null
	return item.get("icon") as Texture2D

func _get_equipped_item_for_slot(character: CharacterData, slot_name: String) -> Resource:
	if character == null:
		return null
	match _normalize_equipment_slot_name(slot_name):
		"Weapon":
			return character.equipped_weapon
		"Armor":
			return character.equipped_armor
		"Accessory":
			return character.equipped_accessory
		_:
			return null

func _get_equipment_slot_button(slot_name: String) -> Button:
	match _normalize_equipment_slot_name(slot_name):
		"Weapon":
			return weapon_slot_button
		"Armor":
			return armor_slot_button
		"Accessory":
			return accessory_slot_button
		_:
			return null

func _normalize_equipment_slot_name(slot_name: String) -> String:
	match slot_name.strip_edges().to_lower():
		"weapon":
			return "Weapon"
		"armor":
			return "Armor"
		"accessory":
			return "Accessory"
		_:
			return ""

func _class_uses_magic_damage(class_data: ClassData) -> bool:
	if class_data == null:
		return false
	var damage_stat := String(class_data.primary_damage_stat).to_lower()
	if damage_stat == "intelligence" or damage_stat == "int":
		return true
	if damage_stat == "strength" or damage_stat == "str":
		return false
	return String(class_data.role).to_lower().contains("mage")

func _get_party_roster() -> Array[CharacterData]:
	return ProgressionService.get_party_roster() if ProgressionService != null else []

func _get_selected_party_member() -> CharacterData:
	var roster := _get_party_roster()
	if roster.is_empty():
		return null
	_selected_party_index = clampi(_selected_party_index, 0, roster.size() - 1)
	return roster[_selected_party_index]

func _is_player_character(character: CharacterData) -> bool:
	var player_data := ProgressionService.get_player_character_data() if ProgressionService != null else null
	return character != null and character == player_data

func _get_party_names() -> Array[String]:
	var labels: Array[String] = []
	for member in _get_party_roster():
		labels.append(String(member.display_name))
	return labels

func _wire_browse_sound(control: Control, battle_menu_sound: bool) -> void:
	if control == null:
		return
	if not control.focus_entered.is_connected(_on_control_focus_entered.bind(control, battle_menu_sound)):
		control.focus_entered.connect(_on_control_focus_entered.bind(control, battle_menu_sound))
	if not control.mouse_entered.is_connected(_on_control_mouse_entered.bind(control, battle_menu_sound)):
		control.mouse_entered.connect(_on_control_mouse_entered.bind(control, battle_menu_sound))

func _on_control_focus_entered(control: Control, battle_menu_sound: bool) -> void:
	var ui_sounds := _ui_sound_manager()
	if ui_sounds == null:
		return
	if battle_menu_sound:
		ui_sounds.play_browse_battle(control)
	else:
		ui_sounds.play_browse_general(control)

func _on_control_mouse_entered(control: Control, battle_menu_sound: bool) -> void:
	_on_control_focus_entered(control, battle_menu_sound)

func _activate_selected_equipment_choice() -> void:
	if equipment_choice_list == null:
		return
	var selected := equipment_choice_list.get_selected_items()
	if selected.is_empty():
		if equipment_choice_list.item_count > 0:
			equipment_choice_list.select(0)
			_update_equipment_detail_from_index(_active_equipment_slot, 0)
		return
	_apply_equipment_choice(_active_equipment_slot, int(selected[0]))

func _is_action_pressed(event: InputEvent, actions: Array[StringName]) -> bool:
	for action in actions:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			return true
	return false

func _focus_section_root_deferred() -> void:
	call_deferred("_focus_section_root")

func _focus_section_root() -> void:
	var target := _get_section_root_button(_current_section)
	if target != null and target.visible:
		target.grab_focus()

func _focus_selected_roster_button() -> void:
	var roster_button := _get_selected_roster_button()
	if roster_button != null and roster_button.visible:
		roster_button.grab_focus()

func _clear_container_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _get_selected_roster_button() -> Button:
	if roster_list == null:
		return null
	var buttons := _get_roster_buttons()
	if _selected_party_index < 0 or _selected_party_index >= buttons.size():
		return null
	return buttons[_selected_party_index] as Button

func _get_first_inventory_slot() -> Control:
	var slots := _get_inventory_slot_controls()
	return slots[0] if not slots.is_empty() else null

func _rebuild_focus_graph() -> void:
	_link_vertical_focus([party_button, inventory_button, calendar_button])

	_set_focus_neighbor(party_button, Vector2.LEFT, party_button)
	_set_focus_neighbor(inventory_button, Vector2.LEFT, inventory_button)
	_set_focus_neighbor(calendar_button, Vector2.LEFT, calendar_button)
	_set_focus_neighbor(party_button, Vector2.RIGHT, party_button)
	_set_focus_neighbor(inventory_button, Vector2.RIGHT, _get_section_entry_target(MenuSection.INVENTORY))
	_set_focus_neighbor(calendar_button, Vector2.RIGHT, calendar_button)

	match _current_section:
		MenuSection.PARTY:
			_rebuild_party_focus_graph()
		MenuSection.INVENTORY:
			_rebuild_inventory_focus_graph()
		MenuSection.CALENDAR:
			_rebuild_calendar_focus_graph()

func _rebuild_party_focus_graph() -> void:
	var roster_buttons := _get_roster_buttons()
	_link_vertical_focus(roster_buttons)
	var entry_target := _get_party_detail_entry_target()

	for roster_button in roster_buttons:
		_set_focus_neighbor(roster_button, Vector2.LEFT, roster_button)
		_set_focus_neighbor(roster_button, Vector2.RIGHT, entry_target)

	if _party_equipment_picker_open:
		var slot_buttons := [weapon_slot_button, armor_slot_button, accessory_slot_button]
		_link_vertical_focus(slot_buttons)
		for slot_button in slot_buttons:
			_set_focus_neighbor(slot_button, Vector2.LEFT, _get_selected_roster_button())
			_set_focus_neighbor(slot_button, Vector2.RIGHT, equipment_choice_list)
		_set_focus_neighbor(equipment_choice_list, Vector2.LEFT, _get_equipment_slot_button(_active_equipment_slot))
	else:
		var overview_buttons := _get_overview_equipment_buttons()
		_link_vertical_focus(overview_buttons)
		for button in overview_buttons:
			_set_focus_neighbor(button, Vector2.LEFT, _get_selected_roster_button())

func _rebuild_inventory_focus_graph() -> void:
	var slots := _get_inventory_slot_controls()
	_link_inventory_grid_focus(slots)

func _rebuild_calendar_focus_graph() -> void:
	pass

func _get_section_root_button(section: MenuSection) -> Button:
	match section:
		MenuSection.PARTY:
			return party_button
		MenuSection.INVENTORY:
			return inventory_button
		MenuSection.CALENDAR:
			return calendar_button
	return null

func _get_section_from_root_button(button: Control) -> int:
	if button == party_button:
		return MenuSection.PARTY
	if button == inventory_button:
		return MenuSection.INVENTORY
	if button == calendar_button:
		return MenuSection.CALENDAR
	return -1

func _get_section_entry_target(section: MenuSection) -> Control:
	match section:
		MenuSection.PARTY:
			var roster_button := _get_selected_roster_button()
			if roster_button != null:
				return roster_button
			return _get_party_detail_entry_target()
		MenuSection.INVENTORY:
			return _get_first_inventory_slot()
		MenuSection.CALENDAR:
			return null
	return null

func _get_party_detail_entry_target() -> Control:
	if _party_equipment_picker_open:
		return _get_equipment_slot_button(_active_equipment_slot)
	var overview_button := _party_equipment_buttons.get("Weapon", null) as Control
	return overview_button

func _get_inventory_detail_entry_target() -> Control:
	return _get_first_inventory_slot()

func _get_roster_buttons() -> Array[Control]:
	var buttons: Array[Control] = []
	if roster_list == null:
		return buttons
	for child in roster_list.get_children():
		if child is Control and child.visible and not child.is_queued_for_deletion():
			buttons.append(child as Control)
	return buttons

func _get_inventory_slot_controls() -> Array[Control]:
	var slots: Array[Control] = []
	if inventory_grid == null:
		return slots
	for child in inventory_grid.get_children():
		if child is Control and child.visible and not child.is_queued_for_deletion():
			slots.append(child as Control)
	return slots

func _link_vertical_focus(controls: Array) -> void:
	for index in range(controls.size()):
		var control := controls[index] as Control
		if control == null:
			continue
		var above := controls[index - 1] as Control if index > 0 else control
		var below := controls[index + 1] as Control if index + 1 < controls.size() else control
		_set_focus_neighbor(control, Vector2.UP, above)
		_set_focus_neighbor(control, Vector2.DOWN, below)

func _link_horizontal_focus(controls: Array) -> void:
	for index in range(controls.size()):
		var control := controls[index] as Control
		if control == null:
			continue
		var left_control := controls[index - 1] as Control if index > 0 else control
		var right_control := controls[index + 1] as Control if index + 1 < controls.size() else control
		_set_focus_neighbor(control, Vector2.LEFT, left_control)
		_set_focus_neighbor(control, Vector2.RIGHT, right_control)

func _link_inventory_grid_focus(slots: Array[Control]) -> void:
	var columns := maxi(inventory_grid.columns, 1) if inventory_grid != null else 1
	for index in range(slots.size()):
		var slot := slots[index]
		if slot == null:
			continue
		var left_index := index - 1 if index % columns != 0 else -1
		var right_index := index + 1 if (index + 1) % columns != 0 and index + 1 < slots.size() else -1
		var up_index := index - columns
		var down_index := index + columns
		_set_focus_neighbor(slot, Vector2.LEFT, slots[left_index] if left_index >= 0 else slot)
		_set_focus_neighbor(slot, Vector2.RIGHT, slots[right_index] if right_index >= 0 else slot)
		_set_focus_neighbor(slot, Vector2.UP, slots[up_index] if up_index >= 0 else slot)
		_set_focus_neighbor(slot, Vector2.DOWN, slots[down_index] if down_index < slots.size() else slot)

func _set_focus_neighbor(control: Control, direction: Vector2, neighbor: Control) -> void:
	if control == null:
		return
	var neighbor_path := NodePath()
	if neighbor != null and is_instance_valid(neighbor):
		neighbor_path = control.get_path_to(neighbor)
	if direction == Vector2.UP:
		control.focus_neighbor_top = neighbor_path
	elif direction == Vector2.DOWN:
		control.focus_neighbor_bottom = neighbor_path
	elif direction == Vector2.LEFT:
		control.focus_neighbor_left = neighbor_path
	elif direction == Vector2.RIGHT:
		control.focus_neighbor_right = neighbor_path

func _is_in_active_content(control: Control) -> bool:
	if control == null or not visible:
		return false
	if control == party_button or control == inventory_button or control == calendar_button:
		return true

	match _current_section:
		MenuSection.PARTY:
			if party_section == control or party_section.is_ancestor_of(control):
				return true
		MenuSection.INVENTORY:
			if inventory_section == control or inventory_section.is_ancestor_of(control):
				return true
		MenuSection.CALENDAR:
			if calendar_section == control or calendar_section.is_ancestor_of(control):
				return true
	return false

func _refresh_status_highlight() -> void:
	if not _status_tab_highlight_enabled:
		_stop_status_highlight()
		return
	if _current_section == MenuSection.PARTY:
		_stop_status_highlight()
		return
	if _status_tab_highlight_tween != null:
		_status_tab_highlight_tween.kill()
	_status_tab_highlight_tween = create_tween()
	_status_tab_highlight_tween.set_loops()
	_status_tab_highlight_tween.tween_property(party_button, "modulate", Color(0.82, 0.94, 1.0, 1.0), 0.45)
	_status_tab_highlight_tween.tween_property(party_button, "modulate", Color(1.0, 0.95, 0.76, 1.0), 0.45)

func _stop_status_highlight() -> void:
	if _status_tab_highlight_tween != null:
		_status_tab_highlight_tween.kill()
		_status_tab_highlight_tween = null
	_update_button_state(party_button, _current_section == MenuSection.PARTY)

func _complete_status_review_if_needed(from_close: bool = false) -> void:
	if not _status_tab_highlight_enabled:
		return
	if not visible and not from_close:
		return
	if _current_section != MenuSection.PARTY:
		return
	_status_tab_highlight_enabled = false
	_stop_status_highlight()
	status_tab_viewed.emit()

func _try_close_equipment_picker() -> bool:
	if not visible:
		return false
	if _current_section != MenuSection.PARTY or not _party_equipment_picker_open:
		return false
	var focus_owner: Control = get_viewport().gui_get_focus_owner() as Control
	if focus_owner != equipment_choice_list:
		return false
	_close_party_equipment_picker()
	var overview_button := _party_equipment_buttons.get(_active_equipment_slot, null) as Button
	if overview_button != null:
		overview_button.grab_focus()
	return true

func _try_step_back_within_menu() -> bool:
	if not visible:
		return false
	var focus_owner: Control = get_viewport().gui_get_focus_owner() as Control
	if focus_owner == null or not _is_in_active_content(focus_owner):
		return false

	match _current_section:
		MenuSection.PARTY:
			if _party_equipment_picker_open and (focus_owner == equipment_choice_list or focus_owner == weapon_slot_button or focus_owner == armor_slot_button or focus_owner == accessory_slot_button):
				var overview_button := _party_equipment_buttons.get(_active_equipment_slot, null) as Button
				_close_party_equipment_picker()
				if overview_button != null:
					overview_button.grab_focus()
					return true
			if focus_owner == equipment_choice_list and _party_equipment_picker_open:
				var slot_button := _get_equipment_slot_button(_active_equipment_slot)
				if slot_button != null:
					slot_button.grab_focus()
					return true
			if _is_party_detail_focus(focus_owner):
				var roster_button := _get_selected_roster_button()
				if roster_button != null:
					roster_button.grab_focus()
					return true
			if _is_party_header_focus(focus_owner):
				party_button.grab_focus()
				return true
		MenuSection.INVENTORY:
			if _is_inventory_detail_focus(focus_owner):
				inventory_button.grab_focus()
				return true
			if _is_inventory_header_focus(focus_owner):
				inventory_button.grab_focus()
				return true
		MenuSection.CALENDAR:
			if focus_owner == calendar_legend_panel:
				calendar_button.grab_focus()
				return true
	return false

func _is_party_detail_focus(control: Control) -> bool:
	if control == null:
		return false
	if control == equipment_choice_list:
		return true
	if control == weapon_slot_button or control == armor_slot_button or control == accessory_slot_button:
		return true
	return _get_overview_equipment_buttons().has(control)

func _is_party_header_focus(control: Control) -> bool:
	if control == null:
		return false
	return roster_list != null and roster_list.is_ancestor_of(control)

func _is_inventory_detail_focus(control: Control) -> bool:
	if control == null:
		return false
	return inventory_grid != null and inventory_grid.is_ancestor_of(control)

func _is_inventory_header_focus(control: Control) -> bool:
	if control == null:
		return false
	return false

func _is_section_root_focus(control: Control) -> bool:
	return control == party_button or control == inventory_button or control == calendar_button

func _get_overview_equipment_buttons() -> Array[Control]:
	var buttons: Array[Control] = []
	for slot_name in ["Weapon", "Armor", "Accessory"]:
		var button := _party_equipment_buttons.get(slot_name, null) as Control
		if button != null and is_instance_valid(button) and button.visible:
			buttons.append(button)
	return buttons

func _rebuild_party_stats_grid(stats: UnitStats, character: CharacterData) -> void:
	if _party_stats_grid == null:
		return
	_clear_container_children(_party_stats_grid)
	var entries := [
		{"label": "HP", "value": "%d/%d" % [stats.hp, stats.max_hp]},
		{"label": "ATK", "value": _build_attack_label(character, stats).replace("ATK: ", "")},
		{"label": "DEF", "value": str(stats.physical_def)},
		{"label": "MDEF", "value": str(stats.magic_def)},
		{"label": "DEX", "value": str(stats.dex)},
		{"label": "INT", "value": str(stats.int_stat)},
		{"label": "SPD", "value": str(stats.spd)},
		{"label": "MOV", "value": str(stats.mov)},
	]
	for entry_variant in entries:
		var entry := entry_variant as Dictionary
		var label := Label.new()
		label.text = String(entry.get("label", ""))
		label.modulate = Color(0.84, 0.76, 0.58, 1.0)
		label.add_theme_font_size_override("font_size", 18)
		_party_stats_grid.add_child(label)
		var value := Label.new()
		value.text = String(entry.get("value", ""))
		value.add_theme_font_size_override("font_size", 20)
		_party_stats_grid.add_child(value)

func _rebuild_party_abilities(character: CharacterData) -> void:
	if _party_abilities_list == null:
		return
	_clear_container_children(_party_abilities_list)
	if character == null or character.abilities.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No abilities learned yet."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_party_abilities_list.add_child(empty_label)
		return
	for ability in character.abilities:
		if ability == null:
			continue
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.12, 0.09, 0.92)
		style.border_color = Color(0.35, 0.28, 0.16, 1.0)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		card.add_theme_stylebox_override("panel", style)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(margin)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 4)
		margin.add_child(stack)
		var title := Label.new()
		title.text = String(ability.ability_name)
		title.add_theme_font_size_override("font_size", 22)
		stack.add_child(title)
		var meta := Label.new()
		meta.text = "Range %d | Radius %d | Cooldown %d" % [int(ability.range), int(ability.radius), int(ability.cooldown_turns)]
		meta.modulate = Color(0.86, 0.8, 0.62, 1.0)
		meta.add_theme_font_size_override("font_size", 16)
		stack.add_child(meta)
		var body := Label.new()
		body.text = String(ability.description)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 18)
		stack.add_child(body)
		_party_abilities_list.add_child(card)
