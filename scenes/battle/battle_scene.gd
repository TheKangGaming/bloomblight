extends CanvasLayer

const DAMAGE_POPUP_SCRIPT := preload("res://scenes/battle/battle_damage_popup.gd")
const PROJECTILE_VFX_SCRIPT := preload("res://scenes/battle/battle_projectile_vfx.gd")
const MAGIC_VFX_SCRIPT := preload("res://scenes/battle/battle_magic_vfx.gd")

# --- NODE REFERENCES ---
@onready var battle_world: Node2D = $BattleWorld
@onready var ui_layer: CanvasLayer = $UI

# --- STAGING ANCHORS ---
@onready var center_anchor: Marker2D = $BattleWorld/CenterAnchor
@onready var attacker_start: Marker2D = $BattleWorld/AttackerStart
@onready var defender_start: Marker2D = $BattleWorld/DefenderStart
@onready var attacker_melee: Marker2D = $BattleWorld/AttackerMelee
@onready var defender_melee: Marker2D = $BattleWorld/DefenderMelee

# --- COMBAT DATA ---
var _combat_distance: int = 1
var _attacker_data: CharacterData
var _defender_data: CharacterData
var _attacker_stats: UnitStats
var _defender_stats: UnitStats
var _attacker_weapon: WeaponData
var _defender_weapon: WeaponData

var _combat_strikes: Array[CombatStrike] = []
var active_attacker: BattleActor
var active_defender: BattleActor
var _attacker_is_melee := false
var _defender_is_melee := false
var _defender_will_counter := false
var _attacker_has_advanced := false
var _defender_has_advanced := false
var _screen_center := Vector2.ZERO
var _current_focus := Vector2.ZERO
var _current_zoom := 1.0
var _presentation_overlay: Control

const ENTRY_REVEAL_DURATION := 0.18
const EXIT_HIDE_DURATION := 0.16
const OPENING_APPROACH_DURATION := 0.78
const COUNTER_APPROACH_DURATION := 0.56
const APPROACH_SETTLE_TIME := 0.12
const RETREAT_DURATION := 0.42
const MELEE_STANDOFF := 80.0
const IDLE_ZOOM := 3.25
const MELEE_ZOOM := 4.05
const RANGED_ZOOM := 3.55
const MAGIC_ZOOM := 3.7
const HIT_STOP_NORMAL := 0.08
const HIT_STOP_CRIT := 0.22
const SHAKE_DURATION_NORMAL := 0.12
const SHAKE_DURATION_CRIT := 0.18
const SHAKE_INTENSITY_NORMAL := 14.0
const SHAKE_INTENSITY_CRIT := 24.0
const EFFECT_VERTICAL_OFFSET := Vector2.ZERO
const LETTERBOX_HEIGHT_RATIO := 0.17
const LETTERBOX_MAX_HEIGHT := 156.0
const LETTERBOX_COLOR := Color(0.01, 0.01, 0.02, 0.82)
const LETTERBOX_EDGE_COLOR := Color(0.96, 0.86, 0.62, 0.72)
const LETTERBOX_EDGE_HEIGHT := 3.0

func _ready() -> void:
	var payload := CombatManager.get_payload()
		
	if payload == null:
		push_error("BattleScene Error: Booted up without a CombatPayload!")
		_return_to_map() # <--- SAFETY NET ADDED HERE
		return
		
	# Extract the data
	_attacker_data = payload.attacker_data
	_defender_data = payload.defender_data
	_attacker_stats = payload.attacker_stats
	_defender_stats = payload.defender_stats
	_attacker_weapon = payload.attacker_weapon
	_defender_weapon = payload.defender_weapon
	_combat_strikes = payload.strikes
	
	# Save the distance so we know if a counterattack is possible!
	_combat_distance = payload.distance
	
	# Clear the payload from the Autoload
	CombatManager.clear_payload()
	
	# FIX: Only run the sequence if spawning succeeds
	if _spawn_actors():
		_setup_staging()
		_execute_battle_sequence()
		
