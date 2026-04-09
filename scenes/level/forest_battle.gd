extends Node2D

const FOREST_BACKDROP_SCENE := preload("res://scenes/level/battlemap.tmx")
const FOREST_MAP_SIZE := Vector2(24, 16)
const FOREST_CELL_SIZE := Vector2(32, 32)

const FOREST_CURSOR_CELL := Vector2(11, 3)
const FOREST_SAVANNAH_CELL := Vector2(11, 3)
const FOREST_TERA_CELL := Vector2(12, 4)
const FOREST_SILAS_CELL := Vector2(13, 3)
const FOREST_BANDIT_WARRIOR_CELL := Vector2(11, 11)
const FOREST_BANDIT_MARAUDER_CELL := Vector2(12, 12)
const FOREST_BANDIT_ARCHER_CELL := Vector2(13, 11)


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
	var game_board := battle_root.get_node_or_null("GameBoard")
	if game_board != null:
		game_board.grid = forest_grid

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
	_set_node_to_cell(battle_root.get_node_or_null("GameBoard/BanditWarrior"), FOREST_BANDIT_WARRIOR_CELL, forest_grid)
	_set_node_to_cell(battle_root.get_node_or_null("GameBoard/BanditMarauder"), FOREST_BANDIT_MARAUDER_CELL, forest_grid)
	_set_node_to_cell(battle_root.get_node_or_null("GameBoard/BanditArcher"), FOREST_BANDIT_ARCHER_CELL, forest_grid)


func _set_node_to_cell(node: Node, cell: Vector2, forest_grid: Grid) -> void:
	if node == null or not (node is Node2D):
		return

	(node as Node2D).position = forest_grid.calculate_map_position(cell)


func _apply_loop_party_state(battle_root: Node) -> void:
	if not Global.loop_hub_mode_active:
		return

	if not Global.has_loop_plot(Global.LOOP_PLOT_FOREST):
		_remove_unit(battle_root, "Silas")

	if Global.loop_battle_index < 3:
		_remove_unit(battle_root, "BanditMarauder")

func _remove_unit(battle_root: Node, unit_name: String) -> void:
	var unit := battle_root.get_node_or_null("GameBoard/%s" % unit_name)
	if unit == null:
		return

	var unit_parent := unit.get_parent()
	if unit_parent != null:
		unit_parent.remove_child(unit)
	unit.queue_free()
