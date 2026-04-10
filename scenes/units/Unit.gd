@tool
class_name Unit
extends Path2D

var _hp_bar: ProgressBar
var _hp_fill_style: StyleBoxFlat
@onready var animation_tree: AnimationTree = get_node_or_null("PathFollow2D/Visuals/AnimationTree")
var move_state_machine = null

signal walk_finished
signal died(unit)

var ability_cooldowns: Dictionary = {}
var active_combat_effects: Dictionary = {}

@export var grid: Grid

@export var is_enemy: bool
@export var character_data: CharacterData
@export var current_stats: UnitStats
@export var level: int = 1

@export var is_player: bool = false
@export var is_wait := false
var main_action_used := false
var bonus_action_used := false

var move_range: int:
	get:
		return current_stats.mov
@export var move_speed := 150.0

var attack_range: int:
	get:
		if character_data != null and character_data.equipped_weapon != null:
			return maxi(1, int(character_data.equipped_weapon.attack_range))
		if current_stats != null:
			return maxi(1, current_stats.atk_rng)
		return 1

var min_attack_range: int:
	get:
		if character_data != null and character_data.equipped_weapon != null:
			var equipped_weapon := character_data.equipped_weapon
			if int(equipped_weapon.min_attack_range) >= 0:
				return maxi(1, int(equipped_weapon.min_attack_range))
			return maxi(1, int(equipped_weapon.attack_range))
		return attack_range

@export var skin: Texture:
	set(value):
		skin = value
		if not _sprite:
			await ready
		_sprite.texture = value

@export var skin_offset := Vector2.ZERO:
	set(value):
		skin_offset = value
		if not _sprite:
			await ready
		_sprite.position = value

var cell := Vector2.ZERO:
	set(value):
		cell = grid.grid_clamp(value)

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
@onready var _visual_anim_player: AnimationPlayer = get_node_or_null("PathFollow2D/Visuals/AnimationPlayer")
var _status_indicator: Label = null

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

const ARCHER_DAMAGE_STR_WEIGHT := 0.4
const ARCHER_DAMAGE_DEX_WEIGHT := 0.6


func _ready() -> void:
	set_process(false)
	_path_follow = $PathFollow2D
	_sprite = $PathFollow2D/Visuals/Sprite2D
	_anim_player = $AnimationPlayer
	_visual_anim_player = get_node_or_null("PathFollow2D/Visuals/AnimationPlayer")

	if current_stats == null:
		current_stats = UnitStats.new()
	else:
		current_stats = current_stats.clone()

	_initialize_unit_data()

	if is_player:
		_load_player_stats()

	if health <= 0:
		queue_free()
		return

	_setup_hp_bar()
	_setup_status_indicator()
	_path_follow.rotates = false

	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

	if not Engine.is_editor_hint():
		curve = Curve2D.new()

	if animation_tree:
		animation_tree.active = true
		move_state_machine = animation_tree.get("parameters/MoveStateMachine/playback")
		move_state_machine.travel("idle")
		animation_tree.set("parameters/MoveStateMachine/idle/blend_position", Vector2(0, 1))
	elif _visual_anim_player and _visual_anim_player.has_animation("idle"):
		_visual_anim_player.play("idle")


func apply_runtime_stats(new_stats: UnitStats) -> void:
	if new_stats == null:
		return

	current_stats = new_stats.clone()
	if _hp_bar != null and is_instance_valid(_hp_bar):
		_update_hp_bar(true)


func _process(delta: float) -> void:
	if _is_walking:
		var old_pos = _path_follow.position

		_path_follow.progress += move_speed * delta

		# Use actual path motion for facing so the rig stays honest on diagonal turns.
		var direction = (old_pos.direction_to(_path_follow.position)).normalized()
		if direction != Vector2.ZERO and animation_tree:
			animation_tree.set("parameters/MoveStateMachine/run/blend_position", direction)
			animation_tree.set("parameters/MoveStateMachine/idle/blend_position", direction)

		if _path_follow.progress_ratio >= 1.0:
			_is_walking = false

			if move_state_machine:
				move_state_machine.travel("idle")
			elif _visual_anim_player and _visual_anim_player.has_animation("idle"):
				_visual_anim_player.play("idle")

			_path_follow.progress = 0.0
			position = grid.calculate_map_position(cell)
			curve.clear_points()
			walk_finished.emit()