# --- THE STAGING DIRECTOR ---
func _setup_staging() -> void:
	_screen_center = get_viewport().get_visible_rect().size / 2.0

	# Snap actors to their designated starting corners inside the world.
	active_attacker.position = attacker_start.position
	active_defender.position = defender_start.position
	
	# Ensure they are facing each other using Vectors.
	if active_attacker.has_method("set_facing"):
		active_attacker.set_facing(Vector2.RIGHT)
	if active_defender.has_method("set_facing"):
		active_defender.set_facing(Vector2.LEFT)

	_current_zoom = IDLE_ZOOM
	_current_focus = _get_actor_midpoint()
	_apply_world_focus(_current_focus, _current_zoom)
	battle_world.modulate.a = 0.0
	_setup_presentation_overlay()

func _spawn_actors() -> bool:
	# 1. Spawn Attacker (Left Side, Facing Right)
	if _attacker_data and _attacker_data.battle_actor_scene:
		active_attacker = _attacker_data.battle_actor_scene.instantiate() as BattleActor
		battle_world.add_child(active_attacker)
		# Ensure their position is snapped exactly to the marker
		active_attacker.position = Vector2.ZERO 
		active_attacker.setup_from_combat_snapshot(_attacker_data, _attacker_stats, true, _attacker_weapon)
	else:
		push_error("BattleScene: Attacker missing battle_actor_scene in CharacterData!")

	# 2. Spawn Defender (Right Side, Facing Left)
	if _defender_data and _defender_data.battle_actor_scene:
		active_defender = _defender_data.battle_actor_scene.instantiate() as BattleActor
		battle_world.add_child(active_defender)
		active_defender.position = Vector2.ZERO
		active_defender.setup_from_combat_snapshot(_defender_data, _defender_stats, false, _defender_weapon)
	else:
		push_error("BattleScene: Defender missing battle_actor_scene in CharacterData!")
		
	if active_attacker == null or active_defender == null:
		push_error("BattleScene Error: Failed to spawn actors. Aborting sequence.")
		_return_to_map()
		return false # Tell _ready() to abort!
		
	return true # Tell _ready() it's safe to proceed!

func _execute_battle_sequence() -> void:
	await _play_entry_reveal()
	await get_tree().create_timer(0.12).timeout
	
	# --- 1. THE DASH ---
	await _play_approach()
	
	var attacker_survived = true
	var defender_survived = true
	
	# --- 2. THE MOVIE PLAYER ---
	for strike in _combat_strikes:
		
		var striker: BattleActor = active_attacker if strike.is_attacker_striking else active_defender
		var target: BattleActor = active_defender if strike.is_attacker_striking else active_attacker
		var waits_for_reaction := false

		await _focus_on_exchange(striker, target, strike.attack_kind)
		await _prepare_striker_for_strike(strike)
		
		# Initiate the attack animation
		striker.play_attack()
		
		# Wait for the EXACT frame the weapon connects
		await striker.strike_impact
		
		# --- DELIVER THE RANGED/MAGIC PAYLOAD ---
		if strike.attack_kind == CombatStrike.AttackKind.RANGED:
			await _play_projectile(striker, target, strike.is_hit)
		elif strike.attack_kind == CombatStrike.AttackKind.MAGIC:
			# ADDED THE 'striker' VARIABLE HERE!
			await _play_magic_vfx(striker, target, strike.is_hit)
		# ----------------------------------------
		
		if strike.is_hit:
			await _play_hit_feedback(striker, target, strike)
		
		# The Reaction
		if strike.is_hit:
			# -> SPAWN THE NUMBER!
			_spawn_damage_popup(target, strike)
			waits_for_reaction = true
			
			if strike.target_survived:
				target.play_hit()
			else:
				target.play_death()
				if strike.is_attacker_striking:
					defender_survived = false
				else:
					attacker_survived = false
		else:
			# -> SPAWN THE MISS!
			_spawn_damage_popup(target, strike)
			waits_for_reaction = true
			
			if target.has_method("play_evade"):
				target.play_evade()
			else:
				target.play_hit() 
				
		# Wait for the attacker to finish their swing follow-through
		await striker.wait_for_tracked_action()
		if waits_for_reaction:
			await target.wait_for_tracked_action()
		
		# A tiny buffer between strikes so they don't blend together
		await get_tree().create_timer(0.1).timeout

	# --- 3. THE RETREAT ---
	await _play_retreat(attacker_survived, defender_survived)
	await _tween_world_focus(_get_actor_midpoint(), IDLE_ZOOM, 0.16)

	# The script is over! Let the dust settle, then close the overlay.
	await get_tree().create_timer(0.28).timeout
	_return_to_map()
	
