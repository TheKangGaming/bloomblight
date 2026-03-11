extends CharacterBody2D

@export var visuals_scene: PackedScene

var visuals: Node
var animation_tree: AnimationTree
var move_state_machine: AnimationNodeStateMachinePlayback
var tool_state_machine: AnimationNodeStateMachinePlayback
@onready var tool_particles = $ToolParticles

@export var tool_direction_offset := 30
@export var chest_offset := 40

var direction: Vector2
var last_direction: Vector2 = Vector2.DOWN
@export var walk_speed := 150
@export var run_speed := 250
var current_speed := walk_speed
var can_move : bool = true
var current_tool: Global.Tools = Global.Tools.AXE

const tool_connection = {
	Global.Tools.HOE: 'hoe',
	Global.Tools.AXE: 'axe',
	Global.Tools.WATER: 'water',
}

const TOOL_CYCLE_ORDER: Array[Global.Tools] = [
	Global.Tools.HOE,
	Global.Tools.WATER,
	Global.Tools.AXE,
]

signal tool_use(tool: Global.Tools, pos: Vector2)

#signals to handle tool switching UI
signal tool_changed(tool: Global.Tools)

func _physics_process(_delta: float) -> void:
	if can_move:
		get_input()

	if direction:
		# --- NEW: Tutorial Check! ---
		if Global.tutorial_step == 0:
			Global.advance_tutorial()
		# ----------------------------

		last_direction = _to_cardinal_direction(direction)
		if not $Sounds/StepsTimer.time_left:
			$Sounds/StepsTimer.start()
	else:
		$Sounds/StepsTimer.stop()

	velocity = direction * current_speed * int(can_move)
	move_and_slide()
	animation()

signal toggle_menu_requested(pos: Vector2)

func _to_cardinal_direction(input_dir: Vector2) -> Vector2:
	if input_dir == Vector2.ZERO:
		return last_direction

	if absf(input_dir.x) > absf(input_dir.y):
		return Vector2(sign(input_dir.x), 0)
	elif absf(input_dir.y) > 0.0:
		return Vector2(0, sign(input_dir.y))

	return last_direction

func get_input():
	# 1. Grab the raw input into a temporary variable first
	var raw_input = Input.get_vector('left', 'right', 'up', 'down')

	if raw_input.length() > 0.1:
		direction = raw_input.normalized()
	else:
		# The stick is resting (or just drifting slightly). Force it to a perfect stop.
		direction = Vector2.ZERO

	if Input.is_action_pressed('run'):
		current_speed = run_speed
	else:
		current_speed = walk_speed

	if Input.is_action_just_pressed('action'):
		if Global.unlocked_tools.has(Global.Tools.HOE):
		# 1. Find the Player's Center (Move up 16px from feet)
			var player_center = global_position + Vector2(0, -chest_offset)

			# 2. Reach out 24px in the direction we are facing
			var target_pos = player_center + (last_direction * tool_direction_offset)
			tool_state_machine.travel(tool_connection[current_tool])
			animation_tree.set('parameters/OneShot/request', AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			can_move = false

			if current_tool in [Global.Tools.HOE, Global.Tools.WATER]:
				await animation_tree.animation_finished

				if current_tool == Global.Tools.HOE:
					$Sounds/HoeSound.play()
					tool_particles.global_position = target_pos
					tool_particles.color = Color("#593a28") # Dirt Brown
					tool_particles.emitting = true
				else:
					$Sounds/WaterSound.play()

			if current_tool != Global.Tools.AXE:
				tool_use.emit(current_tool, target_pos)

	if Input.is_action_just_pressed('plant'):
		var player_center = global_position + Vector2(0, -chest_offset)
		var target_pos = player_center + (last_direction * tool_direction_offset)

		toggle_menu_requested.emit(target_pos)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('tool_forward'):
		cycle_tool(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed('tool_backward'):
		cycle_tool(-1)
		get_viewport().set_input_as_handled()

func cycle_tool(tool_direction: int) -> void:
	var available_tools: Array[Global.Tools] = []
	for tool in TOOL_CYCLE_ORDER:
		if Global.unlocked_tools.has(tool):
			available_tools.append(tool)

	if available_tools.is_empty():
		return

	var current_index = available_tools.find(current_tool)
	if current_index == -1:
		current_index = 0
	else:
		current_index = posmod(current_index + tool_direction, available_tools.size())

	current_tool = available_tools[current_index]
	if Global.tutorial_step == 3 and current_tool == Global.Tools.HOE:
		Global.advance_tutorial()
	tool_changed.emit(current_tool)

func _ready() -> void:
	_setup_visuals()
	update_animation_blend_positions(last_direction)
	animation_tree.animation_finished.connect(_on_animation_tree_animation_finished)

func _setup_visuals() -> void:
	if visuals_scene:
		var current_visuals = get_node_or_null("Visuals")
		if current_visuals:
			current_visuals.free()

		var visuals_instance = visuals_scene.instantiate()
		visuals_instance.name = "Visuals"
		add_child(visuals_instance)
		move_child(visuals_instance, 1)

	visuals = get_node("Visuals")
	animation_tree = visuals.get_node("AnimationTree") as AnimationTree
	move_state_machine = animation_tree.get('parameters/MoveStateMachine/playback')
	tool_state_machine = animation_tree.get('parameters/ToolStateMachine/playback')

func animation():
	if direction:
		if current_speed == run_speed:
			move_state_machine.travel('run')
		else:
			move_state_machine.travel('move')

		update_animation_blend_positions(last_direction)
	else:
		update_animation_blend_positions(last_direction)
		move_state_machine.travel('idle')

func update_animation_blend_positions(target_vec: Vector2):
	var blend_pos = Vector2(round(target_vec.x), round(target_vec.y))
	animation_tree.set('parameters/MoveStateMachine/move/blend_position', blend_pos)
	animation_tree.set('parameters/MoveStateMachine/idle/blend_position', blend_pos)
	animation_tree.set('parameters/MoveStateMachine/run/blend_position', blend_pos)

	for state in tool_connection.values():
		animation_tree.set('parameters/ToolStateMachine/' + state + '/blend_position', blend_pos)

func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	print("Player was successfully unlocked!")
	can_move = true

func axe_use():
	# 1. Find the Player's Center to match the other tools
	var player_center = global_position + Vector2(0, -chest_offset)

	# 2. Reach out 24px from the center
	var target_pos = player_center + (last_direction * tool_direction_offset)

	tool_particles.global_position = target_pos
	tool_particles.color = Color("#e3c298") # Light Wood Beige
	tool_particles.emitting = true

	tool_use.emit(Global.Tools.AXE, target_pos)
	$Sounds/AxeSound.play()


func _on_steps_timer_timeout() -> void:
	$Sounds/Steps.play()
