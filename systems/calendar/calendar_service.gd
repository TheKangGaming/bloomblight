extends Node
# systems/calendar/calendar_service.gd

const DAYS_PER_SEASON := 28
const SEASON_ORDER: Array[StringName] = [Global.SPRING, Global.SUMMER, Global.FALL, Global.WINTER]

# Emitted when a new day officially begins
signal day_changed(new_day: int, encounter_data: Dictionary)

# A typed dictionary contract for our deterministic encounters
const THREAT_CALENDAR: Dictionary = {
	2: {
		"id": &"orc_scout",
		"display_name": "Orc Scouting Party",
		"combat_scene": "res://scenes/level/day_two_battle.tscn",
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

## Converts world day to a season. Day 1 starts in Spring.
func get_season_for_day(day: int) -> StringName:
	if day <= 0:
		return Global.SPRING

	var season_index := int(floor(float(day - 1) / float(DAYS_PER_SEASON))) % SEASON_ORDER.size()
	return SEASON_ORDER[season_index]

func get_current_season() -> StringName:
	return get_season_for_day(Global.current_day)