func _determine_combatants_reach() -> void:
	_attacker_is_melee = (_get_attack_kind_for_weapon(_attacker_weapon) == CombatStrike.AttackKind.MELEE)
	_defender_is_melee = (_get_attack_kind_for_weapon(_defender_weapon) == CombatStrike.AttackKind.MELEE)
	_defender_will_counter = CombatCalculator.can_attack_at_distance(_combat_distance, _get_attack_range_for_weapon(_defender_weapon, _defender_stats))
	_attacker_has_advanced = false
	_defender_has_advanced = false

func _play_approach() -> void:
	_determine_combatants_reach() # Figure out who has swords!
	
	var tween: Tween = null
	var movement_happened = false
	
	# Melee-vs-melee uses the center clash anchors. If only the attacker is
	# melee, close to the defender's actual position instead.
	if _attacker_is_melee:
		if tween == null:
			tween = create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		active_attacker.play_run()
		tween.tween_property(active_attacker, "position", _get_opening_destination_for_attacker(), OPENING_APPROACH_DURATION)
		_attacker_has_advanced = true
		movement_happened = true

	if _attacker_is_melee and _defender_will_counter and _defender_is_melee:
		if tween == null:
			tween = create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		active_defender.play_run()
		tween.tween_property(active_defender, "position", defender_melee.position, OPENING_APPROACH_DURATION)
		_defender_has_advanced = true
		movement_happened = true
		
	if movement_happened:
		await tween.finished
		if _attacker_is_melee: active_attacker.play_idle()
		if _defender_will_counter and _defender_is_melee: active_defender.play_idle()
		await _tween_world_focus(_get_actor_midpoint(), MELEE_ZOOM, 0.14)
		await get_tree().create_timer(APPROACH_SETTLE_TIME).timeout

func _play_retreat(attacker_survived: bool, defender_survived: bool) -> void:
	var tween: Tween = null
	var movement_happened = false
	
	# Only hop back if they actually dashed forward in the first place!
	if attacker_survived and _attacker_has_advanced and is_instance_valid(active_attacker):
		if tween == null:
			tween = create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		active_attacker.play_jump()
		tween.tween_property(active_attacker, "position", attacker_start.position, RETREAT_DURATION)
		movement_happened = true
		
	if defender_survived and _defender_has_advanced and is_instance_valid(active_defender):
		if tween == null:
			tween = create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		active_defender.play_jump()
		tween.tween_property(active_defender, "position", defender_start.position, RETREAT_DURATION)
		movement_happened = true
		
	if movement_happened:
		await tween.finished
		if attacker_survived and _attacker_has_advanced and is_instance_valid(active_attacker):
			active_attacker.play_idle()
		if defender_survived and _defender_has_advanced and is_instance_valid(active_defender):
			active_defender.play_idle()

