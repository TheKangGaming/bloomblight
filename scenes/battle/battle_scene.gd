extends CanvasLayer

# --- NODE REFERENCES ---
@onready var battle_world: Node2D = $BattleWorld

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

var _combat_strikes: Array[CombatStrike] = []
var active_attacker: BattleActor
var active_defender: BattleActor
var _attacker_is_melee := false
var _defender_is_melee := false
var _defender_will_counter := false
var _attacker_has_advanced := false
var _defender_has_advanced := false

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
	# 1. Move the entire BattleWorld to the exact center of your monitor
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	battle_world.global_position = screen_center
	
	# 2. "Zoom" in by scaling the world! (Adjust these numbers for perfect framing)
	battle_world.scale = Vector2(4, 4) 
	
	# 3. Snap actors to their designated starting corners inside the world
	active_attacker.position = attacker_start.position
	active_defender.position = defender_start.position
	
	# 4. Ensure they are facing each other using Vectors!
	if active_attacker.has_method("set_facing"):
		active_attacker.set_facing(Vector2.RIGHT)
	if active_defender.has_method("set_facing"):
		active_defender.set_facing(Vector2.LEFT)

func _spawn_actors() -> bool:
	# 1. Spawn Attacker (Left Side, Facing Right)
	if _attacker_data and _attacker_data.battle_actor_scene:
		active_attacker = _attacker_data.battle_actor_scene.instantiate() as BattleActor
		battle_world.add_child(active_attacker)
		# Ensure their position is snapped exactly to the marker
		active_attacker.position = Vector2.ZERO 
		active_attacker.setup_from_combat_snapshot(_attacker_data, _attacker_stats, true)
	else:
		push_error("BattleScene: Attacker missing battle_actor_scene in CharacterData!")

	# 2. Spawn Defender (Right Side, Facing Left)
	if _defender_data and _defender_data.battle_actor_scene:
		active_defender = _defender_data.battle_actor_scene.instantiate() as BattleActor
		battle_world.add_child(active_defender)
		active_defender.position = Vector2.ZERO
		active_defender.setup_from_combat_snapshot(_defender_data, _defender_stats, false)
	else:
		push_error("BattleScene: Defender missing battle_actor_scene in CharacterData!")
		
	if active_attacker == null or active_defender == null:
		push_error("BattleScene Error: Failed to spawn actors. Aborting sequence.")
		_return_to_map()
		return false # Tell _ready() to abort!
		
	return true # Tell _ready() it's safe to proceed!

func _execute_battle_sequence() -> void:
	# A dramatic pause as the arena fades in
	await get_tree().create_timer(0.4).timeout
	
	# --- 1. THE DASH ---
	await _play_approach()
	
	var attacker_survived = true
	var defender_survived = true
	
	# --- 2. THE MOVIE PLAYER ---
	for strike in _combat_strikes:
		
		var striker: BattleActor = active_attacker if strike.is_attacker_striking else active_defender
		var target: BattleActor = active_defender if strike.is_attacker_striking else active_attacker
		var waits_for_reaction := false

		await _prepare_striker_for_strike(strike)
		
		# Initiate the attack animation
		striker.play_attack()
		
		# Wait for the EXACT frame the weapon connects
		await striker.strike_impact
		
		# --- THE JUICE: LOCAL HIT-STOP ---
		if strike.is_hit:
			# Freeze the actors (pauses their AnimationPlayers exactly on impact!)
			striker.process_mode = Node.PROCESS_MODE_DISABLED
			target.process_mode = Node.PROCESS_MODE_DISABLED
			
			# Wait a split second (Freeze longer if it's a CRITICAL HIT!)
			var stop_time = 0.25 if strike.is_crit else 0.08
			await get_tree().create_timer(stop_time).timeout
			
			# Unfreeze them so the follow-through continues
			striker.process_mode = Node.PROCESS_MODE_INHERIT
			target.process_mode = Node.PROCESS_MODE_INHERIT
		# ---------------------------------
		
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

	# The script is over! Let the dust settle, then close the overlay.
	await get_tree().create_timer(0.5).timeout
	_return_to_map()
	
