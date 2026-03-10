extends Resource
class_name AbilityData

@export var ability_name: String = "New Ability"
@export var description: String = "Ability description."
@export var icon: Texture2D

@export_group("Mechanics")
@export var cooldown_turns: int = 4 # Replaced energy_cost with your Cooldown idea!
@export var range: int = 1          # Casting range
@export var radius: int = 2         # AOE radius

# The Execution Selector
enum AbilityType { DAMAGE, HEAL, BLOOM, HARVEST, BUFF }
@export var type: AbilityType = AbilityType.DAMAGE
