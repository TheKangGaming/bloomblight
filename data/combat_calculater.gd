class_name CombatCalculator extends RefCounted

# Locking in your repo's official threshold
const FOLLOW_UP_SPEED_DIFF: int = 4 

## 1. THE FORECAST: Generates the raw numbers for the UI and the RNG resolver.
static func get_combat_forecast(attacker: Unit, defender: Unit, distance: int) -> CombatForecast:
	var forecast = CombatForecast.new()
	var atk_stats = attacker.current_stats
	var def_stats = defender.current_stats
	
	# --- Attacker Math ---
	# (NOTE: Replace these with your actual game formulas!)
	forecast.attacker_damage = maxi(0, atk_stats.attack - def_stats.defense) 
	forecast.attacker_hit_chance = 85 # Placeholder formula
	forecast.attacker_crit_chance = 5 # Placeholder formula
	forecast.attacker_can_double = (atk_stats.speed - def_stats.speed) >= FOLLOW_UP_SPEED_DIFF
	
	# --- Defender Math ---
	var def_weapon = defender.character_data.equipped_weapon
	var def_range = def_weapon.attack_range if def_weapon else 1
	
	if distance <= def_range:
		forecast.defender_can_counter = true
		forecast.defender_damage = maxi(0, def_stats.attack - atk_stats.defense)
		forecast.defender_hit_chance = 85 # Placeholder formula
		forecast.defender_crit_chance = 5 # Placeholder formula
		forecast.defender_can_double = (def_stats.speed - atk_stats.speed) >= FOLLOW_UP_SPEED_DIFF
		
	return forecast

## 2. THE RESOLUTION: Rolls the dice and writes the script for the Battle Scene.
static func resolve_combat(attacker: Unit, defender: Unit, distance: int) -> Array[CombatStrike]:
	var strikes: Array[CombatStrike] = []
	var forecast = get_combat_forecast(attacker, defender, distance)
	
	# Track the HP dynamically as the strikes resolve
	var current_defender_hp = defender.current_stats.hp
	var current_attacker_hp = attacker.current_stats.hp
	
	# --- Helper Function to Process a Single Strike ---
	var process_strike = func(is_attacker: bool, dmg: int, hit_chance: int, crit_chance: int, is_counter: bool, is_follow_up: bool) -> bool:
		var strike = CombatStrike.new()
		strike.is_attacker_striking = is_attacker
		strike.is_counter = is_counter
		strike.is_follow_up = is_follow_up
		
		# RNG Roll: Did it hit?
		strike.is_hit = (randi() % 100) < hit_chance
		
		if strike.is_hit:
			# RNG Roll: Did it crit?
			strike.is_crit = (randi() % 100) < crit_chance
			strike.damage_dealt = dmg * 3 if strike.is_crit else dmg # Standard 3x crit multiplier
			
			# Apply damage to the correct target
			if is_attacker:
				current_defender_hp -= strike.damage_dealt
				strike.target_hp_after_strike = current_defender_hp
				strike.target_survived = current_defender_hp > 0
			else:
				current_attacker_hp -= strike.damage_dealt
				strike.target_hp_after_strike = current_attacker_hp
				strike.target_survived = current_attacker_hp > 0
		else:
			# Missed!
			strike.damage_dealt = 0
			strike.target_hp_after_strike = current_defender_hp if is_attacker else current_attacker_hp
			strike.target_survived = true
			
		strikes.append(strike)
		return strike.target_survived # Return true if they lived, false if they died

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
