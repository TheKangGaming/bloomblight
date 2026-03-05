@tool
class_name ClassData
extends Resource

@export var metadata_name: String = ""
@export var tags: PackedStringArray = PackedStringArray()
@export var default_weapon_profile: StringName = &""

@export var base_stats: Dictionary = {
	"max_health": 20,
	"strength": 5,
	"defense": 2,
	"dexterity": 5,
	"intelligence": 0,
	"speed": 5,
	"move_range": 6,
	"attack_range": 0,
}

@export var growth_rates: Dictionary = {
	"max_health": 50,
	"strength": 40,
	"defense": 30,
	"dexterity": 35,
	"intelligence": 25,
	"speed": 35,
	"move_range": 0,
	"attack_range": 0,
}

@export var stat_caps: Dictionary = {
	"max_health": 60,
	"strength": 30,
	"defense": 30,
	"dexterity": 30,
	"intelligence": 30,
	"speed": 30,
	"move_range": 9,
	"attack_range": 3,
}


func get_base_stat(stat_key: String, fallback: int = 0) -> int:
	return int(base_stats.get(stat_key, fallback))


func get_growth_rate(stat_key: String, fallback: int = 0) -> int:
	return int(growth_rates.get(stat_key, fallback))


func get_stat_cap(stat_key: String, fallback: int = 0) -> int:
	return int(stat_caps.get(stat_key, fallback))
