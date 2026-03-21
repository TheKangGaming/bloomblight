class_name CombatForecast extends RefCounted

# Attacker's side
var attacker_damage: int = 0
var attacker_hit_chance: int = 0
var attacker_crit_chance: int = 0
var attacker_can_double: bool = false

# Defender's side
var defender_can_counter: bool = false
var defender_damage: int = 0
var defender_hit_chance: int = 0
var defender_crit_chance: int = 0
var defender_can_double: bool = false