func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty() or path.size() == 1:
		_is_walking = false
		walk_finished.emit()
		return

	if move_state_machine:
		move_state_machine.travel("run")
	elif _visual_anim_player:
		if _visual_anim_player.has_animation("run_start") and _visual_anim_player.has_animation("run"):
			_visual_anim_player.play("run_start")
			_visual_anim_player.queue("run")
		elif _visual_anim_player.has_animation("run"):
			_visual_anim_player.play("run")

	curve.clear_points()

	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)

	cell = path[-1]
	_path_follow.progress = 0.0
	_is_walking = true


func _initialize_unit_data() -> void:
	current_stats.apply_class_progression(character_data)
	current_stats.apply_delta(_build_runtime_equipment_delta())
	if not is_player and character_data != null and level > 1:
		current_stats.apply_auto_levels(level - 1)


func _load_player_stats() -> void:
	Global.ensure_player_stat_formats()
	var global_player_level := Global.get_player_level()
	if level > global_player_level:
		Global.apply_player_auto_levels(level - global_player_level)
	global_player_level = Global.get_player_level()
	level = global_player_level
	if character_data != null and character_data.class_data != null:
		Global.set_player_class_name(String(character_data.class_data.metadata_name))

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
func get_combat_stats(target: Unit, distance: int = -1) -> Dictionary:
	var equipped_weapon: WeaponData = null
	if character_data != null:
		equipped_weapon = character_data.equipped_weapon

	var weapon_might := 2
	var weapon_hit := 70
	if equipped_weapon != null:
		weapon_might = int(equipped_weapon.might)
		weapon_hit = int(equipped_weapon.hit_rate)

	var hit_chance = clamp(weapon_hit + (dexterity * 2) - (target.speed * 2) + get_combat_modifier("hit"), 0, 100)
	var crit_chance = clamp(dexterity - int(target.speed / 2.0) + get_combat_modifier("crit"), 0, 100)
	var is_magic_damage := _uses_magic_damage()
	var damage_profile := _resolve_damage_stat_profile(is_magic_damage, equipped_weapon)
	var attack_stat := int(damage_profile.get("attack_stat", 0))

	var defense_stat := target.magic_defense if is_magic_damage else target.defense
	var actual_damage = max(0, (attack_stat + weapon_might) - defense_stat)
	if distance > 1 and equipped_weapon != null:
		actual_damage = max(0, actual_damage - maxi(int(equipped_weapon.ranged_damage_penalty), 0))

	return {
		"hit": hit_chance,
		"crit": crit_chance,
		"damage": actual_damage,
		"uses_magic_damage": is_magic_damage,
		"damage_profile": damage_profile
	}


func get_attack_preview_data(weapon: WeaponData = null) -> Dictionary:
	var equipped_weapon := weapon
	if equipped_weapon == null and character_data != null:
		equipped_weapon = character_data.equipped_weapon

	var weapon_might := 2
	if equipped_weapon != null:
		weapon_might = int(equipped_weapon.might)

	var profile := _resolve_damage_stat_profile(_uses_magic_damage(), equipped_weapon)
	var attack_stat := int(profile.get("attack_stat", 0))
	var attack_total := maxi(0, attack_stat + weapon_might)

	return {
		"attack_total": attack_total,
		"weapon_might": weapon_might,
		"attack_stat": attack_stat,
		"profile": profile
	}