func _prepare_striker_for_strike(strike: CombatStrike) -> void:
	if strike.attack_kind != CombatStrike.AttackKind.MELEE:
		return

	if strike.is_attacker_striking:
		if _attacker_has_advanced:
			return
		await _advance_actor_to_melee(active_attacker, _get_dynamic_melee_destination(true))
		_attacker_has_advanced = true
		return

	if _defender_has_advanced:
		return

	await _advance_actor_to_melee(active_defender, _get_dynamic_melee_destination(false))
	_defender_has_advanced = true

func _advance_actor_to_melee(actor: BattleActor, destination: Vector2) -> void:
	if not is_instance_valid(actor):
		return

	actor.play_run()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(actor, "position", destination, COUNTER_APPROACH_DURATION)
	await tween.finished
	actor.play_idle()
	await _tween_world_focus(_get_actor_midpoint(), MELEE_ZOOM, 0.1)
	await get_tree().create_timer(APPROACH_SETTLE_TIME).timeout

func _get_opening_destination_for_attacker() -> Vector2:
	if _defender_will_counter and _defender_is_melee:
		return attacker_melee.position
	return _get_dynamic_melee_destination(true)

func _get_dynamic_melee_destination(is_attacker_striking: bool) -> Vector2:
	var target := active_defender if is_attacker_striking else active_attacker
	if not is_instance_valid(target):
		return attacker_melee.position if is_attacker_striking else defender_melee.position

	var x_offset := -MELEE_STANDOFF if is_attacker_striking else MELEE_STANDOFF
	return target.position + Vector2(x_offset, 0.0)

func _get_attack_kind_for_weapon(weapon: WeaponData) -> CombatStrike.AttackKind:
	return CombatCalculator.get_attack_kind(weapon)

func _get_attack_range_for_weapon(weapon: WeaponData, stats: UnitStats) -> int:
	if weapon == null:
		if stats != null:
			return maxi(1, int(stats.atk_rng))
		return 1
	return weapon.attack_range
	
func _return_to_map() -> void:
	# Tell the transition manager to fade out, delete this node, and unpause the map
	if TransitionManager and TransitionManager.has_method("close_overlay"):
		TransitionManager.close_overlay(self, 0.2)
	else:
		queue_free()
		get_tree().paused = false

func begin_overlay_exit() -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(battle_world, "modulate:a", 0.0, EXIT_HIDE_DURATION)
	tween.tween_property(battle_world, "scale", Vector2.ONE * (_current_zoom * 1.04), EXIT_HIDE_DURATION)
	tween.tween_property(battle_world, "position:y", battle_world.position.y - 16.0, EXIT_HIDE_DURATION)
	if is_instance_valid(_presentation_overlay):
		tween.tween_property(_presentation_overlay, "modulate:a", 0.0, EXIT_HIDE_DURATION)

func _play_entry_reveal() -> void:
	var target_focus := _get_actor_midpoint()
	var target_zoom := IDLE_ZOOM
	var target_position := _build_world_position(target_focus, target_zoom)

	battle_world.modulate.a = 0.0
	battle_world.scale = Vector2.ONE * (target_zoom * 0.94)
	battle_world.position = target_position + Vector2(0.0, 20.0)
	if is_instance_valid(_presentation_overlay):
		_presentation_overlay.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(battle_world, "modulate:a", 1.0, ENTRY_REVEAL_DURATION)
	tween.tween_property(battle_world, "scale", Vector2.ONE * target_zoom, ENTRY_REVEAL_DURATION)
	tween.tween_property(battle_world, "position", target_position, ENTRY_REVEAL_DURATION)
	if is_instance_valid(_presentation_overlay):
		tween.tween_property(_presentation_overlay, "modulate:a", 1.0, ENTRY_REVEAL_DURATION)
	await tween.finished
	_apply_world_focus(target_focus, target_zoom)

func _build_world_position(focus_local: Vector2, zoom: float) -> Vector2:
	return _screen_center - (focus_local * zoom)

