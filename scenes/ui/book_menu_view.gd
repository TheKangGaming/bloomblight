extends Control
class_name BookMenuView

signal close_requested
signal section_requested(section: int)
signal roster_selected(index: int)
signal equipment_slot_requested(slot_name: String)
signal equipment_choice_requested(index: int)
signal item_equip_requested(entry: Dictionary)
signal item_use_requested(item_type: int)

const SECTION_PARTY := 0
const SECTION_ITEMS := 1
const SECTION_STAGES := 2

const FILTER_ALL := "All"
const FILTER_WEAPONS := "Weapons"
const FILTER_ARMOR := "Armor"
const FILTER_ACCESSORIES := "Accessories"
const FILTER_SEEDS := "Seeds"

const BOOK_SIZE := Vector2(2030, 1311)
const PAGE_LEFT := Rect2(Vector2(150, 145), Vector2(760, 1010))
const PAGE_RIGHT := Rect2(Vector2(1095, 145), Vector2(760, 1010))
const INK := Color(0.05, 0.035, 0.025, 1.0)
const MUTED_INK := Color(0.23, 0.18, 0.14, 1.0)
const ACTIVE_TINT := Color(1.0, 0.96, 0.78, 1.0)
const DISABLED_TINT := Color(0.58, 0.54, 0.48, 0.78)

const FONT_HAND := preload("res://graphics/ui/ReallyFree-ALwl7 copy.ttf")
const FONT_DISPLAY := preload("res://graphics/ui/Ironfist-nAdoO copy.ttf")

const BOOK_PAGES := preload("res://graphics/ui/book/pages.png")
const BOOK_COVER := preload("res://graphics/ui/book/cover.png")
const BOOK_PATTERN := preload("res://graphics/ui/book/pattern overlay.png")
const TAB_PARTY := preload("res://graphics/ui/book/bookmark party.png")
const TAB_ITEMS := preload("res://graphics/ui/book/bookmark items.png")
const TAB_STAGES := preload("res://graphics/ui/book/bookmark stages.png")
const CLOSE_TEXTURE := preload("res://graphics/ui/book/X.png")

const PARTY_CARD_TEXTURES := [
	preload("res://graphics/ui/book/party/char card1.png"),
	preload("res://graphics/ui/book/party/char card2.png"),
	preload("res://graphics/ui/book/party/char card3.png"),
	preload("res://graphics/ui/book/party/char card4.png"),
	preload("res://graphics/ui/book/party/char card5.png"),
	preload("res://graphics/ui/book/party/char card6.png"),
]
const PARTY_PREVIEW_BG := preload("res://graphics/ui/book/party/preview bg.png")
const PARTY_NAME_BG := preload("res://graphics/ui/book/party/bg char name.png")
const PARTY_STATS_BG := preload("res://graphics/ui/book/party/bg battle read.png")
const PARTY_ABILITY_BG := preload("res://graphics/ui/book/party/bg ability.png")
const PARTY_EQUIPMENT_BG := preload("res://graphics/ui/book/party/bg equipment.png")
const PARTY_EQ_PICKER_BG := preload("res://graphics/ui/book/party/hover replace eq.png")
const PARTY_EQ_CHOICE_BG := preload("res://graphics/ui/book/party/hover replace eq row.png")
const PARTY_PORTRAIT_FALLBACK := preload("res://graphics/ui/book/party/char portrait 1.png")
const ROLE_BG := preload("res://graphics/ui/book/party/ico role bg.png")
const ROLE_ICONS := {
	"support": preload("res://graphics/ui/book/party/ico role support.png"),
	"tank": preload("res://graphics/ui/book/party/ico role tank.png"),
	"dps": preload("res://graphics/ui/book/party/ico role dps.png"),
	"ranged": preload("res://graphics/ui/book/party/ico role ranged.png"),
	"healer": preload("res://graphics/ui/book/party/ico role healer.png"),
}
const ABILITY_ICONS := {
	"bloom": preload("res://graphics/ui/book/party/ico ability bloom ink.png"),
	"hunt": preload("res://graphics/ui/book/party/ico ability hunt ink.png"),
	"harvest": preload("res://graphics/ui/book/party/ico ability harvest ink.png"),
}
const EQUIPMENT_ICONS := {
	"Weapon": preload("res://graphics/ui/book/party/ico eq weapon.png"),
	"Armor": preload("res://graphics/ui/book/party/ico eq armor.png"),
	"Accessory": preload("res://graphics/ui/book/party/ico eq accessory.png"),
}
const STAT_ICONS := {
	"HP": preload("res://graphics/ui/book/party/ico stat hp ink.png"),
	"ATK": preload("res://graphics/ui/book/party/ico stat atk ink.png"),
	"DEF": preload("res://graphics/ui/book/party/ico stat def ink.png"),
	"MDEF": preload("res://graphics/ui/book/party/ico stat mdef ink.png"),
	"DEX": preload("res://graphics/ui/book/party/ico stat dex ink.png"),
	"INT": preload("res://graphics/ui/book/party/ico stat int ink.png"),
	"SPD": preload("res://graphics/ui/book/party/ico stat spd ink.png"),
	"MOV": preload("res://graphics/ui/book/party/ico stat mov ink.png"),
	"RNG": preload("res://graphics/ui/book/party/ico stat rng ink.png"),
	"RAD": preload("res://graphics/ui/book/party/ico stat rad ink.png"),
	"CLD": preload("res://graphics/ui/book/party/ico stat cld ink.png"),
}

const ITEM_ROW_TOP := preload("res://graphics/ui/book/items/row top.png")
const ITEM_ROW_MID := preload("res://graphics/ui/book/items/row mid.png")
const ITEM_ROW_BOTTOM := preload("res://graphics/ui/book/items/row bottom.png")
const ITEM_SELECTION := preload("res://graphics/ui/book/items/selection1.png")
const ITEM_NAME_BG := preload("res://graphics/ui/book/items/item name bg.png")
const ITEM_PREVIEW_BG := preload("res://graphics/ui/book/items/preview bg.png")
const ITEM_DETAILS_BG := preload("res://graphics/ui/book/items/details bg.png")
const ITEM_STATS_BG := preload("res://graphics/ui/book/items/stats bg.png")
const ITEM_EQUIP_TO_BG := preload("res://graphics/ui/book/items/equip to bg.png")
const ITEM_EQUIPPED_BY_BG := preload("res://graphics/ui/book/items/equipped by.png")
const ITEM_FILTER_ALL_ICON := preload("res://graphics/ui/book/items/ico item all.png")
const ITEM_FILTER_SEED_ICON := preload("res://graphics/ui/book/items/ico item seed.png")
const ITEM_MARKER_EQUIPPED := preload("res://graphics/ui/book/items/marker equipped1.png")
const ITEM_SHEET_FARM := preload("res://graphics/plants/Atlas-Props4-crops update.png")
const ITEM_SHEET_LOOT := preload("res://graphics/loot/loot-drops.png")
const ITEM_SHEET_FURNITURE := preload("res://graphics/tilesets/furniture_and_props.png")
const ITEM_APPLE := preload("res://graphics/plants/apple.png")
const ITEM_POTION := preload("res://graphics/loot/fc85.png")

