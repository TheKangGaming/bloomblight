extends Node

signal party_roster_changed
signal equipment_catalog_changed

const SAVANNAH_PATH := "res://data/units/Savannah/savannah_data.tres"
const TERA_PATH := "res://data/units/Tera/tera_data.tres"
const SILAS_PATH := "res://data/units/Silas/silas_data.tres"

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_seed: int = 0
var party_roster: Array[CharacterData] = []

var _character_library: Dictionary = {}
var _equipment_catalog := {
	"Weapon": [],
	"Armor": [],
	"Accessory": [],
}

func _ready() -> void:
	if current_seed == 0:
		seed_from_run(int(Time.get_unix_time_from_system()))
	reset_demo_roster()

func reset_demo_roster() -> void:
	_character_library.clear()
	_equipment_catalog = {
		"Weapon": [],
		"Armor": [],
		"Accessory": [],
	}
	party_roster.clear()

	var savannah_data := _load_character_data(SAVANNAH_PATH)
	var tera_data := _load_character_data(TERA_PATH)
	if savannah_data != null:
		party_roster.append(savannah_data)
		_register_character_equipment(savannah_data)
	if tera_data != null:
		party_roster.append(tera_data)
		_register_character_equipment(tera_data)

	_sync_player_equipment_to_global()
	party_roster_changed.emit()
	equipment_catalog_changed.emit()

func get_party_roster() -> Array[CharacterData]:
	return party_roster.duplicate()

func get_player_character_data() -> CharacterData:
	if not party_roster.is_empty():
		return party_roster[0]
	return null

func get_starting_player_level() -> int:
	return 1

func seed_from_run(run_seed: int) -> void:
	_set_seed(run_seed)

func seed_from_map(map_seed: int) -> void:
	_set_seed(map_seed)

func seed_from_save(save_seed: int) -> void:
	_set_seed(save_seed)

func roll_growth(chance_percent: int) -> bool:
	var clamped_chance := clampi(chance_percent, 0, 100)
	return rng.randf() < (clamped_chance / 100.0)

func ensure_party_member(display_name: String) -> CharacterData:
	var normalized_name := display_name.strip_edges().to_lower()
	if normalized_name.is_empty():
		return null

	var existing := get_party_member_by_name(display_name)
	if existing != null:
		return existing

	var path := ""
	match normalized_name:
		"savannah":
			path = SAVANNAH_PATH
		"tera":
			path = TERA_PATH
		"silas":
			path = SILAS_PATH

	if path.is_empty():
		return null

	var character := _load_character_data(path)
	if character == null:
		return null

	party_roster.append(character)
	_register_character_equipment(character)
	party_roster_changed.emit()
	equipment_catalog_changed.emit()
	return character

func get_party_member_by_name(display_name: String) -> CharacterData:
	var normalized_name := display_name.strip_edges().to_lower()
	for member in party_roster:
		if member != null and String(member.display_name).strip_edges().to_lower() == normalized_name:
			return member
	return null

func get_owned_equipment(slot_name: String) -> Array:
	var catalog: Array = _equipment_catalog.get(slot_name, [])
	return catalog.duplicate()

func equip_character_item(character: CharacterData, slot_name: String, item: Resource) -> bool:
	if character == null:
		return false

	var canonical_slot := _normalize_slot_name(slot_name)
	if canonical_slot.is_empty():
		return false

	if item != null:
		_register_equipment_item(canonical_slot, item)
		_remove_item_from_other_party_members(character, canonical_slot, item)

	match canonical_slot:
		"Weapon":
			character.equipped_weapon = item as WeaponData
		"Armor":
			character.equipped_armor = item as ArmorData
		"Accessory":
			character.equipped_accessory = item as AccessoryData
		_:
			return false

	_sync_player_equipment_to_global()
	party_roster_changed.emit()
	equipment_catalog_changed.emit()
	return true

func unequip_character_slot(character: CharacterData, slot_name: String) -> bool:
	return equip_character_item(character, slot_name, null)

