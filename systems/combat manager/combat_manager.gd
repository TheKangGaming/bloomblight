extends Node

# The secure briefcase
var _current_payload: CombatPayload

## Stores the payload securely before a scene transition.
func setup_combat(payload: CombatPayload) -> void:
	if payload == null:
		push_error("CombatManager: Attempted to setup combat with a null payload!")
		return
		
	_current_payload = payload

## Called by the BattleScene when it finishes loading.
func get_payload() -> CombatPayload:
	if _current_payload == null:
		push_warning("CombatManager: Requested payload, but none exists. Did the map fail to set it up?")
		
	return _current_payload

## Called when the battle is over and we return to the map.
func clear_payload() -> void:
	_current_payload = null

## Optional utility: Check if we are currently holding an active battle state
func is_combat_active() -> bool:
	return _current_payload != null
