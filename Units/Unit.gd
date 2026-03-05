## Represents a unit on the game board.
## The board manages its position inside the game grid.
## The unit itself holds stats and a visual representation that moves smoothly in the game world.
@tool
class_name Unit
extends Path2D

var _hp_bar: ProgressBar
var _hp_fill_style: StyleBoxFlat
@onready var animation_tree: AnimationTree = get_node_or_null("PathFollow2D/Visuals/AnimationTree")
var move_state_machine = null # We will set this in _ready if the tree exists

## Emitted when the unit reached the end of a path along which it was walking.
signal walk_finished
signal died(unit)

## Shared resource of type Grid, used to calculate map coordinates.
@export var grid: Resource

@export var is_enemy: bool
@export var character_data: CharacterData
@export var current_stats: UnitStats
@export var level: int = 1

@export var is_player: bool = false
@export var is_wait := false

## Distance to which the unit can walk in cells.
var move_range: int:
	get:
		return current_stats.mov
## The unit's move speed when it's moving along a path.
@export var move_speed := 150.0

var attack_range: int:
	get:
		return current_stats.atk_rng

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

var health: int:
	get:
		return current_stats.hp

var max_health: int:
	get:
		return current_stats.max_hp

var strength: int:
	get:
		return current_stats.str

var defense: int:
	get:
		return current_stats.physical_def

var magic_defense: int:
	get:
		return current_stats.magic_def

var dexterity: int:
	get:
		return current_stats.dex

var int_stat: int:
	get:
		return current_stats.int_stat

var speed: int:
	get:
		return current_stats.spd


func _ready() -> void:
	set_process(false)
	_path_follow = $PathFollow2D
	_sprite = $PathFollow2D/Visuals/Sprite2D
	_anim_player = $AnimationPlayer

	if current_stats == null:
		current_stats = UnitStats.new()
	else:
		current_stats = current_stats.clone()

	_initialize_unit_data()

	if is_player:
		# Override class-derived stats with persisted player stats + active buffs.
		_load_player_stats()

	if health <= 0:
		queue_free()
		return

	_setup_hp_bar()
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


func apply_runtime_stats(new_stats: UnitStats) -> void:
	if new_stats == null:
		return

	current_stats = new_stats.clone()
	if _hp_bar != null and is_instance_valid(_hp_bar):
		_update_hp_bar(true)


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


func _initialize_unit_data() -> void:
	current_stats.apply_class_progression(character_data)
	if not is_player and character_data != null and level > 1:
		current_stats.apply_auto_levels(level - 1)


func _load_player_stats() -> void:
	Global.ensure_player_stat_formats()
	var global_player_level := Global.get_player_level()
	if level > global_player_level:
		Global.apply_player_auto_levels(level - global_player_level)
	global_player_level = Global.get_player_level()
	level = global_player_level
	var permanent_stats: Dictionary = Global.get_player_permanent_totals()
	var temporary_modifiers: Dictionary = Global.get_player_temporary_modifiers()
	current_stats.apply_player_snapshot(permanent_stats, temporary_modifiers)


func _sync_player_hp_to_global() -> void:
	if not is_player:
		return

	var permanent_stats: Dictionary = Global.get_player_permanent_totals()
	var temporary_modifiers: Dictionary = Global.get_player_temporary_modifiers()
	current_stats.sync_player_hp_to(permanent_stats, temporary_modifiers)
	Global.set_player_unbuffed_hp(int(permanent_stats.get("HP", current_stats.hp)))


## Calculates and returns combat math without actually executing the attack
func get_combat_stats(target: Unit) -> Dictionary:
	var hit_chance = clamp(80 + (dexterity * 2) - (target.speed * 2), 0, 100)
	var crit_chance = clamp(dexterity - int(target.speed / 2.0), 0, 100)
	var weapon_might = 5 # Simulating a basic Iron Axe
	var is_magic_damage := _uses_magic_damage()
	var attack_stat := int_stat if is_magic_damage else strength
	var defense_stat := target.magic_defense if is_magic_damage else target.defense
	var actual_damage = max(1, (attack_stat + weapon_might) - defense_stat)

	return {
		"hit": hit_chance,
		"crit": crit_chance,
		"damage": actual_damage,
		"uses_magic_damage": is_magic_damage
	}


