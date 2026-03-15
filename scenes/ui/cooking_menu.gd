extends CanvasLayer

const RECIPE_ROW_SCENE := preload("res://scenes/ui/recipe_row.tscn")
const ROLE_SORT_ORDER := {
	"Archer": 0,
	"Frontliner": 1,
	"Purifier": 2
}

@onready var recipe_list: VBoxContainer = $Panel/MarginContainer/RecipeList

var _recipe_rows: Array = []

func _ready() -> void:
	visible = false
	_build_recipe_rows()
	Global.inventory_updated.connect(_on_inventory_updated)

func open_menu() -> void:
	visible = true
	_refresh_recipe_rows()
	_focus_first_available_button()

func close_menu() -> void:
	visible = false

func _unhandled_input(event) -> void:
	if visible and event.is_action_pressed("cancel"):
		close_menu()
		get_viewport().set_input_as_handled()

func _on_inventory_updated() -> void:
	if visible:
		_refresh_recipe_rows()

func _build_recipe_rows() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

	_recipe_rows.clear()

	var sorted_outputs := _get_sorted_recipe_outputs()
	for recipe_output in sorted_outputs:
		var recipe_data: Dictionary = Global.recipes[recipe_output]
		var row = RECIPE_ROW_SCENE.instantiate()
		row.setup(
			recipe_output,
			String(recipe_data.get("display_name", _format_item_name(recipe_output))),
			_build_ingredient_summary(recipe_output),
			String(recipe_data.get("buff_preview", "No buff")),
			_can_cook(recipe_output)
		)
		row.craft_requested.connect(_on_craft_requested)
		recipe_list.add_child(row)
		_recipe_rows.append(row)

	_assign_focus_neighbors()

func _refresh_recipe_rows() -> void:
	_build_recipe_rows()

func _focus_first_available_button() -> void:
	for row in _recipe_rows:
		var button: Button = row.get_craft_button()
		if not button.disabled:
			button.grab_focus()
			return

	if not _recipe_rows.is_empty():
		var fallback_button: Button = _recipe_rows[0].get_craft_button()
		fallback_button.grab_focus()

func _assign_focus_neighbors() -> void:
	if _recipe_rows.is_empty():
		return

	for i in _recipe_rows.size():
		var current_button: Button = _recipe_rows[i].get_craft_button()
		current_button.focus_mode = Control.FOCUS_ALL

		var previous_index := maxi(i - 1, 0)
		var next_index := mini(i + 1, _recipe_rows.size() - 1)
		var previous_button: Button = _recipe_rows[previous_index].get_craft_button()
		var next_button: Button = _recipe_rows[next_index].get_craft_button()

		current_button.focus_neighbor_top = current_button.get_path_to(previous_button)
		current_button.focus_neighbor_bottom = current_button.get_path_to(next_button)
		current_button.focus_neighbor_left = NodePath("")
		current_button.focus_neighbor_right = NodePath("")

func _get_sorted_recipe_outputs() -> Array:
	var outputs := Global.recipes.keys()
	outputs.sort_custom(_sort_recipe_outputs)
	return outputs

func _sort_recipe_outputs(a: Global.Items, b: Global.Items) -> bool:
	var a_ready := _can_cook(a)
	var b_ready := _can_cook(b)
	if a_ready != b_ready:
		return a_ready and not b_ready

	var a_tag := _get_role_tag(a)
	var b_tag := _get_role_tag(b)
	var a_role_order := int(ROLE_SORT_ORDER.get(a_tag, ROLE_SORT_ORDER.size()))
	var b_role_order := int(ROLE_SORT_ORDER.get(b_tag, ROLE_SORT_ORDER.size()))
	if a_role_order != b_role_order:
		return a_role_order < b_role_order

	return _get_display_name(a).nocasecmp_to(_get_display_name(b)) < 0

func _get_role_tag(recipe_output: Global.Items) -> String:
	var recipe_data: Dictionary = Global.recipes.get(recipe_output, {})
	return String(recipe_data.get("role_tag", "")).strip_edges()

func _get_display_name(recipe_output: Global.Items) -> String:
	var recipe_data: Dictionary = Global.recipes.get(recipe_output, {})
	return String(recipe_data.get("display_name", _format_item_name(recipe_output)))

func _build_ingredient_summary(recipe_output: Global.Items) -> String:
	var recipe_data: Dictionary = Global.recipes.get(recipe_output, {})
	var ingredient_data: Dictionary = recipe_data.get("ingredients", {})
	var parts: Array[String] = []

	for ingredient in ingredient_data.keys():
		var required_amount := int(ingredient_data[ingredient])
		var owned_amount := int(Global.inventory.get(ingredient, 0))
		parts.append("%s %d/%d" % [_format_item_name(ingredient), owned_amount, required_amount])

	parts.sort()
	return ", ".join(parts)

func _can_cook(recipe_output: Global.Items) -> bool:
	if not Global.recipes.has(recipe_output):
		return false

	var ingredient_data: Dictionary = Global.recipes[recipe_output].get("ingredients", {})
	for ingredient in ingredient_data:
		var required_amount: int = int(ingredient_data[ingredient])
		if int(Global.inventory.get(ingredient, 0)) < required_amount:
			return false

	return true

func _craft_item(recipe_output: Global.Items) -> void:
	if not _can_cook(recipe_output):
		return

	var ingredient_data: Dictionary = Global.recipes[recipe_output].get("ingredients", {})
	for ingredient in ingredient_data:
		Global.inventory[ingredient] -= int(ingredient_data[ingredient])

	Global.inventory[recipe_output] = int(Global.inventory.get(recipe_output, 0)) + 1
	Global.inventory_updated.emit()

	if Global.tutorial_step == 11:
		Global.advance_tutorial()

	_refresh_recipe_rows()
	close_menu()

func _on_craft_requested(recipe_output: Global.Items) -> void:
	_craft_item(recipe_output)

func _format_item_name(item_type: Global.Items) -> String:
	var key := String(Global.Items.keys()[item_type]).to_lower().split("_")
	for i in key.size():
		key[i] = String(key[i]).capitalize()
	return " ".join(key)
