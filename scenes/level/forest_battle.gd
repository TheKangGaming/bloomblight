extends Node2D

const FOREST_BACKDROP_SCENE := preload("res://scenes/level/battlemap.tmx")
const BANDIT_WARRIOR_SCENE := preload("res://scenes/units/BanditWarrior.tscn")
const BANDIT_ARCHER_SCENE := preload("res://scenes/units/BanditArcher.tscn")
const BANDIT_MARAUDER_SCENE := preload("res://scenes/units/BanditMarauder.tscn")
const BANDIT_ASSASSIN_SCENE := preload("res://scenes/units/BanditAssassin.tscn")
const BANDIT_SPEARMAN_SCENE := preload("res://scenes/units/BanditSpearman.tscn")
const BANDIT_ROBBER_SCENE := preload("res://scenes/units/BanditRobber.tscn")

const FOREST_MAP_SIZE := Vector2(24, 16)
const FOREST_CELL_SIZE := Vector2(32, 32)

const FOREST_CURSOR_CELL := Vector2(11, 3)
const FOREST_SAVANNAH_CELL := Vector2(11, 3)
const FOREST_TERA_CELL := Vector2(12, 4)
const FOREST_SILAS_CELL := Vector2(13, 3)
const FOREST_ENEMY_CELLS := [
	Vector2(11, 11),
	Vector2(12, 12),
	Vector2(13, 11),
]
const FOREST_DEPLOYMENT_CELLS := [
	Vector2(11, 3),
	Vector2(12, 4),
	Vector2(13, 3),
]

const ENEMY_TYPE_WARRIOR := &"warrior"
const ENEMY_TYPE_ARCHER := &"archer"
const ENEMY_TYPE_MARAUDER := &"marauder"
const ENEMY_TYPE_ASSASSIN := &"assassin"
const ENEMY_TYPE_SPEARMAN := &"spearman"
const ENEMY_TYPE_ROBBER := &"robber"

const STAGE_ROSTERS := [
	[ENEMY_TYPE_WARRIOR, ENEMY_TYPE_ARCHER],
	[ENEMY_TYPE_WARRIOR, ENEMY_TYPE_SPEARMAN],
	[ENEMY_TYPE_ARCHER, ENEMY_TYPE_ASSASSIN],
	[ENEMY_TYPE_WARRIOR, ENEMY_TYPE_ARCHER, ENEMY_TYPE_SPEARMAN],
	[ENEMY_TYPE_WARRIOR, ENEMY_TYPE_ASSASSIN, ENEMY_TYPE_SPEARMAN],
	[ENEMY_TYPE_MARAUDER, ENEMY_TYPE_ARCHER, ENEMY_TYPE_ASSASSIN],
	[ENEMY_TYPE_MARAUDER, ENEMY_TYPE_WARRIOR, ENEMY_TYPE_SPEARMAN],
	[ENEMY_TYPE_MARAUDER, ENEMY_TYPE_ARCHER, ENEMY_TYPE_SPEARMAN],
	[ENEMY_TYPE_MARAUDER, ENEMY_TYPE_ASSASSIN, ENEMY_TYPE_SPEARMAN],
	[ENEMY_TYPE_ROBBER, ENEMY_TYPE_SPEARMAN, ENEMY_TYPE_ARCHER],
]

const ENEMY_SCENE_BY_TYPE := {
	ENEMY_TYPE_WARRIOR: BANDIT_WARRIOR_SCENE,
	ENEMY_TYPE_ARCHER: BANDIT_ARCHER_SCENE,
	ENEMY_TYPE_MARAUDER: BANDIT_MARAUDER_SCENE,
	ENEMY_TYPE_ASSASSIN: BANDIT_ASSASSIN_SCENE,
	ENEMY_TYPE_SPEARMAN: BANDIT_SPEARMAN_SCENE,
	ENEMY_TYPE_ROBBER: BANDIT_ROBBER_SCENE,
}

