## Player-controlled cursor. Allows them to navigate the game grid, select units, and move them.
## Supports both keyboard and mouse (or touch) input.
@tool
class_name Cursor
extends Node2D

## Emitted when clicking on the currently hovered cell or when pressing the confirm action.
signal accept_pressed(cell)
## Emitted when the cursor moved to a new cell.
signal moved(new_cell)



## Grid resource, giving the node access to the grid size, and more.
@export var grid: Grid
## Time before the cursor can move again in seconds.
@export var ui_cooldown := 0.1

var is_mouse = false
var is_active: bool = true
## Coordinates of the current cell the cursor is hovering.
var cell := Vector2.ZERO:
	set(value):
		# We first clamp the cell coordinates and ensure that we aren't
		#	trying to move outside the grid boundaries
		var new_cell: Vector2 = grid.grid_clamp(value)
		if new_cell.is_equal_approx(cell):
			return

		cell = new_cell
		# If we move to a new cell, we update the cursor's position, emit
		#	a signal, and start the cooldown timer that will limit the rate
		#	at which the cursor moves when we keep the direction key held
		#	down
		position = grid.calculate_map_position(cell)
		emit_signal("moved", cell)
		_timer.start()

@onready var _timer: Timer = $Timer

var _left_action: StringName = &"ui_left"
var _right_action: StringName = &"ui_right"
var _up_action: StringName = &"ui_up"
var _down_action: StringName = &"ui_down"
var _move_deadzone := 0.2


func _ready() -> void:
	_timer.wait_time = ui_cooldown
	_setup_direction_actions()
	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

func _is_accept_event(event: InputEvent) -> bool:
	return event.is_action_pressed("click") or event.is_action_pressed("confirm")

func _process(_delta: float) -> void:
	if not is_active:
		return

	_poll_directional_input()
	var mouse_velocity := Input.get_last_mouse_velocity()
	if is_mouse or mouse_velocity.length_squared() > 0.0:
		is_mouse = true
		var grid_coords = grid.calculate_grid_coordinates(get_global_mouse_position())
		if cell != grid_coords:
			cell = grid_coords


func _setup_direction_actions() -> void:
	_left_action = _resolve_input_action(&"left", &"ui_left")
	_right_action = _resolve_input_action(&"right", &"ui_right")
	_up_action = _resolve_input_action(&"up", &"ui_up")
	_down_action = _resolve_input_action(&"down", &"ui_down")

	if _left_action.is_empty() or _right_action.is_empty() or _up_action.is_empty() or _down_action.is_empty():
		_move_deadzone = 0.2
		return

	_move_deadzone = maxf(
		maxf(InputMap.action_get_deadzone(_left_action), InputMap.action_get_deadzone(_right_action)),
		maxf(InputMap.action_get_deadzone(_up_action), InputMap.action_get_deadzone(_down_action))
	)


func _resolve_input_action(preferred: StringName, fallback: StringName) -> StringName:
	if InputMap.has_action(preferred):
		return preferred
	if InputMap.has_action(fallback):
		return fallback
	return &""


func _poll_directional_input() -> void:
	if _left_action.is_empty() or _right_action.is_empty() or _up_action.is_empty() or _down_action.is_empty():
		return

	var input_vector := Input.get_vector(_left_action, _right_action, _up_action, _down_action, _move_deadzone)
	if input_vector.is_zero_approx() or not _timer.is_stopped():
		return

	is_mouse = false
	if absf(input_vector.x) >= absf(input_vector.y):
		cell += Vector2.RIGHT if input_vector.x > 0.0 else Vector2.LEFT
	else:
		cell += Vector2.DOWN if input_vector.y > 0.0 else Vector2.UP

func _unhandled_input(event: InputEvent) -> void:
	# ADD THIS SAFETY CHECK: Ignore everything if the cursor is frozen!
	if not is_active:
		return
	
	# Navigating cells with the mouse.
	if event is InputEventMouseMotion:
		is_mouse = true
	# Trying to select something in a cell.
	elif _is_accept_event(event):
		emit_signal("accept_pressed", cell)
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if not grid:
		return
	draw_rect(Rect2(-grid.cell_size / 2, grid.cell_size), Color.ALICE_BLUE, false, 2.0)
