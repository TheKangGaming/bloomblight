extends CanvasLayer

const DAMAGE_POPUP_SCRIPT := preload("res://scenes/battle/battle_damage_popup.gd")
const PROJECTILE_VFX_SCRIPT := preload("res://scenes/battle/battle_projectile_vfx.gd")
const MAGIC_VFX_SCRIPT := preload("res://scenes/battle/battle_magic_vfx.gd")
const BOW_ATTACK_SFX := preload("res://audio/sfx/Bow Attack 1.wav")
const BOW_IMPACT_SFX := preload("res://audio/sfx/Bow Impact Hit 1.wav")
const SWORD_ATTACK_SFX := preload("res://audio/sfx/Sword Attack 1.wav")
const SWORD_IMPACT_SFX := preload("res://audio/sfx/Sword Impact Hit 1.wav")
const ORC_HIT_SFX := preload("res://audio/sfx/Monster_Grunt6.mp3")
const ORC_DEATH_SFX := preload("res://audio/sfx/Monster_Grunt4.mp3")
const ORC_THUD_SFX := preload("res://audio/sfx/Monster_Thud.mp3")
const BOW_ATTACK_SFX_DELAY := 0.06
const STRIKE_IMPACT_TIMEOUT := 0.5
const DEBUG_COMBAT_LOGS := false

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
var _attacker_moved_for_melee := false
var _defender_moved_for_melee := false
var _active_shake_tween: Tween
var _screen_center := Vector2.ZERO
var _current_focus := Vector2.ZERO
var _current_zoom := 1.0
var _presentation_overlay: Control
var _attack_sfx_player: AudioStreamPlayer = null
var _impact_sfx_player: AudioStreamPlayer = null
var _orc_hit_sfx_player: AudioStreamPlayer = null
var _orc_death_sfx_player: AudioStreamPlayer = null
var _orc_thud_sfx_player: AudioStreamPlayer = null

