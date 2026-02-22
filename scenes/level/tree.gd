extends StaticBody2D

var health = 4
var is_stump = false

@onready var sprite = $Sprite2D
var stump_texture = preload("res://graphics/plants/trunk 1.png")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func hit():
	if is_stump:
		return # Stop taking damage if it's already a stump!
		
	health -= 1
	shake_tree()
	
	if health <= 0:
		become_stump()

func shake_tree():
	# Create a quick code animation (Tween) to wobble the tree
	var tween = create_tween()
	var orig_x = sprite.position.x
	
	# Move left 4 pixels, right 4 pixels, then back to center rapidly
	tween.tween_property(sprite, "position:x", orig_x - 4, 0.05)
	tween.tween_property(sprite, "position:x", orig_x + 4, 0.1)
	tween.tween_property(sprite, "position:x", orig_x, 0.05)

func become_stump():
	is_stump = true
	sprite.texture = stump_texture
	
	# Optional: If the stump is shorter than the tree, you might need to move it down 
	# so it sits on the crosshair properly!
	# sprite.position.y += 10 
	
	# Give the player wood!
	Global.inventory[Global.Items.WOOD] += 2
	Global.inventory_updated.emit()
	print("Tree chopped! Got 2 wood.")
