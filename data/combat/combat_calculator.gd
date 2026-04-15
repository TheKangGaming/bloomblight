class_name CombatCalculator
extends RefCounted

const FOLLOW_UP_SPEED_DIFF: int = 4
const ARCHER_DAMAGE_STR_WEIGHT := 0.4
const ARCHER_DAMAGE_DEX_WEIGHT := 0.6

static func can_attack_at_distance(distance: int, attack_range: int, min_attack_range: int = -1) -> bool:
	if attack_range <= 0:
		return false
	if min_attack_range < 0:
		return distance == attack_range
	var lower_bound := mini(min_attack_range, attack_range)
	var upper_bound := maxi(min_attack_range, attack_range)
	return distance >= lower_bound and distance <= upper_bound

static func get_attack_kind(weapon: WeaponData, distance: int = -1) -> CombatStrike.AttackKind:
	if weapon == null:
		return CombatStrike.AttackKind.MELEE
	if weapon.weapon_type == "Bow":
		return CombatStrike.AttackKind.RANGED
	if weapon.weapon_type == "Tome" or weapon.weapon_type == "Staff":
		return CombatStrike.AttackKind.MAGIC
	if distance > 1 and weapon.projectile_style != StringName():
		return CombatStrike.AttackKind.RANGED
	return CombatStrike.AttackKind.MELEE

static func get_attack_preview_data_from_snapshot(stats: UnitStats, character_data: CharacterData, weapon: WeaponData = null) -> Dictionary:
	var resolved_weapon := weapon
	if resolved_weapon == null and character_data != null:
		resolved_weapon = character_data.equipped_weapon

	var weapon_might := 2
	if resolved_weapon != null:
		weapon_might = int(resolved_weapon.might)

	var uses_magic := _uses_magic_damage(character_data)
	var profile := _resolve_damage_stat_profile(stats, character_data, uses_magic)
	var attack_stat := int(profile.get("attack_stat", 0))
	var attack_total := maxi(0, attack_stat + weapon_might)

	return {
		"attack_total": attack_total,
		"weapon_might": weapon_might,
		"attack_stat": attack_stat,
		"profile": profile,
		"uses_magic_damage": uses_magic,
	}

static func get_combat_stats_from_snapshot(attacker_stats: UnitStats, attacker_data: CharacterData, attacker_weapon: WeaponData, attacker_modifiers: Dictionary, defender_stats: UnitStats, distance: int = -1) -> Dictionary:
	var weapon_might := 2
	var weapon_hit := 70
	if attacker_weapon != null:
		weapon_might = int(attacker_weapon.might)
		weapon_hit = int(attacker_weapon.hit_rate)

	var dexterity := _get_dexterity(attacker_stats)
	var target_speed := _get_speed(defender_stats)
	var hit_chance := clampi(weapon_hit + (dexterity * 2) - (target_speed * 2) + _get_modifier(attacker_modifiers, "hit"), 0, 100)
	var crit_chance := clampi(dexterity - int(target_speed / 2.0) + _get_modifier(attacker_modifiers, "crit"), 0, 100)
	var uses_magic_damage := _uses_magic_damage(attacker_data)
	var damage_profile := _resolve_damage_stat_profile(attacker_stats, attacker_data, uses_magic_damage)
	var attack_stat := int(damage_profile.get("attack_stat", 0))
	var defense_stat := _get_magic_defense(defender_stats) if uses_magic_damage else _get_defense(defender_stats)
	var actual_damage := maxi(0, (attack_stat + weapon_might) - defense_stat)
	if distance > 1 and attacker_weapon != null:
		actual_damage = maxi(0, actual_damage - maxi(int(attacker_weapon.ranged_damage_penalty), 0))

	return {
		"hit": hit_chance,
		"crit": crit_chance,
		"damage": actual_damage,
		"uses_magic_damage": uses_magic_damage,
		"damage_profile": damage_profile,
	}

static func get_combat_forecast(attacker: Unit, defender: Unit, distance: int) -> CombatForecast:
	if attacker == null or defender == null:
		return CombatForecast.new()

	var attacker_weapon: WeaponData = attacker.character_data.equipped_weapon if attacker.character_data != null else null
	var defender_weapon: WeaponData = defender.character_data.equipped_weapon if defender.character_data != null else null
	var attacker_modifiers := attacker.get_combat_modifiers_snapshot() if attacker.has_method("get_combat_modifiers_snapshot") else {}
	var defender_modifiers := defender.get_combat_modifiers_snapshot() if defender.has_method("get_combat_modifiers_snapshot") else {}

	return _build_forecast_from_snapshots(
		attacker.current_stats,
		attacker.character_data,
		attacker_weapon,
		attacker_modifiers,
		attacker.attack_range,
		attacker.min_attack_range,
		defender.current_stats,
		defender.character_data,
		defender_weapon,
		defender_modifiers,
		defender.attack_range,
		defender.min_attack_range,
		distance
	)

