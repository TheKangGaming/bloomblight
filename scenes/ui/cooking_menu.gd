extends CanvasLayer

@onready var corn_button = $Panel/HBoxContainer/BtnRoastedCorn
@onready var soup_button = $Panel/HBoxContainer/BtnTomatoSoup

func _ready():
	# Hide the menu when the game starts
	visible = false

	# Ensure gamepad/keyboard focus navigation works between recipe buttons
	corn_button.focus_mode = Control.FOCUS_ALL
	soup_button.focus_mode = Control.FOCUS_ALL
	corn_button.focus_neighbor_right = corn_button.get_path_to(soup_button)
	soup_button.focus_neighbor_left = soup_button.get_path_to(corn_button)
	
	# Connect the buttons
	corn_button.pressed.connect(_on_cook_roasted_corn)
	soup_button.pressed.connect(_on_cook_tomato_soup)

func open_menu():
	visible = true
	check_ingredients()
	if not corn_button.disabled:
		corn_button.grab_focus()
	elif not soup_button.disabled:
		soup_button.grab_focus()

func close_menu():
	visible = false

func _unhandled_input(event):
	if visible and event.is_action_pressed("cancel"):
		close_menu()
		get_viewport().set_input_as_handled()

func check_ingredients():
	corn_button.disabled = not _can_cook(Global.Items.ROASTED_CORN)
	soup_button.disabled = not _can_cook(Global.Items.TOMATO_SOUP)

func _can_cook(recipe_output: Global.Items) -> bool:
	if not Global.recipes.has(recipe_output):
		return false

	for ingredient in Global.recipes[recipe_output]:
		var required_amount: int = Global.recipes[recipe_output][ingredient]
		if Global.inventory.get(ingredient, 0) < required_amount:
			return false

	return true

func _craft_item(recipe_output: Global.Items) -> void:
	if not _can_cook(recipe_output):
		return

	for ingredient in Global.recipes[recipe_output]:
		Global.inventory[ingredient] -= Global.recipes[recipe_output][ingredient]

	Global.inventory[recipe_output] = Global.inventory.get(recipe_output, 0) + 1
	Global.inventory_updated.emit()

	if Global.tutorial_step == 11:
		Global.advance_tutorial()

	check_ingredients()
	close_menu()

func _on_cook_roasted_corn():
	_craft_item(Global.Items.ROASTED_CORN)

func _on_cook_tomato_soup():
	_craft_item(Global.Items.TOMATO_SOUP)