const ENTRY_REVEAL_DURATION := 0.18
const EXIT_HIDE_DURATION := 0.16
const OPENING_APPROACH_DURATION := 0.78
const COUNTER_APPROACH_DURATION := 0.56
const APPROACH_SETTLE_TIME := 0.08
const RETREAT_DURATION := 0.42
const MELEE_STANDOFF := 38.0
const MELEE_POSITION_EPSILON := 2.0
const IDLE_ZOOM := 3.25
const MELEE_ZOOM := 4.35
const RANGED_ZOOM := 3.55
const MAGIC_ZOOM := 3.7
const HIT_STOP_NORMAL := 0.1
const HIT_STOP_CRIT := 0.26
const MELEE_HIT_STOP_EXTRA_NORMAL := 0.09
const MELEE_HIT_STOP_EXTRA_CRIT := 0.1
const SHAKE_DURATION_NORMAL := 0.15
const SHAKE_DURATION_CRIT := 0.24
const SHAKE_INTENSITY_NORMAL := 18.0
const SHAKE_INTENSITY_CRIT := 32.0
const MELEE_SHAKE_INTENSITY_EXTRA_NORMAL := 14.0
const MELEE_SHAKE_INTENSITY_EXTRA_CRIT := 18.0
const MELEE_IMPACT_FLASH_DURATION := 0.18
const MELEE_IMPACT_SLASH_DISTANCE := 64.0
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
		if CombatManager and CombatManager.has_method("queue_failure_notice"):
			CombatManager.queue_failure_notice("Combat failed to load.", 1.8)
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
		_ensure_sfx_players()
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
		if CombatManager and CombatManager.has_method("queue_failure_notice"):
			CombatManager.queue_failure_notice("Combat failed to load.", 1.8)
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
	var strike_index := 0
	
	# --- 2. THE MOVIE PLAYER ---
	for strike in _combat_strikes:
		strike_index += 1
		
		var striker: BattleActor = active_attacker if strike.is_attacker_striking else active_defender
		var target: BattleActor = active_defender if strike.is_attacker_striking else active_attacker
		var waits_for_reaction := false
		_debug_combat("Strike %d start: %s -> %s kind=%s hit=%s target_survived=%s" % [
			strike_index,
			_actor_name(striker),
			_actor_name(target),
			_attack_kind_name(strike.attack_kind),
			str(strike.is_hit),
			str(strike.target_survived)
		])

		await _focus_on_exchange(striker, target, strike.attack_kind)
		await _prepare_striker_for_strike(strike)
		
		# Initiate the attack animation
		_debug_combat("Strike %d attack animation: %s" % [strike_index, _actor_name(striker)])
		striker.play_attack_variant(_get_attack_animation_variant_for_strike(strike))
		_play_attack_sfx_for_strike(strike)
		
		# Wait for the exact frame the weapon connects, but do not let a missing
		# impact callback stall the entire battle cut-in.
		await _await_strike_impact(striker, strike_index)
		
		# --- DELIVER THE RANGED/MAGIC PAYLOAD ---
		if strike.attack_kind == CombatStrike.AttackKind.RANGED:
			_debug_combat("Strike %d projectile start" % strike_index)
			await _play_projectile(striker, target, strike.is_hit, _get_weapon_for_strike(strike))
			if strike.is_hit:
				_play_impact_sfx_for_strike(strike)
		elif strike.attack_kind == CombatStrike.AttackKind.MAGIC:
			# ADDED THE 'striker' VARIABLE HERE!
			_debug_combat("Strike %d magic vfx start" % strike_index)
			await _play_magic_vfx(striker, target, strike.is_hit)
		elif strike.is_hit:
			_play_impact_sfx_for_strike(strike)
		# ----------------------------------------
		
		if strike.is_hit:
			_debug_combat("Strike %d hit feedback" % strike_index)
			if strike.attack_kind == CombatStrike.AttackKind.MELEE:
				_play_melee_impact_flash(striker, target, strike)
			await _play_hit_feedback(striker, target, strike)
		
		# The Reaction
		if strike.is_hit:
			# -> SPAWN THE NUMBER!
			_spawn_damage_popup(target, strike)
			waits_for_reaction = true
			
			if strike.target_survived:
				_play_orc_hit_sfx(target)
				target.play_hit()
			else:
				_play_orc_death_sfx(target)
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
		_debug_combat("Strike %d waiting for striker finish: %s" % [strike_index, _actor_name(striker)])
		await striker.wait_for_tracked_action()
		_debug_combat("Strike %d striker finished: %s" % [strike_index, _actor_name(striker)])
		if waits_for_reaction:
			_debug_combat("Strike %d waiting for target reaction: %s" % [strike_index, _actor_name(target)])
			await target.wait_for_tracked_action()
			_debug_combat("Strike %d target reaction finished: %s" % [strike_index, _actor_name(target)])
		
		# Keep a little air between multi-hit strikes, but do not add a dead pause
		# after the final hit before retreating back to the map.
		if strike_index < _combat_strikes.size():
			await get_tree().create_timer(0.10).timeout

	# --- 3. THE RETREAT ---
	_debug_combat("Retreat start: attacker_survived=%s defender_survived=%s" % [str(attacker_survived), str(defender_survived)])
	await _play_retreat(attacker_survived, defender_survived)
	await _tween_world_focus(_get_actor_midpoint(), IDLE_ZOOM, 0.16)

	# The script is over! Let the dust settle, then close the overlay.
	await get_tree().create_timer(0.22).timeout
	_return_to_map()
	
func _determine_combatants_reach() -> void:
	_attacker_is_melee = (_get_attack_kind_for_weapon(_attacker_weapon, _combat_distance) == CombatStrike.AttackKind.MELEE)
	_defender_is_melee = (_get_attack_kind_for_weapon(_defender_weapon, _combat_distance) == CombatStrike.AttackKind.MELEE)
	_defender_will_counter = CombatCalculator.can_attack_at_distance(
		_combat_distance,
		_get_attack_range_for_weapon(_defender_weapon, _defender_stats),
		_get_min_attack_range_for_weapon(_defender_weapon, _defender_stats)
	)
	_attacker_has_advanced = false
	_defender_has_advanced = false
	_attacker_moved_for_melee = false
	_defender_moved_for_melee = false