func _determine_combatants_reach() -> void:
	_attacker_is_melee = false
	_defender_is_melee = false
	_defender_will_counter = false
	_attacker_has_advanced = false
	_defender_has_advanced = false

	# Peek at the script to see who is using a Melee weapon!
	for strike in _combat_strikes:
		if strike.is_attacker_striking:
			_attacker_is_melee = (strike.attack_kind == CombatStrike.AttackKind.MELEE)
		else:
			_defender_will_counter = true
			_defender_is_melee = (strike.attack_kind == CombatStrike.AttackKind.MELEE)

func _play_approach() -> void:
	_determine_combatants_reach() # Figure out who has swords!
	
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var movement_happened = false
	
	# The opener only pre-positions the attacker. The defender should not
	# step in early just because they might counter later.
	if _attacker_is_melee:
		active_attacker.play_run()
		tween.tween_property(active_attacker, "position", attacker_melee.position, 0.4)
		_attacker_has_advanced = true
		movement_happened = true
		
	if movement_happened:
		await tween.finished
		if _attacker_is_melee: active_attacker.play_idle()
		await get_tree().create_timer(0.1).timeout

func _play_retreat(attacker_survived: bool, defender_survived: bool) -> void:
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var movement_happened = false
	
	# Only hop back if they actually dashed forward in the first place!
	if attacker_survived and _attacker_has_advanced and is_instance_valid(active_attacker):
		active_attacker.play_jump()
		tween.tween_property(active_attacker, "position", attacker_start.position, 0.3)
		movement_happened = true
		
	if defender_survived and _defender_has_advanced and is_instance_valid(active_defender):
		active_defender.play_jump()
		tween.tween_property(active_defender, "position", defender_start.position, 0.3)
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
		await _advance_actor_to_melee(active_attacker, attacker_melee.position)
		_attacker_has_advanced = true
		return

	if _defender_has_advanced:
		return

	await _advance_actor_to_melee(active_defender, defender_melee.position)
	_defender_has_advanced = true

func _advance_actor_to_melee(actor: BattleActor, destination: Vector2) -> void:
	if not is_instance_valid(actor):
		return

	actor.play_run()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(actor, "position", destination, 0.35)
	await tween.finished
	actor.play_idle()
	await get_tree().create_timer(0.08).timeout
	
func _return_to_map() -> void:
	# Tell the transition manager to fade out, delete this node, and unpause the map
	if TransitionManager and TransitionManager.has_method("close_overlay"):
		TransitionManager.close_overlay(self, 0.5)
	else:
		queue_free()
		get_tree().paused = false

# --- VISUAL EFFECTS ---
func _spawn_damage_popup(target: BattleActor, strike: CombatStrike) -> void:
	var popup = Label.new()
	
	# 1. Format the Text and Color!
	if not strike.is_hit:
		popup.text = "Miss"
		popup.modulate = Color(0.7, 0.7, 0.7) # Gray
	elif strike.is_crit:
		popup.text = str(strike.damage_dealt) + "!"
		popup.modulate = Color(1.0, 0.8, 0.0) # Gold
		popup.scale = Vector2(1.5, 1.5) # Make crits huge!
	else:
		popup.text = str(strike.damage_dealt)
		popup.modulate = Color(1.0, 1.0, 1.0) # White
		
	# 2. Make it look nice (Bold outline)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_font_size_override("font_size", 24)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 3. Put it in the BattleWorld so it zooms with the camera
	battle_world.add_child(popup)
	
	# Center it directly over the target's head
	# (We offset X by -50 so the center of the text aligns with the unit)
	popup.position = target.position + Vector2(-50, -40) 
	
	# 4. The Float & Fade Animation
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Float up 30 pixels
	tween.tween_property(popup, "position:y", popup.position.y - 30, 0.6)
	# Fade to transparent
	tween.tween_property(popup, "modulate:a", 0.0, 0.6)
	
	# Delete the label out of memory when the animation finishes!
	tween.chain().tween_callback(popup.queue_free)
