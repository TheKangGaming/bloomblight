extends MSCAPlayer

@onready var tool_particles: CPUParticles2D = $ToolParticles
@onready var steps_timer: Timer = $Sounds/StepsTimer

@export var tool_direction_offset := 30
@export var chest_offset := 40
@export var walk_speed := 150.0
@export var run_speed := 250.0

var direction: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.DOWN
var current_speed := walk_speed
var can_move: bool = true
var current_tool: Global.Tools = Global.Tools.AXE

const TOOL_ANIMATIONS := {
	Global.Tools.HOE: "StrikeOverhandHoe",
	Global.Tools.AXE: "StrikeForehandAxe",
	Global.Tools.WATER: "WaterGround",
}

const TOOL_CYCLE_ORDER: Array[Global.Tools] = [
	Global.Tools.HOE,
	Global.Tools.WATER,
	Global.Tools.AXE,
]

signal tool_use(tool: Global.Tools, pos: Vector2)
signal tool_changed(tool: Global.Tools)
signal toggle_menu_requested(pos: Vector2)

func _ready() -> void:
	super._ready()
	update_animation_blend_positions(last_direction)

func _physics_process(_delta: float) -> void:
	if can_move:
		get_input()
	else:
		direction = Vector2.ZERO

	if direction != Vector2.ZERO:
		if Global.tutorial_step == 0:
			Global.advance_tutorial()
		last_direction = _to_cardinal_direction(direction)
		if not steps_timer.time_left:
			steps_timer.start()
	else:
		steps_timer.stop()

	velocity = direction * current_speed * int(can_move)
	move_and_slide()
	animation()

func _to_cardinal_direction(input_dir: Vector2) -> Vector2:
	if input_dir == Vector2.ZERO:
		return last_direction

	if absf(input_dir.x) > absf(input_dir.y):
		return Vector2(sign(input_dir.x), 0)
	elif absf(input_dir.y) > 0.0:
		return Vector2(0, sign(input_dir.y))

	return last_direction

func get_input() -> void:
	var raw_input := Input.get_vector("left", "right", "up", "down")
	direction = raw_input.normalized() if raw_input.length() > 0.1 else Vector2.ZERO
	current_speed = run_speed if Input.is_action_pressed("run") else walk_speed

	if Input.is_action_just_pressed("action") and Global.unlocked_tools.has(Global.Tools.HOE):
		_perform_tool_action()

	if Input.is_action_just_pressed("plant"):
		var player_center = global_position + Vector2(0, -chest_offset)
		var target_pos = player_center + (last_direction * tool_direction_offset)
		toggle_menu_requested.emit(target_pos)

func _perform_tool_action() -> void:
	var player_center = global_position + Vector2(0, -chest_offset)
	var target_pos = player_center + (last_direction * tool_direction_offset)
	var animation_name: String = TOOL_ANIMATIONS.get(current_tool, "Idle")

	travel_to_anim(animation_name, last_direction)
	can_move = false

	if current_tool == Global.Tools.HOE:
		await animationPlayer.animation_finished
		$Sounds/HoeSound.play()
		tool_particles.global_position = target_pos
		tool_particles.color = Color("#593a28")
		tool_particles.emitting = true
	elif current_tool == Global.Tools.WATER:
		await animationPlayer.animation_finished
		$Sounds/WaterSound.play()
	elif current_tool == Global.Tools.AXE:
		axe_use()

	if current_tool != Global.Tools.AXE:
		tool_use.emit(current_tool, target_pos)

	can_move = true
	travel_to_anim("Idle", last_direction)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tool_forward"):
		cycle_tool(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("tool_backward"):
		cycle_tool(-1)
		get_viewport().set_input_as_handled()

func cycle_tool(tool_direction: int) -> void:
	var available_tools: Array[Global.Tools] = []
	for tool in TOOL_CYCLE_ORDER:
		if Global.unlocked_tools.has(tool):
			available_tools.append(tool)

	if available_tools.is_empty():
		return

	var current_index := available_tools.find(current_tool)
	if current_index == -1:
		current_index = 0
	else:
		current_index = posmod(current_index + tool_direction, available_tools.size())

	current_tool = available_tools[current_index]
	if Global.tutorial_step == 3 and current_tool == Global.Tools.HOE:
		Global.advance_tutorial()
	tool_changed.emit(current_tool)

func animation() -> void:
	if direction != Vector2.ZERO:
		if current_speed == run_speed:
			travel_to_anim("Run", last_direction)
		else:
			travel_to_anim("Walk", last_direction)
	else:
		travel_to_anim("Idle", last_direction)

func update_animation_blend_positions(target_vec: Vector2) -> void:
	var blend_pos := Vector2(round(target_vec.x), round(target_vec.y))
	facing_direction = blend_pos

func axe_use() -> void:
	var player_center = global_position + Vector2(0, -chest_offset)
	var target_pos = player_center + (last_direction * tool_direction_offset)

	tool_particles.global_position = target_pos
	tool_particles.color = Color("#e3c298")
	tool_particles.emitting = true

	tool_use.emit(Global.Tools.AXE, target_pos)
	$Sounds/AxeSound.play()

func _on_steps_timer_timeout() -> void:
	$Sounds/Steps.play()