func _resolve_damage_stat_profile(is_magic_damage: bool, _weapon_override: WeaponData = null) -> Dictionary:
	if is_magic_damage:
		var int_total := int_stat
		return {
			"attack_stat": int_total,
			"stat_label": "INT",
			"formula_text": "INT"
		}

	var class_data: ClassData = character_data.class_data if character_data != null else null
	var primary_stat := String(class_data.primary_damage_stat).to_lower() if class_data != null else "strength"
	var secondary_stat := String(class_data.secondary_stat).to_lower() if class_data != null else ""

	var strength_total := strength
	var dexterity_total := dexterity

	if (primary_stat == "strength" or primary_stat == "str") and (secondary_stat == "dexterity" or secondary_stat == "dex"):
		var weighted_attack := int(floor((strength_total * ARCHER_DAMAGE_STR_WEIGHT) + (dexterity_total * ARCHER_DAMAGE_DEX_WEIGHT)))
		return {
			"attack_stat": weighted_attack,
			"stat_label": "STR/DEX",
			"formula_text": "floor(STR×0.4 + DEX×0.6)",
			"strength_total": strength_total,
			"dexterity_total": dexterity_total
		}

	return {
		"attack_stat": strength_total,
		"stat_label": "STR",
		"formula_text": "STR"
	}

func _get_stat_bonus_from_item(item: Resource, key: String) -> int:
	if item == null:
		return 0

	var bonuses = item.get("stat_bonuses")
	if bonuses is Dictionary:
		return int((bonuses as Dictionary).get(key, 0))

	return 0


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

func _build_runtime_equipment_delta() -> Dictionary:
	var delta := {
		"HP": 0,
		"MAX_HP": 0,
		"STR": 0,
		"DEF": 0,
		"MDEF": 0,
		"DEX": 0,
		"INT": 0,
		"SPD": 0,
		"MOV": 0,
	}
	if character_data == null:
		return delta

	for item in [character_data.equipped_weapon, character_data.equipped_armor, character_data.equipped_accessory]:
		_accumulate_runtime_item_bonus(delta, item)

	return delta

func _accumulate_runtime_item_bonus(delta: Dictionary, item: Resource) -> void:
	if item == null:
		return

	var stat_bonuses = item.get("stat_bonuses")
	if not (stat_bonuses is Dictionary):
		return

	var key_map := {
		"max_health": "MAX_HP",
		"strength": "STR",
		"defense": "DEF",
		"magic_defense": "MDEF",
		"dexterity": "DEX",
		"intelligence": "INT",
		"speed": "SPD",
		"move_range": "MOV",
	}

	for source_key in key_map.keys():
		var target_key := String(key_map[source_key])
		var value := int(stat_bonuses.get(source_key, 0))
		if value == 0:
			continue
		delta[target_key] = int(delta.get(target_key, 0)) + value
		if target_key == "MAX_HP":
			delta["HP"] = int(delta.get("HP", 0)) + value

func get_combat_modifier(stat_name: String) -> int:
	var total := 0
	for effect_state in active_combat_effects.values():
		if not (effect_state is Dictionary):
			continue
		var modifiers: Dictionary = effect_state.get("modifiers", {})
		total += int(modifiers.get(stat_name, 0))
	return total

func apply_timed_combat_effect(effect_id: StringName, modifiers: Dictionary, turns: int) -> void:
	if effect_id.is_empty() or turns <= 0:
		return

	active_combat_effects[effect_id] = {
		"turns_remaining": turns,
		"modifiers": modifiers.duplicate(true),
		"applied_this_turn": true,
	}
	_update_status_indicator()

func has_combat_effect(effect_id: StringName) -> bool:
	return active_combat_effects.has(effect_id)

func get_combat_effect_turns(effect_id: StringName) -> int:
	if not has_combat_effect(effect_id):
		return 0
	var effect_state: Dictionary = active_combat_effects.get(effect_id, {})
	return int(effect_state.get("turns_remaining", 0))

