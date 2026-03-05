@tool
class_name UnitStats
extends Resource

@export var hp: int = 20
@export var max_hp: int = 20
@export var str: int = 5
@export var def: int = 2
@export var dex: int = 5
@export var int_stat: int = 0
@export var spd: int = 5
@export var mov: int = 6
@export var atk_rng: int = 1

@export var growth_rates: Dictionary = {}
@export var stat_caps: Dictionary = {}

const _ALIASES := {
	"HP": "hp",
	"health": "hp",
	"MAX_HP": "max_hp",
	"max_health": "max_hp",
	"STR": "str",
	"strength": "str",
	"DEF": "def",
	"defense": "def",
	"DEX": "dex",
	"dexterity": "dex",
	"INT": "int_stat",
	"intelligence": "int_stat",
	"SPD": "spd",
	"speed": "spd",
	"MOV": "mov",
	"move_range": "mov",
	"ATK_RNG": "atk_rng",
	"attack_range": "atk_rng",
}


func clone() -> UnitStats:
	var copy := UnitStats.new()
	copy.hp = hp
	copy.max_hp = max_hp
	copy.str = str
	copy.def = def
	copy.dex = dex
	copy.int_stat = int_stat
	copy.spd = spd
	copy.mov = mov
	copy.atk_rng = atk_rng
	copy.growth_rates = growth_rates.duplicate(true)
	copy.stat_caps = stat_caps.duplicate(true)
	return copy


func apply_delta(delta: Dictionary) -> void:
	for raw_key in delta.keys():
		var key := _normalize_key(String(raw_key))
		if key.is_empty():
			continue
		set(key, int(get(key)) + int(delta[raw_key]))


func clamp_to_caps(caps: Dictionary = stat_caps) -> void:
	var resolved_caps := caps if not caps.is_empty() else stat_caps
	if not resolved_caps.is_empty():
		if resolved_caps.has("HP") or resolved_caps.has("MAX_HP") or resolved_caps.has("max_health"):
			max_hp = mini(max_hp, _extract_value(resolved_caps, "MAX_HP", max_hp))
		str = mini(str, _extract_value(resolved_caps, "STR", str))
		def = mini(def, _extract_value(resolved_caps, "DEF", def))
		dex = mini(dex, _extract_value(resolved_caps, "DEX", dex))
		int_stat = mini(int_stat, _extract_value(resolved_caps, "INT", int_stat))
		spd = mini(spd, _extract_value(resolved_caps, "SPD", spd))
		mov = mini(mov, _extract_value(resolved_caps, "MOV", mov))
		atk_rng = mini(atk_rng, _extract_value(resolved_caps, "ATK_RNG", atk_rng))

	hp = clampi(hp, 0, max_hp)


func apply_class_progression(character_data: CharacterData) -> void:
	if character_data == null or character_data.class_data == null:
		return

	var class_info := character_data.class_data
	var personal_bases: Dictionary = character_data.personal_base_bonuses
	var personal_growths: Dictionary = character_data.personal_growth_bonuses

	max_hp = class_info.get_base_stat("max_health", max_hp) + int(personal_bases.get("max_health", 0))
	hp = max_hp + int(personal_bases.get("health", 0))
	str = class_info.get_base_stat("strength", str) + int(personal_bases.get("strength", 0))
	def = class_info.get_base_stat("defense", def) + int(personal_bases.get("defense", 0))
	dex = class_info.get_base_stat("dexterity", dex) + int(personal_bases.get("dexterity", 0))
	int_stat = class_info.get_base_stat("intelligence", int_stat) + int(personal_bases.get("intelligence", 0))
	spd = class_info.get_base_stat("speed", spd) + int(personal_bases.get("speed", 0))
	mov = class_info.get_base_stat("move_range", mov) + int(personal_bases.get("move_range", 0))
	atk_rng = class_info.get_base_stat("attack_range", atk_rng) + int(personal_bases.get("attack_range", 0))

	growth_rates = {
		"HP": clampi(class_info.get_growth_rate("max_health", 0) + int(personal_growths.get("max_health", 0)), 0, 100),
		"STR": clampi(class_info.get_growth_rate("strength", 0) + int(personal_growths.get("strength", 0)), 0, 100),
		"DEF": clampi(class_info.get_growth_rate("defense", 0) + int(personal_growths.get("defense", 0)), 0, 100),
		"DEX": clampi(class_info.get_growth_rate("dexterity", 0) + int(personal_growths.get("dexterity", 0)), 0, 100),
		"INT": clampi(class_info.get_growth_rate("intelligence", 0) + int(personal_growths.get("intelligence", 0)), 0, 100),
		"SPD": clampi(class_info.get_growth_rate("speed", 0) + int(personal_growths.get("speed", 0)), 0, 100),
		"MOV": clampi(class_info.get_growth_rate("move_range", 0) + int(personal_growths.get("move_range", 0)), 0, 100),
		"ATK_RNG": clampi(class_info.get_growth_rate("attack_range", 0) + int(personal_growths.get("attack_range", 0)), 0, 100),
	}

	stat_caps = {
		"MAX_HP": class_info.get_stat_cap("max_health", max_hp),
		"STR": class_info.get_stat_cap("strength", str),
		"DEF": class_info.get_stat_cap("defense", def),
		"DEX": class_info.get_stat_cap("dexterity", dex),
		"INT": class_info.get_stat_cap("intelligence", int_stat),
		"SPD": class_info.get_stat_cap("speed", spd),
		"MOV": class_info.get_stat_cap("move_range", mov),
		"ATK_RNG": class_info.get_stat_cap("attack_range", atk_rng),
	}

	clamp_to_caps()


func apply_player_snapshot(player_stats: Dictionary, buffs: Dictionary = {}) -> void:
	var bonus_hp := int(buffs.get("VIT", 0)) * 2
	var saved_hp := int(player_stats.get("HP", hp))
	max_hp = int(player_stats.get("MAX_HP", max_hp)) + bonus_hp

	if saved_hp > bonus_hp:
		hp = clampi(saved_hp + bonus_hp, 0, max_hp)
	else:
		hp = clampi(saved_hp, 0, max_hp)

	str = int(player_stats.get("STR", str)) + int(buffs.get("STR", 0))
	def = int(player_stats.get("DEF", def)) + int(buffs.get("DEF", 0))
	dex = int(player_stats.get("DEX", dex)) + int(buffs.get("DEX", 0))
	int_stat = int(player_stats.get("INT", int_stat)) + int(buffs.get("INT", 0))
	spd = int(player_stats.get("SPD", spd)) + int(buffs.get("SPD", 0))
	mov = int(player_stats.get("MOV", mov)) + int(buffs.get("MOV", 0))
	atk_rng = int(player_stats.get("ATK_RNG", atk_rng))

	clamp_to_caps()


func sync_player_hp_to(player_stats: Dictionary, buffs: Dictionary = {}) -> void:
	var bonus_hp := int(buffs.get("VIT", 0)) * 2
	var base_max_hp := int(player_stats.get("MAX_HP", max_hp))
	var unbuffed_hp := hp if hp <= bonus_hp else hp - bonus_hp
	player_stats["HP"] = clampi(unbuffed_hp, 0, base_max_hp)


func _normalize_key(raw_key: String) -> String:
	return _ALIASES.get(raw_key, "")


func _extract_value(stats: Dictionary, primary_key: String, fallback: int) -> int:
	if stats.has(primary_key):
		return int(stats[primary_key])

	for key in _ALIASES.keys():
		if _ALIASES[key] == _normalize_key(primary_key) and stats.has(key):
			return int(stats[key])

	return fallback
