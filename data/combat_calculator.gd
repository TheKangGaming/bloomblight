class_name CombatCalculator extends RefCounted

# Locking in your repo's official threshold
const FOLLOW_UP_SPEED_DIFF: int = 4 

## 1. THE FORECAST: Generates the raw numbers for the UI and the RNG resolver.
## 1. THE FORECAST: Generates the raw numbers for the UI and the RNG resolver.
static func get_combat_forecast(attacker: Unit, defender: Unit, distance: int) -> CombatForecast:
	var forecast = CombatForecast.new()
	var atk_stats = attacker.current_stats
	var def_stats = defender.current_stats
	
	# --- ATTACKER MATH ---
	var atk_weapon = attacker.character_data.equipped_weapon
	
	# Default to Strength vs Physical Defense
	var atk_base_stat: int = atk_stats.str
	var def_resistance: int = def_stats.physical_def
	
	if atk_weapon:
		if atk_weapon.weapon_type == "Tome" or atk_weapon.weapon_type == "Staff":
			atk_base_stat = atk_stats.int_stat
			def_resistance = def_stats.magic_def
		elif atk_weapon.weapon_type == "Bow":
			# RESTORED ARCHER WEIGHTING: 40% STR, 60% DEX
			atk_base_stat = int(floor((atk_stats.str * 0.4) + (atk_stats.dex * 0.6)))
			
	var atk_power = atk_base_stat + (atk_weapon.might if atk_weapon else 0)
	forecast.attacker_damage = maxi(0, atk_power - def_resistance) 
	
	# Hit Rate: Weapon Hit + (Dexterity * 2) - (Enemy Speed * 2)
	var atk_base_hit = atk_weapon.hit_rate if atk_weapon else 0
	var atk_accuracy = atk_base_hit + (atk_stats.dex * 2)
	var def_evasion = def_stats.spd * 2
	forecast.attacker_hit_chance = clampi(atk_accuracy - def_evasion, 0, 100)
	
	# Crit Rate: Dexterity / 2
	forecast.attacker_crit_chance = clampi(atk_stats.dex / 2, 0, 100)
	
	# Double Attack: Speed Difference
	forecast.attacker_can_double = (atk_stats.spd - def_stats.spd) >= FOLLOW_UP_SPEED_DIFF
	
	# --- DEFENDER MATH ---
	var def_weapon = defender.character_data.equipped_weapon
	var def_range = def_weapon.attack_range if def_weapon else 1
	
	# CRITICAL: Only calculate a counterattack if the defender can actually reach the attacker!
	if distance <= def_range:
		forecast.defender_can_counter = true
		
		# Figure out what stat the defender uses
		var def_base_stat: int = def_stats.str
		var atk_resistance: int = atk_stats.physical_def
		
		if def_weapon:
			if def_weapon.weapon_type == "Tome" or def_weapon.weapon_type == "Staff":
				def_base_stat = def_stats.int_stat
				atk_resistance = atk_stats.magic_def
			elif def_weapon.weapon_type == "Bow":
				# RESTORED ARCHER WEIGHTING: 40% STR, 60% DEX
				def_base_stat = int(floor((def_stats.str * 0.4) + (def_stats.dex * 0.6)))
				
		var def_power = def_base_stat + (def_weapon.might if def_weapon else 0)
		forecast.defender_damage = maxi(0, def_power - atk_resistance)
		
		# Accuracy and Crit
		var def_base_hit = def_weapon.hit_rate if def_weapon else 0
		var def_accuracy = def_base_hit + (def_stats.dex * 2)
		var atk_evasion = atk_stats.spd * 2
		forecast.defender_hit_chance = clampi(def_accuracy - atk_evasion, 0, 100)
		
		forecast.defender_crit_chance = clampi(def_stats.dex / 2, 0, 100)
		forecast.defender_can_double = (def_stats.spd - atk_stats.spd) >= FOLLOW_UP_SPEED_DIFF
		
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
	
	# --- Helper to determine Attack Kind ---
	var get_attack_kind = func(weapon: WeaponData) -> CombatStrike.AttackKind:
		if not weapon: return CombatStrike.AttackKind.MELEE
		if weapon.weapon_type == "Bow": return CombatStrike.AttackKind.RANGED
		if weapon.weapon_type == "Tome" or weapon.weapon_type == "Staff": return CombatStrike.AttackKind.MAGIC
		return CombatStrike.AttackKind.MELEE

	var atk_kind = get_attack_kind.call(attacker.character_data.equipped_weapon)
	var def_kind = get_attack_kind.call(defender.character_data.equipped_weapon)
	
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
