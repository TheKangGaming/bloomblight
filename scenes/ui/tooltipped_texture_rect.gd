extends TextureRect

const ItemTooltipPanel = preload("res://scenes/ui/item_tooltip.gd")

@export var tooltip_min_width := 320.0
@export var tooltip_font_size := 18

var _tooltip_layer: CanvasLayer = null
var _tooltip: ItemTooltip = null
var _is_hovered := false

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_apply_focus_visual(false)

func _exit_tree() -> void:
	_hide_tooltip(true)

func _gui_input(event: InputEvent) -> void:
	if _is_hovered and event is InputEventMouseMotion:
		_update_tooltip_position(true)

func _get_tooltip(_at_position: Vector2) -> String:
	return ""

func _on_mouse_entered() -> void:
	_is_hovered = true
	_apply_focus_visual(true)
	_show_tooltip(true)

func _on_mouse_exited() -> void:
	_is_hovered = false
	_apply_focus_visual(has_focus())
	if has_focus():
		_show_tooltip(false)
	else:
		_hide_tooltip()

func _on_focus_entered() -> void:
	_apply_focus_visual(true)
	_show_tooltip(_is_hovered)

func _on_focus_exited() -> void:
	_apply_focus_visual(_is_hovered)
	if _is_hovered:
		_show_tooltip(true)
	else:
		_hide_tooltip()

func _apply_focus_visual(is_active: bool) -> void:
	self_modulate = Color(1.0, 0.95, 0.72, 1.0) if is_active else Color.WHITE

func _show_tooltip(prefer_cursor: bool) -> void:
	if tooltip_text.strip_edges().is_empty():
		return

	var tooltip := _get_or_create_tooltip()
	tooltip.setup(tooltip_text, tooltip_min_width, tooltip_font_size)
	_update_tooltip_position(prefer_cursor)
	tooltip.visible = true

func _hide_tooltip(force_free: bool = false) -> void:
	if not is_instance_valid(_tooltip):
		return

	_tooltip.hide()
	if force_free:
		if is_instance_valid(_tooltip_layer):
			_tooltip_layer.queue_free()
		_tooltip_layer = null
		_tooltip = null

func _get_or_create_tooltip() -> ItemTooltip:
	if is_instance_valid(_tooltip):
		return _tooltip

	_tooltip_layer = CanvasLayer.new()
	_tooltip_layer.layer = 200
	get_tree().root.add_child(_tooltip_layer)

	_tooltip = ItemTooltipPanel.new()
	_tooltip.visible = false
	_tooltip_layer.add_child(_tooltip)
	return _tooltip

func _update_tooltip_position(prefer_cursor: bool) -> void:
	if not is_instance_valid(_tooltip):
		return

	var tooltip_size := _tooltip.size
	var viewport_size: Vector2 = get_viewport_rect().size
	var target_position := Vector2.ZERO

	if prefer_cursor:
		target_position = get_viewport().get_mouse_position() + Vector2(18.0, 20.0)
	else:
		var rect := get_global_rect()
		target_position = rect.position + Vector2(rect.size.x + 12.0, 0.0)
		if target_position.x + tooltip_size.x > viewport_size.x:
			target_position.x = rect.position.x - tooltip_size.x - 12.0
		target_position.y = rect.position.y + ((rect.size.y - tooltip_size.y) * 0.5)

	if target_position.x + tooltip_size.x > viewport_size.x:
		target_position.x = viewport_size.x - tooltip_size.x - 8.0
	if target_position.y + tooltip_size.y > viewport_size.y:
		target_position.y = viewport_size.y - tooltip_size.y - 8.0

	target_position.x = maxf(target_position.x, 8.0)
	target_position.y = maxf(target_position.y, 8.0)
	_tooltip.position = target_position.round()
