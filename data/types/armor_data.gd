@tool
class_name ArmorData
extends Resource

@export var armor_name: String = "Leather Vest"
@export var description: String = "Simple armor that offers modest protection."
@export var icon: Texture2D

@export_group("Bonus Modifiers")
@export var stat_bonuses: Dictionary = {
	"strength": 0,
	"intelligence": 0,
	"speed": 0,
	"defense": 0,
	"magic_defense": 0,
	"dexterity": 0,
}
