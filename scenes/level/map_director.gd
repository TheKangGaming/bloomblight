extends Node

@export var base_level: int = 1
@export var min_level: int = 1
@export var max_level: int = 99
@export var use_player_level: bool = true
@export var class_level_offsets: Dictionary = {}
@export var enemy_stat_scale_by_class: Dictionary = {}
@export var enemy_stat_flat_bonus_by_class: Dictionary = {}


func _ready() -> void:
	_apply_enemy_level_scaling()
	var tree := get_tree()
	if tree != null and not tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.connect(_on_tree_node_added)


func _exit_tree() -> void:
	var tree := get_tree()
	if tree != null and tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.disconnect(_on_tree_node_added)


func configure_enemy_spawn(enemy: Unit) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if not enemy.is_enemy:
		return
	if enemy.get_meta("map_director_scaled", false):
		return

	var target_level := _compute_enemy_target_level(enemy)
	var leveled_stats := _build_enemy_stats_for_level(enemy, target_level)
	if leveled_stats == null:
		return

	enemy.apply_runtime_stats(leveled_stats)
	enemy.level = target_level
	enemy.set_meta("map_director_scaled", true)
	enemy.set_meta("map_director_target_level", target_level)


func _apply_enemy_level_scaling() -> void:
	for unit in _find_map_units():
		configure_enemy_spawn(unit)


func _on_tree_node_added(node: Node) -> void:
	if not (node is Unit):
		return

	var unit := node as Unit
	if not unit.is_enemy:
		return

	call_deferred("configure_enemy_spawn", unit)


func _compute_enemy_target_level(enemy: Unit) -> int:
	var computed_level := enemy.level if enemy != null and enemy.level > 0 else base_level
	if use_player_level:
		computed_level = _resolve_player_level()

	computed_level += _get_class_level_offset(enemy)
	var lower_bound := mini(min_level, max_level)
	var upper_bound := maxi(min_level, max_level)
	return clampi(computed_level, lower_bound, upper_bound)


func _build_enemy_stats_for_level(enemy: Unit, target_level: int) -> UnitStats:
	if enemy.character_data == null:
		return enemy.current_stats.clone() if enemy.current_stats != null else UnitStats.new()

	var generated_stats := UnitStats.new()
	generated_stats.apply_class_progression(enemy.character_data)

	var level_ups := maxi(target_level, 1) - 1
	if level_ups > 0:
		generated_stats.apply_auto_levels(level_ups)

	_apply_enemy_stat_scaling(enemy, generated_stats)

	return generated_stats


func _apply_enemy_stat_scaling(enemy: Unit, generated_stats: UnitStats) -> void:
	if enemy == null or generated_stats == null:
		return

	var class_key := _get_enemy_class_key(enemy)
	if class_key.is_empty():
		return

	var scale_map: Dictionary = _get_class_table_entry(enemy_stat_scale_by_class, class_key)
	if not scale_map.is_empty():
		_apply_stat_scale_map(generated_stats, scale_map)

	var flat_map: Dictionary = _get_class_table_entry(enemy_stat_flat_bonus_by_class, class_key)
	if not flat_map.is_empty():
		generated_stats.apply_delta(flat_map)

	generated_stats.clamp_to_caps()
	generated_stats.hp = generated_stats.max_hp


func _get_class_table_entry(table: Dictionary, class_key: String) -> Dictionary:
	if table.has(class_key) and table[class_key] is Dictionary:
		return table[class_key] as Dictionary
	if table.has("default") and table["default"] is Dictionary:
		return table["default"] as Dictionary
	return {}


func _apply_stat_scale_map(stats: UnitStats, scale_map: Dictionary) -> void:
	for raw_key in scale_map.keys():
		var property_name := _stat_property_from_key(String(raw_key))
		if property_name.is_empty():
			continue

		var current_value := int(stats.get(property_name))
		var scale_percent := maxi(int(scale_map[raw_key]), 0)
		var scaled_value := int(round(float(current_value) * (float(scale_percent) / 100.0)))
		stats.set(property_name, scaled_value)


func _stat_property_from_key(raw_key: String) -> String:
	match raw_key.to_upper():
		"HP", "MAX_HP", "MAX_HEALTH":
			return "max_hp"
		"STR", "STRENGTH":
			return "str"
		"DEF", "DEFENSE", "PHYSICAL_DEF", "PHYSICAL_DEFENSE":
			return "physical_def"
		"MDEF", "MAGIC_DEF", "MAGIC_DEFENSE":
			return "magic_def"
		"DEX", "DEXTERITY":
			return "dex"
		"INT", "INTELLIGENCE":
			return "int_stat"
		"SPD", "SPEED":
			return "spd"
		"MOV", "MOVE_RANGE":
			return "mov"
		"ATK_RNG", "ATTACK_RANGE":
			return "atk_rng"
		_:
			return ""


func _get_enemy_class_key(enemy: Unit) -> String:
	if enemy == null or enemy.character_data == null or enemy.character_data.class_data == null:
		return ""

	return String(enemy.character_data.class_data.metadata_name)


func _resolve_player_level() -> int:
	var global_node := get_node_or_null("/root/Global")
	if global_node != null:
		if global_node.has_method("get_player_level"):
			return int(global_node.call("get_player_level"))

		var maybe_player_level = global_node.get("player_level")
		if maybe_player_level != null:
			return int(maybe_player_level)

	for unit in _find_map_units():
		if unit.is_player:
			if unit.has_meta("level"):
				return int(unit.get_meta("level"))

			var maybe_level = unit.get("level")
			if maybe_level != null:
				return int(maybe_level)

	return base_level


func _get_class_level_offset(enemy: Unit) -> int:
	if enemy == null or enemy.character_data == null:
		return 0

	var class_info := enemy.character_data.class_data
	if class_info == null:
		return 0

	var lookup_keys := [
		String(class_info.metadata_name),
		String(enemy.character_data.display_name),
	]

	for key in lookup_keys:
		if key.is_empty():
			continue
		if class_level_offsets.has(key):
			return int(class_level_offsets[key])

	return 0


func _find_map_units() -> Array[Unit]:
	var units: Array[Unit] = []
	var board := get_parent().get_node_or_null("GameBoard") if get_parent() != null else null
	if board == null:
		return units

	for child in board.get_children():
		if child is Unit:
			units.append(child)

	return units