func _apply_world_focus(focus_local: Vector2, zoom: float) -> void:
	_current_focus = focus_local
	_current_zoom = zoom
	battle_world.position = _build_world_position(focus_local, zoom)
	battle_world.scale = Vector2.ONE * zoom

func _tween_world_focus(focus_local: Vector2, zoom: float, duration: float) -> void:
	_current_focus = focus_local
	_current_zoom = zoom

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(battle_world, "position", _build_world_position(focus_local, zoom), duration)
	tween.tween_property(battle_world, "scale", Vector2.ONE * zoom, duration)
	await tween.finished

func _get_actor_midpoint() -> Vector2:
	if is_instance_valid(active_attacker) and is_instance_valid(active_defender):
		return (active_attacker.position + active_defender.position) * 0.5
	return center_anchor.position

func _get_zoom_for_attack_kind(attack_kind: CombatStrike.AttackKind) -> float:
	match attack_kind:
		CombatStrike.AttackKind.RANGED:
			return RANGED_ZOOM
		CombatStrike.AttackKind.MAGIC:
			return MAGIC_ZOOM
		_:
			return MELEE_ZOOM

func _focus_on_exchange(striker: BattleActor, target: BattleActor, attack_kind: CombatStrike.AttackKind) -> void:
	if not is_instance_valid(striker) or not is_instance_valid(target):
		return

	var midpoint := (striker.position + target.position) * 0.5
	await _tween_world_focus(midpoint, _get_zoom_for_attack_kind(attack_kind), 0.12)

func _play_hit_feedback(striker: BattleActor, target: BattleActor, strike: CombatStrike) -> void:
	var shake_tween := _play_world_shake(
		SHAKE_INTENSITY_CRIT if strike.is_crit else SHAKE_INTENSITY_NORMAL,
		SHAKE_DURATION_CRIT if strike.is_crit else SHAKE_DURATION_NORMAL
	)

	striker.process_mode = Node.PROCESS_MODE_DISABLED
	target.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(HIT_STOP_CRIT if strike.is_crit else HIT_STOP_NORMAL).timeout
	striker.process_mode = Node.PROCESS_MODE_INHERIT
	target.process_mode = Node.PROCESS_MODE_INHERIT
	await shake_tween.finished

func _play_world_shake(intensity: float, duration: float) -> Tween:
	var base_position := _build_world_position(_current_focus, _current_zoom)
	var step_time := duration / 4.0
	var tween := create_tween()
	tween.tween_property(battle_world, "position", base_position + Vector2(intensity, -intensity * 0.25), step_time)
	tween.tween_property(battle_world, "position", base_position + Vector2(-intensity * 0.7, intensity * 0.2), step_time)
	tween.tween_property(battle_world, "position", base_position + Vector2(intensity * 0.45, intensity * 0.12), step_time)
	tween.tween_property(battle_world, "position", base_position, step_time)
	return tween

# --- VISUAL EFFECTS ---
func _spawn_damage_popup(target: BattleActor, strike: CombatStrike) -> void:
	var popup = DAMAGE_POPUP_SCRIPT.new()
	popup.setup_from_strike(strike)
	battle_world.add_child(popup)
	popup.position = battle_world.to_local(target.get_damage_anchor_position())
	popup.play()

