extends Node2D

# Point this to wherever your MSCA AnimationTree controller is in the child scene
@onready var msca_player = $Player # Adjust this path to point to your MSCA visual rig!

var _character_data: CharacterData
var _facing := Vector2.RIGHT

func apply_combat_snapshot(data: CharacterData, stats: UnitStats) -> void:
	_character_data = data
	# Future: Swap weapon sprites, color palettes, or armor layers here based on the data!

func set_facing(dir: Vector2) -> void:
	_facing = dir

func play_idle() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		msca_player.travel_to_anim("Idle", _facing)

func play_attack() -> void:
	if not msca_player or not msca_player.has_method("travel_to_anim"):
		return
		
	# Smart Animation Routing based on Weapon Type
	var weapon_type = ""
	if _character_data and _character_data.equipped_weapon:
		# Assuming your WeaponData has a way to check its type/category
		weapon_type = _character_data.equipped_weapon.weapon_type 
		
	match weapon_type:
		"Bow":
			msca_player.travel_to_anim("BowShot", _facing)
		"Tome", "Staff":
			msca_player.travel_to_anim("CastSpell1", _facing)
		_:
			# Default to melee for Swords, Axes, Lances, etc.
			msca_player.travel_to_anim("StrikeForehandOneHandWeapon", _facing)

func play_hit() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		msca_player.travel_to_anim("Hurt", _facing)

func play_death() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		msca_player.travel_to_anim("Death", _facing)
