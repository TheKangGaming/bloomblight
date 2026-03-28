extends CharacterBody2D

@onready var move_state_machine: AnimationNodeStateMachinePlayback = $Visuals/AnimationTree.get('parameters/MoveStateMachine/playback')
@onready var tool_state_machine: AnimationNodeStateMachinePlayback = $Visuals/AnimationTree.get('parameters/ToolStateMachine/playback')
@onready var visuals_anim_player: AnimationPlayer = $Visuals/AnimationPlayer
@onready var tool_particles = $ToolParticles
@onready var visuals_root: Node2D = $Visuals
@onready var walk_step_player: AudioStreamPlayer2D = $Sounds/Steps
@onready var run_step_player: AudioStreamPlayer2D = $Sounds/RunSteps

@export var tool_direction_offset := 30
@export var chest_offset := 40

var direction: Vector2
var last_direction: Vector2 = Vector2.DOWN
@export var walk_speed := 150
@export var run_speed := 250
var current_speed := walk_speed
var can_move : bool = true
var current_tool: Global.Tools = Global.Tools.AXE
var _cutscene_anim_state: StringName = &""
var _cutscene_anim_direction: Vector2 = Vector2.DOWN
var _cutscene_emote_tween: Tween = null
var _cutscene_emote_base_position := Vector2.ZERO
var _cutscene_emote_active := false
var _footstep_mode: StringName = &""
var _footstep_last_position := 0.0
var _footstep_last_animation := ""
var _footstep_cycle_duration := 0.0

@export var walk_footfall_times := PackedFloat32Array([0.0, 0.405])
@export var run_footfall_times := PackedFloat32Array([0.0, 0.25])

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

signal tool_changed(tool: Global.Tools)

