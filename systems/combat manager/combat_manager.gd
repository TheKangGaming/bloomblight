extends Node

signal payload_set(payload: CombatPayload)
signal payload_cleared

var _active_payload: CombatPayload = null

func has_payload() -> bool:
	return _active_payload != null

func get_payload() -> CombatPayload:
	return _active_payload

func clear_payload() -> void:
	_active_payload = null
	payload_cleared.emit()

## Extracts data from the live map units, builds a secure snapshot, and stores it for transition.
func setup_combat(attacker, defender, terrain_modifier: int = 0, distance: int = 1) -> CombatPayload:
	if attacker == null or defender == null:
		push_error("CombatManager: setup_combat requires both attacker and defender.")
		return null

	var payload := CombatPayload.new()

	# 1. Core Identities & Metadata
	payload.attacker_data = attacker.character_data
	payload.defender_data = defender.character_data
	
	# Assuming your map Unit script has an 'is_player' boolean (adjust if named differently!)
	payload.attacker_is_player = attacker.is_player
	payload.defender_is_player = defender.is_player

	# 2. Stat Snapshots (Deep Copies)
	if attacker.current_stats:
		payload.attacker_stats = attacker.current_stats.clone()
	if defender.current_stats:
		payload.defender_stats = defender.current_stats.clone()

	# 3. Equipment Snapshots
	if attacker.character_data:
		payload.attacker_weapon = attacker.character_data.equipped_weapon.duplicate(true) if attacker.character_data.equipped_weapon else null
		payload.attacker_armor = attacker.character_data.equipped_armor.duplicate(true) if attacker.character_data.equipped_armor else null
		payload.attacker_accessory = attacker.character_data.equipped_accessory.duplicate(true) if attacker.character_data.equipped_accessory else null

	if defender.character_data:
		payload.defender_weapon = defender.character_data.equipped_weapon.duplicate(true) if defender.character_data.equipped_weapon else null
		payload.defender_armor = defender.character_data.equipped_armor.duplicate(true) if defender.character_data.equipped_armor else null
		payload.defender_accessory = defender.character_data.equipped_accessory.duplicate(true) if defender.character_data.equipped_accessory else null

	# 4. Context
	payload.terrain_modifier = terrain_modifier
	payload.distance = distance

	# 5. Store and Emit
	_active_payload = payload
	payload_set.emit(payload)

	return payload
