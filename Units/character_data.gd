@tool
class_name CharacterData
extends Resource

@export var display_name: String = ""
@export var class_data: ClassData

@export var personal_base_bonuses: Dictionary = {}
@export var personal_growth_bonuses: Dictionary = {}
@export var abilities: Array[AbilityData] = []

@export var portrait: Texture2D
@export var scene_reference: PackedScene

@export_group("Equipment")
@export var equipped_weapon: WeaponData
@export var equipped_armor: ArmorData
@export var equipped_accessory: AccessoryData
