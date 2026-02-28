## Represents a unit on the game board.
## The board manages its position inside the game grid.
## The unit itself holds stats and a visual representation that moves smoothly in the game world.
@tool
class_name Unit
extends Path2D

@onready var animation_tree: AnimationTree = $PathFollow2D/Visuals/AnimationTree
@onready var move_state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/MoveStateMachine/playback")

## Emitted when the unit reached the end of a path along which it was walking.
signal walk_finished

## Shared resource of type Grid, used to calculate map coordinates.
@export var grid: Resource

@export var is_enemy: bool

@export var is_wait := false
## Distance to which the unit can walk in cells.
@export var move_range := 6
## The unit's move speed when it's moving along a path.
@export var move_speed := 150.0

@export var attack_range := 0
## Texture representing the unit.
@export var skin: Texture:
	set(value):
		skin = value
		if not _sprite:
			# This will resume execution after this node's _ready()
			await ready
		_sprite.texture = value
## Offset to apply to the `skin` sprite in pixels.
@export var skin_offset := Vector2.ZERO:
	set(value):
		skin_offset = value
		if not _sprite:
			await ready
		_sprite.position = value

## Coordinates of the current cell the cursor moved to.
var cell := Vector2.ZERO:
	set(value):
		# When changing the cell's value, we don't want to allow coordinates outside
		#	the grid, so we clamp them
		cell = grid.grid_clamp(value)
## Toggles the "selected" animation on the unit.
var is_selected := false:
	set(value):
		is_selected = value
		if is_selected:
			_anim_player.play("selected")
		else:
			_anim_player.play("idle")

var _is_walking := false:
	set(value):
		_is_walking = value
		set_process(_is_walking)

@onready var _sprite: Sprite2D = $PathFollow2D/Visuals/Sprite2D
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _path_follow: PathFollow2D = $PathFollow2D
@onready var is_player: bool = false

func _ready() -> void:
	
	set_process(false)
	_path_follow = $PathFollow2D
	_sprite = $PathFollow2D/Visuals/Sprite2D
	_anim_player = $AnimationPlayer
	
	if is_player:
		# Override the export with Savannah's global stats!
		move_range = Global.player_stats["MOV"] + Global.active_food_buff.stats.get("MOV", 0)
	
	set_process(false)
	_path_follow.rotates = false
	
	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)
	
	# We create the curve resource here because creating it in the editor prevents us from
	# moving the unit.
	if not Engine.is_editor_hint():
		curve = Curve2D.new()
		
	# Wake up the puppet!
	animation_tree.active = true
	move_state_machine.travel("idle")
	
	# We will set a default blend position so she faces forward
	animation_tree.set("parameters/MoveStateMachine/idle/blend_position", Vector2(0, 1))		


func _process(delta: float) -> void:
	if _is_walking:
		# A. Save her current position before she steps forward
		var old_pos = _path_follow.position
		
		# (Your existing movement math)
		_path_follow.progress += move_speed * delta

		# B. Calculate which direction she just stepped, and feed it to the puppet!
		var direction = (old_pos.direction_to(_path_follow.position)).normalized()
		if direction != Vector2.ZERO:
			animation_tree.set("parameters/MoveStateMachine/run/blend_position", direction)
			animation_tree.set("parameters/MoveStateMachine/idle/blend_position", direction)

		# C. When she reaches the final tile...
		if _path_follow.progress_ratio >= 1.0:
			_is_walking = false
			
			# Stop the walking animation!
			move_state_machine.travel("idle")
			
			# (Your existing cleanup code)
			_path_follow.progress = 0.0
			position = grid.calculate_map_position(cell)
			curve.clear_points()
			walk_finished.emit()


## Starts walking along the `path`.
## `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty() or path.size() == 1:
		_is_walking = false
		walk_finished.emit()
		return

	# 1. Start the walk animation!
	move_state_machine.travel("run")

	# CRITICAL: Clear the old path before drawing the new one!
	curve.clear_points() 
	
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
		
	cell = path[-1]
	_path_follow.progress = 0.0 # Reset animation progress to the start
	_is_walking = true
