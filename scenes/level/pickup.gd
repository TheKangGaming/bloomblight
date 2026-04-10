extends Area2D

var can_pickup = false
@onready var sprite = $Sprite2D # Grab your sprite!
@export var item_type: Global.Items = Global.Items.WOOD

const ITEM_ATLAS_COORDS := {
	Global.Items.WOOD: Vector2i(5, 4),
	Global.Items.STONE: Vector2i(5, 2),
}

func _ready():
	# Connect the signal so it detects the player
	body_entered.connect(_on_body_entered)
	_apply_visual()

func configure_item(next_item_type: Global.Items) -> void:
	item_type = next_item_type
	_apply_visual()

func _apply_visual() -> void:
	if sprite == null:
		return
	var atlas_coords: Vector2i = ITEM_ATLAS_COORDS.get(item_type, Vector2i(5, 4))
	sprite.region_rect = Rect2(atlas_coords.x * 32, atlas_coords.y * 32, 32, 32)
	sprite.scale = Vector2(1.0, 1.0)

func pop_out(min_angle: float = 0.0, max_angle: float = TAU, min_distance: float = 25.0, max_distance: float = 45.0):
	# 1. Pick a random direction and distance inside the requested arc.
	var random_angle = randf_range(min_angle, max_angle)
	var random_dist = randf_range(min_distance, max_distance)
	
	# 2. Calculate exactly where it should land
	var target_pos = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_dist
	
	# 3. Animate the burst
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# 4. Wait for the animation to completely finish before it can be collected
	await tween.finished
	can_pickup = true
	

func _on_body_entered(body):
	if can_pickup and body.is_in_group("Player"):
		Global.add_item(item_type)
		if Global.tutorial_step == 7 and item_type == Global.Items.WOOD:
			Global.advance_tutorial()
		
		# Destroy the physical item once collected
		queue_free()