func _uses_magic_damage() -> bool:
	if character_data == null or character_data.class_data == null:
		return false

	var class_info := character_data.class_data
	var damage_stat := String(class_info.primary_damage_stat).to_lower()
	if damage_stat == "intelligence" or damage_stat == "int":
		return true
	if damage_stat == "strength" or damage_stat == "str":
		return false

	return String(class_info.role).to_lower().contains("mage")


func attack(target: Unit) -> void:
	if not is_instance_valid(target) or target.health <= 0:
		return

	var visuals_node = get_node_or_null("PathFollow2D/Visuals")

	# 1. Calculate the exact direction to the target in world space
	var target_dir = (target.global_position - global_position).normalized()

	# 2. Check if this unit has an advanced AnimationTree (like Savannah)
	if visuals_node and visuals_node.has_node("AnimationTree"):
		var anim_tree = visuals_node.get_node("AnimationTree")
		var tool_playback = anim_tree.get("parameters/ToolStateMachine/playback")

		# 3. Update the BlendSpaces so the animation knows which direction to face
		# (We set the move state idle direction as well, so she stays facing the enemy after swinging)
		anim_tree.set("parameters/MoveStateMachine/idle/blend_position", target_dir)
		anim_tree.set("parameters/ToolStateMachine/axe/blend_position", target_dir)

		# 4. Tell the Tool State Machine to prepare the "axe" animation
		if tool_playback:
			tool_playback.travel("axe")

		# 5. CRITICAL FIX: Fire the OneShot node to push the animation to the screen!
		anim_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

		# 6. Wait for the visual "hit" frame (adjust this float based on your animation speed)
		await get_tree().create_timer(0.4).timeout

		# Wait just a tiny bit more for follow-through before the turn actually ends
		await get_tree().create_timer(0.2).timeout

	else:
		# FALLBACK: If the unit is a simple sprite (like the Orc), use the physical bump tween
		if visuals_node:
			var start_pos = visuals_node.position
			var bump_dir = target_dir * 15

			var tween = create_tween()
			tween.tween_property(visuals_node, "position", start_pos + bump_dir, 0.1)
			tween.tween_property(visuals_node, "position", start_pos, 0.15)
			await tween.finished

	# --- NEW COMBAT MATH & RNG ---
	# Pull the math from our helper function!
	var stats = get_combat_stats(target)

	# 2. Roll the digital dice!
	var hit_roll = randi() % 100
	var crit_roll = randi() % 100

	if hit_roll < stats["hit"]: # Replaced 'hit_chance'
		var actual_damage = stats["damage"] # Replaced the raw calculation

		var is_crit = (crit_roll < stats["crit"]) # Replaced 'crit_chance'
		if is_crit:
			actual_damage *= 3
			print(name + " LANDS A CRITICAL HIT! " + str(actual_damage) + " damage!")
		else:
			print(name + " strikes " + target.name + " for " + str(actual_damage) + " damage.")

		await target.take_damage(actual_damage, is_crit)
	else:
		# MISS!
		print(name + " MISSED!")
		target.show_miss_text()
		await get_tree().create_timer(0.2).timeout

	await get_tree().create_timer(0.2).timeout


## Subtracts health, flashes red, and checks for death
func take_damage(amount: int, is_crit: bool = false) -> void:
	if health <= 0:
		return

	current_stats.apply_delta({"HP": -amount})
	current_stats.clamp_to_caps()

	_sync_player_hp_to_global()

	_update_hp_bar()

	# Pass the crit flag to the text spawner!
	_spawn_damage_text(str(amount), is_crit, false)

	var visuals_node = get_node_or_null("PathFollow2D/Visuals")
	if visuals_node:
		var base_color = visuals_node.modulate
		var tween = create_tween()
		tween.tween_property(visuals_node, "modulate", Color.RED, 0.1)
		tween.tween_property(visuals_node, "modulate", base_color, 0.1)
		await tween.finished

	# Unified Death Block
	if health <= 0:
		current_stats.hp = 0

		await get_tree().create_timer(0.5).timeout
		die()


