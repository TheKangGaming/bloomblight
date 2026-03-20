class_name CombatPayload
extends RefCounted

# Core identities
var attacker_data: CharacterData
var defender_data: CharacterData
var attacker_is_player: bool = false
var defender_is_player: bool = false

# --- The Return Ticket ---
var map_scene_path: String = ""

# --- The Combat Math ---
var attacker_damage_to_deal: int = 0
var defender_damage_to_deal: int = 0

# --- The Rules ---
var defender_can_counter: bool = false
var defender_survived: bool = true

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
