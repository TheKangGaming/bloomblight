extends HBoxContainer

signal craft_requested(recipe_output: Global.Items)

var _recipe_output: Global.Items

func _ui_sound_manager() -> Node:
	return get_node_or_null("/root/UISoundManager")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	$CraftButton.pressed.connect(_on_craft_button_pressed)
	$CraftButton.focus_entered.connect(_on_craft_button_highlighted)
	$CraftButton.mouse_entered.connect(_on_craft_button_highlighted)

func setup(recipe_output: Global.Items, recipe_name: String, ingredients_summary: String, buff_summary: String, can_craft: bool) -> void:
	_recipe_output = recipe_output
	$NameLabel.text = recipe_name
	$IngredientsLabel.text = ingredients_summary
	$BuffLabel.text = buff_summary
	$CraftButton.text = "Cook"
	$CraftButton.disabled = not can_craft

func get_craft_button() -> Button:
	return $CraftButton

func _on_craft_button_pressed() -> void:
	craft_requested.emit(_recipe_output)

func _on_craft_button_highlighted() -> void:
	var ui_sounds := _ui_sound_manager()
	if ui_sounds:
		ui_sounds.play_browse_general($CraftButton)
