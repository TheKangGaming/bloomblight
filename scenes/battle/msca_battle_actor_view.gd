extends Node2D

# Point this to wherever your MSCA AnimationTree controller is in the child scene
@onready var msca_player = $Player # Adjust this path to point to your MSCA visual rig!
@onready var parent_actor = get_parent()
@onready var sprite_layers: Node = $Player/SpriteLayers

var _character_data: CharacterData
var _facing := Vector2.RIGHT
var _pending_attack_state := ""

func _ready() -> void:
	if sprite_layers and sprite_layers.has_signal("animation_state_finished"):
		sprite_layers.connect("animation_state_finished", Callable(self, "_on_animation_state_finished"))

func _on_animation_state_finished(state_name: String, _wait_time: float = 0.0) -> void:
	if state_name != _pending_attack_state:
		return

	_pending_attack_state = ""

	if is_instance_valid(parent_actor) and parent_actor.has_signal("animation_finished_playing"):
		parent_actor.animation_finished_playing.emit()

func emit_impact() -> void:
	if is_instance_valid(parent_actor) and parent_actor.has_signal("strike_impact"):
		parent_actor.strike_impact.emit()

func apply_combat_snapshot(data: CharacterData, stats: UnitStats) -> void:
	_character_data = data
	# Future: Swap weapon sprites, color palettes, or armor layers here based on the data!

func set_facing(dir: Vector2) -> void:
	_facing = dir
	
	if msca_player != null:
		# 1. Force the MSCA internal variable to update
		if "facing_direction" in msca_player:
			msca_player.facing_direction = dir
			
		# 2. Immediately force the AnimationTree to adopt the new facing direction
		if msca_player.has_method("travel_to_anim"):
			msca_player.travel_to_anim("Idle", dir)
			
		# 3. (Optional) Keep the Sprite flip_h fallback just in case your rig 
		# relies on it instead of true directional animations
		var sprite = msca_player.get_node_or_null("SpriteLayers/01body") 
		if sprite and "flip_h" in sprite:
			sprite.flip_h = (dir == Vector2.LEFT)

func play_idle() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		msca_player.travel_to_anim("Idle", _facing)

func play_attack() -> void:
	if not msca_player or not msca_player.has_method("travel_to_anim"):
		return

	_pending_attack_state = _get_attack_animation_name()
	msca_player.travel_to_anim(_pending_attack_state, _facing)

func _get_attack_animation_name() -> String:
	var weapon_type := ""
	if _character_data and _character_data.equipped_weapon:
		weapon_type = _character_data.equipped_weapon.weapon_type

	match weapon_type:
		"Bow":
			return "BowShot"
		"Tome", "Staff":
			return "CastSpell1"
		_:
			return "StrikeForehandOneHandWeapon"

func play_hit() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		msca_player.travel_to_anim("Hurt", _facing)

func play_death() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		msca_player.travel_to_anim("DeathBounce", Vector2.DOWN)
		
func play_evade() -> void:
	if msca_player and msca_player.has_method("travel_to_anim"):
		msca_player.travel_to_anim("Evade", _facing)