func _ensure_sfx_players() -> void:
	if _attack_sfx_player == null:
		_attack_sfx_player = AudioStreamPlayer.new()
		_attack_sfx_player.name = "AttackSfxPlayer"
		_attack_sfx_player.bus = "SFX"
		add_child(_attack_sfx_player)

	if _impact_sfx_player == null:
		_impact_sfx_player = AudioStreamPlayer.new()
		_impact_sfx_player.name = "ImpactSfxPlayer"
		_impact_sfx_player.bus = "SFX"
		add_child(_impact_sfx_player)

	if _orc_hit_sfx_player == null:
		_orc_hit_sfx_player = AudioStreamPlayer.new()
		_orc_hit_sfx_player.name = "OrcHitSfxPlayer"
		_orc_hit_sfx_player.bus = "SFX"
		add_child(_orc_hit_sfx_player)

	if _orc_death_sfx_player == null:
		_orc_death_sfx_player = AudioStreamPlayer.new()
		_orc_death_sfx_player.name = "OrcDeathSfxPlayer"
		_orc_death_sfx_player.bus = "SFX"
		add_child(_orc_death_sfx_player)

	if _orc_thud_sfx_player == null:
		_orc_thud_sfx_player = AudioStreamPlayer.new()
		_orc_thud_sfx_player.name = "OrcThudSfxPlayer"
		_orc_thud_sfx_player.bus = "SFX"
		add_child(_orc_thud_sfx_player)

func _play_attack_sfx_for_strike(strike: CombatStrike) -> void:
	var stream := _get_attack_sfx_for_weapon(_get_weapon_for_strike(strike))
	if stream == null or _attack_sfx_player == null:
		return

	if _get_weapon_sound_family(_get_weapon_for_strike(strike)) == "bow" and BOW_ATTACK_SFX_DELAY > 0.0:
		await get_tree().create_timer(BOW_ATTACK_SFX_DELAY).timeout

	_attack_sfx_player.stream = stream
	_attack_sfx_player.play()

func _play_impact_sfx_for_strike(strike: CombatStrike) -> void:
	var stream := _get_impact_sfx_for_weapon(_get_weapon_for_strike(strike))
	if stream == null or _impact_sfx_player == null:
		return

	_impact_sfx_player.stream = stream
	_impact_sfx_player.play()

func _await_strike_impact(striker: BattleActor, strike_index: int = -1) -> void:
	if not is_instance_valid(striker):
		return

	var impact_received := [false]
	var on_impact := func() -> void:
		impact_received[0] = true
		_debug_combat("Strike %d impact received: %s" % [strike_index, _actor_name(striker)])

	striker.strike_impact.connect(on_impact, CONNECT_ONE_SHOT)

	var timer := get_tree().create_timer(STRIKE_IMPACT_TIMEOUT)
	while not impact_received[0] and timer.time_left > 0.0:
		await get_tree().process_frame

	if not impact_received[0]:
		push_warning("BattleScene: Strike impact timeout for %s. Continuing combat sequence." % _actor_name(striker))
		_debug_combat("Strike %d impact timeout: %s" % [strike_index, _actor_name(striker)])

func _play_orc_hit_sfx(target: BattleActor) -> void:
	if not _is_orc_actor(target) or _orc_hit_sfx_player == null:
		return

	_orc_hit_sfx_player.stream = ORC_HIT_SFX
	_orc_hit_sfx_player.play()

func _play_orc_death_sfx(target: BattleActor) -> void:
	if not _is_orc_actor(target) or _orc_death_sfx_player == null or _orc_thud_sfx_player == null:
		return

	_orc_death_sfx_player.stream = ORC_DEATH_SFX
	_orc_death_sfx_player.play()
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(_orc_thud_sfx_player):
		_orc_thud_sfx_player.stream = ORC_THUD_SFX
		_orc_thud_sfx_player.play()

func _get_weapon_for_strike(strike: CombatStrike) -> WeaponData:
	return _attacker_weapon if strike.is_attacker_striking else _defender_weapon

func _is_orc_actor(actor: BattleActor) -> bool:
	if actor == null:
		return false

	var scene_path := String(actor.scene_file_path)
	return scene_path.find("orc_battle_actor.tscn") != -1

func _get_attack_sfx_for_weapon(weapon: WeaponData) -> AudioStream:
	match _get_weapon_sound_family(weapon):
		"bow":
			return BOW_ATTACK_SFX
		"sword":
			return SWORD_ATTACK_SFX
		_:
			return null

