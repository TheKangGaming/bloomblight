extends HBoxContainer

signal craft_requested(recipe_output: Global.Items)

@onready var recipe_name_label: Label = $NameLabel
@onready var ingredients_label: Label = $IngredientsLabel
@onready var buff_label: Label = $BuffLabel
@onready var craft_button: Button = $CraftButton

var _recipe_output: Global.Items

func _ready() -> void:
	craft_button.pressed.connect(_on_craft_button_pressed)

func setup(recipe_output: Global.Items, recipe_name: String, ingredients_summary: String, buff_summary: String, can_craft: bool) -> void:
	_recipe_output = recipe_output
	recipe_name_label.text = recipe_name
	ingredients_label.text = ingredients_summary
	buff_label.text = buff_summary
	craft_button.disabled = not can_craft

func get_craft_button() -> Button:
	return craft_button

func _on_craft_button_pressed() -> void:
	craft_requested.emit(_recipe_output)
