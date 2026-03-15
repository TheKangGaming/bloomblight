extends HBoxContainer

signal craft_requested(recipe_output: Global.Items)

var _recipe_output: Global.Items

func _ready() -> void:
	$CraftButton.pressed.connect(_on_craft_button_pressed)

func setup(recipe_output: Global.Items, recipe_name: String, ingredients_summary: String, buff_summary: String, can_craft: bool) -> void:
	_recipe_output = recipe_output
	$NameLabel.text = recipe_name
	$IngredientsLabel.text = ingredients_summary
	$BuffLabel.text = buff_summary
	$CraftButton.disabled = not can_craft

func get_craft_button() -> Button:
	return $CraftButton

func _on_craft_button_pressed() -> void:
	craft_requested.emit(_recipe_output)
