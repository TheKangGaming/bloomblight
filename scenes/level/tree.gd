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
	if SettingsManager != null and not SettingsManager.is_screen_shake_enabled():
		return
	# Create a quick code animation (Tween) to wobble the tree
	var tween = create_tween()
	var orig_x = sprite.position.x
	
	# Move left 4 pixels, right 4 pixels, then back to center rapidly
	tween.tween_property(sprite, "position:x", orig_x - 4, 0.05)
	tween.tween_property(sprite, "position:x", orig_x + 4, 0.1)
	tween.tween_property(sprite, "position:x", orig_x, 0.05)

var pickup_scene = preload("res://scenes/level/pickup.tscn")

func become_stump():
	is_stump = true
	sprite.texture = stump_texture
	sprite.region_enabled = false
	sprite.offset.y = -14 
	
	# Spawn a random amount of wood!
	var wood_amount = randi_range(2, 4)
	
	for i in range(wood_amount):
		var wood = pickup_scene.instantiate()
		
		# Add the wood to the main level (the parent of the tree) so it Y-sorts properly
		get_parent().add_child(wood)
		
		# Start the wood slightly up the trunk so it doesn't spawn inside the dirt
		wood.global_position = global_position + Vector2(0, -70)
		wood.pop_out()
