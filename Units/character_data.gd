@tool
class_name CharacterData
extends Resource

@export var display_name: String = ""
@export var class_data: ClassData

@export var personal_base_bonuses: Dictionary = {}
@export var personal_growth_bonuses: Dictionary = {}

@export var portrait: Texture2D
@export var scene_reference: PackedScene