func _play_projectile(striker: BattleActor, target: BattleActor, is_hit: bool) -> void:
	var arrow = PROJECTILE_VFX_SCRIPT.new()
	battle_world.add_child(arrow)
	
	var start_pos = striker.get_effect_anchor_position() + EFFECT_VERTICAL_OFFSET
	arrow.global_position = start_pos
	var target_pos = target.get_damage_anchor_position() + EFFECT_VERTICAL_OFFSET
	
	if is_hit:
		arrow.rotation = (target_pos - start_pos).angle()
		var tween = create_tween()
		tween.tween_property(arrow, "global_position", target_pos, 0.25).set_trans(Tween.TRANS_LINEAR)
		await tween.finished
		arrow.queue_free()
	else:
		# FIX 1: The Near-Miss Split!
		var direction = (target_pos - start_pos).normalized()
		var overshoot_pos = target_pos + (direction * 250)

		arrow.rotation = (overshoot_pos - start_pos).angle()
		var tween = create_tween()

		# Tween part 1: Fly to the target's face (takes 0.15s)
		tween.tween_property(arrow, "global_position", target_pos, 0.15).set_trans(Tween.TRANS_LINEAR)

		# Wait ONLY for the exact moment the arrow reaches the target...
		await get_tree().create_timer(0.15).timeout

		# Tween part 2: Continue flying into the void in the background!
		tween.tween_property(arrow, "global_position", overshoot_pos, 0.15).set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(arrow.queue_free)

		# Return control to the main loop IMMEDIATELY so play_evade() triggers!
		return


func _play_magic_vfx(striker: BattleActor, target: BattleActor, is_hit: bool) -> void:
	var magic = MAGIC_VFX_SCRIPT.new()
	battle_world.add_child(magic)
	
	# Start at their feet/effect anchor
	var spawn_pos = target.get_effect_anchor_position() + EFFECT_VERTICAL_OFFSET
	
	# WHIFF LOGIC: If it's a miss, offset the pillar so the player can read the whiff!
	if not is_hit:
		# FIX 3: Dynamic Relative Whiff!
		# If target is to the right of the striker, miss further to the right (+1)
		# If target is to the left of the striker, miss further to the left (-1)
		var whiff_dir = 1 if target.global_position.x > striker.global_position.x else -1
		spawn_pos.x += 60 * whiff_dir
		
	magic.global_position = spawn_pos
	
	# 2. Animate it shooting upward
	var tween = create_tween().set_parallel(true)
	tween.tween_property(magic, "beam_height", 120.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(magic, "global_position:y", magic.global_position.y - 118.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Wait for the pillar to hit maximum height before doing damage
	await tween.finished
	
	# 3. Fade it out quickly
	var fade_tween = create_tween()
	fade_tween.tween_property(magic, "modulate:a", 0.0, 0.2)
	
	# Notice we DON'T 'await' the fade! We want the hit-stop to trigger while it's fading!
	fade_tween.chain().tween_callback(magic.queue_free)

func _setup_presentation_overlay() -> void:
	if ui_layer == null:
		return

	if is_instance_valid(_presentation_overlay):
		_presentation_overlay.queue_free()

	var overlay := Control.new()
	overlay.name = "PresentationOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.modulate.a = 0.0
	ui_layer.add_child(overlay)
	_presentation_overlay = overlay

	var viewport_size := get_viewport().get_visible_rect().size
	var bar_height := minf(viewport_size.y * LETTERBOX_HEIGHT_RATIO, LETTERBOX_MAX_HEIGHT)
	var top_bar_rect := Rect2(Vector2.ZERO, Vector2(viewport_size.x, bar_height))
	var bottom_bar_rect := Rect2(Vector2(0.0, viewport_size.y - bar_height), Vector2(viewport_size.x, bar_height))

	_add_letterbox_bar(overlay, top_bar_rect, false)
	_add_letterbox_bar(overlay, bottom_bar_rect, true)

func _add_letterbox_bar(parent: Control, rect: Rect2, edge_on_top: bool) -> void:
	var bar := ColorRect.new()
	bar.position = rect.position.round()
	bar.size = rect.size.round()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.color = LETTERBOX_COLOR
	parent.add_child(bar)

	var edge := ColorRect.new()
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.color = LETTERBOX_EDGE_COLOR
	edge.position = Vector2(
		rect.position.x,
		rect.position.y if edge_on_top else rect.end.y - LETTERBOX_EDGE_HEIGHT
	).round()
	edge.size = Vector2(rect.size.x, LETTERBOX_EDGE_HEIGHT)
	parent.add_child(edge)