const STAGE_RIBBON_BG := preload("res://graphics/ui/book/stages/stages ribbon bg.png")
const STAGE_TYPES_BG := preload("res://graphics/ui/book/stages/types of enemies bg.png")
const STAGE_DONE := preload("res://graphics/ui/book/stages/stage done.png")
const STAGE_CURRENT := preload("res://graphics/ui/book/stages/stage in progress.png")
const STAGE_BLIGHT := preload("res://graphics/ui/book/stages/stage blight.png")
const STAGE_SELECTION := preload("res://graphics/ui/book/stages/selection.png")
const STAGE_SPOT := preload("res://graphics/ui/book/stages/spot.png")
const STAGE_HOVER := preload("res://graphics/ui/book/stages/hover.png")
const STAGE_NUMBERS := [
	preload("res://graphics/ui/book/stages/1.png"),
	preload("res://graphics/ui/book/stages/2.png"),
	preload("res://graphics/ui/book/stages/3.png"),
	preload("res://graphics/ui/book/stages/4.png"),
	preload("res://graphics/ui/book/stages/5.png"),
	preload("res://graphics/ui/book/stages/6.png"),
	preload("res://graphics/ui/book/stages/7.png"),
	preload("res://graphics/ui/book/stages/8.png"),
	preload("res://graphics/ui/book/stages/9.png"),
	preload("res://graphics/ui/book/stages/10.png"),
]
const STAGE_ARROWS := [
	preload("res://graphics/ui/book/stages/arrow1.png"),
	preload("res://graphics/ui/book/stages/arrow2.png"),
	preload("res://graphics/ui/book/stages/arrow3.png"),
	preload("res://graphics/ui/book/stages/arrow4.png"),
	preload("res://graphics/ui/book/stages/arrow5.png"),
	preload("res://graphics/ui/book/stages/arrow6.png"),
	preload("res://graphics/ui/book/stages/arrow7.png"),
	preload("res://graphics/ui/book/stages/arrow8.png"),
	preload("res://graphics/ui/book/stages/arrow9.png"),
]
const ENEMY_ICONS := {
	"bandit warrior": preload("res://graphics/ui/book/stages/ico enemy  b warr.png"),
	"bandit archer": preload("res://graphics/ui/book/stages/ico enemy b arch.png"),
	"bandit assassin": preload("res://graphics/ui/book/stages/ico enemy b assas.png"),
	"bandit marauder": preload("res://graphics/ui/book/stages/ico enemy b mar.png"),
	"bandit spearman": preload("res://graphics/ui/book/stages/ico enemy b spear.png"),
	"bandit robber": preload("res://graphics/ui/book/stages/ico enemy boss.png"),
}

var _host: Control = null
var _canvas: Control = null
var _tabs := {}
var _section_roots := {}
var _current_section := SECTION_PARTY
var _active_item_filter := FILTER_ALL
var _selected_item_index := 0
var _selected_stage := 1

var _party_roster_grid: GridContainer = null
var _party_roster_scroll: ScrollContainer = null
var _party_roster_buttons: Array[Button] = []
var _party_name_label: Label = null
var _party_role_label: Label = null
var _party_level_label: Label = null
var _party_portrait: TextureRect = null
var _party_role_icon: TextureRect = null
var _party_stats_grid: GridContainer = null
var _party_meal_label: Label = null
var _party_ability_icon: TextureRect = null
var _party_ability_label: Label = null
var _party_ability_meta_label: Label = null
var _party_equipment_buttons := {}
var _party_equipment_picker: Control = null
var _party_equipment_title: Label = null
var _party_equipment_choice_list: VBoxContainer = null
var _party_equipment_choice_scroll: ScrollContainer = null
var _party_equipment_choice_buttons: Array[Button] = []
var _party_equipment_detail: Label = null

var _item_filter_buttons := {}
var _item_list: VBoxContainer = null
var _item_list_scroll: ScrollContainer = null
var _item_buttons: Array[Button] = []
var _item_entries: Array[Dictionary] = []
var _item_name_label: Label = null
var _item_preview_icon: TextureRect = null
var _item_detail_label: Label = null
var _item_stats_label: Label = null
var _item_owner_label: Label = null
var _item_action_button: Button = null

var _stage_buttons: Array[TextureButton] = []
var _stage_detail_label: Label = null


func setup(host: Control) -> void:
	_host = host
	if _canvas != null:
		return
	_build_shell()
	_build_party_page()
	_build_items_page()
	_build_stages_page()
	_raise_navigation_controls()
	set_section(SECTION_PARTY)


func set_section(section: int) -> void:
	_current_section = clampi(section, SECTION_PARTY, SECTION_STAGES)
	for key in _section_roots.keys():
		var root := _section_roots[key] as Control
		if root != null:
			root.visible = int(key) == _current_section
	for key in _tabs.keys():
		var tab := _tabs[key] as CanvasItem
		if tab != null:
			tab.modulate = ACTIVE_TINT if int(key) == _current_section else Color.WHITE


func refresh() -> void:
	if _host == null:
		return
	set_section(_get_host_section())
	_refresh_party_page()
	_refresh_items_page()
	_refresh_stages_page()
	rebuild_focus_graph()


func get_tab_button(section: int) -> Control:
	return _tabs.get(section, null) as Control


func get_section_entry_target(section: int) -> Control:
	match section:
		SECTION_PARTY:
			if _get_host_equipment_picker_open() and not _party_equipment_choice_buttons.is_empty():
				return _party_equipment_choice_buttons[0]
			if not _party_roster_buttons.is_empty():
				var index := clampi(_get_host_selected_party_index(), 0, _party_roster_buttons.size() - 1)
				return _party_roster_buttons[index]
			return _party_equipment_buttons.get("Weapon", null) as Control
		SECTION_ITEMS:
			if not _item_buttons.is_empty():
				var index := clampi(_selected_item_index, 0, _item_buttons.size() - 1)
				return _item_buttons[index]
			return _item_filter_buttons.get(FILTER_ALL, null) as Control
		SECTION_STAGES:
			if not _stage_buttons.is_empty():
				var index := clampi(_selected_stage - 1, 0, _stage_buttons.size() - 1)
				return _stage_buttons[index]
	return null


func get_roster_buttons() -> Array[Control]:
	var controls: Array[Control] = []
	for button in _party_roster_buttons:
		if button != null and is_instance_valid(button) and button.visible:
			controls.append(button)
	return controls


func get_item_buttons() -> Array[Control]:
	var controls: Array[Control] = []
	for button in _item_buttons:
		if button != null and is_instance_valid(button) and button.visible:
			controls.append(button)
	return controls


func get_active_scroll_container() -> ScrollContainer:
	match _current_section:
		SECTION_PARTY:
			return _party_equipment_choice_scroll if _get_host_equipment_picker_open() else _party_roster_scroll
		SECTION_ITEMS:
			return _item_list_scroll
	return null


func focus_section_root() -> void:
	var target := get_tab_button(_current_section)
	if target != null and target.visible:
		target.grab_focus()


func focus_selected_roster() -> void:
	if _party_roster_buttons.is_empty():
		return
	var index := clampi(_get_host_selected_party_index(), 0, _party_roster_buttons.size() - 1)
	var target := _party_roster_buttons[index]
	if target != null and target.visible:
		target.grab_focus()


func focus_equipment_slot(slot_name: String) -> void:
	var target := _party_equipment_buttons.get(slot_name, null) as Control
	if target != null and target.visible:
		target.grab_focus()


func focus_equipment_choice() -> void:
	if not _party_equipment_choice_buttons.is_empty():
		_party_equipment_choice_buttons[0].grab_focus()


func rebuild_focus_graph() -> void:
	_link_horizontal_focus([get_tab_button(SECTION_PARTY), get_tab_button(SECTION_ITEMS), get_tab_button(SECTION_STAGES)])
	var close_button := get_node_or_null("BookCenter/BookCanvas/CloseButton") as Control
	for tab_variant in _tabs.values():
		var tab := tab_variant as Control
		if tab != null:
			_set_focus_neighbor(tab, Vector2.DOWN, get_section_entry_target(_current_section))
			_set_focus_neighbor(tab, Vector2.UP, tab)
	if close_button != null:
		_set_focus_neighbor(close_button, Vector2.LEFT, get_tab_button(SECTION_STAGES))
		_set_focus_neighbor(close_button, Vector2.DOWN, get_section_entry_target(_current_section))

	match _current_section:
		SECTION_PARTY:
			_rebuild_party_focus_graph()
		SECTION_ITEMS:
			_rebuild_items_focus_graph()
		SECTION_STAGES:
			_rebuild_stages_focus_graph()


func _build_shell() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var dim := Panel.new()
	dim.name = "BookDim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim_style := StyleBoxFlat.new()
	dim_style.bg_color = Color(0.0, 0.0, 0.0, 0.24)
	dim.add_theme_stylebox_override("panel", dim_style)
	add_child(dim)

	var center := CenterContainer.new()
	center.name = "BookCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_canvas = Control.new()
	_canvas.name = "BookCanvas"
	_canvas.custom_minimum_size = BOOK_SIZE
	_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	center.add_child(_canvas)

	_add_texture(_canvas, BOOK_COVER, Vector2.ZERO, BOOK_SIZE, "Cover")
	_add_texture(_canvas, BOOK_PAGES, Vector2(45, 35), Vector2(1939, 1241), "Pages")
	var pattern := _add_texture(_canvas, BOOK_PATTERN, Vector2(160, 130), Vector2(1714, 1220), "Pattern")
	pattern.modulate.a = 0.54

	_tabs[SECTION_PARTY] = _make_texture_tab(TAB_PARTY, Vector2(120, -70), "Party", SECTION_PARTY)
	_tabs[SECTION_ITEMS] = _make_texture_tab(TAB_ITEMS, Vector2(840, -70), "Items", SECTION_ITEMS)
	_tabs[SECTION_STAGES] = _make_texture_tab(TAB_STAGES, Vector2(1160, -58), "Stages", SECTION_STAGES)

	var close_button := TextureButton.new()
	close_button.name = "CloseButton"
	close_button.texture_normal = CLOSE_TEXTURE
	close_button.texture_hover = CLOSE_TEXTURE
	close_button.texture_pressed = CLOSE_TEXTURE
	close_button.position = Vector2(1840, 54)
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.pressed.connect(func() -> void:
		_play_button_sound()
		close_requested.emit()
	)
	close_button.focus_entered.connect(_play_browse_sound)
	close_button.mouse_entered.connect(_play_browse_sound)
	_canvas.add_child(close_button)