func _get_impact_sfx_for_weapon(weapon: WeaponData) -> AudioStream:
	match _get_weapon_sound_family(weapon):
		"bow":
			return BOW_IMPACT_SFX
		"sword":
			return SWORD_IMPACT_SFX
		_:
			return null

func _get_weapon_sound_family(weapon: WeaponData) -> String:
	if weapon == null:
		return "sword"

	var weapon_type := String(weapon.weapon_type)
	if weapon_type == "Bow":
		return "bow"
	if weapon_type in ["Tome", "Staff"]:
		return ""
	return "sword"

func _play_approach() -> void:
	_determine_combatants_reach() # Figure out who has swords!
	
	if _attacker_is_melee:
		_attacker_moved_for_melee = await _advance_actor_to_melee(
			active_attacker,
			_get_opening_destination_for_attacker(),
			OPENING_APPROACH_DURATION
		)
		_attacker_has_advanced = true

func _play_retreat(attacker_survived: bool, defender_survived: bool) -> void:
	var tween: Tween = null
	var movement_happened = false
	
	# Only hop back if they actually dashed forward in the first place!
	if attacker_survived and _attacker_moved_for_melee and is_instance_valid(active_attacker):
		if tween == null:
			tween = create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		active_attacker.play_jump()
		tween.tween_property(active_attacker, "position", attacker_start.position, RETREAT_DURATION)
		movement_happened = true
		
	if defender_survived and _defender_moved_for_melee and is_instance_valid(active_defender):
		if tween == null:
			tween = create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		active_defender.play_jump()
		tween.tween_property(active_defender, "position", defender_start.position, RETREAT_DURATION)
		movement_happened = true
		
	if movement_happened:
		await tween.finished
		if attacker_survived and _attacker_moved_for_melee and is_instance_valid(active_attacker):
			active_attacker.play_idle()
		if defender_survived and _defender_moved_for_melee and is_instance_valid(active_defender):
			active_defender.play_idle()

func _prepare_striker_for_strike(strike: CombatStrike) -> void:
	if strike.attack_kind != CombatStrike.AttackKind.MELEE:
		return

	if strike.is_attacker_striking:
		if _attacker_has_advanced:
			return
		_attacker_moved_for_melee = await _advance_actor_to_melee(active_attacker, _get_dynamic_melee_destination(true))
		_attacker_has_advanced = true
		return

	if _defender_has_advanced:
		return

	_defender_moved_for_melee = await _advance_actor_to_melee(active_defender, _get_dynamic_melee_destination(false))
	_defender_has_advanced = true

func _advance_actor_to_melee(actor: BattleActor, destination: Vector2, duration: float = COUNTER_APPROACH_DURATION) -> bool:
	if not is_instance_valid(actor):
		return false

	if actor.position.distance_to(destination) <= MELEE_POSITION_EPSILON:
		actor.play_idle()
		return false

	actor.play_run()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(actor, "position", destination, duration)
	await tween.finished
	actor.play_idle()
	await _tween_world_focus(_get_actor_midpoint(), MELEE_ZOOM, 0.1)
	await get_tree().create_timer(APPROACH_SETTLE_TIME).timeout
	return true

func _get_opening_destination_for_attacker() -> Vector2:
	return _get_dynamic_melee_destination(true)

func _get_dynamic_melee_destination(is_attacker_striking: bool) -> Vector2:
	var target := active_defender if is_attacker_striking else active_attacker
	if not is_instance_valid(target):
		return attacker_melee.position if is_attacker_striking else defender_melee.position

	var x_offset := -MELEE_STANDOFF if is_attacker_striking else MELEE_STANDOFF
	return target.position + Vector2(x_offset, 0.0)

func _get_attack_kind_for_weapon(weapon: WeaponData, distance: int = -1) -> CombatStrike.AttackKind:
	return CombatCalculator.get_attack_kind(weapon, distance)

func _get_attack_range_for_weapon(weapon: WeaponData, stats: UnitStats) -> int:
	if weapon == null:
		if stats != null:
			return maxi(1, int(stats.atk_rng))
		return 1
	return weapon.attack_range

