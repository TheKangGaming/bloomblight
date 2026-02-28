extends Node2D

# Catch the animation calls and pass them up to the parent (Player or Combat Unit)

func axe_use() -> void:
	if get_parent().has_method("axe_use"):
		get_parent().axe_use()

func on_tool_animation_finished() -> void:
	print("Visuals caught the animation!")
	if get_parent().has_method("on_tool_animation_finished"):
		get_parent()._on_tool_animation_finished()

func _perform_tool_action() -> void:
	if get_parent().has_method("perform_tool_action"):
		get_parent()._perform_tool_action()
