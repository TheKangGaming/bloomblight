extends Node2D

# 1. The moment the tool strikes the ground (The Middle Shout)
func axe_use() -> void:
	if get_parent().has_method("_perform_tool_action"):
		get_parent()._perform_tool_action()

func hoe_use() -> void:
	if get_parent().has_method("_perform_tool_action"):
		get_parent()._perform_tool_action()

func water_use() -> void:
	if get_parent().has_method("_perform_tool_action"):
		get_parent()._perform_tool_action()

# 2. The moment the animation ends (The End Shout - THIS UNFREEZES YOU!)
func _on_tool_animation_finished() -> void:
	if get_parent().has_method("_on_tool_animation_finished"):
		get_parent()._on_tool_animation_finished()