const ENEMY_LEVEL_BONUS_BY_TYPE := {
	ENEMY_TYPE_WARRIOR: 0,
	ENEMY_TYPE_ARCHER: 0,
	ENEMY_TYPE_ASSASSIN: 0,
	ENEMY_TYPE_SPEARMAN: 0,
	ENEMY_TYPE_MARAUDER: 1,
	ENEMY_TYPE_ROBBER: 2,
}

const LEGACY_ENEMY_NODE_NAMES := [&"BanditWarrior", &"BanditMarauder", &"BanditArcher"]
const LOOP_BONUS_OBJECTIVES := {
	2: {"id": "no_ally_falls", "label": "No ally falls", "gold_reward": 6},
	3: {"id": "turn_limit", "label": "Win within 4 player turns", "gold_reward": 8, "turn_limit": 4},
	4: {"id": "use_bloom_once", "label": "Use Bloom at least once", "gold_reward": 8},
	5: {"id": "no_ally_falls", "label": "No ally falls", "gold_reward": 10},
	6: {"id": "turn_limit", "label": "Win within 5 player turns", "gold_reward": 10, "turn_limit": 5},
	7: {"id": "use_bloom_once", "label": "Use Bloom at least once", "gold_reward": 12},
	8: {"id": "above_half_hp", "label": "Finish with all allies above 50% HP", "gold_reward": 12},
	9: {"id": "no_ally_falls", "label": "No ally falls", "gold_reward": 14},
	10: {"id": "turn_limit", "label": "Win within 6 player turns", "gold_reward": 16, "turn_limit": 6},
}

func _enter_tree() -> void:
	var battle_root := get_node_or_null("BattleRoot")
	if battle_root == null:
		return

	_remove_legacy_backdrop_nodes(battle_root)
	_attach_forest_backdrop(battle_root)

	var forest_grid := Grid.new()
	forest_grid.size = FOREST_MAP_SIZE
	forest_grid.cell_size = FOREST_CELL_SIZE
	_apply_grid_overrides(battle_root, forest_grid)
	_apply_opening_positions(battle_root, forest_grid)
	_apply_loop_party_state(battle_root)
	_spawn_stage_enemies(battle_root, forest_grid)

func _remove_legacy_backdrop_nodes(battle_root: Node) -> void:
	for node_name in [&"FarmBackdrop", &"FarmSetDress"]:
		var node := battle_root.get_node_or_null(String(node_name))
		if node == null:
			continue
		battle_root.remove_child(node)
		node.queue_free()

func _attach_forest_backdrop(battle_root: Node) -> void:
	if battle_root.get_node_or_null("ForestBackdrop") != null:
		return

	var forest_backdrop := FOREST_BACKDROP_SCENE.instantiate()
	forest_backdrop.name = "ForestBackdrop"
	if forest_backdrop is CanvasItem:
		(forest_backdrop as CanvasItem).z_index = -20
	battle_root.add_child(forest_backdrop)
	battle_root.move_child(forest_backdrop, 0)

func _apply_grid_overrides(battle_root: Node, forest_grid: Grid) -> void:
	var game_board := battle_root.get_node_or_null("GameBoard") as GameBoard
	if game_board != null:
		var deployment_slots: Array[Vector2] = []
		for cell in FOREST_DEPLOYMENT_CELLS:
			deployment_slots.append(cell)
		var empty_slots: Array[Vector2] = []
		game_board.grid = forest_grid
		if Global.loop_hub_mode_active:
			game_board.deployment_enabled = true
			game_board.deployment_cells = deployment_slots
			game_board.bonus_objective_config = _get_loop_bonus_objective_config()
		else:
			game_board.deployment_enabled = false
			game_board.deployment_cells = empty_slots
			game_board.bonus_objective_config = {}

	var cursor := battle_root.get_node_or_null("GameBoard/Cursor")
	if cursor != null:
		cursor.grid = forest_grid

	var unit_path := battle_root.get_node_or_null("GameBoard/UnitPath")
	if unit_path != null:
		unit_path.grid = forest_grid

	for node in battle_root.get_children():
		_apply_grid_to_units_recursive(node, forest_grid)

