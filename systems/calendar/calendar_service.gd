extends Node
# systems/calendar/calendar_service.gd

# Emitted when a new day officially begins
signal day_changed(new_day: int, encounter_data: Dictionary)

# A typed dictionary contract for our deterministic encounters
const THREAT_CALENDAR: Dictionary = {
	3: {
		"id": &"orc_scout",
		"display_name": "Orc Scouting Party",
		"combat_scene": "res://scenes/level/CombatMap_1.tscn",
		"difficulty_tier": 1
	},
	7: {
		"id": &"blight_swarm",
		"display_name": "Blighted Swarm",
		"combat_scene": "res://scenes/level/CombatMap_2.tscn", # (You can build this scene later!)
		"difficulty_tier": 2
	}
}

## Returns the encounter data for a specific day. Returns empty dict if peaceful.
func get_encounter_for_day(day: int) -> Dictionary:
	if THREAT_CALENDAR.has(day):
		return THREAT_CALENDAR[day].duplicate(true)
	return {}

## Quick boolean check if a day has an attack scheduled
func has_encounter(day: int) -> bool:
	return THREAT_CALENDAR.has(day)

## Called by the global clock when the day officially advances
func trigger_day_change(new_day: int) -> void:
	var encounter = get_encounter_for_day(new_day)
	day_changed.emit(new_day, encounter)
