extends Area2D

var can_pickup = false

func _ready():
	# Connect the signal so it detects the player
	body_entered.connect(_on_body_entered)

func pop_out():
	# 1. Pick a completely random direction (0 to 360 degrees) and distance
	var random_angle = randf_range(0, TAU) 
	var random_dist = randf_range(25, 45)
	
	# 2. Calculate exactly where it should land
	var target_pos = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_dist
	
	# 3. Animate the burst
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# 4. Wait for the animation to completely finish before it can be collected
	await tween.finished
	can_pickup = true

func _on_body_entered(body):
	if can_pickup and body.name == "Player":
		Global.inventory[Global.Items.WOOD] += 1
		Global.inventory_updated.emit()
		
		# Destroy the physical item once collected
		queue_free()
