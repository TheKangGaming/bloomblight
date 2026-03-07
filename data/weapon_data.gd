@tool
class_name WeaponData
extends Resource

@export var weapon_name: String = "Rusty Sword"
@export var description: String = "A weathered blade."
@export var icon: Texture2D

@export_group("Combat Stats")
@export var might: int = 5
@export var hit_rate: int = 90
@export var attack_range: int = 1

@export_group("Bonus Modifiers")
@export var stat_bonuses: Dictionary = {
	"strength": 0,
	"intelligence": 0,
	"speed": 0,
	"defense": 0,
	"magic_defense": 0,
	"dexterity": 0,
}
