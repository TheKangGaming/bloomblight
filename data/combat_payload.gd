class_name CombatPayload
extends RefCounted

# Core identities
var attacker_data: CharacterData
var defender_data: CharacterData
var attacker_is_player: bool = false
var defender_is_player: bool = false

# The entire combat sequence, pre-calculated and ordered!
var strikes: Array[CombatStrike] = []

# Runtime stat snapshots
var attacker_stats: UnitStats
var defender_stats: UnitStats

# Runtime equipment snapshots
var attacker_weapon: WeaponData
var defender_weapon: WeaponData
var attacker_armor: ArmorData
var defender_armor: ArmorData
var attacker_accessory: AccessoryData
var defender_accessory: AccessoryData

# Context
var terrain_modifier: int = 0
var distance: int = 1