func _get_min_attack_range_for_weapon(weapon: WeaponData, stats: UnitStats) -> int:
	if weapon == null:
		if stats != null:
			return maxi(1, int(stats.atk_rng))
		return 1
	if int(weapon.min_attack_range) >= 0:
		return maxi(1, int(weapon.min_attack_range))
	return maxi(1, int(weapon.attack_range))

func _get_attack_animation_variant_for_strike(strike: CombatStrike) -> StringName:
	var weapon := _get_weapon_for_strike(strike)
	if strike.attack_kind == CombatStrike.AttackKind.RANGED and weapon != null:
		match String(weapon.projectile_style):
			"dagger":
				return &"attack_ranged"
	return StringName()
	
func _return_to_map() -> void:
	# Tell the transition manager to fade out, delete this node, and unpause the map
	_debug_combat("Return to map")
	if TransitionManager and TransitionManager.has_method("close_overlay"):
		TransitionManager.close_overlay(self, 0.2)
	else:
		queue_free()
		get_tree().paused = false

func _debug_combat(message: String) -> void:
	if DEBUG_COMBAT_LOGS:
		print("[BattleScene] %s" % message)

func _actor_name(actor: BattleActor) -> String:
	if actor == null:
		return "null"
	var data: CharacterData = actor._character_data
	if data != null and data is CharacterData and not String(data.display_name).is_empty():
		return String(data.display_name)
	return actor.name

func _attack_kind_name(kind: CombatStrike.AttackKind) -> String:
	match kind:
		CombatStrike.AttackKind.MELEE:
			return "MELEE"
		CombatStrike.AttackKind.RANGED:
			return "RANGED"
		CombatStrike.AttackKind.MAGIC:
			return "MAGIC"
		_:
			return "UNKNOWN"

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
	await _tween_world_focus(midpoint, _get_zoom_for_attack_kind(attack_kind), 0.18)

func _play_hit_feedback(striker: BattleActor, target: BattleActor, strike: CombatStrike) -> void:
	_debug_combat("Hit feedback start: %s -> %s" % [_actor_name(striker), _actor_name(target)])
	var screen_shake_enabled := SettingsManager == null or SettingsManager.is_screen_shake_enabled()
	var shake_intensity: float = SHAKE_INTENSITY_CRIT if strike.is_crit else SHAKE_INTENSITY_NORMAL
	var shake_duration: float = SHAKE_DURATION_CRIT if strike.is_crit else SHAKE_DURATION_NORMAL
	var hit_stop_duration: float = HIT_STOP_CRIT if strike.is_crit else HIT_STOP_NORMAL
	if strike.attack_kind == CombatStrike.AttackKind.MELEE:
		shake_intensity += MELEE_SHAKE_INTENSITY_EXTRA_CRIT if strike.is_crit else MELEE_SHAKE_INTENSITY_EXTRA_NORMAL
		hit_stop_duration += MELEE_HIT_STOP_EXTRA_CRIT if strike.is_crit else MELEE_HIT_STOP_EXTRA_NORMAL
	if screen_shake_enabled:
		_play_world_shake(shake_intensity, shake_duration)
	else:
		shake_duration = 0.0

	striker.process_mode = Node.PROCESS_MODE_DISABLED
	target.process_mode = Node.PROCESS_MODE_DISABLED
	_debug_combat("Hit feedback hit-stop waiting: %s -> %s" % [_actor_name(striker), _actor_name(target)])
	await get_tree().create_timer(hit_stop_duration, true).timeout
	_debug_combat("Hit feedback hit-stop done: %s -> %s" % [_actor_name(striker), _actor_name(target)])
	striker.process_mode = Node.PROCESS_MODE_INHERIT
	target.process_mode = Node.PROCESS_MODE_INHERIT
	_debug_combat("Hit feedback waiting on shake settle: %s -> %s" % [_actor_name(striker), _actor_name(target)])
	await get_tree().create_timer(shake_duration + 0.02, true).timeout
	_apply_world_focus(_current_focus, _current_zoom)
	if is_instance_valid(_active_shake_tween):
		_active_shake_tween.kill()
		_active_shake_tween = null
	_debug_combat("Hit feedback done: %s -> %s" % [_actor_name(striker), _actor_name(target)])

