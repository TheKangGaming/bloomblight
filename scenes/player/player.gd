extends CharacterBody2D

@onready var move_state_machine: AnimationNodeStateMachinePlayback = $Visuals/AnimationTree.get('parameters/MoveStateMachine/playback')
@onready var tool_state_machine: AnimationNodeStateMachinePlayback = $Visuals/AnimationTree.get('parameters/ToolStateMachine/playback')
@onready var tool_particles = $ToolParticles

@export var tool_direction_offset := 30
@export var chest_offset := 40

var direction: Vector2
var last_direction: Vector2 = Vector2.DOWN
@export var walk_speed := 150
@export var run_speed := 250
var current_speed := walk_speed
var can_move : bool = true
var current_tool: Tools = Tools.AXE

enum Tools {HOE, AXE, WATER}

const tool_connection = { 
	Tools.HOE: 'hoe', 
	Tools.AXE: 'axe', 
	Tools.WATER: 'water',
}

signal tool_use(tool: Tools, pos: Vector2)

#signals to handle tool switching UI
signal tool_changed(tool: Tools)

func _physics_process(_delta: float) -> void:
	if can_move:
		get_input()
	if direction:
		last_direction = direction
		if not $Sounds/StepsTimer.time_left:
			$Sounds/StepsTimer.start()
	else:
		$Sounds/StepsTimer.stop()
		
	velocity = direction * current_speed * int(can_move)
	move_and_slide()
	animation()
	
signal toggle_menu_requested(pos: Vector2)	
	
func get_input():
	# 1. Grab the raw input into a temporary variable first
	var raw_input = Input.get_vector('left', 'right', 'up', 'down')
	
	if raw_input.length() > 0.1: 
		direction = raw_input
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
			$Visuals/AnimationTree.set('parameters/OneShot/request', AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			can_move = false

			if current_tool in [Tools.HOE, Tools.WATER]:
				await $Visuals/AnimationTree.animation_finished
				
				if current_tool == Tools.HOE:
					$Sounds/HoeSound.play()
					tool_particles.global_position = target_pos
					tool_particles.color = Color("#593a28") # Dirt Brown
					tool_particles.emitting = true
				else:
					$Sounds/WaterSound.play()
			
			if current_tool != Tools.AXE:
				tool_use.emit(current_tool, target_pos)
		
	if Input.is_action_just_pressed('tool_forward') or Input.is_action_just_pressed('tool_backward'):
		var tool_direction = Input.get_axis('tool_backward', 'tool_forward') as int
		current_tool = posmod(current_tool + tool_direction, Tools.size()) as Tools
		#emit the signal
		tool_changed.emit(current_tool)
	
	if Input.is_action_just_pressed('plant'):
		var player_center = global_position + Vector2(0, -chest_offset)
		var target_pos = player_center + (last_direction * tool_direction_offset)
		
		toggle_menu_requested.emit(target_pos)

func _ready() -> void:
	update_animation_blend_positions(last_direction)
	
func animation():
	if direction:
		if current_speed == run_speed:
			move_state_machine.travel('run')
		else:
			move_state_machine.travel('move') 
			
		update_animation_blend_positions(direction)
	else:
		move_state_machine.travel('idle')

func update_animation_blend_positions(target_vec: Vector2):
	var blend_pos = Vector2(round(target_vec.x), round(target_vec.y))
	$Visuals/AnimationTree.set('parameters/MoveStateMachine/move/blend_position', blend_pos)
	$Visuals/AnimationTree.set('parameters/MoveStateMachine/idle/blend_position', blend_pos)
	$Visuals/AnimationTree.set('parameters/MoveStateMachine/run/blend_position', blend_pos)
	
	for state in tool_connection.values():
		$Visuals/AnimationTree.set('parameters/ToolStateMachine/' + state + '/blend_position', blend_pos)
		
func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	can_move = true
	
func axe_use():
	# 1. Find the Player's Center to match the other tools
	var player_center = global_position + Vector2(0, -chest_offset)
	
	# 2. Reach out 24px from the center
	var target_pos = player_center + (last_direction * tool_direction_offset)
	
	tool_particles.global_position = target_pos
	tool_particles.color = Color("#e3c298") # Light Wood Beige
	tool_particles.emitting = true
	
	tool_use.emit(Tools.AXE, target_pos)
	$Sounds/AxeSound.play()


func _on_steps_timer_timeout() -> void:
	$Sounds/Steps.play()
