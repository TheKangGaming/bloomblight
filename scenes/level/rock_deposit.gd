extends StaticBody2D

const STONE_POP_MIN_ANGLE := deg_to_rad(200.0)
const STONE_POP_MAX_ANGLE := deg_to_rad(340.0)

@onready var sprite: Sprite2D = $Sprite2D

var player_in_range := false
var depleted := false
var pickup_scene: PackedScene = preload("res://scenes/level/pickup.tscn")

func _ready() -> void:
	$InteractArea.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea.body_exited.connect(_on_interact_area_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if depleted or not player_in_range:
		return
	if not (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		return
	if event is InputEventKey and event.echo:
		return
	gather()

func gather() -> void:
	if depleted:
		return
	depleted = true
	modulate = Color(0.7, 0.7, 0.7, 0.65)
	$InteractArea/CollisionShape2D.set_deferred("disabled", true)

	var stone_amount := randi_range(2, 4)
	for _i in range(stone_amount):
		var stone = pickup_scene.instantiate()
		get_parent().add_child(stone)
		stone.global_position = global_position + Vector2(0, -12)
		if stone.has_method("configure_item"):
			stone.configure_item(Global.Items.STONE)
		stone.pop_out(STONE_POP_MIN_ANGLE, STONE_POP_MAX_ANGLE, 18.0, 42.0)

func _on_interact_area_body_entered(body: Node2D) -> void:
	if body != null and body.is_in_group("Player"):
		player_in_range = true

func _on_interact_area_body_exited(body: Node2D) -> void:
	if body != null and body.is_in_group("Player"):
		player_in_range = false