## Emits the death signal and removes the unit from the map
func die() -> void:
	died.emit(self)
	if is_player:
		Global.set_player_unbuffed_hp(0)
	print(name + " has fallen in battle!")
	# (We can play a fancy death animation or sound effect here later!)
	queue_free()


## Spawns a floating red damage number above the unit's head
func show_miss_text() -> void:
	_spawn_damage_text("MISS", false, true)


## Spawns dynamic floating combat text above the unit's head
func _spawn_damage_text(text_value: String, is_crit: bool = false, is_miss: bool = false) -> void:
	var label = Label.new()
	label.text = text_value

	# Dynamic Styling based on the RNG outcome!
	if is_miss:
		label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		label.add_theme_font_size_override("font_size", 16)
	elif is_crit:
		label.add_theme_color_override("font_color", Color.GOLD)
		label.add_theme_font_size_override("font_size", 28)
	else:
		label.add_theme_color_override("font_color", Color.RED)
		label.add_theme_font_size_override("font_size", 20)

	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	label.position = Vector2(-20, -40)
	label.z_index = 100

	var visuals_node = get_node_or_null("PathFollow2D/Visuals")
	if visuals_node:
		visuals_node.add_child(label)
	else:
		add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -30), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)

	await tween.finished
	label.queue_free()


## Dynamically generates a themed HP bar above the unit's head
func _setup_hp_bar() -> void:
	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false # Hide the default Godot text

	# Sizing and positioning (Centered nicely above a 32x32 sprite)
	_hp_bar.custom_minimum_size = Vector2(24, 4)
	_hp_bar.position = Vector2(-12, -50)
	_hp_bar.z_index = 50
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 1. The Carved Wood Background
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.18, 0.13, 0.1) # Dark wood
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.08, 0.05, 0.03) # Darker carved border
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	_hp_bar.add_theme_stylebox_override("background", bg_style)

	# 2. The Sap Fill
	_hp_fill_style = StyleBoxFlat.new()
	_hp_fill_style.corner_radius_top_left = 1
	_hp_fill_style.corner_radius_top_right = 1
	_hp_fill_style.corner_radius_bottom_left = 1
	_hp_fill_style.corner_radius_bottom_right = 1
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill_style)

	_hp_bar.max_value = max_health
	_hp_bar.value = health

	var visuals_node = get_node_or_null("PathFollow2D/Visuals")
	if visuals_node:
		visuals_node.add_child(_hp_bar)
	else:
		add_child(_hp_bar)

	# Set the initial color
	_update_hp_bar(true)


## Animates the health dropping and handles the "Blight" color change
func _update_hp_bar(instant: bool = false) -> void:
	if not is_instance_valid(_hp_bar):
		return

	_hp_bar.max_value = max_health

	if instant:
		_hp_bar.value = health
	else:
		# Smoothly animate the health dropping over 0.3 seconds!
		var tween = create_tween()
		tween.tween_property(_hp_bar, "value", health, 0.3).set_trans(Tween.TRANS_SINE)

	# The Blight Check: Change the sap color if critically wounded
	if max_health <= 0:
		_hp_fill_style.bg_color = Color(0.2, 0.2, 0.2)
		return

	if float(health) / float(max_health) <= 0.3:
		_hp_fill_style.bg_color = Color(0.6, 0.1, 0.6) # Toxic Blight Purple!
	else:
		if is_enemy:
			_hp_fill_style.bg_color = Color(0.8, 0.2, 0.2) # Enemy Red
		else:
			_hp_fill_style.bg_color = Color(0.3, 0.8, 0.3) # Healthy Player Green