func sync_runtime_party_to_scene(scene_root: Node) -> void:
	if scene_root == null:
		return

	for member in party_roster:
		if member == null:
			continue
		var unit := scene_root.get_node_or_null("GameBoard/%s" % String(member.display_name))
		if unit != null:
			unit.character_data = member

func print_class_growth_debug_summary(characters: Array[CharacterData], levels_to_simulate: int = 20, simulations_per_class: int = 250) -> void:
	if characters.is_empty():
		print("[ProgressionService] No character entries were provided for growth summary.")
		return

	var level_count := maxi(levels_to_simulate, 0)
	var runs := maxi(simulations_per_class, 1)

	print("[ProgressionService] Growth summary across ", runs, " simulations and ", level_count, " level-ups.")
	for entry in characters:
		if entry == null or entry.class_data == null:
			continue

		var class_info := entry.class_data
		var gains_totals := {
			"MAX_HP": 0.0,
			"STR": 0.0,
			"DEF": 0.0,
			"DEX": 0.0,
			"INT": 0.0,
			"SPD": 0.0,
			"MOV": 0.0,
			"ATK_RNG": 0.0,
		}

		for _run in range(runs):
			var sim_stats := UnitStats.new()
			sim_stats.apply_class_progression(entry)
			var gains := sim_stats.apply_auto_levels(level_count)
			for growth_key in gains_totals.keys():
				gains_totals[growth_key] = float(gains_totals[growth_key]) + float(gains.get(growth_key, 0))

		var average_gains := {}
		for growth_key in gains_totals.keys():
			average_gains[growth_key] = snappedf(float(gains_totals[growth_key]) / runs, 0.01)

		var class_label := class_info.metadata_name if not class_info.metadata_name.is_empty() else entry.display_name
		print("[ProgressionService] ", class_label,
			" | role=", class_info.role,
			" | primary=", class_info.primary_damage_stat,
			" | secondary=", class_info.secondary_stat,
			" | avg gains=", average_gains)

func _load_character_data(path: String) -> CharacterData:
	if _character_library.has(path):
		return _character_library[path]

	var resource := load(path) as CharacterData
	if resource == null:
		return null

	var character := resource.duplicate(true) as CharacterData
	_character_library[path] = character
	return character

func _set_seed(seed_value: int) -> void:
	current_seed = seed_value
	rng.seed = current_seed

func _register_character_equipment(character: CharacterData) -> void:
	if character == null:
		return
	_register_equipment_item("Weapon", character.equipped_weapon)
	_register_equipment_item("Armor", character.equipped_armor)
	_register_equipment_item("Accessory", character.equipped_accessory)

func _register_equipment_item(slot_name: String, item: Resource) -> void:
	if item == null:
		return
	var catalog: Array = _equipment_catalog.get(slot_name, [])
	if not catalog.has(item):
		catalog.append(item)
		_equipment_catalog[slot_name] = catalog

func _remove_item_from_other_party_members(target_character: CharacterData, slot_name: String, item: Resource) -> void:
	if item == null:
		return
	for member in party_roster:
		if member == null or member == target_character:
			continue
		match slot_name:
			"Weapon":
				if member.equipped_weapon == item:
					member.equipped_weapon = null
			"Armor":
				if member.equipped_armor == item:
					member.equipped_armor = null
			"Accessory":
				if member.equipped_accessory == item:
					member.equipped_accessory = null

func _normalize_slot_name(slot_name: String) -> String:
	match slot_name.strip_edges().to_lower():
		"weapon":
			return "Weapon"
		"armor":
			return "Armor"
		"accessory":
			return "Accessory"
		_:
			return ""

func _sync_player_equipment_to_global() -> void:
	if Global == null:
		return

	var player_data := get_player_character_data()
	Global.equipment["Weapon"] = player_data.equipped_weapon if player_data != null else null
	Global.equipment["Armor"] = player_data.equipped_armor if player_data != null else null
	Global.equipment["Accessory"] = player_data.equipped_accessory if player_data != null else null
	Global.ensure_player_stat_formats()
	if Global.has_method("_refresh_equipment_temporary_modifiers"):
		Global.call("_refresh_equipment_temporary_modifiers")
	Global.stats_updated.emit()
