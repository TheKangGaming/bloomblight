@tool
class_name ClassData
extends Resource

@export var metadata_name: String = ""
@export var tags: PackedStringArray = PackedStringArray()
@export var default_weapon_profile: StringName = &""
@export var primary_damage_stat: StringName = &"strength"
@export var secondary_stat: StringName = &""
# Free-form class role label (for example: fighter, mage, tank).
# Tanks can now fully negate weak attacks when their defense meets/exceeds incoming might.
@export var role: String = ""

@export var base_stats: Dictionary = {
	"max_health": 20,
	"strength": 5,
	"defense": 2,
	"magic_defense": 1,
	"dexterity": 5,
	"intelligence": 0,
	"speed": 5,
	"move_range": 6,
	"attack_range": 0,
}

@export var growth_rates: Dictionary = {
	"max_health": 50,
	"strength": 40,
	"defense": 22,
	"magic_defense": 20,
	"dexterity": 35,
	"intelligence": 25,
	"speed": 35,
	"move_range": 0,
	"attack_range": 0,
}

@export var stat_caps: Dictionary = {
	"max_health": 60,
	"strength": 30,
	"defense": 24,
	"magic_defense": 22,
	"dexterity": 30,
	"intelligence": 30,
	"speed": 30,
	"move_range": 9,
	"attack_range": 3,
}

# Optional pity-style floor for growths.
# Example: {"strength": 3} guarantees at least +1 STR every 3 levels.
@export var minimum_gain_intervals: Dictionary = {}


func get_base_stat(stat_key: String, fallback: int = 0) -> int:
	return int(base_stats.get(stat_key, fallback))


func get_growth_rate(stat_key: String, fallback: int = 0) -> int:
	return int(growth_rates.get(stat_key, fallback))


func get_stat_cap(stat_key: String, fallback: int = 0) -> int:
	return int(stat_caps.get(stat_key, fallback))


func get_minimum_gain_interval(stat_key: String, fallback: int = 0) -> int:
	return maxi(int(minimum_gain_intervals.get(stat_key, fallback)), 0)
