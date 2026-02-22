extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func hit():
	var tween = create_tween()
	tween.tween_property($Sprite2D.material, 'shader_parameter/progress', 1.0, 0.2)
	tween.tween_property($Sprite2D.material, 'shader_parameter/progress', 0.0, 0.4)