func _apply_grid_to_units_recursive(node: Node, forest_grid: Grid) -> void:
	if node is Unit:
		(node as Unit).grid = forest_grid

	for child in node.get_children():
		_apply_grid_to_units_recursive(child, forest_grid)

func _apply_opening_positions(battle_root: Node, forest_grid: Grid) -> void:
	_set_node_to_cell(battle_root.get_node_or_null("GameBoard/Cursor"), FOREST_CURSOR_CELL, forest_grid)
	_set_node_to_cell(battle_root.get_node_or_null("GameBoard/Savannah"), FOREST_SAVANNAH_CELL, forest_grid)
	_set_node_to_cell(battle_root.get_node_or_null("GameBoard/Tera"), FOREST_TERA_CELL, forest_grid)
	_set_node_to_cell(battle_root.get_node_or_null("GameBoard/Silas"), FOREST_SILAS_CELL, forest_grid)

func _set_node_to_cell(node: Node, cell: Vector2, forest_grid: Grid) -> void:
	if node == null or not (node is Node2D):
		return
	(node as Node2D).position = forest_grid.calculate_map_position(cell)

func _apply_loop_party_state(battle_root: Node) -> void:
	if not Global.loop_hub_mode_active:
		return

	if not Global.has_loop_plot(Global.LOOP_PLOT_FOREST):
		_remove_unit(battle_root, "Silas")

func _spawn_stage_enemies(battle_root: Node, forest_grid: Grid) -> void:
	var game_board := battle_root.get_node_or_null("GameBoard")
	if game_board == null:
		return

	for legacy_name in LEGACY_ENEMY_NODE_NAMES:
		_remove_unit(battle_root, String(legacy_name))

	var stage_index := clampi(maxi(Global.loop_battle_index, 1) - 1, 0, STAGE_ROSTERS.size() - 1)
	var stage_roster: Array = STAGE_ROSTERS[stage_index]
	var base_level := maxi(Global.loop_battle_index, 1)

	for i in range(mini(stage_roster.size(), FOREST_ENEMY_CELLS.size())):
		var enemy_type: StringName = stage_roster[i]
		var enemy_scene: PackedScene = ENEMY_SCENE_BY_TYPE.get(enemy_type, null)
		if enemy_scene == null:
			continue

		var enemy := enemy_scene.instantiate() as Unit
		if enemy == null:
			continue

		enemy.name = _build_enemy_node_name(enemy_type, i)
		enemy.grid = forest_grid
		enemy.level = base_level + int(ENEMY_LEVEL_BONUS_BY_TYPE.get(enemy_type, 0))
		enemy.is_enemy = true
		enemy.set_meta("map_director_scaled", true)
		enemy.position = forest_grid.calculate_map_position(FOREST_ENEMY_CELLS[i])
		game_board.add_child(enemy)

func _build_enemy_node_name(enemy_type: StringName, slot_index: int) -> String:
	var base_name := String(enemy_type).capitalize()
	return "Forest%s%d" % [base_name, slot_index + 1]

func _remove_unit(battle_root: Node, unit_name: String) -> void:
	var unit := battle_root.get_node_or_null("GameBoard/%s" % unit_name)
	if unit == null:
		return

	var unit_parent := unit.get_parent()
	if unit_parent != null:
		unit_parent.remove_child(unit)
	unit.queue_free()

func _get_loop_bonus_objective_config() -> Dictionary:
	if not Global.loop_hub_mode_active:
		return {}
	return Dictionary(LOOP_BONUS_OBJECTIVES.get(clampi(Global.loop_battle_index, 1, 10), {})).duplicate(true)