func _raise_navigation_controls() -> void:
	if _canvas == null:
		return
	for tab_variant in _tabs.values():
		var tab := tab_variant as Node
		if tab != null and tab.get_parent() == _canvas:
			_canvas.move_child(tab, _canvas.get_child_count() - 1)
	var close_button := _canvas.get_node_or_null("CloseButton")
	if close_button != null:
		_canvas.move_child(close_button, _canvas.get_child_count() - 1)


func _build_party_page() -> void:
	var root := Control.new()
	root.name = "PartyPage"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.add_child(root)
	_section_roots[SECTION_PARTY] = root

	_party_roster_scroll = ScrollContainer.new()
	_party_roster_scroll.position = PAGE_LEFT.position + Vector2(10, 68)
	_party_roster_scroll.size = Vector2(720, 895)
	_party_roster_scroll.follow_focus = true
	_party_roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_party_roster_scroll)

	_party_roster_grid = GridContainer.new()
	_party_roster_grid.columns = 2
	_party_roster_grid.add_theme_constant_override("h_separation", 22)
	_party_roster_grid.add_theme_constant_override("v_separation", 18)
	_party_roster_scroll.add_child(_party_roster_grid)

	_add_texture(root, PARTY_NAME_BG, PAGE_RIGHT.position + Vector2(65, 0), Vector2(418, 147), "PartyNameBg")
	_party_name_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(110, 36), Vector2(360, 58), 46, HORIZONTAL_ALIGNMENT_CENTER)
	_party_role_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(110, 94), Vector2(380, 42), 28, HORIZONTAL_ALIGNMENT_CENTER)
	_party_level_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(500, 50), Vector2(130, 48), 32, HORIZONTAL_ALIGNMENT_CENTER)

	var preview_bg := _add_texture(root, PARTY_PREVIEW_BG, PAGE_RIGHT.position + Vector2(80, 150), Vector2(360, 485), "PartyPreviewBg")
	preview_bg.modulate.a = 0.92
	_party_portrait = _add_texture(root, PARTY_PORTRAIT_FALLBACK, PAGE_RIGHT.position + Vector2(155, 190), Vector2(220, 345), "PartyPortrait")
	_party_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_party_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_add_texture(root, ROLE_BG, PAGE_RIGHT.position + Vector2(505, 160), Vector2(74, 100), "RoleBg")
	_party_role_icon = _add_texture(root, ROLE_ICONS["support"], PAGE_RIGHT.position + Vector2(520, 174), Vector2(48, 60), "RoleIcon")
	_party_role_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	_add_texture(root, PARTY_STATS_BG, PAGE_RIGHT.position + Vector2(455, 165), Vector2(285, 285), "StatsBg")
	_party_stats_grid = GridContainer.new()
	_party_stats_grid.columns = 4
	_party_stats_grid.position = PAGE_RIGHT.position + Vector2(500, 250)
	_party_stats_grid.size = Vector2(215, 185)
	_party_stats_grid.add_theme_constant_override("h_separation", 10)
	_party_stats_grid.add_theme_constant_override("v_separation", 7)
	root.add_child(_party_stats_grid)

	_party_meal_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(90, 610), Vector2(640, 72), 26, HORIZONTAL_ALIGNMENT_LEFT)
	_party_meal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_add_texture(root, PARTY_ABILITY_BG, PAGE_RIGHT.position + Vector2(92, 710), Vector2(166, 251), "AbilityBg")
	_party_ability_icon = _add_texture(root, ABILITY_ICONS["harvest"], PAGE_RIGHT.position + Vector2(142, 782), Vector2(54, 54), "AbilityIcon")
	_party_ability_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(88, 858), Vector2(180, 52), 28, HORIZONTAL_ALIGNMENT_CENTER)
	_party_ability_meta_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(295, 715), Vector2(420, 125), 24, HORIZONTAL_ALIGNMENT_LEFT)
	_party_ability_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_add_texture(root, PARTY_EQUIPMENT_BG, PAGE_RIGHT.position + Vector2(285, 840), Vector2(420, 220), "EquipmentBg")
	var slot_positions := {
		"Weapon": PAGE_RIGHT.position + Vector2(332, 910),
		"Armor": PAGE_RIGHT.position + Vector2(468, 910),
		"Accessory": PAGE_RIGHT.position + Vector2(604, 910),
	}
	for slot_name in ["Weapon", "Armor", "Accessory"]:
		var button := _make_paper_button(slot_positions[slot_name], Vector2(96, 104), "", 18)
		button.name = "%sBookSlotButton" % slot_name
		button.pressed.connect(func(slot: String = slot_name) -> void:
			_play_button_sound()
			equipment_slot_requested.emit(slot)
		)
		root.add_child(button)
		_party_equipment_buttons[slot_name] = button
		_add_texture(button, EQUIPMENT_ICONS[slot_name], Vector2(22, 8), Vector2(52, 52), "%sIcon" % slot_name)
		var label := _add_label(button, slot_name, Vector2(4, 62), Vector2(88, 34), 18, HORIZONTAL_ALIGNMENT_CENTER)
		label.name = "SlotLabel"

	_build_party_equipment_picker(root)


