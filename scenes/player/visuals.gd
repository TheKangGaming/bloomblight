extends Node2D

# Catch the animation calls and pass them up to the parent (Player or Combat Unit)

func on_tool_animation_finished() -> void:
	if get_parent().has_method("on_tool_animation_finished"):
		get_parent().on_tool_animation_finished()

func perform_tool_action() -> void:
	if get_parent().has_method("perform_tool_action"):
		get_parent().perform_tool_action()
