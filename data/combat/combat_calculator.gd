class_name CombatCalculator extends RefCounted

# Locking in your repo's official threshold
const FOLLOW_UP_SPEED_DIFF: int = 4 

static func can_attack_at_distance(distance: int, attack_range: int, min_attack_range: int = -1) -> bool:
	if attack_range <= 0:
		return false
	if min_attack_range < 0:
		return distance == attack_range
	var lower_bound := mini(min_attack_range, attack_range)
	var upper_bound := maxi(min_attack_range, attack_range)
	return distance >= lower_bound and distance <= upper_bound

static func get_attack_kind(weapon: WeaponData, distance: int = -1) -> CombatStrike.AttackKind:
	if not weapon:
		return CombatStrike.AttackKind.MELEE
	if weapon.weapon_type == "Bow":
		return CombatStrike.AttackKind.RANGED
	if weapon.weapon_type == "Tome" or weapon.weapon_type == "Staff":
		return CombatStrike.AttackKind.MAGIC
	if distance > 1 and weapon.projectile_style != StringName():
		return CombatStrike.AttackKind.RANGED
	return CombatStrike.AttackKind.MELEE

## 1. THE FORECAST: Generates the raw numbers for the UI and the RNG resolver.
static func get_combat_forecast(attacker: Unit, defender: Unit, distance: int) -> CombatForecast:
	var forecast = CombatForecast.new()
	var attacker_preview := attacker.get_combat_stats(defender, distance)
	var defender_preview := defender.get_combat_stats(attacker, distance)

	forecast.attacker_damage = int(attacker_preview.get("damage", 0))
	forecast.attacker_hit_chance = int(attacker_preview.get("hit", 0))
	forecast.attacker_crit_chance = int(attacker_preview.get("crit", 0))
	forecast.attacker_can_double = (attacker.speed - defender.speed) >= FOLLOW_UP_SPEED_DIFF

	# CRITICAL: Only calculate a counterattack if the defender can actually reach the attacker!
	if can_attack_at_distance(distance, defender.attack_range, defender.min_attack_range):
		forecast.defender_can_counter = true
		forecast.defender_damage = int(defender_preview.get("damage", 0))
		forecast.defender_hit_chance = int(defender_preview.get("hit", 0))
		forecast.defender_crit_chance = int(defender_preview.get("crit", 0))
		forecast.defender_can_double = (defender.speed - attacker.speed) >= FOLLOW_UP_SPEED_DIFF
		
	return forecast

## 2. THE RESOLUTION: Rolls the dice and writes the script for the Battle Scene.
static func resolve_combat(attacker: Unit, defender: Unit, distance: int) -> Array[CombatStrike]:
	var strikes: Array[CombatStrike] = []
	var forecast = get_combat_forecast(attacker, defender, distance)
	
	# Track the HP dynamically as the strikes resolve
	var hp_state := {
		"defender": defender.current_stats.hp,
		"attacker": attacker.current_stats.hp
	}
	var atk_kind = get_attack_kind(attacker.character_data.equipped_weapon, distance)
	var def_kind = get_attack_kind(defender.character_data.equipped_weapon, distance)
	
	# --- Helper Function to Process a Single Strike ---
	var process_strike = func(is_attacker: bool, dmg: int, hit_chance: int, crit_chance: int, is_counter: bool, is_follow_up: bool) -> bool:
		var strike = CombatStrike.new()
		strike.is_attacker_striking = is_attacker
		strike.is_counter = is_counter
		strike.is_follow_up = is_follow_up
		# Assign the correct classification!
		strike.attack_kind = atk_kind if is_attacker else def_kind
		
		# RNG Roll: Did it hit?
		strike.is_hit = (randi() % 100) < hit_chance
		
		if strike.is_hit:
			strike.is_crit = (randi() % 100) < crit_chance
			strike.damage_dealt = dmg * 3 if strike.is_crit else dmg
			
			if is_attacker:
				hp_state["defender"] = int(hp_state["defender"]) - strike.damage_dealt
				strike.target_hp_after_strike = int(hp_state["defender"])
				strike.target_survived = int(hp_state["defender"]) > 0
			else:
				hp_state["attacker"] = int(hp_state["attacker"]) - strike.damage_dealt
				strike.target_hp_after_strike = int(hp_state["attacker"])
				strike.target_survived = int(hp_state["attacker"]) > 0
		else:
			strike.damage_dealt = 0
			strike.target_hp_after_strike = int(hp_state["defender"] if is_attacker else hp_state["attacker"])
			strike.target_survived = true
			
		strikes.append(strike)
		return strike.target_survived

	# --- PHASE 1: The Opener ---
	var def_survived = process_strike.call(true, forecast.attacker_damage, forecast.attacker_hit_chance, forecast.attacker_crit_chance, false, false)
	
	# --- PHASE 2: The Counterattack ---
	var atk_survived = true
	if def_survived and forecast.defender_can_counter:
		atk_survived = process_strike.call(false, forecast.defender_damage, forecast.defender_hit_chance, forecast.defender_crit_chance, true, false)
		
	# --- PHASE 3: The Follow-Up (Double Attack) ---
	if def_survived and atk_survived:
		if forecast.attacker_can_double:
			process_strike.call(true, forecast.attacker_damage, forecast.attacker_hit_chance, forecast.attacker_crit_chance, false, true)
		elif forecast.defender_can_double and forecast.defender_can_counter:
			process_strike.call(false, forecast.defender_damage, forecast.defender_hit_chance, forecast.defender_crit_chance, true, true)
			
	return strikes