func _build_party_equipment_picker(root: Control) -> void:
	_party_equipment_picker = Control.new()
	_party_equipment_picker.name = "BookEquipmentPicker"
	_party_equipment_picker.position = PAGE_RIGHT.position + Vector2(505, 650)
	_party_equipment_picker.size = Vector2(330, 440)
	root.add_child(_party_equipment_picker)

	_add_texture(_party_equipment_picker, PARTY_EQ_PICKER_BG, Vector2.ZERO, Vector2(330, 392), "PickerBg")
	_party_equipment_title = _add_label(_party_equipment_picker, "", Vector2(38, 22), Vector2(250, 42), 28, HORIZONTAL_ALIGNMENT_CENTER)

	_party_equipment_choice_scroll = ScrollContainer.new()
	_party_equipment_choice_scroll.position = Vector2(38, 78)
	_party_equipment_choice_scroll.size = Vector2(255, 170)
	_party_equipment_choice_scroll.follow_focus = true
	_party_equipment_choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_party_equipment_picker.add_child(_party_equipment_choice_scroll)

	_party_equipment_choice_list = VBoxContainer.new()
	_party_equipment_choice_list.add_theme_constant_override("separation", 8)
	_party_equipment_choice_scroll.add_child(_party_equipment_choice_list)

	_party_equipment_detail = _add_label(_party_equipment_picker, "", Vector2(38, 265), Vector2(250, 105), 20, HORIZONTAL_ALIGNMENT_LEFT)
	_party_equipment_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _build_items_page() -> void:
	var root := Control.new()
	root.name = "ItemsPage"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.add_child(root)
	_section_roots[SECTION_ITEMS] = root

	var filters := [
		{"label": FILTER_ALL, "pos": PAGE_LEFT.position + Vector2(20, 20), "icon": ITEM_FILTER_ALL_ICON},
		{"label": FILTER_WEAPONS, "pos": PAGE_LEFT.position + Vector2(155, 20), "icon": EQUIPMENT_ICONS["Weapon"]},
		{"label": FILTER_ARMOR, "pos": PAGE_LEFT.position + Vector2(335, 20), "icon": EQUIPMENT_ICONS["Armor"]},
		{"label": FILTER_ACCESSORIES, "pos": PAGE_LEFT.position + Vector2(485, 20), "icon": EQUIPMENT_ICONS["Accessory"]},
		{"label": FILTER_SEEDS, "pos": PAGE_LEFT.position + Vector2(640, 20), "icon": ITEM_FILTER_SEED_ICON},
	]
	for filter_variant in filters:
		var filter_data := filter_variant as Dictionary
		var label := String(filter_data.get("label", ""))
		var button := _make_paper_button(filter_data.get("pos", Vector2.ZERO), Vector2(124, 64), label, 22)
		button.name = "%sFilterButton" % label
		button.pressed.connect(func(filter_name := label) -> void:
			_play_button_sound()
			_active_item_filter = filter_name
			_selected_item_index = 0
			_refresh_items_page()
			rebuild_focus_graph()
			var target := get_section_entry_target(SECTION_ITEMS)
			if target != null:
				target.grab_focus()
		)
		root.add_child(button)
		var icon := _add_texture(button, filter_data.get("icon", null) as Texture2D, Vector2(10, 14), Vector2(34, 34), "FilterIcon")
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_item_filter_buttons[label] = button

	_item_list_scroll = ScrollContainer.new()
	_item_list_scroll.position = PAGE_LEFT.position + Vector2(20, 105)
	_item_list_scroll.size = Vector2(710, 700)
	_item_list_scroll.follow_focus = true
	_item_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_item_list_scroll)

	_item_list = VBoxContainer.new()
	_item_list.add_theme_constant_override("separation", 0)
	_item_list_scroll.add_child(_item_list)

	_add_texture(root, ITEM_EQUIP_TO_BG, PAGE_LEFT.position + Vector2(20, 835), Vector2(710, 130), "EquipToBg")
	var equip_to := _add_label(root, "Equip to", PAGE_LEFT.position + Vector2(52, 875), Vector2(180, 52), 30, HORIZONTAL_ALIGNMENT_LEFT)
	equip_to.rotation_degrees = -1.5

	_add_texture(root, ITEM_NAME_BG, PAGE_RIGHT.position + Vector2(10, 20), Vector2(700, 150), "ItemNameBg")
	_item_name_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(145, 65), Vector2(440, 58), 38, HORIZONTAL_ALIGNMENT_CENTER)
	_add_texture(root, ITEM_PREVIEW_BG, PAGE_RIGHT.position + Vector2(40, 190), Vector2(620, 390), "ItemPreviewBg")
	_item_preview_icon = _add_texture(root, null, PAGE_RIGHT.position + Vector2(230, 260), Vector2(250, 250), "ItemPreviewIcon")
	_item_preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_item_preview_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_add_texture(root, ITEM_DETAILS_BG, PAGE_RIGHT.position + Vector2(30, 640), Vector2(430, 250), "ItemDetailsBg")
	_item_detail_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(62, 675), Vector2(360, 180), 24, HORIZONTAL_ALIGNMENT_LEFT)
	_item_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_texture(root, ITEM_STATS_BG, PAGE_RIGHT.position + Vector2(500, 645), Vector2(215, 185), "ItemStatsBg")
	_item_stats_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(530, 675), Vector2(160, 135), 24, HORIZONTAL_ALIGNMENT_LEFT)
	_item_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_texture(root, ITEM_EQUIPPED_BY_BG, PAGE_RIGHT.position + Vector2(150, 930), Vector2(420, 105), "EquippedByBg")
	_item_owner_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(190, 955), Vector2(350, 52), 28, HORIZONTAL_ALIGNMENT_CENTER)
	_item_action_button = _make_paper_button(PAGE_RIGHT.position + Vector2(585, 930), Vector2(140, 74), "Equip", 25)
	_item_action_button.name = "ItemActionButton"
	_item_action_button.pressed.connect(_on_item_action_pressed)
	root.add_child(_item_action_button)


func _build_stages_page() -> void:
	var root := Control.new()
	root.name = "StagesPage"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.add_child(root)
	_section_roots[SECTION_STAGES] = root

	_add_texture(root, STAGE_RIBBON_BG, PAGE_LEFT.position + Vector2(55, 25), Vector2(600, 315), "StagesRibbon")
	var title := _add_label(root, "Stages", PAGE_LEFT.position + Vector2(220, 165), Vector2(260, 70), 42, HORIZONTAL_ALIGNMENT_CENTER)
	title.rotation_degrees = -1.5
	_add_texture(root, STAGE_TYPES_BG, PAGE_RIGHT.position + Vector2(-20, 25), Vector2(710, 380), "EnemyTypesBg")
	_add_label(root, "Types of enemies", PAGE_RIGHT.position + Vector2(190, 85), Vector2(300, 44), 28, HORIZONTAL_ALIGNMENT_CENTER)

	var enemy_entries := [
		{"name": "bandit warrior", "pos": PAGE_RIGHT.position + Vector2(65, 145)},
		{"name": "bandit marauder", "pos": PAGE_RIGHT.position + Vector2(420, 145)},
		{"name": "bandit archer", "pos": PAGE_RIGHT.position + Vector2(65, 225)},
		{"name": "bandit spearman", "pos": PAGE_RIGHT.position + Vector2(420, 225)},
		{"name": "bandit assassin", "pos": PAGE_RIGHT.position + Vector2(65, 305)},
		{"name": "bandit robber", "pos": PAGE_RIGHT.position + Vector2(420, 305)},
	]
	for entry_variant in enemy_entries:
		var entry := entry_variant as Dictionary
		var enemy_name := String(entry.get("name", ""))
		var pos := entry.get("pos", Vector2.ZERO) as Vector2
		_add_texture(root, ENEMY_ICONS.get(enemy_name, null) as Texture2D, pos, Vector2(54, 54), "%sIcon" % enemy_name)
		var display := enemy_name.capitalize()
		if enemy_name == "bandit robber":
			display = "Bandit Robber\n(Boss)"
		_add_label(root, display, pos + Vector2(80, -2), Vector2(210, 62), 24, HORIZONTAL_ALIGNMENT_LEFT)

	var arrow_positions := [
		Vector2(378, 720),
		Vector2(618, 720),
		Vector2(858, 720),
		Vector2(1170, 720),
		Vector2(1415, 720),
		Vector2(1660, 720),
		Vector2(285, 995),
		Vector2(525, 995),
		Vector2(765, 995),
	]
	for index in range(arrow_positions.size()):
		_add_texture(root, STAGE_ARROWS[index], arrow_positions[index], STAGE_ARROWS[index].get_size(), "StageArrow%d" % index)

	var stage_positions := [
		Vector2(205, 645),
		Vector2(455, 645),
		Vector2(705, 645),
		Vector2(1030, 645),
		Vector2(1280, 645),
		Vector2(1530, 645),
		Vector2(175, 920),
		Vector2(425, 920),
		Vector2(675, 920),
		Vector2(1005, 920),
	]
	for index in range(stage_positions.size()):
		var button := TextureButton.new()
		button.name = "Stage%dButton" % (index + 1)
		button.position = stage_positions[index]
		button.texture_normal = STAGE_BLIGHT
		button.texture_hover = STAGE_HOVER
		button.texture_pressed = STAGE_CURRENT
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(func(stage_number := index + 1) -> void:
			_play_button_sound()
			_selected_stage = stage_number
			_refresh_stages_page()
			rebuild_focus_graph()
		)
		button.focus_entered.connect(func(stage_number := index + 1) -> void:
			_selected_stage = stage_number
			_refresh_stage_detail()
			_play_browse_sound()
		)
		button.mouse_entered.connect(func(stage_number := index + 1) -> void:
			_selected_stage = stage_number
			_refresh_stage_detail()
			_play_browse_sound()
		)
		root.add_child(button)
		var number := _add_texture(button, STAGE_NUMBERS[index], Vector2(62, 58), STAGE_NUMBERS[index].get_size(), "StageNumber")
		number.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_stage_buttons.append(button)

	_stage_detail_label = _add_label(root, "", PAGE_RIGHT.position + Vector2(15, 820), Vector2(690, 110), 28, HORIZONTAL_ALIGNMENT_CENTER)
	_stage_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _refresh_party_page() -> void:
	var roster: Array = _host.call("_get_party_roster") if _host != null else []
	_clear_container_children(_party_roster_grid)
	_party_roster_buttons.clear()
	for index in range(roster.size()):
		var member := roster[index] as CharacterData
		if member == null:
			continue
		var button := _make_party_card(member, index)
		_party_roster_grid.add_child(button)
		_party_roster_buttons.append(button)

	var character := _host.call("_get_selected_party_member") as CharacterData
	if character == null:
		return

	_party_name_label.text = String(character.display_name)
	_party_role_label.text = _host.call("_build_character_role_text", character)
	_party_level_label.text = "Lv %d" % int(_host.call("_resolve_character_level", character))
	_party_portrait.texture = _host.call("_resolve_character_portrait", character) as Texture2D
	if _party_portrait.texture == null:
		_party_portrait.texture = PARTY_PORTRAIT_FALLBACK
	_party_role_icon.texture = _get_role_icon(character)

	var stats := _host.call("_build_character_unit_stats", character) as UnitStats
	_refresh_party_stats(stats, character)
	_party_meal_label.text = _host.call("_build_meal_status_text", character)
	_refresh_party_ability(character)
	_refresh_party_equipment(character)


