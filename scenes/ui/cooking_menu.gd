extends CanvasLayer

@onready var corn_button = $Panel/HBoxContainer/BtnRoastedCorn
@onready var soup_button = $Panel/HBoxContainer/BtnTomatoSoup

func _ready():
	# Hide the menu when the game starts
	visible = false
	
	# Connect the buttons
	corn_button.pressed.connect(_on_cook_roasted_corn)
	soup_button.pressed.connect(_on_cook_tomato_soup)

func open_menu():
	visible = true
	check_ingredients()

func close_menu():
	visible = false

func check_ingredients():
	# Check Roasted Corn (Requires 1 Corn, 1 Wood)
	var has_corn = Global.inventory[Global.Items.CORN] >= 1
	var has_wood = Global.inventory[Global.Items.WOOD] >= 1
	corn_button.disabled = not (has_corn and has_wood)
	
	# Check Tomato Soup (Requires 2 Tomatoes, 1 Water)
	var has_tomatoes = Global.inventory[Global.Items.TOMATO] >= 2
	var has_water = Global.inventory[Global.Items.WATER] >= 1
	soup_button.disabled = not (has_tomatoes and has_water)

func _on_cook_roasted_corn():
	print("Cooking Roasted Corn!")
	# Subtract ingredients
	Global.inventory[Global.Items.CORN] -= 1
	Global.inventory[Global.Items.WOOD] -= 1
	# Add cooked food
	Global.inventory[Global.Items.ROASTED_CORN] += 1
	
	Global.inventory_updated.emit()
	check_ingredients() # Re-check in case we ran out of ingredients!

func _on_cook_tomato_soup():
	print("Cooking Tomato Soup!")
	Global.inventory[Global.Items.TOMATO] -= 2
	Global.inventory[Global.Items.WATER] -= 1
	Global.inventory[Global.Items.TOMATO_SOUP] += 1
	
	Global.inventory_updated.emit()
	check_ingredients()