static func get_combat_forecast_from_payload(payload: CombatPayload) -> CombatForecast:
	if payload == null:
		return CombatForecast.new()

	return _build_forecast_from_snapshots(
		payload.attacker_stats,
		payload.attacker_data,
		payload.attacker_weapon,
		payload.attacker_combat_modifiers,
		_get_attack_range(payload.attacker_weapon, payload.attacker_stats),
		_get_min_attack_range(payload.attacker_weapon, payload.attacker_stats),
		payload.defender_stats,
		payload.defender_data,
		payload.defender_weapon,
		payload.defender_combat_modifiers,
		_get_attack_range(payload.defender_weapon, payload.defender_stats),
		_get_min_attack_range(payload.defender_weapon, payload.defender_stats),
		payload.distance
	)

static func resolve_combat(attacker: Unit, defender: Unit, distance: int) -> Array[CombatStrike]:
	if attacker == null or defender == null:
		return []

	var forecast := get_combat_forecast(attacker, defender, distance)
	var attacker_weapon: WeaponData = attacker.character_data.equipped_weapon if attacker.character_data != null else null
	var defender_weapon: WeaponData = defender.character_data.equipped_weapon if defender.character_data != null else null
	return _build_strikes_from_forecast(
		forecast,
		_get_hp(attacker.current_stats),
		_get_hp(defender.current_stats),
		get_attack_kind(attacker_weapon, distance),
		get_attack_kind(defender_weapon, distance)
	)

static func resolve_combat_from_payload(payload: CombatPayload) -> Array[CombatStrike]:
	if payload == null:
		return []

	var forecast := get_combat_forecast_from_payload(payload)
	return _build_strikes_from_forecast(
		forecast,
		_get_hp(payload.attacker_stats),
		_get_hp(payload.defender_stats),
		get_attack_kind(payload.attacker_weapon, payload.distance),
		get_attack_kind(payload.defender_weapon, payload.distance)
	)

static func _build_forecast_from_snapshots(attacker_stats: UnitStats, attacker_data: CharacterData, attacker_weapon: WeaponData, attacker_modifiers: Dictionary, attacker_attack_range: int, attacker_min_attack_range: int, defender_stats: UnitStats, defender_data: CharacterData, defender_weapon: WeaponData, defender_modifiers: Dictionary, defender_attack_range: int, defender_min_attack_range: int, distance: int) -> CombatForecast:
	var forecast := CombatForecast.new()
	var attacker_preview := get_combat_stats_from_snapshot(attacker_stats, attacker_data, attacker_weapon, attacker_modifiers, defender_stats, distance)
	var defender_preview := get_combat_stats_from_snapshot(defender_stats, defender_data, defender_weapon, defender_modifiers, attacker_stats, distance)

	forecast.attacker_damage = int(attacker_preview.get("damage", 0))
	forecast.attacker_hit_chance = int(attacker_preview.get("hit", 0))
	forecast.attacker_crit_chance = int(attacker_preview.get("crit", 0))
	forecast.attacker_can_double = (_get_speed(attacker_stats) - _get_speed(defender_stats)) >= FOLLOW_UP_SPEED_DIFF

	if can_attack_at_distance(distance, defender_attack_range, defender_min_attack_range):
		forecast.defender_can_counter = true
		forecast.defender_damage = int(defender_preview.get("damage", 0))
		forecast.defender_hit_chance = int(defender_preview.get("hit", 0))
		forecast.defender_crit_chance = int(defender_preview.get("crit", 0))
		forecast.defender_can_double = (_get_speed(defender_stats) - _get_speed(attacker_stats)) >= FOLLOW_UP_SPEED_DIFF

	return forecast

