@tool
class_name AccessoryData
extends Resource

@export var accessory_name: String = "Traveler Charm"
@export var description: String = "A small trinket said to bring subtle fortune."
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