func _physics_process(delta: float) -> void:
	if can_move:
		get_input()

	if direction:
		if Global.tutorial_step == 0:
			Global.advance_tutorial()

		last_direction = _to_cardinal_direction(direction)
	else:
		_reset_footstep_state()

	velocity = direction * current_speed * int(can_move)
	move_and_slide()
	animation()
	_update_footstep_audio(delta)

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
	var raw_input = Input.get_vector('left', 'right', 'up', 'down')

	if raw_input.length() > 0.1:
		direction = raw_input.normalized()
	else:
		# Treat stick drift as neutral so the player does not creep around.
		direction = Vector2.ZERO

	if Input.is_action_pressed('run'):
		current_speed = run_speed
	else:
		current_speed = walk_speed

	if Input.is_action_just_pressed('action'):
		if Global.unlocked_tools.has(Global.Tools.HOE):
			var player_center = global_position + Vector2(0, -chest_offset)
			var target_pos = player_center + (last_direction * tool_direction_offset)
			tool_state_machine.travel(tool_connection[current_tool])
			$Visuals/AnimationTree.set('parameters/OneShot/request', AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			can_move = false

			if current_tool in [Global.Tools.HOE, Global.Tools.WATER]:
				await $Visuals/AnimationTree.animation_finished

				if current_tool == Global.Tools.HOE:
					$Sounds/HoeSound.play()
					tool_particles.global_position = target_pos
					tool_particles.color = Color("#593a28")
					tool_particles.emitting = true
				else:
					$Sounds/WaterSound.play()

			if current_tool != Global.Tools.AXE:
				tool_use.emit(current_tool, target_pos)

	if Input.is_action_just_pressed('plant'):
		var player_center = global_position + Vector2(0, -chest_offset)
		var target_pos = player_center + (last_direction * tool_direction_offset)

		if _has_tilled_soil_at(target_pos):
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
	update_animation_blend_positions(last_direction)
	$Visuals/AnimationTree.animation_finished.connect(_on_animation_tree_animation_finished)

func animation():
	if _cutscene_anim_state != &"":
		update_animation_blend_positions(_cutscene_anim_direction)
		move_state_machine.travel(String(_cutscene_anim_state))
		return

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
	$Visuals/AnimationTree.set('parameters/MoveStateMachine/move/blend_position', blend_pos)
	$Visuals/AnimationTree.set('parameters/MoveStateMachine/idle/blend_position', blend_pos)
	$Visuals/AnimationTree.set('parameters/MoveStateMachine/run/blend_position', blend_pos)

	for state in tool_connection.values():
		$Visuals/AnimationTree.set('parameters/ToolStateMachine/' + state + '/blend_position', blend_pos)

func face_direction(target_vec: Vector2) -> void:
	_clear_cutscene_anim_override()
	last_direction = _to_cardinal_direction(target_vec)
	update_animation_blend_positions(last_direction)
	move_state_machine.travel('idle')

func play_cutscene_move(target_vec: Vector2) -> void:
	_clear_cutscene_emote()
	last_direction = _to_cardinal_direction(target_vec)
	direction = Vector2.ZERO
	current_speed = walk_speed
	_set_cutscene_anim_override(&"move", last_direction)

func play_cutscene_idle(target_vec: Vector2 = last_direction) -> void:
	_clear_cutscene_emote()
	last_direction = _to_cardinal_direction(target_vec)
	direction = Vector2.ZERO
	_set_cutscene_anim_override(&"idle", last_direction)

func play_cutscene_shock(target_vec: Vector2 = last_direction) -> void:
	play_cutscene_idle(target_vec)
	_play_cutscene_emote_shake(Vector2(2.5, 1.8), 0.24, 3)

func play_cutscene_impatient(target_vec: Vector2 = last_direction) -> void:
	play_cutscene_idle(target_vec)
	_play_cutscene_emote_shake(Vector2(1.5, 1.0), 0.42, 4)

func clear_cutscene_animation() -> void:
	_clear_cutscene_emote()
	_clear_cutscene_anim_override()
	direction = Vector2.ZERO
	update_animation_blend_positions(last_direction)
	move_state_machine.travel('idle')

func _set_cutscene_anim_override(state: StringName, facing: Vector2) -> void:
	_clear_cutscene_emote()
	_cutscene_anim_state = state
	_cutscene_anim_direction = _to_cardinal_direction(facing)
	update_animation_blend_positions(_cutscene_anim_direction)
	move_state_machine.travel(String(_cutscene_anim_state))

func _clear_cutscene_anim_override() -> void:
	_cutscene_anim_state = &""

func _play_cutscene_emote_shake(amplitude: Vector2, duration: float, shakes: int) -> void:
	_clear_cutscene_emote()
	if SettingsManager != null and not SettingsManager.is_screen_shake_enabled():
		return
	if visuals_root == null or shakes <= 0 or duration <= 0.0:
		return

	_cutscene_emote_active = true
	_cutscene_emote_base_position = visuals_root.position
	_cutscene_emote_tween = create_tween()
	_cutscene_emote_tween.set_trans(Tween.TRANS_SINE)
	_cutscene_emote_tween.set_ease(Tween.EASE_IN_OUT)

	var step_duration := duration / float(shakes * 2)
	for i in range(shakes):
		var shake_direction := 1.0 if i % 2 == 0 else -1.0
		_cutscene_emote_tween.tween_property(visuals_root, "position", _cutscene_emote_base_position + Vector2(amplitude.x * shake_direction, -amplitude.y), step_duration)
		_cutscene_emote_tween.tween_property(visuals_root, "position", _cutscene_emote_base_position, step_duration)

func _clear_cutscene_emote() -> void:
	if _cutscene_emote_tween:
		_cutscene_emote_tween.kill()
		_cutscene_emote_tween = null
	_cutscene_emote_active = false

func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	print("Player was successfully unlocked!")
	can_move = true

func axe_use():
	var player_center = global_position + Vector2(0, -chest_offset)
	var target_pos = player_center + (last_direction * tool_direction_offset)

	tool_particles.global_position = target_pos
	tool_particles.color = Color("#e3c298")
	tool_particles.emitting = true

	tool_use.emit(Global.Tools.AXE, target_pos)
	$Sounds/AxeSound.play()


func _on_steps_timer_timeout() -> void:
	pass

func _update_footstep_audio(delta: float) -> void:
	if not can_move or _cutscene_anim_state != &"" or direction == Vector2.ZERO:
		_reset_footstep_state()
		return

	if visuals_anim_player == null:
		return

	var mode: StringName = &"run" if current_speed == run_speed else &"move"
	var animation_name := _get_locomotion_animation_name(mode, last_direction)
	if animation_name.is_empty():
		_reset_footstep_state()
		return

	var cycle_duration := _get_locomotion_cycle_duration(animation_name, mode)
	if cycle_duration <= 0.0:
		_reset_footstep_state()
		return

	if _footstep_mode != mode or _footstep_last_animation != animation_name or !is_equal_approx(_footstep_cycle_duration, cycle_duration):
		_footstep_mode = mode
		_footstep_last_animation = animation_name
		_footstep_cycle_duration = cycle_duration
		_footstep_last_position = -0.001

	var animation_position := wrapf(_footstep_last_position + delta, 0.0, cycle_duration)
	_emit_crossed_footfalls(_footstep_last_position, animation_position, _get_footfall_times_for_mode(mode), mode)
	_footstep_last_position = animation_position

func _emit_crossed_footfalls(previous_position: float, current_position: float, footfall_times: PackedFloat32Array, mode: StringName) -> void:
	if footfall_times.is_empty():
		return

	if current_position < previous_position:
		_emit_crossed_footfalls(previous_position, INF, footfall_times, mode)
		previous_position = -0.001

	for footfall_time in footfall_times:
		if footfall_time > previous_position and footfall_time <= current_position:
			_play_footstep_for_mode(mode)

func _play_footstep_for_mode(mode: StringName) -> void:
	if mode == &"run":
		if run_step_player:
			run_step_player.play()
		return

	if walk_step_player:
		walk_step_player.play()

func _get_footfall_times_for_mode(mode: StringName) -> PackedFloat32Array:
	return run_footfall_times if mode == &"run" else walk_footfall_times

func _get_locomotion_animation_name(mode: StringName, facing: Vector2) -> StringName:
	var cardinal := _to_cardinal_direction(facing)
	if cardinal.x > 0.0:
		return StringName("%s_right" % mode)
	if cardinal.x < 0.0:
		return StringName("%s_left" % mode)
	if cardinal.y < 0.0:
		return StringName("%s_up" % mode)
	return StringName("%s_down" % mode)

func _get_locomotion_cycle_duration(animation_name: StringName, mode: StringName) -> float:
	if visuals_anim_player != null and visuals_anim_player.has_animation(animation_name):
		var locomotion_animation := visuals_anim_player.get_animation(animation_name)
		if locomotion_animation != null and locomotion_animation.length > 0.0:
			return locomotion_animation.length

	return 0.5 if mode == &"run" else 0.81

func _reset_footstep_state() -> void:
	_footstep_mode = &""
	_footstep_last_position = 0.0
	_footstep_last_animation = ""
	_footstep_cycle_duration = 0.0

func _has_tilled_soil_at(global_pos: Vector2) -> bool:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("is_tilled_soil_at"):
		return scene.is_tilled_soil_at(global_pos)

	return false