static func _build_strikes_from_forecast(forecast: CombatForecast, attacker_hp: int, defender_hp: int, attacker_kind: CombatStrike.AttackKind, defender_kind: CombatStrike.AttackKind) -> Array[CombatStrike]:
	var strikes: Array[CombatStrike] = []
	var hp_state := {
		"attacker": attacker_hp,
		"defender": defender_hp,
	}

	var process_strike = func(is_attacker: bool, damage: int, hit_chance: int, crit_chance: int, is_counter: bool, is_follow_up: bool) -> bool:
		var strike := CombatStrike.new()
		strike.is_attacker_striking = is_attacker
		strike.is_counter = is_counter
		strike.is_follow_up = is_follow_up
		strike.attack_kind = attacker_kind if is_attacker else defender_kind
		strike.is_hit = (randi() % 100) < hit_chance

		var target_key := "defender" if is_attacker else "attacker"
		if strike.is_hit:
			strike.is_crit = (randi() % 100) < crit_chance
			strike.damage_dealt = damage * 3 if strike.is_crit else damage
			hp_state[target_key] = maxi(int(hp_state[target_key]) - strike.damage_dealt, 0)
			strike.target_hp_after_strike = int(hp_state[target_key])
			strike.target_survived = int(hp_state[target_key]) > 0
		else:
			strike.damage_dealt = 0
			strike.target_hp_after_strike = maxi(int(hp_state[target_key]), 0)
			strike.target_survived = strike.target_hp_after_strike > 0

		strikes.append(strike)
		return strike.target_survived

	var defender_survived: bool = process_strike.call(true, forecast.attacker_damage, forecast.attacker_hit_chance, forecast.attacker_crit_chance, false, false)
	var attacker_survived: bool = true
	if defender_survived and forecast.defender_can_counter:
		attacker_survived = process_strike.call(false, forecast.defender_damage, forecast.defender_hit_chance, forecast.defender_crit_chance, true, false)

	if defender_survived and attacker_survived:
		if forecast.attacker_can_double:
			process_strike.call(true, forecast.attacker_damage, forecast.attacker_hit_chance, forecast.attacker_crit_chance, false, true)
		elif forecast.defender_can_double and forecast.defender_can_counter:
			process_strike.call(false, forecast.defender_damage, forecast.defender_hit_chance, forecast.defender_crit_chance, true, true)

	return strikes

static func _resolve_damage_stat_profile(stats: UnitStats, character_data: CharacterData, uses_magic_damage: bool) -> Dictionary:
	if uses_magic_damage:
		return {
			"attack_stat": _get_intelligence(stats),
			"stat_label": "INT",
			"formula_text": "INT",
		}

	var class_data: ClassData = character_data.class_data if character_data != null else null
	var primary_stat := String(class_data.primary_damage_stat).to_lower() if class_data != null else "strength"
	var secondary_stat := String(class_data.secondary_stat).to_lower() if class_data != null else ""
	var strength_total := _get_strength(stats)
	var dexterity_total := _get_dexterity(stats)

	if (primary_stat == "strength" or primary_stat == "str") and (secondary_stat == "dexterity" or secondary_stat == "dex"):
		var weighted_attack := int(floor((strength_total * ARCHER_DAMAGE_STR_WEIGHT) + (dexterity_total * ARCHER_DAMAGE_DEX_WEIGHT)))
		return {
			"attack_stat": weighted_attack,
			"stat_label": "STR/DEX",
			"formula_text": "floor(STR*0.4 + DEX*0.6)",
			"strength_total": strength_total,
			"dexterity_total": dexterity_total,
		}

	return {
		"attack_stat": strength_total,
		"stat_label": "STR",
		"formula_text": "STR",
	}

static func _uses_magic_damage(character_data: CharacterData) -> bool:
	if character_data == null or character_data.class_data == null:
		return false

	var class_info := character_data.class_data
	var damage_stat := String(class_info.primary_damage_stat).to_lower()
	if damage_stat == "intelligence" or damage_stat == "int":
		return true
	if damage_stat == "strength" or damage_stat == "str":
		return false
	return String(class_info.role).to_lower().contains("mage")

static func _get_attack_range(weapon: WeaponData, stats: UnitStats) -> int:
	if weapon != null:
		return maxi(1, int(weapon.attack_range))
	if stats != null:
		return maxi(1, int(stats.atk_rng))
	return 1

static func _get_min_attack_range(weapon: WeaponData, stats: UnitStats) -> int:
	if weapon != null:
		if int(weapon.min_attack_range) >= 0:
			return maxi(1, int(weapon.min_attack_range))
		return maxi(1, int(weapon.attack_range))
	return _get_attack_range(weapon, stats)

static func _get_modifier(modifiers: Dictionary, key: String) -> int:
	if modifiers.is_empty():
		return 0
	return int(modifiers.get(key, 0))

static func _get_hp(stats: UnitStats) -> int:
	return int(stats.hp) if stats != null else 0

static func _get_speed(stats: UnitStats) -> int:
	return int(stats.spd) if stats != null else 0

static func _get_strength(stats: UnitStats) -> int:
	return int(stats.str) if stats != null else 0

static func _get_dexterity(stats: UnitStats) -> int:
	return int(stats.dex) if stats != null else 0

static func _get_intelligence(stats: UnitStats) -> int:
	return int(stats.int_stat) if stats != null else 0

static func _get_defense(stats: UnitStats) -> int:
	return int(stats.physical_def) if stats != null else 0

static func _get_magic_defense(stats: UnitStats) -> int:
	return int(stats.magic_def) if stats != null else 0