func _play_world_shake(intensity: float, duration: float) -> Tween:
	if SettingsManager != null and not SettingsManager.is_screen_shake_enabled():
		return null

	var base_position := _build_world_position(_current_focus, _current_zoom)
	var step_time := duration / 6.0
	if is_instance_valid(_active_shake_tween):
		_active_shake_tween.kill()
	_apply_world_focus(_current_focus, _current_zoom)
	var tween := create_tween()
	_active_shake_tween = tween
	tween.tween_property(battle_world, "position", base_position + Vector2(intensity, -intensity * 0.25), step_time)
	tween.tween_property(battle_world, "position", base_position + Vector2(-intensity * 0.7, intensity * 0.2), step_time)
	tween.tween_property(battle_world, "position", base_position + Vector2(intensity * 0.58, intensity * 0.22), step_time)
	tween.tween_property(battle_world, "position", base_position + Vector2(-intensity * 0.38, -intensity * 0.14), step_time)
	tween.tween_property(battle_world, "position", base_position + Vector2(intensity * 0.24, intensity * 0.08), step_time)
	tween.tween_property(battle_world, "position", base_position, step_time)
	return tween

# --- VISUAL EFFECTS ---
func _play_melee_impact_flash(striker: BattleActor, target: BattleActor, strike: CombatStrike) -> void:
	if not is_instance_valid(striker) or not is_instance_valid(target):
		return

	var impact_root := Node2D.new()
	impact_root.name = "MeleeImpactFlash"
	battle_world.add_child(impact_root)
	impact_root.global_position = target.get_damage_anchor_position()
	impact_root.rotation = (target.global_position - striker.global_position).angle()

	var slash := Line2D.new()
	slash.width = 9.0 if strike.is_crit else 6.0
	slash.default_color = Color(1.0, 0.94, 0.58, 0.96) if strike.is_crit else Color(1.0, 1.0, 0.88, 0.88)
	slash.points = PackedVector2Array([
		Vector2(-MELEE_IMPACT_SLASH_DISTANCE * 0.5, -24.0),
		Vector2(MELEE_IMPACT_SLASH_DISTANCE * 0.5, 24.0),
	])
	impact_root.add_child(slash)

	var cross_slash := Line2D.new()
	cross_slash.width = slash.width * 0.72
	cross_slash.default_color = Color(1.0, 0.6, 0.28, 0.76) if strike.is_crit else Color(0.94, 0.72, 0.36, 0.58)
	cross_slash.points = PackedVector2Array([
		Vector2(-MELEE_IMPACT_SLASH_DISTANCE * 0.32, 20.0),
		Vector2(MELEE_IMPACT_SLASH_DISTANCE * 0.32, -18.0),
	])
	impact_root.add_child(cross_slash)

	impact_root.scale = Vector2(0.45, 0.45)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(impact_root, "scale", Vector2(1.32, 1.32) if strike.is_crit else Vector2(1.08, 1.08), MELEE_IMPACT_FLASH_DURATION * 0.55)
	tween.tween_property(impact_root, "modulate:a", 0.0, MELEE_IMPACT_FLASH_DURATION).set_delay(MELEE_IMPACT_FLASH_DURATION * 0.35)
	tween.chain().tween_callback(impact_root.queue_free)

func _spawn_damage_popup(target: BattleActor, strike: CombatStrike) -> void:
	var popup = DAMAGE_POPUP_SCRIPT.new()
	popup.setup_from_strike(strike)
	battle_world.add_child(popup)
	popup.position = battle_world.to_local(target.get_damage_anchor_position())
	popup.play()

func _play_projectile(striker: BattleActor, target: BattleActor, is_hit: bool, weapon: WeaponData = null) -> void:
	var arrow = PROJECTILE_VFX_SCRIPT.new()
	battle_world.add_child(arrow)
	if arrow is BattleProjectileVfx:
		var projectile := arrow as BattleProjectileVfx
		if weapon != null and weapon.projectile_style != StringName():
			projectile.projectile_style = weapon.projectile_style
		else:
			projectile.projectile_style = &"arrow"
	
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

		# Queue the overshoot before the tween starts so Godot does not reject
		# appending a new step after the first segment has already begun.
		tween.tween_property(arrow, "global_position", overshoot_pos, 0.15).set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(arrow.queue_free)

		# Wait ONLY for the exact moment the arrow reaches the target...
		await get_tree().create_timer(0.15).timeout

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