func _make_party_card(member: CharacterData, index: int) -> Button:
	var selected := index == _get_host_selected_party_index()
	var texture: Texture2D = PARTY_CARD_TEXTURES[index % PARTY_CARD_TEXTURES.size()]
	var button := _make_paper_button(Vector2.ZERO, Vector2(284, 380), "", 20)
	button.custom_minimum_size = Vector2(284, 380)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.name = "PartyCard%d" % index
	button.modulate = ACTIVE_TINT if selected else Color.WHITE
	button.pressed.connect(func(card_index: int = index) -> void:
		_play_button_sound()
		roster_selected.emit(card_index)
	)
	_add_texture(button, texture, Vector2.ZERO, Vector2(284, 380), "CardBg")
	var name_label := _add_label(button, String(member.display_name), Vector2(24, 20), Vector2(224, 42), 28, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.rotation_degrees = -2.0
	var portrait := _add_texture(button, _host.call("_resolve_character_portrait", member) as Texture2D, Vector2(44, 64), Vector2(196, 196), "Portrait")
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_add_texture(button, ROLE_BG, Vector2(22, 268), Vector2(48, 62), "RoleBg")
	var role_icon := _add_texture(button, _get_role_icon(member), Vector2(30, 275), Vector2(34, 42), "RoleIcon")
	role_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var class_label := _add_label(button, _get_class_label(member), Vector2(78, 276), Vector2(166, 34), 22, HORIZONTAL_ALIGNMENT_LEFT)
	class_label.clip_text = true
	var level_label := _add_label(button, "Lv %d" % int(_host.call("_resolve_character_level", member)), Vector2(80, 315), Vector2(90, 32), 20, HORIZONTAL_ALIGNMENT_LEFT)
	level_label.clip_text = true
	return button


func _refresh_party_stats(stats: UnitStats, character: CharacterData) -> void:
	if stats == null:
		return
	_clear_container_children(_party_stats_grid)
	var attack_label := String(_host.call("_build_attack_label", character, stats)).replace("ATK: ", "")
	var entries := [
		{"icon": "HP", "value": "%d/%d" % [stats.hp, stats.max_hp]},
		{"icon": "ATK", "value": attack_label},
		{"icon": "DEF", "value": str(stats.physical_def)},
		{"icon": "MDEF", "value": str(stats.magic_def)},
		{"icon": "DEX", "value": str(stats.dex)},
		{"icon": "INT", "value": str(stats.int_stat)},
		{"icon": "SPD", "value": str(stats.spd)},
		{"icon": "MOV", "value": str(stats.mov)},
	]
	for entry_variant in entries:
		var entry := entry_variant as Dictionary
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.texture = STAT_ICONS.get(String(entry.get("icon", "")), null) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_party_stats_grid.add_child(icon)
		var value := _new_label(String(entry.get("value", "")), 22, HORIZONTAL_ALIGNMENT_LEFT)
		value.custom_minimum_size = Vector2(64, 30)
		value.clip_text = true
		_party_stats_grid.add_child(value)


func _refresh_party_ability(character: CharacterData) -> void:
	if character == null or character.abilities.is_empty():
		_party_ability_icon.texture = ABILITY_ICONS["harvest"]
		_party_ability_label.text = "None"
		_party_ability_meta_label.text = "No abilities learned yet."
		return
	var ability := character.abilities[0]
	if ability == null:
		return
	var ability_name := String(ability.ability_name)
	_party_ability_icon.texture = _get_ability_icon(ability_name)
	_party_ability_label.text = ability_name
	_party_ability_meta_label.text = "Range %d   Radius %d   Cooldown %d\n%s" % [
		int(ability.range),
		int(ability.radius),
		int(ability.cooldown_turns),
		String(ability.description)
	]


func _refresh_party_equipment(character: CharacterData) -> void:
	for slot_name in ["Weapon", "Armor", "Accessory"]:
		var button := _party_equipment_buttons.get(slot_name, null) as Button
		if button == null:
			continue
		var equipped := _host.call("_get_equipped_item_for_slot", character, slot_name) as Resource
		var label := button.get_node_or_null("SlotLabel") as Label
		if label != null:
			label.text = _host.call("_get_equipment_display_name", equipped, slot_name)
			label.add_theme_font_size_override("font_size", 16)
		button.modulate = ACTIVE_TINT if _get_host_active_equipment_slot() == slot_name else Color.WHITE
	_refresh_party_equipment_picker(character)


func _refresh_party_equipment_picker(character: CharacterData) -> void:
	var picker_open := _get_host_equipment_picker_open()
	_party_equipment_picker.visible = picker_open
	if not picker_open:
		return
	var slot_name := _get_host_active_equipment_slot()
	_party_equipment_title.text = "%s Options" % slot_name
	_clear_container_children(_party_equipment_choice_list)
	_party_equipment_choice_buttons.clear()

	var choices: Array = _host.call("_build_equipment_choices", character, slot_name)
	var equipped := _host.call("_get_equipped_item_for_slot", character, slot_name) as Resource
	for index in range(choices.size()):
		var item := choices[index] as Resource
		var label := "Unequip"
		var icon: Texture2D = null
		if item != null:
			label = _host.call("_get_equipment_display_name", item, slot_name)
			icon = _host.call("_get_equipment_icon", item) as Texture2D
		var button := _make_paper_button(Vector2.ZERO, Vector2(245, 56), label, 19)
		button.custom_minimum_size = Vector2(245, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(choice_index := index) -> void:
			_play_button_sound()
			equipment_choice_requested.emit(choice_index)
		)
		if icon != null:
			var icon_rect := _add_texture(button, icon, Vector2(10, 8), Vector2(38, 38), "ChoiceIcon")
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if item == equipped:
			button.modulate = ACTIVE_TINT
		_party_equipment_choice_list.add_child(button)
		_party_equipment_choice_buttons.append(button)

	var selected_index := int(_host.call("_resolve_equipment_choice_index", character, slot_name, choices))
	if selected_index >= 0 and selected_index < choices.size():
		var selected_item := choices[selected_index] as Resource
		if selected_item == null:
			_party_equipment_detail.text = "Unequip this slot.\n%s" % _host.call("_build_equipment_compare_text", null, equipped)
		else:
			_party_equipment_detail.text = _host.call("_build_equipment_description", selected_item, "No item equipped.", equipped)


func _refresh_items_page() -> void:
	for filter_name in _item_filter_buttons.keys():
		var button := _item_filter_buttons[filter_name] as Button
		if button != null:
			button.modulate = ACTIVE_TINT if String(filter_name) == _active_item_filter else Color.WHITE
	_item_entries = _build_item_entries()
	_selected_item_index = clampi(_selected_item_index, 0, maxi(_item_entries.size() - 1, 0))
	_clear_container_children(_item_list)
	_item_buttons.clear()

	if _item_entries.is_empty():
		var empty := _new_label("No items in this pocket yet.", 30, HORIZONTAL_ALIGNMENT_CENTER)
		empty.custom_minimum_size = Vector2(650, 120)
		_item_list.add_child(empty)
		_refresh_item_detail({})
		return

	for index in range(_item_entries.size()):
		var entry := _item_entries[index]
		var button := _make_item_row(entry, index)
		_item_list.add_child(button)
		_item_buttons.append(button)

	_refresh_item_detail(_item_entries[_selected_item_index])


func _build_item_entries() -> Array[Dictionary]:
	var all_entries: Array[Dictionary] = []
	if ProgressionService != null:
		for slot_name in ["Weapon", "Armor", "Accessory"]:
			var owned: Array = ProgressionService.get_owned_equipment(slot_name)
			for item in owned:
				if item == null:
					continue
				all_entries.append({
					"kind": "equipment",
					"slot": slot_name,
					"category": "%ss" % slot_name,
					"item": item,
				})
	if Global != null:
		for raw_item_key in Global.inventory:
			var item_type := _resolve_inventory_item_enum(raw_item_key)
			if item_type < 0:
				continue
			var count := int(Global.inventory.get(raw_item_key, 0))
			if count <= 0:
				continue
			all_entries.append({
				"kind": "inventory",
				"category": FILTER_SEEDS if _is_seed_item(item_type) else "Item",
				"item_type": item_type,
				"count": count,
			})

	var filtered: Array[Dictionary] = []
	for entry in all_entries:
		if _entry_matches_filter(entry):
			filtered.append(entry)
	return filtered


func _entry_matches_filter(entry: Dictionary) -> bool:
	if _active_item_filter == FILTER_ALL:
		return true
	match _active_item_filter:
		FILTER_WEAPONS:
			return String(entry.get("slot", "")) == "Weapon"
		FILTER_ARMOR:
			return String(entry.get("slot", "")) == "Armor"
		FILTER_ACCESSORIES:
			return String(entry.get("slot", "")) == "Accessory"
		FILTER_SEEDS:
			return String(entry.get("category", "")) == FILTER_SEEDS
	return true


func _make_item_row(entry: Dictionary, index: int) -> Button:
	var row_texture := ITEM_ROW_MID
	if index == 0:
		row_texture = ITEM_ROW_TOP
	elif index == _item_entries.size() - 1:
		row_texture = ITEM_ROW_BOTTOM
	var button := _make_paper_button(Vector2.ZERO, Vector2(690, 86), "", 20)
	button.custom_minimum_size = Vector2(690, 86)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.name = "ItemRow%d" % index
	button.pressed.connect(func(row_index := index) -> void:
		_play_button_sound()
		_selected_item_index = row_index
		_refresh_items_page()
		rebuild_focus_graph()
		if row_index < _item_buttons.size():
			_item_buttons[row_index].grab_focus()
	)
	_add_texture(button, row_texture, Vector2.ZERO, Vector2(690, 86), "RowBg")
	if index == _selected_item_index:
		_add_texture(button, ITEM_SELECTION, Vector2(6, -28), Vector2(116, 108), "Selection")
		button.modulate = ACTIVE_TINT
	var icon_texture := _get_entry_icon(entry)
	var icon := _add_texture(button, icon_texture, Vector2(38, 16), Vector2(56, 56), "ItemIcon")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var label := _add_label(button, _get_entry_name(entry), Vector2(118, 17), Vector2(390, 38), 27, HORIZONTAL_ALIGNMENT_LEFT)
	label.clip_text = true
	var sub := _add_label(button, _get_entry_subtitle(entry), Vector2(120, 52), Vector2(500, 28), 19, HORIZONTAL_ALIGNMENT_LEFT)
	sub.clip_text = true
	if _is_entry_equipped(entry):
		_add_texture(button, ITEM_MARKER_EQUIPPED, Vector2(600, 15), Vector2(40, 40), "EquippedMarker")
	return button


func _refresh_item_detail(entry: Dictionary) -> void:
	if entry.is_empty():
		_item_name_label.text = "Empty"
		_item_preview_icon.texture = null
		_item_detail_label.text = "There is nothing to inspect here yet."
		_item_stats_label.text = ""
		_item_owner_label.text = ""
		_item_action_button.visible = false
		return

	_item_name_label.text = _get_entry_name(entry)
	_item_preview_icon.texture = _get_entry_icon(entry)
	_item_detail_label.text = _get_entry_description(entry)
	_item_stats_label.text = _get_entry_stats(entry)
	_item_owner_label.text = _get_entry_owner(entry)
	var action := _get_entry_action(entry)
	_item_action_button.visible = not action.is_empty()
	_item_action_button.text = action
	_item_action_button.disabled = not _can_use_entry_action(entry)
	_item_action_button.modulate = Color.WHITE if not _item_action_button.disabled else DISABLED_TINT


func _on_item_action_pressed() -> void:
	if _selected_item_index < 0 or _selected_item_index >= _item_entries.size():
		return
	var entry := _item_entries[_selected_item_index]
	if not _can_use_entry_action(entry):
		return
	_play_button_sound()
	if String(entry.get("kind", "")) == "equipment":
		item_equip_requested.emit(entry)
	elif String(entry.get("kind", "")) == "inventory":
		item_use_requested.emit(int(entry.get("item_type", -1)))


func _refresh_stages_page() -> void:
	var current_stage := _get_current_stage()
	var completed_count := clampi(current_stage - 1, 0, 10)
	_selected_stage = clampi(_selected_stage, 1, 10)
	for index in range(_stage_buttons.size()):
		var stage_number := index + 1
		var button := _stage_buttons[index]
		if stage_number <= completed_count:
			button.texture_normal = STAGE_DONE
			button.texture_pressed = STAGE_DONE
		elif stage_number == current_stage:
			button.texture_normal = STAGE_CURRENT
			button.texture_pressed = STAGE_CURRENT
		else:
			button.texture_normal = STAGE_BLIGHT
			button.texture_pressed = STAGE_BLIGHT
		button.modulate = ACTIVE_TINT if stage_number == _selected_stage else Color.WHITE
	_refresh_stage_detail()


func _refresh_stage_detail() -> void:
	if _stage_detail_label == null:
		return
	var current_stage := _get_current_stage()
	var state := "Ahead"
	if _selected_stage < current_stage:
		state = "Cleared"
	elif _selected_stage == current_stage:
		state = "Current"
	_stage_detail_label.text = "Stage %d of 10  |  %s\nClear stages to earn Bloom Points, Gold, and party levels." % [_selected_stage, state]


func _rebuild_party_focus_graph() -> void:
	_link_grid_focus(get_roster_buttons(), 2)
	var tabs: Array[Control] = [get_tab_button(SECTION_PARTY), get_tab_button(SECTION_ITEMS), get_tab_button(SECTION_STAGES)]
	for button in _party_roster_buttons:
		_set_focus_neighbor(button, Vector2.UP, tabs[0])
		_set_focus_neighbor(button, Vector2.RIGHT, _party_equipment_buttons.get("Weapon", null) as Control)
	var slot_buttons: Array[Control] = []
	for slot_name in ["Weapon", "Armor", "Accessory"]:
		var slot_button := _party_equipment_buttons.get(slot_name, null) as Control
		if slot_button != null:
			slot_buttons.append(slot_button)
	_link_horizontal_focus(slot_buttons)
	for slot_button in slot_buttons:
		_set_focus_neighbor(slot_button, Vector2.LEFT, _party_roster_buttons[0] if not _party_roster_buttons.is_empty() else get_tab_button(SECTION_PARTY))
		_set_focus_neighbor(slot_button, Vector2.UP, get_tab_button(SECTION_PARTY))
		_set_focus_neighbor(slot_button, Vector2.DOWN, _party_equipment_choice_buttons[0] if _get_host_equipment_picker_open() and not _party_equipment_choice_buttons.is_empty() else slot_button)
	if _get_host_equipment_picker_open():
		_link_vertical_focus(_party_equipment_choice_buttons)
		for choice in _party_equipment_choice_buttons:
			_set_focus_neighbor(choice, Vector2.UP, _party_equipment_buttons.get(_get_host_active_equipment_slot(), null) as Control)
			_set_focus_neighbor(choice, Vector2.LEFT, _party_equipment_buttons.get(_get_host_active_equipment_slot(), null) as Control)


func _rebuild_items_focus_graph() -> void:
	var filters: Array[Control] = []
	for filter_name in [FILTER_ALL, FILTER_WEAPONS, FILTER_ARMOR, FILTER_ACCESSORIES, FILTER_SEEDS]:
		var filter_button := _item_filter_buttons.get(filter_name, null) as Control
		if filter_button != null:
			filters.append(filter_button)
	_link_horizontal_focus(filters)
	for filter_button in filters:
		_set_focus_neighbor(filter_button, Vector2.UP, get_tab_button(SECTION_ITEMS))
		_set_focus_neighbor(filter_button, Vector2.DOWN, _item_buttons[0] if not _item_buttons.is_empty() else filter_button)
	_link_vertical_focus(_item_buttons)
	for item_button in _item_buttons:
		_set_focus_neighbor(item_button, Vector2.LEFT, item_button)
		_set_focus_neighbor(item_button, Vector2.RIGHT, _item_action_button if _item_action_button.visible and not _item_action_button.disabled else item_button)
		_set_focus_neighbor(item_button, Vector2.UP, _item_filter_buttons.get(_active_item_filter, null) as Control)
	if _item_action_button.visible:
		_set_focus_neighbor(_item_action_button, Vector2.LEFT, _item_buttons[_selected_item_index] if not _item_buttons.is_empty() else _item_action_button)
		_set_focus_neighbor(_item_action_button, Vector2.UP, get_tab_button(SECTION_ITEMS))


func _rebuild_stages_focus_graph() -> void:
	_link_grid_focus(_stage_buttons, 6)
	for button in _stage_buttons:
		_set_focus_neighbor(button, Vector2.UP, get_tab_button(SECTION_STAGES))


func _make_texture_tab(texture: Texture2D, pos: Vector2, label_text: String, section: int) -> TextureButton:
	var button := TextureButton.new()
	button.name = "%sTab" % label_text
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.position = pos
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void:
		_play_button_sound()
		section_requested.emit(section)
	)
	button.focus_entered.connect(_play_browse_sound)
	button.mouse_entered.connect(_play_browse_sound)
	_canvas.add_child(button)
	var label := _add_label(button, label_text, Vector2(86, 70), Vector2(185, 66), 46, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_font_override("font", FONT_HAND)
	label.add_theme_color_override("font_color", Color.WHITE)
	return button


func _make_paper_button(pos: Vector2, size_value: Vector2, text: String, font_size: int) -> Button:
	var button := Button.new()
	button.position = pos
	button.size = size_value
	button.custom_minimum_size = size_value
	button.text = text
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", FONT_HAND)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	_apply_empty_button_styles(button)
	button.focus_entered.connect(_play_browse_sound)
	button.mouse_entered.connect(_play_browse_sound)
	return button


func _apply_empty_button_styles(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(1.0, 0.92, 0.38, 0.16)
	focus_style.border_color = Color(0.26, 0.15, 0.05, 0.78)
	focus_style.border_width_left = 3
	focus_style.border_width_top = 3
	focus_style.border_width_right = 3
	focus_style.border_width_bottom = 3
	button.add_theme_stylebox_override("focus", focus_style)


func _add_texture(parent: Node, texture: Texture2D, pos: Vector2, size_value: Vector2, node_name: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.texture = texture
	rect.position = pos
	rect.size = size_value
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(rect)
	return rect


func _add_label(parent: Node, text: String, pos: Vector2, size_value: Vector2, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := _new_label(text, font_size, alignment)
	label.position = pos
	label.size = size_value
	parent.add_child(label)
	return label


func _new_label(text: String, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_HAND)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _get_role_icon(character: CharacterData) -> Texture2D:
	if character == null or character.class_data == null:
		return ROLE_ICONS["support"]
	var role := String(character.class_data.role).to_lower()
	if ROLE_ICONS.has(role):
		return ROLE_ICONS[role]
	var class_label := String(character.class_data.metadata_name).to_lower()
	if class_label.contains("archer") or class_label.contains("ranger"):
		return ROLE_ICONS["ranged"]
	if class_label.contains("tank") or class_label.contains("warrior"):
		return ROLE_ICONS["tank"]
	if class_label.contains("healer") or class_label.contains("support"):
		return ROLE_ICONS["support"]
	return ROLE_ICONS["dps"]


func _get_class_label(character: CharacterData) -> String:
	if character == null or character.class_data == null:
		return "Adventurer"
	return String(character.class_data.metadata_name)


func _get_ability_icon(ability_name: String) -> Texture2D:
	var lower := ability_name.to_lower()
	for key in ABILITY_ICONS.keys():
		if lower.contains(String(key)):
			return ABILITY_ICONS[key]
	return ABILITY_ICONS["harvest"]


func _get_entry_name(entry: Dictionary) -> String:
	if String(entry.get("kind", "")) == "equipment":
		return _host.call("_get_equipment_display_name", entry.get("item", null), String(entry.get("slot", "")))
	return Global.get_item_display_name(int(entry.get("item_type", -1))) if Global != null else "Item"


func _get_entry_subtitle(entry: Dictionary) -> String:
	if String(entry.get("kind", "")) == "equipment":
		var slot_name := String(entry.get("slot", ""))
		var item := entry.get("item", null) as Resource
		return "%s%s" % [slot_name, _host.call("_build_equipment_owner_suffix", item, slot_name)]
	var count := int(entry.get("count", 0))
	var item_type := int(entry.get("item_type", -1))
	if _is_seed_item(item_type):
		return "Seed pouch  x%d" % count
	return "Inventory  x%d" % count


func _get_entry_icon(entry: Dictionary) -> Texture2D:
	if String(entry.get("kind", "")) == "equipment":
		return _host.call("_get_equipment_icon", entry.get("item", null)) as Texture2D
	return _get_inventory_icon(int(entry.get("item_type", -1)))


func _get_entry_description(entry: Dictionary) -> String:
	if String(entry.get("kind", "")) == "equipment":
		var item := entry.get("item", null) as Resource
		var character := _host.call("_get_selected_party_member") as CharacterData
		var slot_name := String(entry.get("slot", ""))
		var equipped := _host.call("_get_equipped_item_for_slot", character, slot_name) as Resource
		return _host.call("_build_equipment_description", item, "No item equipped.", equipped)
	var item_type := int(entry.get("item_type", -1))
	var lines: PackedStringArray = []
	lines.append("Quantity: %d" % int(entry.get("count", 0)))
	if _is_seed_item(item_type):
		lines.append("Growth: %s" % Global.get_seed_growth_label(item_type))
		var harvest_item := int(Global.HARVEST_DROPS.get(item_type, -1))
		if harvest_item >= 0:
			lines.append("Grows into %s." % Global.get_item_display_name(harvest_item))
	elif Global != null and Global.is_battle_tonic(item_type):
		lines.append("Battle tonic. Use from battle item menus.")
	elif Global != null and Global.food_stats.has(item_type):
		lines.append("Meal perk item. Use to prepare the next fight.")
	else:
		lines.append("A stored settlement item.")
	return "\n".join(lines)


func _get_entry_stats(entry: Dictionary) -> String:
	if String(entry.get("kind", "")) == "equipment":
		var bonuses: Variant = (entry.get("item", null) as Resource).get("stat_bonuses")
		if bonuses is not Dictionary:
			return ""
		var parts: PackedStringArray = []
		var labels := {
			"strength": "STR",
			"defense": "DEF",
			"magic_defense": "MDEF",
			"dexterity": "DEX",
			"intelligence": "INT",
			"speed": "SPD",
		}
		for key in labels.keys():
			var value := int((bonuses as Dictionary).get(key, 0))
			if value != 0:
				parts.append("%s %+d" % [String(labels[key]), value])
		return "\n".join(parts)
	var item_type := int(entry.get("item_type", -1))
	if Global != null and Global.food_stats.has(item_type):
		var stats: Dictionary = Global.food_stats[item_type]
		var parts: PackedStringArray = []
		for key in ["VIT", "STR", "DEF", "DEX", "INT", "SPD", "MOV"]:
			var value := int(stats.get(key, 0))
			if value != 0:
				parts.append("%s %+d" % [key, value])
		return "\n".join(parts)
	return ""


func _get_entry_owner(entry: Dictionary) -> String:
	if String(entry.get("kind", "")) == "equipment":
		var item := entry.get("item", null) as Resource
		var slot_name := String(entry.get("slot", ""))
		return String(_host.call("_build_equipment_owner_suffix", item, slot_name)).replace("[", "").replace("]", "")
	if String(entry.get("category", "")) == FILTER_SEEDS:
		return "Seed pouch"
	return "Inventory"


func _get_entry_action(entry: Dictionary) -> String:
	if String(entry.get("kind", "")) == "equipment":
		var character := _host.call("_get_selected_party_member") as CharacterData
		return "Equip\n%s" % (String(character.display_name) if character != null else "")
	if String(entry.get("kind", "")) == "inventory" and Global != null and Global.food_stats.has(int(entry.get("item_type", -1))):
		return "Use"
	return ""


func _can_use_entry_action(entry: Dictionary) -> bool:
	if String(entry.get("kind", "")) == "equipment":
		var character := _host.call("_get_selected_party_member") as CharacterData
		var item := entry.get("item", null) as Resource
		if character == null or item == null:
			return false
		if item is WeaponData and ProgressionService != null:
			return ProgressionService.can_character_equip_item(character, item)
		return true
	if String(entry.get("kind", "")) == "inventory":
		var item_type := int(entry.get("item_type", -1))
		return Global != null and Global.food_stats.has(item_type) and int(entry.get("count", 0)) > 0
	return false


func _is_entry_equipped(entry: Dictionary) -> bool:
	if String(entry.get("kind", "")) != "equipment":
		return false
	var item := entry.get("item", null) as Resource
	var slot_name := String(entry.get("slot", ""))
	if item == null:
		return false
	if ProgressionService == null:
		return false
	for member in ProgressionService.get_party_roster():
		var equipped := _host.call("_get_equipped_item_for_slot", member, slot_name) as Resource
		if equipped == item:
			return true
	return false


func _get_inventory_icon(item_type: int) -> Texture2D:
	if Global == null or item_type < 0:
		return null
	if item_type == int(Global.Items.APPLE):
		return ITEM_APPLE
	if Global.is_battle_tonic(item_type):
		return ITEM_POTION
	var coords := _get_inventory_icon_coords(item_type)
	if not coords.has("sheet"):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = coords["sheet"]
	var cell := coords["cell"] as Vector2i
	atlas.region = Rect2(cell.x * 32, cell.y * 32, 32, 32)
	return atlas


func _get_inventory_icon_coords(item_type: int) -> Dictionary:
	var map := {
		Global.Items.BLUEBERRY_SEED: [ITEM_SHEET_FARM, Vector2i(3, 17)],
		Global.Items.WHEAT_SEED: [ITEM_SHEET_FARM, Vector2i(4, 17)],
		Global.Items.MELON_SEED: [ITEM_SHEET_FARM, Vector2i(5, 17)],
		Global.Items.CORN_SEED: [ITEM_SHEET_FARM, Vector2i(6, 17)],
		Global.Items.HOT_PEPPER_SEED: [ITEM_SHEET_FARM, Vector2i(7, 17)],
		Global.Items.RADISH_SEED: [ITEM_SHEET_FARM, Vector2i(8, 17)],
		Global.Items.RED_CABBAGE_SEED: [ITEM_SHEET_FARM, Vector2i(9, 17)],
		Global.Items.TOMATO_SEED: [ITEM_SHEET_FARM, Vector2i(10, 17)],
		Global.Items.CARROT_SEED: [ITEM_SHEET_FARM, Vector2i(13, 17)],
		Global.Items.CAULIFLOWER_SEED: [ITEM_SHEET_FARM, Vector2i(14, 17)],
		Global.Items.POTATO_SEED: [ITEM_SHEET_FARM, Vector2i(15, 17)],
		Global.Items.PARSNIP_SEED: [ITEM_SHEET_FARM, Vector2i(16, 17)],
		Global.Items.GARLIC_SEED: [ITEM_SHEET_FARM, Vector2i(17, 17)],
		Global.Items.GREEN_BEANS_SEED: [ITEM_SHEET_FARM, Vector2i(18, 17)],
		Global.Items.STRAWBERRY_SEED: [ITEM_SHEET_FARM, Vector2i(19, 17)],
		Global.Items.COFFEE_BEAN_SEED: [ITEM_SHEET_FARM, Vector2i(20, 17)],
		Global.Items.PUMPKIN_SEED: [ITEM_SHEET_FARM, Vector2i(24, 17)],
		Global.Items.BROCCOLI_SEED: [ITEM_SHEET_FARM, Vector2i(25, 17)],
		Global.Items.ARTICHOKE_SEED: [ITEM_SHEET_FARM, Vector2i(26, 17)],
		Global.Items.EGGPLANT_SEED: [ITEM_SHEET_FARM, Vector2i(27, 17)],
		Global.Items.BOK_CHOY_SEED: [ITEM_SHEET_FARM, Vector2i(28, 17)],
		Global.Items.GRAPE_SEED: [ITEM_SHEET_FARM, Vector2i(29, 17)],
		Global.Items.BLUEBERRY: [ITEM_SHEET_FARM, Vector2i(10, 8)],
		Global.Items.WHEAT: [ITEM_SHEET_FARM, Vector2i(10, 9)],
		Global.Items.MELON: [ITEM_SHEET_FARM, Vector2i(10, 10)],
		Global.Items.CORN: [ITEM_SHEET_FARM, Vector2i(10, 11)],
		Global.Items.HOT_PEPPER: [ITEM_SHEET_FARM, Vector2i(10, 12)],
		Global.Items.RADISH: [ITEM_SHEET_FARM, Vector2i(10, 13)],
		Global.Items.RED_CABBAGE: [ITEM_SHEET_FARM, Vector2i(10, 14)],
		Global.Items.TOMATO: [ITEM_SHEET_FARM, Vector2i(10, 15)],
		Global.Items.CARROT: [ITEM_SHEET_FARM, Vector2i(20, 8)],
		Global.Items.CAULIFLOWER: [ITEM_SHEET_FARM, Vector2i(20, 9)],
		Global.Items.POTATO: [ITEM_SHEET_FARM, Vector2i(20, 10)],
		Global.Items.PARSNIP: [ITEM_SHEET_FARM, Vector2i(20, 11)],
		Global.Items.GARLIC: [ITEM_SHEET_FARM, Vector2i(20, 12)],
		Global.Items.GREEN_BEANS: [ITEM_SHEET_FARM, Vector2i(20, 13)],
		Global.Items.STRAWBERRY: [ITEM_SHEET_FARM, Vector2i(20, 14)],
		Global.Items.COFFEE_BEAN: [ITEM_SHEET_FARM, Vector2i(20, 15)],
		Global.Items.PUMPKIN: [ITEM_SHEET_FARM, Vector2i(30, 8)],
		Global.Items.BROCCOLI: [ITEM_SHEET_FARM, Vector2i(30, 9)],
		Global.Items.ARTICHOKE: [ITEM_SHEET_FARM, Vector2i(30, 10)],
		Global.Items.EGGPLANT: [ITEM_SHEET_FARM, Vector2i(30, 11)],
		Global.Items.BOK_CHOY: [ITEM_SHEET_FARM, Vector2i(30, 12)],
		Global.Items.GRAPE: [ITEM_SHEET_FARM, Vector2i(30, 13)],
		Global.Items.WOOD: [ITEM_SHEET_LOOT, Vector2i(5, 4)],
		Global.Items.STONE: [ITEM_SHEET_LOOT, Vector2i(5, 2)],
		Global.Items.WATER: [ITEM_SHEET_FURNITURE, Vector2i(21, 4)],
	}
	if not map.has(item_type):
		return {}
	var data: Array = map[item_type]
	return {"sheet": data[0], "cell": data[1]}


func _resolve_inventory_item_enum(raw_item_key: Variant) -> int:
	if raw_item_key is int:
		return int(raw_item_key)
	var key_name := String(raw_item_key)
	if key_name.is_empty() or Global == null:
		return -1
	return Global.Items.keys().find(key_name)


func _is_seed_item(item_type: int) -> bool:
	return Global != null and Global.HARVEST_DROPS.has(item_type)


func _get_host_section() -> int:
	return int(_host.get("_current_section")) if _host != null else SECTION_PARTY


func _get_host_selected_party_index() -> int:
	return int(_host.get("_selected_party_index")) if _host != null else 0


func _get_host_equipment_picker_open() -> bool:
	return bool(_host.get("_party_equipment_picker_open")) if _host != null else false


func _get_host_active_equipment_slot() -> String:
	return String(_host.get("_active_equipment_slot")) if _host != null else "Weapon"


func _get_current_stage() -> int:
	return clampi(maxi(Global.loop_battle_index, 1), 1, 10) if Global != null else 1


func _play_browse_sound() -> void:
	var ui_sounds := get_node_or_null("/root/UISoundManager")
	if ui_sounds != null:
		ui_sounds.play_browse_general(self)


func _play_button_sound() -> void:
	var ui_sounds := get_node_or_null("/root/UISoundManager")
	if ui_sounds != null:
		ui_sounds.play_menu_button()


func _clear_container_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


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


func _link_grid_focus(controls: Array, columns: int) -> void:
	columns = maxi(columns, 1)
	for index in range(controls.size()):
		var control := controls[index] as Control
		if control == null:
			continue
		var left_index := index - 1 if index % columns != 0 else -1
		var right_index := index + 1 if (index + 1) % columns != 0 and index + 1 < controls.size() else -1
		var up_index := index - columns
		var down_index := index + columns
		_set_focus_neighbor(control, Vector2.LEFT, controls[left_index] if left_index >= 0 else control)
		_set_focus_neighbor(control, Vector2.RIGHT, controls[right_index] if right_index >= 0 else control)
		_set_focus_neighbor(control, Vector2.UP, controls[up_index] if up_index >= 0 else control)
		_set_focus_neighbor(control, Vector2.DOWN, controls[down_index] if down_index < controls.size() else control)


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
