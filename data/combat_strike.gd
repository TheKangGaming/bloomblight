class_name CombatStrike extends RefCounted

var is_attacker_striking: bool = true
var is_hit: bool = false
var is_crit: bool = false
var damage_dealt: int = 0
var target_hp_after_strike: int = 0
var target_survived: bool = true

# Context flags (Optional, but great for UI popups like "DOUBLE!" or "COUNTER!")
var is_counter: bool = false
var is_follow_up: bool = false
