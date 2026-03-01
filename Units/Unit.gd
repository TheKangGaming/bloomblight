## Represents a unit on the game board.
## The board manages its position inside the game grid.
## The unit itself holds stats and a visual representation that moves smoothly in the game world.
@tool
class_name Unit
extends Path2D

@onready var animation_tree: AnimationTree = get_node_or_null("PathFollow2D/Visuals/AnimationTree")
var move_state_machine = null # We will set this in _ready if the tree exists

## Emitted when the unit reached the end of a path along which it was walking.
signal walk_finished
signal died(unit)

## Shared resource of type Grid, used to calculate map coordinates.
@export var grid: Resource

@export var is_enemy: bool
@export var is_player: bool = false

@export var is_wait := false

@export var max_health: int = 20
@export var health: int = 20

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


func _ready() -> void:
	
	set_process(false)
	_path_follow = $PathFollow2D
	_sprite = $PathFollow2D/Visuals/Sprite2D
	_anim_player = $AnimationPlayer
	
	if is_player:
		# Override the export with Savannah's global stats!
		_load_player_stats()
	
	set_process(false)
	_path_follow.rotates = false
	
	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)
	
	# We create the curve resource here because creating it in the editor prevents us from
	# moving the unit.
	if not Engine.is_editor_hint():
		curve = Curve2D.new()
		
	# Wake up the puppet!
	if animation_tree:
		animation_tree.active = true
		move_state_machine = animation_tree.get("parameters/MoveStateMachine/playback")
		move_state_machine.travel("idle")
		animation_tree.set("parameters/MoveStateMachine/idle/blend_position", Vector2(0, 1))		


func _process(delta: float) -> void:
	if _is_walking:
		# A. Save her current position before she steps forward
		var old_pos = _path_follow.position
		
		# (Your existing movement math)
		_path_follow.progress += move_speed * delta

		# B. Calculate which direction she just stepped, and feed it to the puppet!
		var direction = (old_pos.direction_to(_path_follow.position)).normalized()
		if direction != Vector2.ZERO and animation_tree:
			animation_tree.set("parameters/MoveStateMachine/run/blend_position", direction)
			animation_tree.set("parameters/MoveStateMachine/idle/blend_position", direction)

		# C. When she reaches the final tile...
		if _path_follow.progress_ratio >= 1.0:
			_is_walking = false
			
			# Stop the walking animation!
			if move_state_machine:
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
	if move_state_machine:
		move_state_machine.travel("run")

	# CRITICAL: Clear the old path before drawing the new one!
	curve.clear_points() 
	
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
		
	cell = path[-1]
	_path_follow.progress = 0.0 # Reset animation progress to the start
	_is_walking = true

func _load_player_stats() -> void:
	# Pull from the Global dictionary
	max_health = Global.player_stats["MAX_HP"]
	health = Global.player_stats["HP"]
	
	move_range = Global.player_stats["MOV"]
	attack_range = Global.player_stats["ATK_RNG"]
	
	# If you want to calculate the total stats including Food Buffs later, 
	# we will add that math right here!
	
	## Makes the unit physically bump into the target and deal damage!
func attack(target: Unit) -> void:
	var visuals_node = get_node_or_null("PathFollow2D/Visuals")
	
	# 1. Play a quick physical "bump" animation using a Tween
	if visuals_node:
		var start_pos = visuals_node.position
		var bump_dir = (target.position - position).normalized() * 15 # Lunge 15 pixels forward
		
		var tween = create_tween()
		tween.tween_property(visuals_node, "position", start_pos + bump_dir, 0.1)
		tween.tween_property(visuals_node, "position", start_pos, 0.15)
		
		# Wait for the lunge to hit before doing damage
		await tween.finished
		
	# 2. Deal the damage! (Hardcoded to 5 for now, we will add STR math later!)
	target.take_damage(5)


## Subtracts health, flashes red, and checks for death
func take_damage(amount: int) -> void:
	health -= amount
	print(name + " took " + str(amount) + " damage! HP: " + str(health) + "/" + str(max_health))
	
	var visuals_node = get_node_or_null("PathFollow2D/Visuals")
	if visuals_node:
		var tween = create_tween()
		tween.tween_property(visuals_node, "modulate", Color.RED, 0.1)
		tween.tween_property(visuals_node, "modulate", Color.WHITE, 0.1)
		
		# CRITICAL FIX: Wait for the red flash to finish before dying!
		await tween.finished
		
	# Check if dead
	if health <= 0:
		health = 0
		die()


## Emits the death signal and removes the unit from the map
func die() -> void:
	print(name + " has fallen in battle!")
	died.emit(self)
	# (We can play a fancy death animation or sound effect here later!)
	queue_free()
	