func tick_timed_combat_effects() -> void:
	var effect_ids := active_combat_effects.keys()
	for effect_id in effect_ids:
		var effect_state: Dictionary = active_combat_effects.get(effect_id, {})
		# Skip decrementing effects that were just applied this turn
		if effect_state.get("applied_this_turn", false):
			effect_state["applied_this_turn"] = false
			active_combat_effects[effect_id] = effect_state
			continue
		var turns_remaining := int(effect_state.get("turns_remaining", 0)) - 1
		if turns_remaining <= 0:
			active_combat_effects.erase(effect_id)
		else:
			effect_state["turns_remaining"] = turns_remaining
			active_combat_effects[effect_id] = effect_state
	_update_status_indicator()

func reset_turn_action_state() -> void:
	main_action_used = false
	bonus_action_used = false

func consume_main_action() -> void:
	main_action_used = true

func consume_bonus_action() -> void:
	bonus_action_used = true

func has_remaining_main_action() -> bool:
	return not main_action_used

func has_remaining_bonus_action() -> bool:
	return not bonus_action_used


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

		await target.take_damage(actual_damage, is_crit)
	else:
		# MISS!
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


## Restores health and returns the amount actually healed.
func heal(amount: int) -> int:
	if current_stats == null or amount <= 0 or health <= 0:
		return 0

	var before_hp := health
	current_stats.apply_delta({"HP": amount})
	current_stats.clamp_to_caps()
	_sync_player_hp_to_global()
	_update_hp_bar()

	return maxi(0, health - before_hp)


## Emits the death signal and removes the unit from the map
func die() -> void:
	died.emit(self)
	if is_player:
		Global.set_player_unbuffed_hp(0)
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

func _setup_status_indicator() -> void:
	_status_indicator = Label.new()
	_status_indicator.visible = false
	_status_indicator.text = "H"
	_status_indicator.position = Vector2(-5, -64)
	_status_indicator.z_index = 55
	_status_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_indicator.add_theme_font_size_override("font_size", 18)
	_status_indicator.add_theme_color_override("font_color", Color(0.96, 0.88, 0.35))
	_status_indicator.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12))
	_status_indicator.add_theme_constant_override("outline_size", 3)

	var visuals_node = get_node_or_null("PathFollow2D/Visuals")
	if visuals_node:
		visuals_node.add_child(_status_indicator)
	else:
		add_child(_status_indicator)

	_update_status_indicator()

func _update_status_indicator() -> void:
	if not is_instance_valid(_status_indicator):
		return

	var hunt_active := has_combat_effect(&"hunt")
	_status_indicator.visible = hunt_active
	if hunt_active:
		var turns_remaining := maxi(get_combat_effect_turns(&"hunt"), 1)
		_status_indicator.text = "H%d" % turns_remaining


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
			
func apply_battle_result_damage(amount: int) -> void:
	if amount <= 0 or current_stats == null or health <= 0:
		return

	current_stats.apply_delta({"HP": -amount})
	current_stats.clamp_to_caps()
	_sync_player_hp_to_global()
	_update_hp_bar(true)

	if health <= 0:
		current_stats.hp = 0
		die()
			
## Checks if an ability is ready to be used
func is_ability_ready(ability: AbilityData) -> bool:
	return not ability_cooldowns.has(ability)

## Puts an ability on cooldown after use
func start_cooldown(ability: AbilityData) -> void:
	if ability.cooldown_turns > 0:
		# Cooldowns tick at end of the acting unit's turn, so add one here to
		# preserve the advertised "next N turns" lockout.
		ability_cooldowns[ability] = ability.cooldown_turns + 1

## Ticks down cooldowns. Call this at the start of the unit's turn!
func tick_cooldowns() -> void:
	var keys = ability_cooldowns.keys()
	for ability in keys:
		ability_cooldowns[ability] -= 1
		if ability_cooldowns[ability] <= 0:
			ability_cooldowns.erase(ability) # Cooldown finished!
